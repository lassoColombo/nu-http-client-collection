# Auto-generated client for Alerter System API v1.6.0
# Source: https://api.apis.guru/v2/specs/alertersystem.com/1.6.0/openapi.json
# Auth: --token flag or $env.ALERTER_SYSTEM_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ALERTER_SYSTEM_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
def build-multipart-body [parts: record, file_fields: list<string>]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | transpose k v | where {|p| $p.v != null} | each {|p|
    let name = $p.k
    let val = $p.v
    if $name in $file_fields {
      let filename = ($val | path basename)
      let bytes = (open --raw $val | into binary | collect)
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  })
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/ld+json" "text/html"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "alert-log get-collection" } } | get name | first)
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

# Retrieves the collection of AlertLog resources.
#
# GET /api/alert-log
# operationId: api_alert-log_get_collection
export def "alert-log get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --monitor: string # allows empty value
  --monitor: list<string> # allows empty value
  --alert-service: string # allows empty value
  --alert-service: list<string> # allows empty value
  --alert-log-status-code: string # allows empty value
  --alert-log-status-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<alertLogErrorMessage: string, alertLogMessageId: string, alertLogStatusCode: string, alertService: string, createdAt: string, dataSegmentCode: string, id: string, monitor: string, partition: string, ping: string, resourceOwner: string, webhookResponseBody: string, webhookResponseHeaders: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "monitor" $monitor "scalar") (serialize-qp "monitor[]" $monitor "multi") (serialize-qp "alertService" $alert_service "scalar") (serialize-qp "alertService[]" $alert_service "multi") (serialize-qp "alertLogStatusCode" $alert_log_status_code "scalar") (serialize-qp "alertLogStatusCode[]" $alert_log_status_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/alert-log" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of AlertLogStatusCode resources.
#
# GET /api/alert-log-status-code
# operationId: api_alert-log-status-code_get_collection
export def "alert-log-status-code get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --properties: list<string> # allows empty value
]: nothing -> table<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/alert-log-status-code" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a AlertLogStatusCode resource.
#
# GET /api/alert-log-status-code/{id}
# operationId: api_alert-log-status-code_id_get
export def "alert-log-status-code get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/alert-log-status-code/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a AlertLog resource.
#
# GET /api/alert-log/{id}
# operationId: api_alert-log_id_get
export def "alert-log get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<alertLogErrorMessage: string, alertLogMessageId: string, alertLogStatusCode: string, alertService: string, createdAt: string, dataSegmentCode: string, id: string, monitor: string, partition: string, ping: string, resourceOwner: string, webhookResponseBody: string, webhookResponseHeaders: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/alert-log/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of AlertService resources.
#
# GET /api/alert-service
# operationId: api_alert-service_get_collection
export def "alert-service get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<alertServiceName: string, alertServiceNotes: string, alertServiceTransportCode: string, createdAt: string, creditsPerTransportAlert: int, dataSegmentCode: string, id: string, mediaObjects: list<string>, partition: string, recipientEmailAddress: string, recipientPhoneNumber: string, resourceOwner: string, transportAlerta: string, transportAllMySms: string, transportAmazonSns: string, transportBandwidth: string, transportChatwork: string, transportClickSend: string, transportClickatell: string, transportContactEveryone: string, transportDiscord: string, transportEmail: string, transportEngagespot: string, transportEsendex: string, transportExpo: string, transportFirebase: string, transportFortySixElks: string, transportFreeMobile: string, transportFreshdesk: string, transportGatewayApi: string, transportGitter: string, transportGoogleChat: string, transportGotify: string, transportHelpScout: string, transportInfobip: string, transportIqsms: string, transportKazInfoTeh: string, transportLightSms: string, transportLineNotify: string, transportLinkedIn: string, transportMailjet: string, transportMastodon: string, transportMattermost: string, transportMercure: string, transportMessageBird: string, transportMessageMedia: string, transportMicrosoftTeams: string, transportMobyt: string, transportOctopush: string, transportOneSignal: string, transportOpsgenie: string, transportOrangeSms: string, transportOvhCloud: string, transportPagerDuty: string, transportPagerTree: string, transportPlivo: string, transportPushbullet: string, transportPushover: string, transportPushy: string, transportRingCentral: string, transportRocketChat: string, transportSendberry: string, transportSendinblue: string, transportSimpleTextin: string, transportSinch: string, transportSlack: string, transportSms77: string, transportSmsBiuras: string, transportSmsFactor: string, transportSmsapi: string, transportSmsc: string, transportSmsmode: string, transportSpotHit: string, transportTelegram: string, transportTelnyx: string, transportTermii: string, transportTrello: string, transportTurboSms: string, transportTwilio: string, transportTwitter: string, transportVonage: string, transportWebhook: string, transportYunpian: string, transportZendesk: string, transportZulip: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/alert-service" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a AlertService resource.
#
# POST /api/alert-service
# operationId: api_alert-service_post
export def "alert-service create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --alert-service-name: string # The name of the alert service. Max 255 characters. (nullable)
  --alert-service-notes: string # Notes about the alert service. Max 10,000 characters. Formatting using Markdown is allowed. HTML will be removed. (nullable)
  --alert-service-transport-code: string # The transport of the alert service. (nullable, format: iri-reference)
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --media-objects: list<string> # Media objects that must be sent with each alert. Only applicable when you use your own email alert services.
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --recipient-email-address: string # The email address where alerts will be sent. (nullable, format: email)
  --recipient-phone-number: string # The phone number where alerts will be sent. Ensure that the number format complies with the external transport service that will send the alert. (nullable)
  --transport-alerta: string # nullable, format: iri-reference
  --transport-all-my-sms: string # nullable, format: iri-reference
  --transport-amazon-sns: string # nullable, format: iri-reference
  --transport-bandwidth: string # nullable, format: iri-reference
  --transport-chatwork: string # nullable, format: iri-reference
  --transport-click-send: string # nullable, format: iri-reference
  --transport-clickatell: string # nullable, format: iri-reference
  --transport-contact-everyone: string # nullable, format: iri-reference
  --transport-discord: string # nullable, format: iri-reference
  --transport-email: string # nullable, format: iri-reference
  --transport-engagespot: string # nullable, format: iri-reference
  --transport-esendex: string # nullable, format: iri-reference
  --transport-expo: string # nullable, format: iri-reference
  --transport-firebase: string # nullable, format: iri-reference
  --transport-forty-six-elks: string # nullable, format: iri-reference
  --transport-free-mobile: string # nullable, format: iri-reference
  --transport-freshdesk: string # nullable, format: iri-reference
  --transport-gateway-api: string # nullable, format: iri-reference
  --transport-gitter: string # nullable, format: iri-reference
  --transport-google-chat: string # nullable, format: iri-reference
  --transport-gotify: string # nullable, format: iri-reference
  --transport-help-scout: string # nullable, format: iri-reference
  --transport-infobip: string # nullable, format: iri-reference
  --transport-iqsms: string # nullable, format: iri-reference
  --transport-kaz-info-teh: string # nullable, format: iri-reference
  --transport-light-sms: string # nullable, format: iri-reference
  --transport-line-notify: string # nullable, format: iri-reference
  --transport-linked-in: string # nullable, format: iri-reference
  --transport-mailjet: string # nullable, format: iri-reference
  --transport-mastodon: string # nullable, format: iri-reference
  --transport-mattermost: string # nullable, format: iri-reference
  --transport-mercure: string # nullable, format: iri-reference
  --transport-message-bird: string # nullable, format: iri-reference
  --transport-message-media: string # nullable, format: iri-reference
  --transport-microsoft-teams: string # nullable, format: iri-reference
  --transport-mobyt: string # nullable, format: iri-reference
  --transport-octopush: string # nullable, format: iri-reference
  --transport-one-signal: string # nullable, format: iri-reference
  --transport-opsgenie: string # nullable, format: iri-reference
  --transport-orange-sms: string # nullable, format: iri-reference
  --transport-ovh-cloud: string # nullable, format: iri-reference
  --transport-pager-duty: string # nullable, format: iri-reference
  --transport-pager-tree: string # nullable, format: iri-reference
  --transport-plivo: string # nullable, format: iri-reference
  --transport-pushbullet: string # nullable, format: iri-reference
  --transport-pushover: string # nullable, format: iri-reference
  --transport-pushy: string # nullable, format: iri-reference
  --transport-ring-central: string # nullable, format: iri-reference
  --transport-rocket-chat: string # nullable, format: iri-reference
  --transport-sendberry: string # nullable, format: iri-reference
  --transport-sendinblue: string # nullable, format: iri-reference
  --transport-simple-textin: string # nullable, format: iri-reference
  --transport-sinch: string # nullable, format: iri-reference
  --transport-slack: string # nullable, format: iri-reference
  --transport-sms77: string # nullable, format: iri-reference
  --transport-sms-biuras: string # nullable, format: iri-reference
  --transport-sms-factor: string # nullable, format: iri-reference
  --transport-smsapi: string # nullable, format: iri-reference
  --transport-smsc: string # nullable, format: iri-reference
  --transport-smsmode: string # nullable, format: iri-reference
  --transport-spot-hit: string # nullable, format: iri-reference
  --transport-telegram: string # nullable, format: iri-reference
  --transport-telnyx: string # nullable, format: iri-reference
  --transport-termii: string # nullable, format: iri-reference
  --transport-trello: string # nullable, format: iri-reference
  --transport-turbo-sms: string # nullable, format: iri-reference
  --transport-twilio: string # nullable, format: iri-reference
  --transport-twitter: string # nullable, format: iri-reference
  --transport-vonage: string # nullable, format: iri-reference
  --transport-webhook: string # nullable, format: iri-reference
  --transport-yunpian: string # nullable, format: iri-reference
  --transport-zendesk: string # nullable, format: iri-reference
  --transport-zulip: string # nullable, format: iri-reference
]: any -> record<alertServiceName: string, alertServiceNotes: string, alertServiceTransportCode: string, createdAt: string, creditsPerTransportAlert: int, dataSegmentCode: string, id: string, mediaObjects: list<string>, partition: string, recipientEmailAddress: string, recipientPhoneNumber: string, resourceOwner: string, transportAlerta: string, transportAllMySms: string, transportAmazonSns: string, transportBandwidth: string, transportChatwork: string, transportClickSend: string, transportClickatell: string, transportContactEveryone: string, transportDiscord: string, transportEmail: string, transportEngagespot: string, transportEsendex: string, transportExpo: string, transportFirebase: string, transportFortySixElks: string, transportFreeMobile: string, transportFreshdesk: string, transportGatewayApi: string, transportGitter: string, transportGoogleChat: string, transportGotify: string, transportHelpScout: string, transportInfobip: string, transportIqsms: string, transportKazInfoTeh: string, transportLightSms: string, transportLineNotify: string, transportLinkedIn: string, transportMailjet: string, transportMastodon: string, transportMattermost: string, transportMercure: string, transportMessageBird: string, transportMessageMedia: string, transportMicrosoftTeams: string, transportMobyt: string, transportOctopush: string, transportOneSignal: string, transportOpsgenie: string, transportOrangeSms: string, transportOvhCloud: string, transportPagerDuty: string, transportPagerTree: string, transportPlivo: string, transportPushbullet: string, transportPushover: string, transportPushy: string, transportRingCentral: string, transportRocketChat: string, transportSendberry: string, transportSendinblue: string, transportSimpleTextin: string, transportSinch: string, transportSlack: string, transportSms77: string, transportSmsBiuras: string, transportSmsFactor: string, transportSmsapi: string, transportSmsc: string, transportSmsmode: string, transportSpotHit: string, transportTelegram: string, transportTelnyx: string, transportTermii: string, transportTrello: string, transportTurboSms: string, transportTwilio: string, transportTwitter: string, transportVonage: string, transportWebhook: string, transportYunpian: string, transportZendesk: string, transportZulip: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/alert-service")
  let req_body = {"alertServiceName": $alert_service_name, "alertServiceNotes": $alert_service_notes, "alertServiceTransportCode": $alert_service_transport_code, "dataSegmentCode": $data_segment_code, "mediaObjects": $media_objects, "partition": $partition, "recipientEmailAddress": $recipient_email_address, "recipientPhoneNumber": $recipient_phone_number, "transportAlerta": $transport_alerta, "transportAllMySms": $transport_all_my_sms, "transportAmazonSns": $transport_amazon_sns, "transportBandwidth": $transport_bandwidth, "transportChatwork": $transport_chatwork, "transportClickSend": $transport_click_send, "transportClickatell": $transport_clickatell, "transportContactEveryone": $transport_contact_everyone, "transportDiscord": $transport_discord, "transportEmail": $transport_email, "transportEngagespot": $transport_engagespot, "transportEsendex": $transport_esendex, "transportExpo": $transport_expo, "transportFirebase": $transport_firebase, "transportFortySixElks": $transport_forty_six_elks, "transportFreeMobile": $transport_free_mobile, "transportFreshdesk": $transport_freshdesk, "transportGatewayApi": $transport_gateway_api, "transportGitter": $transport_gitter, "transportGoogleChat": $transport_google_chat, "transportGotify": $transport_gotify, "transportHelpScout": $transport_help_scout, "transportInfobip": $transport_infobip, "transportIqsms": $transport_iqsms, "transportKazInfoTeh": $transport_kaz_info_teh, "transportLightSms": $transport_light_sms, "transportLineNotify": $transport_line_notify, "transportLinkedIn": $transport_linked_in, "transportMailjet": $transport_mailjet, "transportMastodon": $transport_mastodon, "transportMattermost": $transport_mattermost, "transportMercure": $transport_mercure, "transportMessageBird": $transport_message_bird, "transportMessageMedia": $transport_message_media, "transportMicrosoftTeams": $transport_microsoft_teams, "transportMobyt": $transport_mobyt, "transportOctopush": $transport_octopush, "transportOneSignal": $transport_one_signal, "transportOpsgenie": $transport_opsgenie, "transportOrangeSms": $transport_orange_sms, "transportOvhCloud": $transport_ovh_cloud, "transportPagerDuty": $transport_pager_duty, "transportPagerTree": $transport_pager_tree, "transportPlivo": $transport_plivo, "transportPushbullet": $transport_pushbullet, "transportPushover": $transport_pushover, "transportPushy": $transport_pushy, "transportRingCentral": $transport_ring_central, "transportRocketChat": $transport_rocket_chat, "transportSendberry": $transport_sendberry, "transportSendinblue": $transport_sendinblue, "transportSimpleTextin": $transport_simple_textin, "transportSinch": $transport_sinch, "transportSlack": $transport_slack, "transportSms77": $transport_sms77, "transportSmsBiuras": $transport_sms_biuras, "transportSmsFactor": $transport_sms_factor, "transportSmsapi": $transport_smsapi, "transportSmsc": $transport_smsc, "transportSmsmode": $transport_smsmode, "transportSpotHit": $transport_spot_hit, "transportTelegram": $transport_telegram, "transportTelnyx": $transport_telnyx, "transportTermii": $transport_termii, "transportTrello": $transport_trello, "transportTurboSms": $transport_turbo_sms, "transportTwilio": $transport_twilio, "transportTwitter": $transport_twitter, "transportVonage": $transport_vonage, "transportWebhook": $transport_webhook, "transportYunpian": $transport_yunpian, "transportZendesk": $transport_zendesk, "transportZulip": $transport_zulip} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of AlertServiceTransportCode resources.
#
# GET /api/alert-service-transport-code
# operationId: api_alert-service-transport-code_get_collection
export def "alert-service-transport-code get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --properties: list<string> # allows empty value
]: nothing -> table<codeName: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/alert-service-transport-code" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a AlertServiceTransportCode resource.
#
# GET /api/alert-service-transport-code/{id}
# operationId: api_alert-service-transport-code_id_get
export def "alert-service-transport-code get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<codeName: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/alert-service-transport-code/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes the AlertService resource.
#
# DELETE /api/alert-service/{id}
# operationId: api_alert-service_id_delete
export def "alert-service delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/alert-service/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a AlertService resource.
#
# GET /api/alert-service/{id}
# operationId: api_alert-service_id_get
export def "alert-service get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<alertServiceName: string, alertServiceNotes: string, alertServiceTransportCode: string, createdAt: string, creditsPerTransportAlert: int, dataSegmentCode: string, id: string, mediaObjects: list<string>, partition: string, recipientEmailAddress: string, recipientPhoneNumber: string, resourceOwner: string, transportAlerta: string, transportAllMySms: string, transportAmazonSns: string, transportBandwidth: string, transportChatwork: string, transportClickSend: string, transportClickatell: string, transportContactEveryone: string, transportDiscord: string, transportEmail: string, transportEngagespot: string, transportEsendex: string, transportExpo: string, transportFirebase: string, transportFortySixElks: string, transportFreeMobile: string, transportFreshdesk: string, transportGatewayApi: string, transportGitter: string, transportGoogleChat: string, transportGotify: string, transportHelpScout: string, transportInfobip: string, transportIqsms: string, transportKazInfoTeh: string, transportLightSms: string, transportLineNotify: string, transportLinkedIn: string, transportMailjet: string, transportMastodon: string, transportMattermost: string, transportMercure: string, transportMessageBird: string, transportMessageMedia: string, transportMicrosoftTeams: string, transportMobyt: string, transportOctopush: string, transportOneSignal: string, transportOpsgenie: string, transportOrangeSms: string, transportOvhCloud: string, transportPagerDuty: string, transportPagerTree: string, transportPlivo: string, transportPushbullet: string, transportPushover: string, transportPushy: string, transportRingCentral: string, transportRocketChat: string, transportSendberry: string, transportSendinblue: string, transportSimpleTextin: string, transportSinch: string, transportSlack: string, transportSms77: string, transportSmsBiuras: string, transportSmsFactor: string, transportSmsapi: string, transportSmsc: string, transportSmsmode: string, transportSpotHit: string, transportTelegram: string, transportTelnyx: string, transportTermii: string, transportTrello: string, transportTurboSms: string, transportTwilio: string, transportTwitter: string, transportVonage: string, transportWebhook: string, transportYunpian: string, transportZendesk: string, transportZulip: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/alert-service/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the AlertService resource.
#
# PUT /api/alert-service/{id}
# operationId: api_alert-service_id_put
export def "alert-service update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --alert-service-name: string # The name of the alert service. Max 255 characters. (nullable)
  --alert-service-notes: string # Notes about the alert service. Max 10,000 characters. Formatting using Markdown is allowed. HTML will be removed. (nullable)
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --media-objects: list<string> # Media objects that must be sent with each alert. Only applicable when you use your own email alert services.
  --recipient-email-address: string # The email address where alerts will be sent. (nullable, format: email)
  --recipient-phone-number: string # The phone number where alerts will be sent. Ensure that the number format complies with the external transport service that will send the alert. (nullable)
  --transport-alerta: string # nullable, format: iri-reference
  --transport-all-my-sms: string # nullable, format: iri-reference
  --transport-amazon-sns: string # nullable, format: iri-reference
  --transport-bandwidth: string # nullable, format: iri-reference
  --transport-chatwork: string # nullable, format: iri-reference
  --transport-click-send: string # nullable, format: iri-reference
  --transport-clickatell: string # nullable, format: iri-reference
  --transport-contact-everyone: string # nullable, format: iri-reference
  --transport-discord: string # nullable, format: iri-reference
  --transport-email: string # nullable, format: iri-reference
  --transport-engagespot: string # nullable, format: iri-reference
  --transport-esendex: string # nullable, format: iri-reference
  --transport-expo: string # nullable, format: iri-reference
  --transport-firebase: string # nullable, format: iri-reference
  --transport-forty-six-elks: string # nullable, format: iri-reference
  --transport-free-mobile: string # nullable, format: iri-reference
  --transport-freshdesk: string # nullable, format: iri-reference
  --transport-gateway-api: string # nullable, format: iri-reference
  --transport-gitter: string # nullable, format: iri-reference
  --transport-google-chat: string # nullable, format: iri-reference
  --transport-gotify: string # nullable, format: iri-reference
  --transport-help-scout: string # nullable, format: iri-reference
  --transport-infobip: string # nullable, format: iri-reference
  --transport-iqsms: string # nullable, format: iri-reference
  --transport-kaz-info-teh: string # nullable, format: iri-reference
  --transport-light-sms: string # nullable, format: iri-reference
  --transport-line-notify: string # nullable, format: iri-reference
  --transport-linked-in: string # nullable, format: iri-reference
  --transport-mailjet: string # nullable, format: iri-reference
  --transport-mastodon: string # nullable, format: iri-reference
  --transport-mattermost: string # nullable, format: iri-reference
  --transport-mercure: string # nullable, format: iri-reference
  --transport-message-bird: string # nullable, format: iri-reference
  --transport-message-media: string # nullable, format: iri-reference
  --transport-microsoft-teams: string # nullable, format: iri-reference
  --transport-mobyt: string # nullable, format: iri-reference
  --transport-octopush: string # nullable, format: iri-reference
  --transport-one-signal: string # nullable, format: iri-reference
  --transport-opsgenie: string # nullable, format: iri-reference
  --transport-orange-sms: string # nullable, format: iri-reference
  --transport-ovh-cloud: string # nullable, format: iri-reference
  --transport-pager-duty: string # nullable, format: iri-reference
  --transport-pager-tree: string # nullable, format: iri-reference
  --transport-plivo: string # nullable, format: iri-reference
  --transport-pushbullet: string # nullable, format: iri-reference
  --transport-pushover: string # nullable, format: iri-reference
  --transport-pushy: string # nullable, format: iri-reference
  --transport-ring-central: string # nullable, format: iri-reference
  --transport-rocket-chat: string # nullable, format: iri-reference
  --transport-sendberry: string # nullable, format: iri-reference
  --transport-sendinblue: string # nullable, format: iri-reference
  --transport-simple-textin: string # nullable, format: iri-reference
  --transport-sinch: string # nullable, format: iri-reference
  --transport-slack: string # nullable, format: iri-reference
  --transport-sms77: string # nullable, format: iri-reference
  --transport-sms-biuras: string # nullable, format: iri-reference
  --transport-sms-factor: string # nullable, format: iri-reference
  --transport-smsapi: string # nullable, format: iri-reference
  --transport-smsc: string # nullable, format: iri-reference
  --transport-smsmode: string # nullable, format: iri-reference
  --transport-spot-hit: string # nullable, format: iri-reference
  --transport-telegram: string # nullable, format: iri-reference
  --transport-telnyx: string # nullable, format: iri-reference
  --transport-termii: string # nullable, format: iri-reference
  --transport-trello: string # nullable, format: iri-reference
  --transport-turbo-sms: string # nullable, format: iri-reference
  --transport-twilio: string # nullable, format: iri-reference
  --transport-twitter: string # nullable, format: iri-reference
  --transport-vonage: string # nullable, format: iri-reference
  --transport-webhook: string # nullable, format: iri-reference
  --transport-yunpian: string # nullable, format: iri-reference
  --transport-zendesk: string # nullable, format: iri-reference
  --transport-zulip: string # nullable, format: iri-reference
]: any -> record<alertServiceName: string, alertServiceNotes: string, alertServiceTransportCode: string, createdAt: string, creditsPerTransportAlert: int, dataSegmentCode: string, id: string, mediaObjects: list<string>, partition: string, recipientEmailAddress: string, recipientPhoneNumber: string, resourceOwner: string, transportAlerta: string, transportAllMySms: string, transportAmazonSns: string, transportBandwidth: string, transportChatwork: string, transportClickSend: string, transportClickatell: string, transportContactEveryone: string, transportDiscord: string, transportEmail: string, transportEngagespot: string, transportEsendex: string, transportExpo: string, transportFirebase: string, transportFortySixElks: string, transportFreeMobile: string, transportFreshdesk: string, transportGatewayApi: string, transportGitter: string, transportGoogleChat: string, transportGotify: string, transportHelpScout: string, transportInfobip: string, transportIqsms: string, transportKazInfoTeh: string, transportLightSms: string, transportLineNotify: string, transportLinkedIn: string, transportMailjet: string, transportMastodon: string, transportMattermost: string, transportMercure: string, transportMessageBird: string, transportMessageMedia: string, transportMicrosoftTeams: string, transportMobyt: string, transportOctopush: string, transportOneSignal: string, transportOpsgenie: string, transportOrangeSms: string, transportOvhCloud: string, transportPagerDuty: string, transportPagerTree: string, transportPlivo: string, transportPushbullet: string, transportPushover: string, transportPushy: string, transportRingCentral: string, transportRocketChat: string, transportSendberry: string, transportSendinblue: string, transportSimpleTextin: string, transportSinch: string, transportSlack: string, transportSms77: string, transportSmsBiuras: string, transportSmsFactor: string, transportSmsapi: string, transportSmsc: string, transportSmsmode: string, transportSpotHit: string, transportTelegram: string, transportTelnyx: string, transportTermii: string, transportTrello: string, transportTurboSms: string, transportTwilio: string, transportTwitter: string, transportVonage: string, transportWebhook: string, transportYunpian: string, transportZendesk: string, transportZulip: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/alert-service/{id}"))
  let req_body = {"alertServiceName": $alert_service_name, "alertServiceNotes": $alert_service_notes, "dataSegmentCode": $data_segment_code, "mediaObjects": $media_objects, "recipientEmailAddress": $recipient_email_address, "recipientPhoneNumber": $recipient_phone_number, "transportAlerta": $transport_alerta, "transportAllMySms": $transport_all_my_sms, "transportAmazonSns": $transport_amazon_sns, "transportBandwidth": $transport_bandwidth, "transportChatwork": $transport_chatwork, "transportClickSend": $transport_click_send, "transportClickatell": $transport_clickatell, "transportContactEveryone": $transport_contact_everyone, "transportDiscord": $transport_discord, "transportEmail": $transport_email, "transportEngagespot": $transport_engagespot, "transportEsendex": $transport_esendex, "transportExpo": $transport_expo, "transportFirebase": $transport_firebase, "transportFortySixElks": $transport_forty_six_elks, "transportFreeMobile": $transport_free_mobile, "transportFreshdesk": $transport_freshdesk, "transportGatewayApi": $transport_gateway_api, "transportGitter": $transport_gitter, "transportGoogleChat": $transport_google_chat, "transportGotify": $transport_gotify, "transportHelpScout": $transport_help_scout, "transportInfobip": $transport_infobip, "transportIqsms": $transport_iqsms, "transportKazInfoTeh": $transport_kaz_info_teh, "transportLightSms": $transport_light_sms, "transportLineNotify": $transport_line_notify, "transportLinkedIn": $transport_linked_in, "transportMailjet": $transport_mailjet, "transportMastodon": $transport_mastodon, "transportMattermost": $transport_mattermost, "transportMercure": $transport_mercure, "transportMessageBird": $transport_message_bird, "transportMessageMedia": $transport_message_media, "transportMicrosoftTeams": $transport_microsoft_teams, "transportMobyt": $transport_mobyt, "transportOctopush": $transport_octopush, "transportOneSignal": $transport_one_signal, "transportOpsgenie": $transport_opsgenie, "transportOrangeSms": $transport_orange_sms, "transportOvhCloud": $transport_ovh_cloud, "transportPagerDuty": $transport_pager_duty, "transportPagerTree": $transport_pager_tree, "transportPlivo": $transport_plivo, "transportPushbullet": $transport_pushbullet, "transportPushover": $transport_pushover, "transportPushy": $transport_pushy, "transportRingCentral": $transport_ring_central, "transportRocketChat": $transport_rocket_chat, "transportSendberry": $transport_sendberry, "transportSendinblue": $transport_sendinblue, "transportSimpleTextin": $transport_simple_textin, "transportSinch": $transport_sinch, "transportSlack": $transport_slack, "transportSms77": $transport_sms77, "transportSmsBiuras": $transport_sms_biuras, "transportSmsFactor": $transport_sms_factor, "transportSmsapi": $transport_smsapi, "transportSmsc": $transport_smsc, "transportSmsmode": $transport_smsmode, "transportSpotHit": $transport_spot_hit, "transportTelegram": $transport_telegram, "transportTelnyx": $transport_telnyx, "transportTermii": $transport_termii, "transportTrello": $transport_trello, "transportTurboSms": $transport_turbo_sms, "transportTwilio": $transport_twilio, "transportTwitter": $transport_twitter, "transportVonage": $transport_vonage, "transportWebhook": $transport_webhook, "transportYunpian": $transport_yunpian, "transportZendesk": $transport_zendesk, "transportZulip": $transport_zulip} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of CreditsConsumption resources.
#
# GET /api/credits-consumption
# operationId: api_credits-consumption_get_collection
export def "credits-consumption get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, creditsConsumptionEventCode: string, creditsConsumptionNotes: string, creditsEventId: string, creditsEventIri: string, creditsUsed: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/credits-consumption" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a CreditsConsumption resource.
#
# GET /api/credits-consumption/{id}
# operationId: api_credits-consumption_id_get
export def "credits-consumption get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, creditsConsumptionEventCode: string, creditsConsumptionNotes: string, creditsEventId: string, creditsEventIri: string, creditsUsed: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/credits-consumption/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of HttpMethodCode resources.
#
# GET /api/http-method-code
# operationId: api_http-method-code_get_collection
export def "http-method-code get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --properties: list<string> # allows empty value
]: nothing -> table<codeName: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/http-method-code" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a HttpMethodCode resource.
#
# GET /api/http-method-code/{id}
# operationId: api_http-method-code_id_get
export def "http-method-code get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<codeName: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/http-method-code/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of MediaObject resources.
#
# GET /api/media-object
# operationId: api_media-object_get_collection
export def "media-object get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<contentUrl: string, createdAt: string, dataSegmentCode: string, fileSize: int, id: string, keywords: string, mimeType: string, originalName: string, partition: string, resourceOwner: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/media-object" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a MediaObject resource.
#
# POST /api/media-object
# operationId: api_media-object_post
export def "media-object create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (format: string)
  --file: string # format: binary
  --keywords: string # A string of keywords that can be used to search for a resource. Max 100 characters. (format: string)
  --partition: string # The unique id of the partition. Can be just the id or an IRI. (format: string)
]: any -> record<contentUrl: string, createdAt: string, dataSegmentCode: string, fileSize: int, id: string, keywords: string, mimeType: string, originalName: string, partition: string, resourceOwner: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/media-object")
  let req_body = {"dataSegmentCode": $data_segment_code, "file": $file, "keywords": $keywords, "partition": $partition} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body ["file"])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Removes the MediaObject resource.
#
# DELETE /api/media-object/{id}
# operationId: api_media-object_id_delete
export def "media-object delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/media-object/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a MediaObject resource.
#
# GET /api/media-object/{id}
# operationId: api_media-object_id_get
export def "media-object get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<contentUrl: string, createdAt: string, dataSegmentCode: string, fileSize: int, id: string, keywords: string, mimeType: string, originalName: string, partition: string, resourceOwner: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/media-object/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of Monitor resources.
#
# GET /api/monitor
# operationId: api_monitor_get_collection
export def "monitor get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<alertPayloadExtended: string, alertPayloadShort: string, alertServices: list<string>, allowUnauthenticatedPings: bool, contentCheckMustNotExist: bool, contentCheckText: string, contentCheckUrl: string, contentCheckXpathFilter: string, createdAt: string, dataSegmentCode: string, graceSeconds: int, humanizedInterval: string, id: string, internalMonitorName: string, intervalDays: int, intervalHours: int, intervalMinutes: int, intervalMonths: int, intervalSeconds: int, intervalYears: int, isMonitorPaused: bool, lastPingAt: string, monitorName: string, monitorNotes: string, monitorStatusCode: string, monitorTypeCode: string, nextPingAt: string, partition: string, pingSecret: string, publicDescription: string, resourceOwner: string, startMonitorAt: string, startMonitorAtUtc: string, systemMessages: list<string>, timezoneCode: string, webResponseSecondsLimit: int, webResponseUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/monitor" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Monitor resource.
#
# POST /api/monitor
# operationId: api_monitor_post
export def "monitor create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --alert-payload-extended: string # Payload that must be sent in the body of each alert when you use your own email or webhook alert services. This is the body for email alerts and the request body for webhook alerts. This text is not sent when using the built-in alert services. Sending user-supplied text via our own email server is too big a risk to our email reputation. Max 2 MB characters. (nullable)
  --alert-payload-short: string # Payload that must be sent in the body of each alert when you use your own short message alert services. This also serves as the subject for email alerts. Not used for webhooks. This text is not sent when using the built-in alert services. Sending user-supplied text via our own email server is too big a risk to our email reputation. Max 100 characters. (nullable)
  --alert-services: list<string> # The alert services that are related to this resource.
  --allow-unauthenticated-pings: oneof<nothing, bool> # Indicates that the monitor will accept pings that are not OAuth authenticated.
  --content-check-must-not-exist: oneof<nothing, bool> # Indicates that the Web Content monitor must verify the absence of the text or the Xpath node, and dispatch an alert if it is present. The default behavior is to verify the presence of the text or the Xpath node, and dispatch an alert if it is absent.
  --content-check-text: string # The text (case-insensitive) that must or must not be present at the contentCheckUrl. If contentCheckXpathFilter is supplied, then the only the text within that nodes is evaluated, otherwise text on the entire web page is evaluated. (nullable)
  --content-check-url: string # The URL that the Web Content monitor type must evaluate for the specified conditions. (nullable, format: uri)
  --content-check-xpath-filter: string # The Xpath filter (Xpath (https://en.wikipedia.org/wiki/XPath), Xpath Cheatsheet (https://devhints.io/xpath)) that selects a specific node in the HTML of the target web page. If contentCheckText is supplied, then only the text within the selected node is evaluated. If contentCheckText is left empty, then the presence or the absence of the selected node is evaluated. (nullable)
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --grace-seconds: int # The number of grace seconds after expiry of the time when the next ping was expected, before raising an alert. The number of grace seconds to allow before classifying a Measured Monitor task duration as an anomaly. (nullable)
  --interval-days: int # The number of days in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --interval-hours: int # The number of hours in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --interval-minutes: int # The number of minutes in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --interval-months: int # The number of months in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --interval-seconds: int # The number of seconds in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --interval-years: int # The number of years in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --is-monitor-paused: oneof<nothing, bool> # Indicates that the monitor is paused and will not send alerts.
  --monitor-name: string # The name of the monitor. Max 255 characters. (nullable)
  --monitor-notes: string # Notes about the monitor. Max 10,000 characters. Formatting using Markdown is allowed. HTML will be removed. (nullable)
  --monitor-type-code: string # The type of the monitor. (nullable, format: iri-reference)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --public-description: string # A text description of the monitor that is accessible to unauthenticated users that receive an alert from the monitor. Formatting using Markdown is allowed. HTML will be removed. (nullable)
  --start-monitor-at: string # When to start the Regular Interval type monitor or Heartbeat type monitor, or when to send the first alert of the Scheduled Repeatable Alert monitor. Cannot be blank for a Regular Interval, Heartbeat, or Scheduled Repeatable Alert type monitor, must be blank for other monitors types. This date-time is always interpreted to be in the timezone of the monitor. Any UTC offset is ignored. (nullable, format: date-time)
  timezone_code: string # The timezone of the monitor. Dates and times in alerts and reports will be in this time zone. (format: iri-reference)
  --web-response-seconds-limit: int # The time in seconds that the Web Response monitor type must allow for the web page to respond. (nullable)
  --web-response-url: string # The URL that the Web Response monitor type must evaluate for the specified conditions. (nullable, format: uri)
]: any -> record<alertPayloadExtended: string, alertPayloadShort: string, alertServices: list<string>, allowUnauthenticatedPings: bool, contentCheckMustNotExist: bool, contentCheckText: string, contentCheckUrl: string, contentCheckXpathFilter: string, createdAt: string, dataSegmentCode: string, graceSeconds: int, humanizedInterval: string, id: string, internalMonitorName: string, intervalDays: int, intervalHours: int, intervalMinutes: int, intervalMonths: int, intervalSeconds: int, intervalYears: int, isMonitorPaused: bool, lastPingAt: string, monitorName: string, monitorNotes: string, monitorStatusCode: string, monitorTypeCode: string, nextPingAt: string, partition: string, pingSecret: string, publicDescription: string, resourceOwner: string, startMonitorAt: string, startMonitorAtUtc: string, systemMessages: list<string>, timezoneCode: string, webResponseSecondsLimit: int, webResponseUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/monitor")
  let req_body = {"alertPayloadExtended": $alert_payload_extended, "alertPayloadShort": $alert_payload_short, "alertServices": $alert_services, "allowUnauthenticatedPings": $allow_unauthenticated_pings, "contentCheckMustNotExist": $content_check_must_not_exist, "contentCheckText": $content_check_text, "contentCheckUrl": $content_check_url, "contentCheckXpathFilter": $content_check_xpath_filter, "dataSegmentCode": $data_segment_code, "graceSeconds": $grace_seconds, "intervalDays": $interval_days, "intervalHours": $interval_hours, "intervalMinutes": $interval_minutes, "intervalMonths": $interval_months, "intervalSeconds": $interval_seconds, "intervalYears": $interval_years, "isMonitorPaused": $is_monitor_paused, "monitorName": $monitor_name, "monitorNotes": $monitor_notes, "monitorTypeCode": $monitor_type_code, "partition": $partition, "publicDescription": $public_description, "startMonitorAt": $start_monitor_at, "timezoneCode": $timezone_code, "webResponseSecondsLimit": $web_response_seconds_limit, "webResponseUrl": $web_response_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of MonitorStatusCode resources.
#
# GET /api/monitor-status-code
# operationId: api_monitor-status-code_get_collection
export def "monitor-status-code get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --properties: list<string> # allows empty value
]: nothing -> table<codeDescription: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/monitor-status-code" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a MonitorStatusCode resource.
#
# GET /api/monitor-status-code/{id}
# operationId: api_monitor-status-code_id_get
export def "monitor-status-code get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<codeDescription: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/monitor-status-code/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of MonitorStatusLog resources.
#
# GET /api/monitor-status-log
# operationId: api_monitor-status-log_get_collection
export def "monitor-status-log get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --monitor: string # allows empty value
  --monitor: list<string> # allows empty value
  --monitor-status-code: string # allows empty value
  --monitor-status-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, monitor: string, monitorStatusCode: string, partition: string, ping: string, resourceOwner: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "monitor" $monitor "scalar") (serialize-qp "monitor[]" $monitor "multi") (serialize-qp "monitorStatusCode" $monitor_status_code "scalar") (serialize-qp "monitorStatusCode[]" $monitor_status_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/monitor-status-log" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a MonitorStatusLog resource.
#
# GET /api/monitor-status-log/{id}
# operationId: api_monitor-status-log_id_get
export def "monitor-status-log get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, monitor: string, monitorStatusCode: string, partition: string, ping: string, resourceOwner: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/monitor-status-log/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of MonitorTypeCode resources.
#
# GET /api/monitor-type-code
# operationId: api_monitor-type-code_get_collection
export def "monitor-type-code get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --properties: list<string> # allows empty value
]: nothing -> table<codeDescription: string, codeDescriptionExpanded: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/monitor-type-code" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a MonitorTypeCode resource.
#
# GET /api/monitor-type-code/{id}
# operationId: api_monitor-type-code_id_get
export def "monitor-type-code get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<codeDescription: string, codeDescriptionExpanded: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/monitor-type-code/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes the Monitor resource.
#
# DELETE /api/monitor/{id}
# operationId: api_monitor_id_delete
export def "monitor delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/monitor/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a Monitor resource.
#
# GET /api/monitor/{id}
# operationId: api_monitor_id_get
export def "monitor get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<alertPayloadExtended: string, alertPayloadShort: string, alertServices: list<string>, allowUnauthenticatedPings: bool, contentCheckMustNotExist: bool, contentCheckText: string, contentCheckUrl: string, contentCheckXpathFilter: string, createdAt: string, dataSegmentCode: string, graceSeconds: int, humanizedInterval: string, id: string, internalMonitorName: string, intervalDays: int, intervalHours: int, intervalMinutes: int, intervalMonths: int, intervalSeconds: int, intervalYears: int, isMonitorPaused: bool, lastPingAt: string, monitorName: string, monitorNotes: string, monitorStatusCode: string, monitorTypeCode: string, nextPingAt: string, partition: string, pingSecret: string, publicDescription: string, resourceOwner: string, startMonitorAt: string, startMonitorAtUtc: string, systemMessages: list<string>, timezoneCode: string, webResponseSecondsLimit: int, webResponseUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/monitor/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the Monitor resource.
#
# PUT /api/monitor/{id}
# operationId: api_monitor_id_put
export def "monitor update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --alert-payload-extended: string # Payload that must be sent in the body of each alert when you use your own email or webhook alert services. This is the body for email alerts and the request body for webhook alerts. This text is not sent when using the built-in alert services. Sending user-supplied text via our own email server is too big a risk to our email reputation. Max 2 MB characters. (nullable)
  --alert-payload-short: string # Payload that must be sent in the body of each alert when you use your own short message alert services. This also serves as the subject for email alerts. Not used for webhooks. This text is not sent when using the built-in alert services. Sending user-supplied text via our own email server is too big a risk to our email reputation. Max 100 characters. (nullable)
  --alert-services: list<string> # The alert services that are related to this resource.
  --allow-unauthenticated-pings: oneof<nothing, bool> # Indicates that the monitor will accept pings that are not OAuth authenticated.
  --content-check-must-not-exist: oneof<nothing, bool> # Indicates that the Web Content monitor must verify the absence of the text or the Xpath node, and dispatch an alert if it is present. The default behavior is to verify the presence of the text or the Xpath node, and dispatch an alert if it is absent.
  --content-check-text: string # The text (case-insensitive) that must or must not be present at the contentCheckUrl. If contentCheckXpathFilter is supplied, then the only the text within that nodes is evaluated, otherwise text on the entire web page is evaluated. (nullable)
  --content-check-url: string # The URL that the Web Content monitor type must evaluate for the specified conditions. (nullable, format: uri)
  --content-check-xpath-filter: string # The Xpath filter (Xpath (https://en.wikipedia.org/wiki/XPath), Xpath Cheatsheet (https://devhints.io/xpath)) that selects a specific node in the HTML of the target web page. If contentCheckText is supplied, then only the text within the selected node is evaluated. If contentCheckText is left empty, then the presence or the absence of the selected node is evaluated. (nullable)
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --grace-seconds: int # The number of grace seconds after expiry of the time when the next ping was expected, before raising an alert. The number of grace seconds to allow before classifying a Measured Monitor task duration as an anomaly. (nullable)
  --interval-days: int # The number of days in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --interval-hours: int # The number of hours in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --interval-minutes: int # The number of minutes in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --interval-months: int # The number of months in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --interval-seconds: int # The number of seconds in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --interval-years: int # The number of years in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --is-monitor-paused: oneof<nothing, bool> # Indicates that the monitor is paused and will not send alerts.
  --monitor-name: string # The name of the monitor. Max 255 characters. (nullable)
  --monitor-notes: string # Notes about the monitor. Max 10,000 characters. Formatting using Markdown is allowed. HTML will be removed. (nullable)
  --public-description: string # A text description of the monitor that is accessible to unauthenticated users that receive an alert from the monitor. Formatting using Markdown is allowed. HTML will be removed. (nullable)
  --start-monitor-at: string # When to start the Regular Interval type monitor or Heartbeat type monitor, or when to send the first alert of the Scheduled Repeatable Alert monitor. Cannot be blank for a Regular Interval, Heartbeat, or Scheduled Repeatable Alert type monitor, must be blank for other monitors types. This date-time is always interpreted to be in the timezone of the monitor. Any UTC offset is ignored. (nullable, format: date-time)
  timezone_code: string # The timezone of the monitor. Dates and times in alerts and reports will be in this time zone. (format: iri-reference)
  --web-response-seconds-limit: int # The time in seconds that the Web Response monitor type must allow for the web page to respond. (nullable)
  --web-response-url: string # The URL that the Web Response monitor type must evaluate for the specified conditions. (nullable, format: uri)
]: any -> record<alertPayloadExtended: string, alertPayloadShort: string, alertServices: list<string>, allowUnauthenticatedPings: bool, contentCheckMustNotExist: bool, contentCheckText: string, contentCheckUrl: string, contentCheckXpathFilter: string, createdAt: string, dataSegmentCode: string, graceSeconds: int, humanizedInterval: string, id: string, internalMonitorName: string, intervalDays: int, intervalHours: int, intervalMinutes: int, intervalMonths: int, intervalSeconds: int, intervalYears: int, isMonitorPaused: bool, lastPingAt: string, monitorName: string, monitorNotes: string, monitorStatusCode: string, monitorTypeCode: string, nextPingAt: string, partition: string, pingSecret: string, publicDescription: string, resourceOwner: string, startMonitorAt: string, startMonitorAtUtc: string, systemMessages: list<string>, timezoneCode: string, webResponseSecondsLimit: int, webResponseUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/monitor/{id}"))
  let req_body = {"alertPayloadExtended": $alert_payload_extended, "alertPayloadShort": $alert_payload_short, "alertServices": $alert_services, "allowUnauthenticatedPings": $allow_unauthenticated_pings, "contentCheckMustNotExist": $content_check_must_not_exist, "contentCheckText": $content_check_text, "contentCheckUrl": $content_check_url, "contentCheckXpathFilter": $content_check_xpath_filter, "dataSegmentCode": $data_segment_code, "graceSeconds": $grace_seconds, "intervalDays": $interval_days, "intervalHours": $interval_hours, "intervalMinutes": $interval_minutes, "intervalMonths": $interval_months, "intervalSeconds": $interval_seconds, "intervalYears": $interval_years, "isMonitorPaused": $is_monitor_paused, "monitorName": $monitor_name, "monitorNotes": $monitor_notes, "publicDescription": $public_description, "startMonitorAt": $start_monitor_at, "timezoneCode": $timezone_code, "webResponseSecondsLimit": $web_response_seconds_limit, "webResponseUrl": $web_response_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of Partition resources.
#
# GET /api/partition
# operationId: api_partition_get_collection
export def "partition get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<alertServices: list<string>, createdAt: string, dataSegmentCode: string, id: string, monitors: list<string>, partitionName: string, partitionNotes: string, resourceOwner: string, teamInvitations: list<string>, teamMembers: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/partition" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Partition resource.
#
# POST /api/partition
# operationId: api_partition_post
export def "partition create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --partition-name: string # The name of the partition. Max 255 characters. (nullable)
  --partition-notes: string # Notes about the partition. Max 10,000 characters. Formatting using Markdown is allowed. HTML will be removed. (nullable)
]: any -> record<alertServices: list<string>, createdAt: string, dataSegmentCode: string, id: string, monitors: list<string>, partitionName: string, partitionNotes: string, resourceOwner: string, teamInvitations: list<string>, teamMembers: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/partition")
  let req_body = {"dataSegmentCode": $data_segment_code, "partitionName": $partition_name, "partitionNotes": $partition_notes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the Partition resource.
#
# DELETE /api/partition/{id}
# operationId: api_partition_id_delete
export def "partition delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/partition/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a Partition resource.
#
# GET /api/partition/{id}
# operationId: api_partition_id_get
export def "partition get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<alertServices: list<string>, createdAt: string, dataSegmentCode: string, id: string, monitors: list<string>, partitionName: string, partitionNotes: string, resourceOwner: string, teamInvitations: list<string>, teamMembers: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/partition/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the Partition resource.
#
# PUT /api/partition/{id}
# operationId: api_partition_id_put
export def "partition update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --partition-name: string # The name of the partition. Max 255 characters. (nullable)
  --partition-notes: string # Notes about the partition. Max 10,000 characters. Formatting using Markdown is allowed. HTML will be removed. (nullable)
]: any -> record<alertServices: list<string>, createdAt: string, dataSegmentCode: string, id: string, monitors: list<string>, partitionName: string, partitionNotes: string, resourceOwner: string, teamInvitations: list<string>, teamMembers: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/partition/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "partitionName": $partition_name, "partitionNotes": $partition_notes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of Ping resources.
#
# GET /api/ping
# operationId: api_ping_get_collection
export def "ping get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --monitor: string # allows empty value
  --monitor: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<alertLogs: list<string>, createdAt: string, dataSegmentCode: string, expectNextPingAt: string, expectNextPingAtEpoch: int, id: string, ipAddress: string, monitor: string, monitorStatusLog: string, partition: string, pingCustomCode: string, pingCustomPayload: string, pingMethodCode: string, resourceOwner: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "monitor" $monitor "scalar") (serialize-qp "monitor[]" $monitor "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ping" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Ping resource.
#
# POST /api/ping
# operationId: api_ping_post
export def "ping create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --expect-next-ping-at: string # When to expect the next ping for a Last Ping monitor type. This date-time is always interpreted to be in the timezone of the monitor. Any UTC offset is ignored. Supply either "expectNextPingAt", or "expectNextPingAtEpoch", or a X_NEXT_PING request header, not more than one of those options. Must be blank for other monitor types. (nullable, format: date-time)
  --expect-next-ping-at-epoch: int # When to expect the next ping for a Last Ping monitor type, expressed in epoch timestamp format. Supply either "expectNextPingAt", or "expectNextPingAtEpoch", or a X_NEXT_PING request header, not more than one of those options. Must be blank for other monitor types. (nullable)
  monitor: string # The monitor that is related to this resource instance. (format: iri-reference)
  --ping-custom-code: string # The client-supplied custom code that is appended to the ping. Only the first 10 characters are used and saved. (nullable)
  --ping-custom-payload: string # The client-supplied custom payload that is saved with the ping. Only the first 100 characters are saved. This value overrides the value of an monitor's alert payload, if the ping results in an alert. (nullable)
]: any -> record<alertLogs: list<string>, createdAt: string, dataSegmentCode: string, expectNextPingAt: string, expectNextPingAtEpoch: int, id: string, ipAddress: string, monitor: string, monitorStatusLog: string, partition: string, pingCustomCode: string, pingCustomPayload: string, pingMethodCode: string, resourceOwner: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/ping")
  let req_body = {"expectNextPingAt": $expect_next_ping_at, "expectNextPingAtEpoch": $expect_next_ping_at_epoch, "monitor": $monitor, "pingCustomCode": $ping_custom_code, "pingCustomPayload": $ping_custom_payload} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of PingMethodCode resources.
#
# GET /api/ping-method-code
# operationId: api_ping-method-code_get_collection
export def "ping-method-code get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --properties: list<string> # allows empty value
]: nothing -> table<codeName: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ping-method-code" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a PingMethodCode resource.
#
# GET /api/ping-method-code/{id}
# operationId: api_ping-method-code_id_get
export def "ping-method-code get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<codeName: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/ping-method-code/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a Ping resource.
#
# GET /api/ping/{id}
# operationId: api_ping_id_get
export def "ping get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<alertLogs: list<string>, createdAt: string, dataSegmentCode: string, expectNextPingAt: string, expectNextPingAtEpoch: int, id: string, ipAddress: string, monitor: string, monitorStatusLog: string, partition: string, pingCustomCode: string, pingCustomPayload: string, pingMethodCode: string, resourceOwner: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/ping/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of TeamInvitation resources.
#
# GET /api/team-invitation
# operationId: api_team-invitation_get_collection
export def "team-invitation get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --invitee-email: string # allows empty value
  --invitee-email: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, inviteeEmail: string, inviteeFirstName: string, inviteeLastName: string, partition: string, resourceOwner: string, statusAt: string, teamInvitationStatus: string, teamMemberRoleCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "inviteeEmail" $invitee_email "scalar") (serialize-qp "inviteeEmail[]" $invitee_email "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/team-invitation" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TeamInvitation resource.
#
# POST /api/team-invitation
# operationId: api_team-invitation_post
export def "team-invitation create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --invitee-email: string # The email address of the person that is being invited. (nullable, format: email)
  --invitee-first-name: string # The first name of the person that is being invited. (nullable)
  --invitee-last-name: string # The last name of the person that is being invited. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --team-member-role-code: string # The role of the team member on the team. (format: iri-reference)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, inviteeEmail: string, inviteeFirstName: string, inviteeLastName: string, partition: string, resourceOwner: string, statusAt: string, teamInvitationStatus: string, teamMemberRoleCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/team-invitation")
  let req_body = {"dataSegmentCode": $data_segment_code, "inviteeEmail": $invitee_email, "inviteeFirstName": $invitee_first_name, "inviteeLastName": $invitee_last_name, "partition": $partition, "teamMemberRoleCode": $team_member_role_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TeamInvitation resource.
#
# DELETE /api/team-invitation/{id}
# operationId: api_team-invitation_id_delete
export def "team-invitation delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/team-invitation/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TeamInvitation resource.
#
# GET /api/team-invitation/{id}
# operationId: api_team-invitation_id_get
export def "team-invitation get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, inviteeEmail: string, inviteeFirstName: string, inviteeLastName: string, partition: string, resourceOwner: string, statusAt: string, teamInvitationStatus: string, teamMemberRoleCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/team-invitation/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of TeamMember resources.
#
# GET /api/team-member
# operationId: api_team-member_get_collection
export def "team-member get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --user-account: string # allows empty value
  --user-account: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, teamMemberRoleCode: string, userAccount: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "userAccount" $user_account "scalar") (serialize-qp "userAccount[]" $user_account "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/team-member" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of TeamMemberRoleCode resources.
#
# GET /api/team-member-role-code
# operationId: api_team-member-role-code_get_collection
export def "team-member-role-code get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --properties: list<string> # allows empty value
]: nothing -> table<codeDescription: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/team-member-role-code" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TeamMemberRoleCode resource.
#
# GET /api/team-member-role-code/{id}
# operationId: api_team-member-role-code_id_get
export def "team-member-role-code get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<codeDescription: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/team-member-role-code/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes the TeamMember resource.
#
# DELETE /api/team-member/{id}
# operationId: api_team-member_id_delete
export def "team-member delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/team-member/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TeamMember resource.
#
# GET /api/team-member/{id}
# operationId: api_team-member_id_get
export def "team-member get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, teamMemberRoleCode: string, userAccount: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/team-member/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TeamMember resource.
#
# PUT /api/team-member/{id}
# operationId: api_team-member_id_put
export def "team-member update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --team-member-role-code: string # The role of the team member on the team. (nullable, format: iri-reference)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, teamMemberRoleCode: string, userAccount: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/team-member/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "teamMemberRoleCode": $team_member_role_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TimezoneCode resources.
#
# GET /api/timezone-code
# operationId: api_timezone-code_get_collection
export def "timezone-code get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --properties: list<string> # allows empty value
]: nothing -> table<codeName: string, id: string, offsetFromUtc: float, timezoneDateString: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/timezone-code" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TimezoneCode resource.
#
# GET /api/timezone-code/{id}
# operationId: api_timezone-code_id_get
export def "timezone-code get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<codeName: string, id: string, offsetFromUtc: float, timezoneDateString: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/timezone-code/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of TransportAlerta resources.
#
# GET /api/transport-alerta
# operationId: api_transport-alerta_get_collection
export def "transport-alerta get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<alertaApiKey: string, alertaCorrelate: string, alertaEnvironment: string, alertaEvent: string, alertaGroup: string, alertaHost: string, alertaOrigin: string, alertaResource: string, alertaService: string, alertaSeverity: string, alertaStatus: string, alertaTags: string, alertaType: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-alerta" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportAlerta resource.
#
# POST /api/transport-alerta
# operationId: api_transport-alerta_post
export def "transport-alerta create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --alerta-api-key: string # The API key for the Alerta service. (nullable)
  --alerta-correlate: string # The comma-separated list of related event names for the Alerta service. (nullable)
  --alerta-environment: string # The environment value for the Alerta service. (nullable)
  --alerta-event: string # The event value for the Alerta service. (nullable)
  --alerta-group: string # The group value for the Alerta service. (nullable)
  --alerta-host: string # The host name for the Alerta service (omit the "https://" part). (nullable, format: hostname)
  --alerta-origin: string # The origin value for the Alerta service. (nullable)
  --alerta-resource: string # The resource value for the Alerta service. (nullable)
  --alerta-service: string # The comma-separated list of affected services for the Alerta service. (nullable)
  --alerta-severity: string # The severity value for the Alerta service. (nullable)
  --alerta-status: string # The status value for the Alerta service. (nullable)
  --alerta-tags: string # The comma-separated list of tags for the Alerta service. (nullable)
  --alerta-type: string # The type value for the Alerta service. (nullable)
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<alertaApiKey: string, alertaCorrelate: string, alertaEnvironment: string, alertaEvent: string, alertaGroup: string, alertaHost: string, alertaOrigin: string, alertaResource: string, alertaService: string, alertaSeverity: string, alertaStatus: string, alertaTags: string, alertaType: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-alerta")
  let req_body = {"alertaApiKey": $alerta_api_key, "alertaCorrelate": $alerta_correlate, "alertaEnvironment": $alerta_environment, "alertaEvent": $alerta_event, "alertaGroup": $alerta_group, "alertaHost": $alerta_host, "alertaOrigin": $alerta_origin, "alertaResource": $alerta_resource, "alertaService": $alerta_service, "alertaSeverity": $alerta_severity, "alertaStatus": $alerta_status, "alertaTags": $alerta_tags, "alertaType": $alerta_type, "dataSegmentCode": $data_segment_code, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportAlerta resource.
#
# DELETE /api/transport-alerta/{id}
# operationId: api_transport-alerta_id_delete
export def "transport-alerta delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-alerta/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportAlerta resource.
#
# GET /api/transport-alerta/{id}
# operationId: api_transport-alerta_id_get
export def "transport-alerta get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<alertaApiKey: string, alertaCorrelate: string, alertaEnvironment: string, alertaEvent: string, alertaGroup: string, alertaHost: string, alertaOrigin: string, alertaResource: string, alertaService: string, alertaSeverity: string, alertaStatus: string, alertaTags: string, alertaType: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-alerta/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportAlerta resource.
#
# PUT /api/transport-alerta/{id}
# operationId: api_transport-alerta_id_put
export def "transport-alerta update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --alerta-api-key: string # The API key for the Alerta service. (nullable)
  --alerta-correlate: string # The comma-separated list of related event names for the Alerta service. (nullable)
  --alerta-environment: string # The environment value for the Alerta service. (nullable)
  --alerta-event: string # The event value for the Alerta service. (nullable)
  --alerta-group: string # The group value for the Alerta service. (nullable)
  --alerta-host: string # The host name for the Alerta service (omit the "https://" part). (nullable, format: hostname)
  --alerta-origin: string # The origin value for the Alerta service. (nullable)
  --alerta-resource: string # The resource value for the Alerta service. (nullable)
  --alerta-service: string # The comma-separated list of affected services for the Alerta service. (nullable)
  --alerta-severity: string # The severity value for the Alerta service. (nullable)
  --alerta-status: string # The status value for the Alerta service. (nullable)
  --alerta-tags: string # The comma-separated list of tags for the Alerta service. (nullable)
  --alerta-type: string # The type value for the Alerta service. (nullable)
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<alertaApiKey: string, alertaCorrelate: string, alertaEnvironment: string, alertaEvent: string, alertaGroup: string, alertaHost: string, alertaOrigin: string, alertaResource: string, alertaService: string, alertaSeverity: string, alertaStatus: string, alertaTags: string, alertaType: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-alerta/{id}"))
  let req_body = {"alertaApiKey": $alerta_api_key, "alertaCorrelate": $alerta_correlate, "alertaEnvironment": $alerta_environment, "alertaEvent": $alerta_event, "alertaGroup": $alerta_group, "alertaHost": $alerta_host, "alertaOrigin": $alerta_origin, "alertaResource": $alerta_resource, "alertaService": $alerta_service, "alertaSeverity": $alerta_severity, "alertaStatus": $alerta_status, "alertaTags": $alerta_tags, "alertaType": $alerta_type, "dataSegmentCode": $data_segment_code, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportAllMySms resources.
#
# GET /api/transport-all-my-sms
# operationId: api_transport-all-my-sms_get_collection
export def "transport-all-my-sms get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<allMySmsApiKey: string, allMySmsFrom: string, allMySmsLogin: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-all-my-sms" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportAllMySms resource.
#
# POST /api/transport-all-my-sms
# operationId: api_transport-all-my-sms_post
export def "transport-all-my-sms create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --all-my-sms-api-key: string # The API key for the Allmysms service. Stored in encrypted format. (nullable)
  --all-my-sms-from: string # The sender value (default 36180) for the Allmysms service. (nullable)
  --all-my-sms-login: string # The login credential for the Allmysms service. (nullable)
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<allMySmsApiKey: string, allMySmsFrom: string, allMySmsLogin: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-all-my-sms")
  let req_body = {"allMySmsApiKey": $all_my_sms_api_key, "allMySmsFrom": $all_my_sms_from, "allMySmsLogin": $all_my_sms_login, "dataSegmentCode": $data_segment_code, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportAllMySms resource.
#
# DELETE /api/transport-all-my-sms/{id}
# operationId: api_transport-all-my-sms_id_delete
export def "transport-all-my-sms delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-all-my-sms/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportAllMySms resource.
#
# GET /api/transport-all-my-sms/{id}
# operationId: api_transport-all-my-sms_id_get
export def "transport-all-my-sms get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<allMySmsApiKey: string, allMySmsFrom: string, allMySmsLogin: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-all-my-sms/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportAllMySms resource.
#
# PUT /api/transport-all-my-sms/{id}
# operationId: api_transport-all-my-sms_id_put
export def "transport-all-my-sms update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --all-my-sms-api-key: string # The API key for the Allmysms service. Stored in encrypted format. (nullable)
  --all-my-sms-from: string # The sender value (default 36180) for the Allmysms service. (nullable)
  --all-my-sms-login: string # The login credential for the Allmysms service. (nullable)
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<allMySmsApiKey: string, allMySmsFrom: string, allMySmsLogin: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-all-my-sms/{id}"))
  let req_body = {"allMySmsApiKey": $all_my_sms_api_key, "allMySmsFrom": $all_my_sms_from, "allMySmsLogin": $all_my_sms_login, "dataSegmentCode": $data_segment_code, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportAmazonSns resources.
#
# GET /api/transport-amazon-sns
# operationId: api_transport-amazon-sns_get_collection
export def "transport-amazon-sns get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<amazonSnsAccessKey: string, amazonSnsRegion: string, amazonSnsSecretKey: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-amazon-sns" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportAmazonSns resource.
#
# POST /api/transport-amazon-sns
# operationId: api_transport-amazon-sns_post
export def "transport-amazon-sns create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --amazon-sns-access-key: string # The access key for the Amazon SNS service. (nullable)
  --amazon-sns-region: string # The region for the Amazon SNS service. (nullable)
  --amazon-sns-secret-key: string # The secret key for the Amazon SNS service. Stored in encrypted format. (nullable)
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<amazonSnsAccessKey: string, amazonSnsRegion: string, amazonSnsSecretKey: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-amazon-sns")
  let req_body = {"amazonSnsAccessKey": $amazon_sns_access_key, "amazonSnsRegion": $amazon_sns_region, "amazonSnsSecretKey": $amazon_sns_secret_key, "dataSegmentCode": $data_segment_code, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportAmazonSns resource.
#
# DELETE /api/transport-amazon-sns/{id}
# operationId: api_transport-amazon-sns_id_delete
export def "transport-amazon-sns delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-amazon-sns/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportAmazonSns resource.
#
# GET /api/transport-amazon-sns/{id}
# operationId: api_transport-amazon-sns_id_get
export def "transport-amazon-sns get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<amazonSnsAccessKey: string, amazonSnsRegion: string, amazonSnsSecretKey: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-amazon-sns/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportAmazonSns resource.
#
# PUT /api/transport-amazon-sns/{id}
# operationId: api_transport-amazon-sns_id_put
export def "transport-amazon-sns update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --amazon-sns-access-key: string # The access key for the Amazon SNS service. (nullable)
  --amazon-sns-region: string # The region for the Amazon SNS service. (nullable)
  --amazon-sns-secret-key: string # The secret key for the Amazon SNS service. Stored in encrypted format. (nullable)
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<amazonSnsAccessKey: string, amazonSnsRegion: string, amazonSnsSecretKey: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-amazon-sns/{id}"))
  let req_body = {"amazonSnsAccessKey": $amazon_sns_access_key, "amazonSnsRegion": $amazon_sns_region, "amazonSnsSecretKey": $amazon_sns_secret_key, "dataSegmentCode": $data_segment_code, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportBandwidth resources.
#
# GET /api/transport-bandwidth
# operationId: api_transport-bandwidth_get_collection
export def "transport-bandwidth get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<bandwidthAccountId: string, bandwidthApplicationId: string, bandwidthFrom: string, bandwidthPassword: string, bandwidthUsername: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-bandwidth" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportBandwidth resource.
#
# POST /api/transport-bandwidth
# operationId: api_transport-bandwidth_post
export def "transport-bandwidth create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --bandwidth-account-id: string # The account ID value for the Bandwidth service. (nullable)
  --bandwidth-application-id: string # The application ID value for the Bandwidth service. (nullable)
  --bandwidth-from: string # The from value for the Bandwidth service. (nullable)
  --bandwidth-password: string # The password for the Bandwidth service. Stored in encrypted format. (nullable)
  --bandwidth-username: string # The username for the Bandwidth service. (nullable)
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<bandwidthAccountId: string, bandwidthApplicationId: string, bandwidthFrom: string, bandwidthPassword: string, bandwidthUsername: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-bandwidth")
  let req_body = {"bandwidthAccountId": $bandwidth_account_id, "bandwidthApplicationId": $bandwidth_application_id, "bandwidthFrom": $bandwidth_from, "bandwidthPassword": $bandwidth_password, "bandwidthUsername": $bandwidth_username, "dataSegmentCode": $data_segment_code, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportBandwidth resource.
#
# DELETE /api/transport-bandwidth/{id}
# operationId: api_transport-bandwidth_id_delete
export def "transport-bandwidth delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-bandwidth/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportBandwidth resource.
#
# GET /api/transport-bandwidth/{id}
# operationId: api_transport-bandwidth_id_get
export def "transport-bandwidth get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<bandwidthAccountId: string, bandwidthApplicationId: string, bandwidthFrom: string, bandwidthPassword: string, bandwidthUsername: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-bandwidth/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportBandwidth resource.
#
# PUT /api/transport-bandwidth/{id}
# operationId: api_transport-bandwidth_id_put
export def "transport-bandwidth update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --bandwidth-account-id: string # The account ID value for the Bandwidth service. (nullable)
  --bandwidth-application-id: string # The application ID value for the Bandwidth service. (nullable)
  --bandwidth-from: string # The from value for the Bandwidth service. (nullable)
  --bandwidth-password: string # The password for the Bandwidth service. Stored in encrypted format. (nullable)
  --bandwidth-username: string # The username for the Bandwidth service. (nullable)
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<bandwidthAccountId: string, bandwidthApplicationId: string, bandwidthFrom: string, bandwidthPassword: string, bandwidthUsername: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-bandwidth/{id}"))
  let req_body = {"bandwidthAccountId": $bandwidth_account_id, "bandwidthApplicationId": $bandwidth_application_id, "bandwidthFrom": $bandwidth_from, "bandwidthPassword": $bandwidth_password, "bandwidthUsername": $bandwidth_username, "dataSegmentCode": $data_segment_code, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportChatwork resources.
#
# GET /api/transport-chatwork
# operationId: api_transport-chatwork_get_collection
export def "transport-chatwork get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<chatworkApiToken: string, chatworkRoomId: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-chatwork" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportChatwork resource.
#
# POST /api/transport-chatwork
# operationId: api_transport-chatwork_post
export def "transport-chatwork create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --chatwork-api-token: string # The API token for the Chatwork service. Stored in encrypted format. (nullable)
  --chatwork-room-id: string # The room ID for the Chatwork service. (nullable)
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<chatworkApiToken: string, chatworkRoomId: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-chatwork")
  let req_body = {"chatworkApiToken": $chatwork_api_token, "chatworkRoomId": $chatwork_room_id, "dataSegmentCode": $data_segment_code, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportChatwork resource.
#
# DELETE /api/transport-chatwork/{id}
# operationId: api_transport-chatwork_id_delete
export def "transport-chatwork delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-chatwork/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportChatwork resource.
#
# GET /api/transport-chatwork/{id}
# operationId: api_transport-chatwork_id_get
export def "transport-chatwork get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<chatworkApiToken: string, chatworkRoomId: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-chatwork/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportChatwork resource.
#
# PUT /api/transport-chatwork/{id}
# operationId: api_transport-chatwork_id_put
export def "transport-chatwork update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --chatwork-api-token: string # The API token for the Chatwork service. Stored in encrypted format. (nullable)
  --chatwork-room-id: string # The room ID for the Chatwork service. (nullable)
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<chatworkApiToken: string, chatworkRoomId: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-chatwork/{id}"))
  let req_body = {"chatworkApiToken": $chatwork_api_token, "chatworkRoomId": $chatwork_room_id, "dataSegmentCode": $data_segment_code, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportClickSend resources.
#
# GET /api/transport-click-send
# operationId: api_transport-click-send_get_collection
export def "transport-click-send get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<clickSendApiKey: string, clickSendApiUsername: string, clickSendFrom: string, clickSendFromEmail: string, clickSendListId: string, clickSendSource: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-click-send" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportClickSend resource.
#
# POST /api/transport-click-send
# operationId: api_transport-click-send_post
export def "transport-click-send create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --click-send-api-key: string # The API key for the ClickSend service. Stored in encrypted format. (nullable)
  --click-send-api-username: string # The API username for the ClickSend service. (nullable)
  --click-send-from: string # The from value for the ClickSend service. (nullable)
  --click-send-from-email: string # The from email value where replies must be emailed for the ClickSend service. (nullable, format: email)
  --click-send-list-id: string # The recipient list ID value for the ClickSend service. (nullable)
  --click-send-source: string # The source method of sending value for the ClickSend service. (nullable)
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<clickSendApiKey: string, clickSendApiUsername: string, clickSendFrom: string, clickSendFromEmail: string, clickSendListId: string, clickSendSource: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-click-send")
  let req_body = {"clickSendApiKey": $click_send_api_key, "clickSendApiUsername": $click_send_api_username, "clickSendFrom": $click_send_from, "clickSendFromEmail": $click_send_from_email, "clickSendListId": $click_send_list_id, "clickSendSource": $click_send_source, "dataSegmentCode": $data_segment_code, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportClickSend resource.
#
# DELETE /api/transport-click-send/{id}
# operationId: api_transport-click-send_id_delete
export def "transport-click-send delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-click-send/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportClickSend resource.
#
# GET /api/transport-click-send/{id}
# operationId: api_transport-click-send_id_get
export def "transport-click-send get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<clickSendApiKey: string, clickSendApiUsername: string, clickSendFrom: string, clickSendFromEmail: string, clickSendListId: string, clickSendSource: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-click-send/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportClickSend resource.
#
# PUT /api/transport-click-send/{id}
# operationId: api_transport-click-send_id_put
export def "transport-click-send update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --click-send-api-key: string # The API key for the ClickSend service. Stored in encrypted format. (nullable)
  --click-send-api-username: string # The API username for the ClickSend service. (nullable)
  --click-send-from: string # The from value for the ClickSend service. (nullable)
  --click-send-from-email: string # The from email value where replies must be emailed for the ClickSend service. (nullable, format: email)
  --click-send-list-id: string # The recipient list ID value for the ClickSend service. (nullable)
  --click-send-source: string # The source method of sending value for the ClickSend service. (nullable)
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<clickSendApiKey: string, clickSendApiUsername: string, clickSendFrom: string, clickSendFromEmail: string, clickSendListId: string, clickSendSource: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-click-send/{id}"))
  let req_body = {"clickSendApiKey": $click_send_api_key, "clickSendApiUsername": $click_send_api_username, "clickSendFrom": $click_send_from, "clickSendFromEmail": $click_send_from_email, "clickSendListId": $click_send_list_id, "clickSendSource": $click_send_source, "dataSegmentCode": $data_segment_code, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportClickatell resources.
#
# GET /api/transport-clickatell
# operationId: api_transport-clickatell_get_collection
export def "transport-clickatell get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<clickatellAccessToken: string, clickatellFrom: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-clickatell" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportClickatell resource.
#
# POST /api/transport-clickatell
# operationId: api_transport-clickatell_post
export def "transport-clickatell create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --clickatell-access-token: string # The access token for the Clickatell service. Stored in encrypted format. (nullable)
  --clickatell-from: string # The from value for the Clickatell service. (nullable)
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<clickatellAccessToken: string, clickatellFrom: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-clickatell")
  let req_body = {"clickatellAccessToken": $clickatell_access_token, "clickatellFrom": $clickatell_from, "dataSegmentCode": $data_segment_code, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportClickatell resource.
#
# DELETE /api/transport-clickatell/{id}
# operationId: api_transport-clickatell_id_delete
export def "transport-clickatell delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-clickatell/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportClickatell resource.
#
# GET /api/transport-clickatell/{id}
# operationId: api_transport-clickatell_id_get
export def "transport-clickatell get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<clickatellAccessToken: string, clickatellFrom: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-clickatell/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportClickatell resource.
#
# PUT /api/transport-clickatell/{id}
# operationId: api_transport-clickatell_id_put
export def "transport-clickatell update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --clickatell-access-token: string # The access token for the Clickatell service. Stored in encrypted format. (nullable)
  --clickatell-from: string # The from value for the Clickatell service. (nullable)
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<clickatellAccessToken: string, clickatellFrom: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-clickatell/{id}"))
  let req_body = {"clickatellAccessToken": $clickatell_access_token, "clickatellFrom": $clickatell_from, "dataSegmentCode": $data_segment_code, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportContactEveryone resources.
#
# GET /api/transport-contact-everyone
# operationId: api_transport-contact-everyone_get_collection
export def "transport-contact-everyone get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<contactEveryoneCategory: string, contactEveryoneDiffusionName: string, contactEveryoneToken: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-contact-everyone" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportContactEveryone resource.
#
# POST /api/transport-contact-everyone
# operationId: api_transport-contact-everyone_post
export def "transport-contact-everyone create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --contact-everyone-category: string # The label of the category that will be displayed in the external service event logs of the ContactEveryone service. (nullable)
  --contact-everyone-diffusion-name: string # The label of the diffusion that will be displayed in the external service event logs of the ContactEveryone service. (nullable)
  --contact-everyone-token: string # The token for the Contact Everyone service. Stored in encrypted format. (nullable)
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<contactEveryoneCategory: string, contactEveryoneDiffusionName: string, contactEveryoneToken: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-contact-everyone")
  let req_body = {"contactEveryoneCategory": $contact_everyone_category, "contactEveryoneDiffusionName": $contact_everyone_diffusion_name, "contactEveryoneToken": $contact_everyone_token, "dataSegmentCode": $data_segment_code, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportContactEveryone resource.
#
# DELETE /api/transport-contact-everyone/{id}
# operationId: api_transport-contact-everyone_id_delete
export def "transport-contact-everyone delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-contact-everyone/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportContactEveryone resource.
#
# GET /api/transport-contact-everyone/{id}
# operationId: api_transport-contact-everyone_id_get
export def "transport-contact-everyone get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<contactEveryoneCategory: string, contactEveryoneDiffusionName: string, contactEveryoneToken: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-contact-everyone/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportContactEveryone resource.
#
# PUT /api/transport-contact-everyone/{id}
# operationId: api_transport-contact-everyone_id_put
export def "transport-contact-everyone update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --contact-everyone-category: string # The label of the category that will be displayed in the external service event logs of the ContactEveryone service. (nullable)
  --contact-everyone-diffusion-name: string # The label of the diffusion that will be displayed in the external service event logs of the ContactEveryone service. (nullable)
  --contact-everyone-token: string # The token for the Contact Everyone service. Stored in encrypted format. (nullable)
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<contactEveryoneCategory: string, contactEveryoneDiffusionName: string, contactEveryoneToken: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-contact-everyone/{id}"))
  let req_body = {"contactEveryoneCategory": $contact_everyone_category, "contactEveryoneDiffusionName": $contact_everyone_diffusion_name, "contactEveryoneToken": $contact_everyone_token, "dataSegmentCode": $data_segment_code, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportDiscord resources.
#
# GET /api/transport-discord
# operationId: api_transport-discord_get_collection
export def "transport-discord get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, discordToken: string, discordWebhookId: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-discord" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportDiscord resource.
#
# POST /api/transport-discord
# operationId: api_transport-discord_post
export def "transport-discord create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --discord-token: string # The token for the Discord service. Stored in encrypted format. (nullable)
  --discord-webhook-id: string # The webhook ID for the Discord service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, discordToken: string, discordWebhookId: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-discord")
  let req_body = {"dataSegmentCode": $data_segment_code, "discordToken": $discord_token, "discordWebhookId": $discord_webhook_id, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportDiscord resource.
#
# DELETE /api/transport-discord/{id}
# operationId: api_transport-discord_id_delete
export def "transport-discord delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-discord/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportDiscord resource.
#
# GET /api/transport-discord/{id}
# operationId: api_transport-discord_id_get
export def "transport-discord get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, discordToken: string, discordWebhookId: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-discord/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportDiscord resource.
#
# PUT /api/transport-discord/{id}
# operationId: api_transport-discord_id_put
export def "transport-discord update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --discord-token: string # The token for the Discord service. Stored in encrypted format. (nullable)
  --discord-webhook-id: string # The webhook ID for the Discord service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, discordToken: string, discordWebhookId: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-discord/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "discordToken": $discord_token, "discordWebhookId": $discord_webhook_id, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportEmail resources.
#
# GET /api/transport-email
# operationId: api_transport-email_get_collection
export def "transport-email get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, emailFromAddress: string, emailFromName: string, emailPassword: string, emailPort: int, emailServer: string, emailUsername: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-email" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportEmail resource.
#
# POST /api/transport-email
# operationId: api_transport-email_post
export def "transport-email create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --email-from-address: string # The sender email address for the SMTP Email service. (nullable, format: email)
  --email-from-name: string # The sender name for the SMTP Email service. (nullable)
  --email-password: string # The password for the SMTP Email service. Stored in encrypted format. (nullable)
  --email-port: int # The port for the SMTP Email service. (nullable)
  --email-server: string # The server for the SMTP Email service. (nullable)
  --email-username: string # The username for the SMTP Email service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, emailFromAddress: string, emailFromName: string, emailPassword: string, emailPort: int, emailServer: string, emailUsername: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-email")
  let req_body = {"dataSegmentCode": $data_segment_code, "emailFromAddress": $email_from_address, "emailFromName": $email_from_name, "emailPassword": $email_password, "emailPort": $email_port, "emailServer": $email_server, "emailUsername": $email_username, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportEmail resource.
#
# DELETE /api/transport-email/{id}
# operationId: api_transport-email_id_delete
export def "transport-email delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-email/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportEmail resource.
#
# GET /api/transport-email/{id}
# operationId: api_transport-email_id_get
export def "transport-email get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, emailFromAddress: string, emailFromName: string, emailPassword: string, emailPort: int, emailServer: string, emailUsername: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-email/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportEmail resource.
#
# PUT /api/transport-email/{id}
# operationId: api_transport-email_id_put
export def "transport-email update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --email-from-address: string # The sender email address for the SMTP Email service. (nullable, format: email)
  --email-from-name: string # The sender name for the SMTP Email service. (nullable)
  --email-password: string # The password for the SMTP Email service. Stored in encrypted format. (nullable)
  --email-port: int # The port for the SMTP Email service. (nullable)
  --email-server: string # The server for the SMTP Email service. (nullable)
  --email-username: string # The username for the SMTP Email service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, emailFromAddress: string, emailFromName: string, emailPassword: string, emailPort: int, emailServer: string, emailUsername: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-email/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "emailFromAddress": $email_from_address, "emailFromName": $email_from_name, "emailPassword": $email_password, "emailPort": $email_port, "emailServer": $email_server, "emailUsername": $email_username, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportEngagespot resources.
#
# GET /api/transport-engagespot
# operationId: api_transport-engagespot_get_collection
export def "transport-engagespot get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, engagespotApiKey: string, engagespotCampaignName: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-engagespot" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportEngagespot resource.
#
# POST /api/transport-engagespot
# operationId: api_transport-engagespot_post
export def "transport-engagespot create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --engagespot-api-key: string # The API key for the EngageSpot service. Stored in encrypted format. (nullable)
  --engagespot-campaign-name: string # The campaign name for the EngageSpot service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, engagespotApiKey: string, engagespotCampaignName: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-engagespot")
  let req_body = {"dataSegmentCode": $data_segment_code, "engagespotApiKey": $engagespot_api_key, "engagespotCampaignName": $engagespot_campaign_name, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportEngagespot resource.
#
# DELETE /api/transport-engagespot/{id}
# operationId: api_transport-engagespot_id_delete
export def "transport-engagespot delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-engagespot/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportEngagespot resource.
#
# GET /api/transport-engagespot/{id}
# operationId: api_transport-engagespot_id_get
export def "transport-engagespot get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, engagespotApiKey: string, engagespotCampaignName: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-engagespot/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportEngagespot resource.
#
# PUT /api/transport-engagespot/{id}
# operationId: api_transport-engagespot_id_put
export def "transport-engagespot update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --engagespot-api-key: string # The API key for the EngageSpot service. Stored in encrypted format. (nullable)
  --engagespot-campaign-name: string # The campaign name for the EngageSpot service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, engagespotApiKey: string, engagespotCampaignName: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-engagespot/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "engagespotApiKey": $engagespot_api_key, "engagespotCampaignName": $engagespot_campaign_name, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportEsendex resources.
#
# GET /api/transport-esendex
# operationId: api_transport-esendex_get_collection
export def "transport-esendex get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, esendexAccountReference: string, esendexFrom: string, esendexPassword: string, esendexUsername: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-esendex" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportEsendex resource.
#
# POST /api/transport-esendex
# operationId: api_transport-esendex_post
export def "transport-esendex create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --esendex-account-reference: string # The account reference that the message should be sent from for the Esendex service. (nullable)
  --esendex-from: string # The alphanumeric originator for the message to appear to originate from for the Esendex service. (nullable)
  --esendex-password: string # The API password for the Esendex service. Stored in encrypted format. (nullable)
  --esendex-username: string # The account email for the Esendex service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, esendexAccountReference: string, esendexFrom: string, esendexPassword: string, esendexUsername: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-esendex")
  let req_body = {"dataSegmentCode": $data_segment_code, "esendexAccountReference": $esendex_account_reference, "esendexFrom": $esendex_from, "esendexPassword": $esendex_password, "esendexUsername": $esendex_username, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportEsendex resource.
#
# DELETE /api/transport-esendex/{id}
# operationId: api_transport-esendex_id_delete
export def "transport-esendex delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-esendex/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportEsendex resource.
#
# GET /api/transport-esendex/{id}
# operationId: api_transport-esendex_id_get
export def "transport-esendex get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, esendexAccountReference: string, esendexFrom: string, esendexPassword: string, esendexUsername: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-esendex/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportEsendex resource.
#
# PUT /api/transport-esendex/{id}
# operationId: api_transport-esendex_id_put
export def "transport-esendex update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --esendex-account-reference: string # The account reference that the message should be sent from for the Esendex service. (nullable)
  --esendex-from: string # The alphanumeric originator for the message to appear to originate from for the Esendex service. (nullable)
  --esendex-password: string # The API password for the Esendex service. Stored in encrypted format. (nullable)
  --esendex-username: string # The account email for the Esendex service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, esendexAccountReference: string, esendexFrom: string, esendexPassword: string, esendexUsername: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-esendex/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "esendexAccountReference": $esendex_account_reference, "esendexFrom": $esendex_from, "esendexPassword": $esendex_password, "esendexUsername": $esendex_username, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportExpo resources.
#
# GET /api/transport-expo
# operationId: api_transport-expo_get_collection
export def "transport-expo get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, expoToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-expo" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportExpo resource.
#
# POST /api/transport-expo
# operationId: api_transport-expo_post
export def "transport-expo create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --expo-token: string # The token for the Expo service. Stored in encrypted format. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, expoToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-expo")
  let req_body = {"dataSegmentCode": $data_segment_code, "expoToken": $expo_token, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportExpo resource.
#
# DELETE /api/transport-expo/{id}
# operationId: api_transport-expo_id_delete
export def "transport-expo delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-expo/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportExpo resource.
#
# GET /api/transport-expo/{id}
# operationId: api_transport-expo_id_get
export def "transport-expo get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, expoToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-expo/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportExpo resource.
#
# PUT /api/transport-expo/{id}
# operationId: api_transport-expo_id_put
export def "transport-expo update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --expo-token: string # The token for the Expo service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, expoToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-expo/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "expoToken": $expo_token, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportFirebase resources.
#
# GET /api/transport-firebase
# operationId: api_transport-firebase_get_collection
export def "transport-firebase get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, firebasePassword: string, firebaseUsername: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-firebase" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportFirebase resource.
#
# POST /api/transport-firebase
# operationId: api_transport-firebase_post
export def "transport-firebase create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --firebase-password: string # The password for the Firebase service. Stored in encrypted format. (nullable)
  --firebase-username: string # The username for the Firebase service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, firebasePassword: string, firebaseUsername: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-firebase")
  let req_body = {"dataSegmentCode": $data_segment_code, "firebasePassword": $firebase_password, "firebaseUsername": $firebase_username, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportFirebase resource.
#
# DELETE /api/transport-firebase/{id}
# operationId: api_transport-firebase_id_delete
export def "transport-firebase delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-firebase/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportFirebase resource.
#
# GET /api/transport-firebase/{id}
# operationId: api_transport-firebase_id_get
export def "transport-firebase get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, firebasePassword: string, firebaseUsername: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-firebase/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportFirebase resource.
#
# PUT /api/transport-firebase/{id}
# operationId: api_transport-firebase_id_put
export def "transport-firebase update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --firebase-password: string # The password for the Firebase service. Stored in encrypted format. (nullable)
  --firebase-username: string # The username for the Firebase service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, firebasePassword: string, firebaseUsername: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-firebase/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "firebasePassword": $firebase_password, "firebaseUsername": $firebase_username, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportFortySixElks resources.
#
# GET /api/transport-forty-six-elks
# operationId: api_transport-forty-six-elks_get_collection
export def "transport-forty-six-elks get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, fortySixElksApiPassword: string, fortySixElksApiUsername: string, fortySixElksFrom: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-forty-six-elks" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportFortySixElks resource.
#
# POST /api/transport-forty-six-elks
# operationId: api_transport-forty-six-elks_post
export def "transport-forty-six-elks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --forty-six-elks-api-password: string # The API password for the 46elks service. Stored in encrypted format. (nullable)
  --forty-six-elks-api-username: string # The API username for the 46elks service. (nullable)
  --forty-six-elks-from: string # The alphanumeric originator for the message to appear to originate from for the 46elks service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, fortySixElksApiPassword: string, fortySixElksApiUsername: string, fortySixElksFrom: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-forty-six-elks")
  let req_body = {"dataSegmentCode": $data_segment_code, "fortySixElksApiPassword": $forty_six_elks_api_password, "fortySixElksApiUsername": $forty_six_elks_api_username, "fortySixElksFrom": $forty_six_elks_from, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportFortySixElks resource.
#
# DELETE /api/transport-forty-six-elks/{id}
# operationId: api_transport-forty-six-elks_id_delete
export def "transport-forty-six-elks delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-forty-six-elks/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportFortySixElks resource.
#
# GET /api/transport-forty-six-elks/{id}
# operationId: api_transport-forty-six-elks_id_get
export def "transport-forty-six-elks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, fortySixElksApiPassword: string, fortySixElksApiUsername: string, fortySixElksFrom: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-forty-six-elks/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportFortySixElks resource.
#
# PUT /api/transport-forty-six-elks/{id}
# operationId: api_transport-forty-six-elks_id_put
export def "transport-forty-six-elks update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --forty-six-elks-api-password: string # The API password for the 46elks service. Stored in encrypted format. (nullable)
  --forty-six-elks-api-username: string # The API username for the 46elks service. (nullable)
  --forty-six-elks-from: string # The alphanumeric originator for the message to appear to originate from for the 46elks service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, fortySixElksApiPassword: string, fortySixElksApiUsername: string, fortySixElksFrom: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-forty-six-elks/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "fortySixElksApiPassword": $forty_six_elks_api_password, "fortySixElksApiUsername": $forty_six_elks_api_username, "fortySixElksFrom": $forty_six_elks_from, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportFreeMobile resources.
#
# GET /api/transport-free-mobile
# operationId: api_transport-free-mobile_get_collection
export def "transport-free-mobile get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, freeMobileApiKey: string, freeMobileLogin: string, freeMobilePhone: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-free-mobile" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportFreeMobile resource.
#
# POST /api/transport-free-mobile
# operationId: api_transport-free-mobile_post
export def "transport-free-mobile create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --free-mobile-api-key: string # The API key for the Free Mobile service. Stored in encrypted format. (nullable)
  --free-mobile-login: string # The login for the Free Mobile service. (nullable)
  --free-mobile-phone: string # The phone number for the Free Mobile service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, freeMobileApiKey: string, freeMobileLogin: string, freeMobilePhone: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-free-mobile")
  let req_body = {"dataSegmentCode": $data_segment_code, "freeMobileApiKey": $free_mobile_api_key, "freeMobileLogin": $free_mobile_login, "freeMobilePhone": $free_mobile_phone, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportFreeMobile resource.
#
# DELETE /api/transport-free-mobile/{id}
# operationId: api_transport-free-mobile_id_delete
export def "transport-free-mobile delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-free-mobile/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportFreeMobile resource.
#
# GET /api/transport-free-mobile/{id}
# operationId: api_transport-free-mobile_id_get
export def "transport-free-mobile get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, freeMobileApiKey: string, freeMobileLogin: string, freeMobilePhone: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-free-mobile/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportFreeMobile resource.
#
# PUT /api/transport-free-mobile/{id}
# operationId: api_transport-free-mobile_id_put
export def "transport-free-mobile update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --free-mobile-api-key: string # The API key for the Free Mobile service. Stored in encrypted format. (nullable)
  --free-mobile-login: string # The login for the Free Mobile service. (nullable)
  --free-mobile-phone: string # The phone number for the Free Mobile service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, freeMobileApiKey: string, freeMobileLogin: string, freeMobilePhone: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-free-mobile/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "freeMobileApiKey": $free_mobile_api_key, "freeMobileLogin": $free_mobile_login, "freeMobilePhone": $free_mobile_phone, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportFreshdesk resources.
#
# GET /api/transport-freshdesk
# operationId: api_transport-freshdesk_get_collection
export def "transport-freshdesk get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, freshdeskApiKey: string, freshdeskEmail: string, freshdeskHost: string, freshdeskPriority: string, freshdeskType: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-freshdesk" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportFreshdesk resource.
#
# POST /api/transport-freshdesk
# operationId: api_transport-freshdesk_post
export def "transport-freshdesk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --freshdesk-api-key: string # The API key for the Freshdesk service. Stored in encrypted format. (nullable)
  --freshdesk-email: string # The requester email address for the Freshdesk service. (nullable, format: email)
  --freshdesk-host: string # The host name for the Freshdesk service (domain.freshdesk.com). (nullable, format: hostname)
  --freshdesk-priority: string # The ticket priority for the Freshdesk service. (nullable)
  --freshdesk-type: string # The ticket type for the Freshdesk service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, freshdeskApiKey: string, freshdeskEmail: string, freshdeskHost: string, freshdeskPriority: string, freshdeskType: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-freshdesk")
  let req_body = {"dataSegmentCode": $data_segment_code, "freshdeskApiKey": $freshdesk_api_key, "freshdeskEmail": $freshdesk_email, "freshdeskHost": $freshdesk_host, "freshdeskPriority": $freshdesk_priority, "freshdeskType": $freshdesk_type, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportFreshdesk resource.
#
# DELETE /api/transport-freshdesk/{id}
# operationId: api_transport-freshdesk_id_delete
export def "transport-freshdesk delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-freshdesk/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportFreshdesk resource.
#
# GET /api/transport-freshdesk/{id}
# operationId: api_transport-freshdesk_id_get
export def "transport-freshdesk get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, freshdeskApiKey: string, freshdeskEmail: string, freshdeskHost: string, freshdeskPriority: string, freshdeskType: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-freshdesk/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportFreshdesk resource.
#
# PUT /api/transport-freshdesk/{id}
# operationId: api_transport-freshdesk_id_put
export def "transport-freshdesk update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --freshdesk-api-key: string # The API key for the Freshdesk service. Stored in encrypted format. (nullable)
  --freshdesk-email: string # The requester email address for the Freshdesk service. (nullable, format: email)
  --freshdesk-host: string # The host name for the Freshdesk service (domain.freshdesk.com). (nullable, format: hostname)
  --freshdesk-priority: string # The ticket priority for the Freshdesk service. (nullable)
  --freshdesk-type: string # The ticket type for the Freshdesk service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, freshdeskApiKey: string, freshdeskEmail: string, freshdeskHost: string, freshdeskPriority: string, freshdeskType: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-freshdesk/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "freshdeskApiKey": $freshdesk_api_key, "freshdeskEmail": $freshdesk_email, "freshdeskHost": $freshdesk_host, "freshdeskPriority": $freshdesk_priority, "freshdeskType": $freshdesk_type, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportGatewayApi resources.
#
# GET /api/transport-gateway-api
# operationId: api_transport-gateway-api_get_collection
export def "transport-gateway-api get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, gatewayApiFrom: string, gatewayApiToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-gateway-api" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportGatewayApi resource.
#
# POST /api/transport-gateway-api
# operationId: api_transport-gateway-api_post
export def "transport-gateway-api create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --gateway-api-from: string # The sender name for the Gateway API service. (nullable)
  --gateway-api-token: string # The token for the Gateway API service. Stored in encrypted format. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, gatewayApiFrom: string, gatewayApiToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-gateway-api")
  let req_body = {"dataSegmentCode": $data_segment_code, "gatewayApiFrom": $gateway_api_from, "gatewayApiToken": $gateway_api_token, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportGatewayApi resource.
#
# DELETE /api/transport-gateway-api/{id}
# operationId: api_transport-gateway-api_id_delete
export def "transport-gateway-api delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-gateway-api/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportGatewayApi resource.
#
# GET /api/transport-gateway-api/{id}
# operationId: api_transport-gateway-api_id_get
export def "transport-gateway-api get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, gatewayApiFrom: string, gatewayApiToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-gateway-api/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportGatewayApi resource.
#
# PUT /api/transport-gateway-api/{id}
# operationId: api_transport-gateway-api_id_put
export def "transport-gateway-api update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --gateway-api-from: string # The sender name for the Gateway API service. (nullable)
  --gateway-api-token: string # The token for the Gateway API service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, gatewayApiFrom: string, gatewayApiToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-gateway-api/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "gatewayApiFrom": $gateway_api_from, "gatewayApiToken": $gateway_api_token, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportGitter resources.
#
# GET /api/transport-gitter
# operationId: api_transport-gitter_get_collection
export def "transport-gitter get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, gitterRoomId: string, gitterToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-gitter" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportGitter resource.
#
# POST /api/transport-gitter
# operationId: api_transport-gitter_post
export def "transport-gitter create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --gitter-room-id: string # The room ID for the Gitter service. (nullable)
  --gitter-token: string # The token for the Gitter service. Stored in encrypted format. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, gitterRoomId: string, gitterToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-gitter")
  let req_body = {"dataSegmentCode": $data_segment_code, "gitterRoomId": $gitter_room_id, "gitterToken": $gitter_token, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportGitter resource.
#
# DELETE /api/transport-gitter/{id}
# operationId: api_transport-gitter_id_delete
export def "transport-gitter delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-gitter/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportGitter resource.
#
# GET /api/transport-gitter/{id}
# operationId: api_transport-gitter_id_get
export def "transport-gitter get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, gitterRoomId: string, gitterToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-gitter/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportGitter resource.
#
# PUT /api/transport-gitter/{id}
# operationId: api_transport-gitter_id_put
export def "transport-gitter update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --gitter-room-id: string # The room ID for the Gitter service. (nullable)
  --gitter-token: string # The token for the Gitter service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, gitterRoomId: string, gitterToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-gitter/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "gitterRoomId": $gitter_room_id, "gitterToken": $gitter_token, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportGoogleChat resources.
#
# GET /api/transport-google-chat
# operationId: api_transport-google-chat_get_collection
export def "transport-google-chat get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, googleChatAccessKey: string, googleChatAccessToken: string, googleChatSpace: string, googleChatThreadKey: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-google-chat" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportGoogleChat resource.
#
# POST /api/transport-google-chat
# operationId: api_transport-google-chat_post
export def "transport-google-chat create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --google-chat-access-key: string # The access key for the Google Chat service. (nullable)
  --google-chat-access-token: string # The access token for the Google Chat service. Stored in encrypted format. (nullable)
  --google-chat-space: string # The space name for the Google Chat service. (nullable)
  --google-chat-thread-key: string # The optional thread key for the Google Chat service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, googleChatAccessKey: string, googleChatAccessToken: string, googleChatSpace: string, googleChatThreadKey: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-google-chat")
  let req_body = {"dataSegmentCode": $data_segment_code, "googleChatAccessKey": $google_chat_access_key, "googleChatAccessToken": $google_chat_access_token, "googleChatSpace": $google_chat_space, "googleChatThreadKey": $google_chat_thread_key, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportGoogleChat resource.
#
# DELETE /api/transport-google-chat/{id}
# operationId: api_transport-google-chat_id_delete
export def "transport-google-chat delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-google-chat/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportGoogleChat resource.
#
# GET /api/transport-google-chat/{id}
# operationId: api_transport-google-chat_id_get
export def "transport-google-chat get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, googleChatAccessKey: string, googleChatAccessToken: string, googleChatSpace: string, googleChatThreadKey: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-google-chat/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportGoogleChat resource.
#
# PUT /api/transport-google-chat/{id}
# operationId: api_transport-google-chat_id_put
export def "transport-google-chat update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --google-chat-access-key: string # The access key for the Google Chat service. (nullable)
  --google-chat-access-token: string # The access token for the Google Chat service. Stored in encrypted format. (nullable)
  --google-chat-space: string # The space name for the Google Chat service. (nullable)
  --google-chat-thread-key: string # The optional thread key for the Google Chat service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, googleChatAccessKey: string, googleChatAccessToken: string, googleChatSpace: string, googleChatThreadKey: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-google-chat/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "googleChatAccessKey": $google_chat_access_key, "googleChatAccessToken": $google_chat_access_token, "googleChatSpace": $google_chat_space, "googleChatThreadKey": $google_chat_thread_key, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportGotify resources.
#
# GET /api/transport-gotify
# operationId: api_transport-gotify_get_collection
export def "transport-gotify get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, gotifyApiUrl: string, gotifyAppToken: string, gotifyPriority: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-gotify" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportGotify resource.
#
# POST /api/transport-gotify
# operationId: api_transport-gotify_post
export def "transport-gotify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --gotify-api-url: string # The API URL name for the Gotify service (https://example.com) - (do not include the path /message/createMessage). (nullable, format: uri)
  --gotify-app-token: string # The app token for the Gotify service. Stored in encrypted format. (nullable)
  --gotify-priority: string # The priority for the Gotify service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, gotifyApiUrl: string, gotifyAppToken: string, gotifyPriority: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-gotify")
  let req_body = {"dataSegmentCode": $data_segment_code, "gotifyApiUrl": $gotify_api_url, "gotifyAppToken": $gotify_app_token, "gotifyPriority": $gotify_priority, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportGotify resource.
#
# DELETE /api/transport-gotify/{id}
# operationId: api_transport-gotify_id_delete
export def "transport-gotify delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-gotify/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportGotify resource.
#
# GET /api/transport-gotify/{id}
# operationId: api_transport-gotify_id_get
export def "transport-gotify get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, gotifyApiUrl: string, gotifyAppToken: string, gotifyPriority: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-gotify/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportGotify resource.
#
# PUT /api/transport-gotify/{id}
# operationId: api_transport-gotify_id_put
export def "transport-gotify update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --gotify-api-url: string # The API URL name for the Gotify service (https://example.com) - (do not include the path /message/createMessage). (nullable, format: uri)
  --gotify-app-token: string # The app token for the Gotify service. Stored in encrypted format. (nullable)
  --gotify-priority: string # The priority for the Gotify service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, gotifyApiUrl: string, gotifyAppToken: string, gotifyPriority: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-gotify/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "gotifyApiUrl": $gotify_api_url, "gotifyAppToken": $gotify_app_token, "gotifyPriority": $gotify_priority, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportHelpScout resources.
#
# GET /api/transport-help-scout
# operationId: api_transport-help-scout_get_collection
export def "transport-help-scout get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, helpScoutCustomerEmail: string, helpScoutMailboxId: int, helpScoutOauthToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-help-scout" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportHelpScout resource.
#
# POST /api/transport-help-scout
# operationId: api_transport-help-scout_post
export def "transport-help-scout create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --help-scout-customer-email: string # The requester customer email address for the HelpScout service. (nullable, format: email)
  --help-scout-mailbox-id: int # The mailbox ID for the HelpScout service. (nullable)
  --help-scout-oauth-token: string # The OAuth token for the HelpScout service. Stored in encrypted format. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, helpScoutCustomerEmail: string, helpScoutMailboxId: int, helpScoutOauthToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-help-scout")
  let req_body = {"dataSegmentCode": $data_segment_code, "helpScoutCustomerEmail": $help_scout_customer_email, "helpScoutMailboxId": $help_scout_mailbox_id, "helpScoutOauthToken": $help_scout_oauth_token, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportHelpScout resource.
#
# DELETE /api/transport-help-scout/{id}
# operationId: api_transport-help-scout_id_delete
export def "transport-help-scout delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-help-scout/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportHelpScout resource.
#
# GET /api/transport-help-scout/{id}
# operationId: api_transport-help-scout_id_get
export def "transport-help-scout get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, helpScoutCustomerEmail: string, helpScoutMailboxId: int, helpScoutOauthToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-help-scout/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportHelpScout resource.
#
# PUT /api/transport-help-scout/{id}
# operationId: api_transport-help-scout_id_put
export def "transport-help-scout update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --help-scout-customer-email: string # The requester customer email address for the HelpScout service. (nullable, format: email)
  --help-scout-mailbox-id: int # The mailbox ID for the HelpScout service. (nullable)
  --help-scout-oauth-token: string # The OAuth token for the HelpScout service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, helpScoutCustomerEmail: string, helpScoutMailboxId: int, helpScoutOauthToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-help-scout/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "helpScoutCustomerEmail": $help_scout_customer_email, "helpScoutMailboxId": $help_scout_mailbox_id, "helpScoutOauthToken": $help_scout_oauth_token, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportInfobip resources.
#
# GET /api/transport-infobip
# operationId: api_transport-infobip_get_collection
export def "transport-infobip get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, infobipAuthToken: string, infobipFrom: string, infobipHost: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-infobip" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportInfobip resource.
#
# POST /api/transport-infobip
# operationId: api_transport-infobip_post
export def "transport-infobip create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --infobip-auth-token: string # The auth token for the Infobip service. Stored in encrypted format. (nullable)
  --infobip-from: string # The sender value for the Infobip service. (nullable)
  --infobip-host: string # The host for the Infobip service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, infobipAuthToken: string, infobipFrom: string, infobipHost: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-infobip")
  let req_body = {"dataSegmentCode": $data_segment_code, "infobipAuthToken": $infobip_auth_token, "infobipFrom": $infobip_from, "infobipHost": $infobip_host, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportInfobip resource.
#
# DELETE /api/transport-infobip/{id}
# operationId: api_transport-infobip_id_delete
export def "transport-infobip delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-infobip/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportInfobip resource.
#
# GET /api/transport-infobip/{id}
# operationId: api_transport-infobip_id_get
export def "transport-infobip get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, infobipAuthToken: string, infobipFrom: string, infobipHost: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-infobip/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportInfobip resource.
#
# PUT /api/transport-infobip/{id}
# operationId: api_transport-infobip_id_put
export def "transport-infobip update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --infobip-auth-token: string # The auth token for the Infobip service. Stored in encrypted format. (nullable)
  --infobip-from: string # The sender value for the Infobip service. (nullable)
  --infobip-host: string # The host for the Infobip service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, infobipAuthToken: string, infobipFrom: string, infobipHost: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-infobip/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "infobipAuthToken": $infobip_auth_token, "infobipFrom": $infobip_from, "infobipHost": $infobip_host, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportIqsms resources.
#
# GET /api/transport-iqsms
# operationId: api_transport-iqsms_get_collection
export def "transport-iqsms get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, iqsmsFrom: string, iqsmsLogin: string, iqsmsPassword: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-iqsms" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportIqsms resource.
#
# POST /api/transport-iqsms
# operationId: api_transport-iqsms_post
export def "transport-iqsms create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --iqsms-from: string # The sender value for the Iqsms service. (nullable)
  --iqsms-login: string # The login for the Iqsms service. (nullable)
  --iqsms-password: string # The password for the Iqsms service. Stored in encrypted format. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, iqsmsFrom: string, iqsmsLogin: string, iqsmsPassword: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-iqsms")
  let req_body = {"dataSegmentCode": $data_segment_code, "iqsmsFrom": $iqsms_from, "iqsmsLogin": $iqsms_login, "iqsmsPassword": $iqsms_password, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportIqsms resource.
#
# DELETE /api/transport-iqsms/{id}
# operationId: api_transport-iqsms_id_delete
export def "transport-iqsms delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-iqsms/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportIqsms resource.
#
# GET /api/transport-iqsms/{id}
# operationId: api_transport-iqsms_id_get
export def "transport-iqsms get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, iqsmsFrom: string, iqsmsLogin: string, iqsmsPassword: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-iqsms/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportIqsms resource.
#
# PUT /api/transport-iqsms/{id}
# operationId: api_transport-iqsms_id_put
export def "transport-iqsms update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --iqsms-from: string # The sender value for the Iqsms service. (nullable)
  --iqsms-login: string # The login for the Iqsms service. (nullable)
  --iqsms-password: string # The password for the Iqsms service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, iqsmsFrom: string, iqsmsLogin: string, iqsmsPassword: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-iqsms/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "iqsmsFrom": $iqsms_from, "iqsmsLogin": $iqsms_login, "iqsmsPassword": $iqsms_password, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportKazInfoTeh resources.
#
# GET /api/transport-kaz-info-teh
# operationId: api_transport-kaz-info-teh_get_collection
export def "transport-kaz-info-teh get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, kazInfoTehFrom: string, kazInfoTehPassword: string, kazInfoTehUsername: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-kaz-info-teh" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportKazInfoTeh resource.
#
# POST /api/transport-kaz-info-teh
# operationId: api_transport-kaz-info-teh_post
export def "transport-kaz-info-teh create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --kaz-info-teh-from: string # The from value for the KazInfoTeh service. (nullable)
  --kaz-info-teh-password: string # The password for the KazInfoTeh service. Stored in encrypted format. (nullable)
  --kaz-info-teh-username: string # The username for the KazInfoTeh service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, kazInfoTehFrom: string, kazInfoTehPassword: string, kazInfoTehUsername: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-kaz-info-teh")
  let req_body = {"dataSegmentCode": $data_segment_code, "kazInfoTehFrom": $kaz_info_teh_from, "kazInfoTehPassword": $kaz_info_teh_password, "kazInfoTehUsername": $kaz_info_teh_username, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportKazInfoTeh resource.
#
# DELETE /api/transport-kaz-info-teh/{id}
# operationId: api_transport-kaz-info-teh_id_delete
export def "transport-kaz-info-teh delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-kaz-info-teh/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportKazInfoTeh resource.
#
# GET /api/transport-kaz-info-teh/{id}
# operationId: api_transport-kaz-info-teh_id_get
export def "transport-kaz-info-teh get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, kazInfoTehFrom: string, kazInfoTehPassword: string, kazInfoTehUsername: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-kaz-info-teh/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportKazInfoTeh resource.
#
# PUT /api/transport-kaz-info-teh/{id}
# operationId: api_transport-kaz-info-teh_id_put
export def "transport-kaz-info-teh update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --kaz-info-teh-from: string # The from value for the KazInfoTeh service. (nullable)
  --kaz-info-teh-password: string # The password for the KazInfoTeh service. Stored in encrypted format. (nullable)
  --kaz-info-teh-username: string # The username for the KazInfoTeh service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, kazInfoTehFrom: string, kazInfoTehPassword: string, kazInfoTehUsername: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-kaz-info-teh/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "kazInfoTehFrom": $kaz_info_teh_from, "kazInfoTehPassword": $kaz_info_teh_password, "kazInfoTehUsername": $kaz_info_teh_username, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportLightSms resources.
#
# GET /api/transport-light-sms
# operationId: api_transport-light-sms_get_collection
export def "transport-light-sms get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, lightSmsLogin: string, lightSmsPhone: string, lightSmsToken: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-light-sms" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportLightSms resource.
#
# POST /api/transport-light-sms
# operationId: api_transport-light-sms_post
export def "transport-light-sms create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --light-sms-login: string # The login for the LightSMS service. (nullable)
  --light-sms-phone: string # The sender phone number for the LightSMS service. (nullable)
  --light-sms-token: string # The token for the LightSMS service. Stored in encrypted format. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, lightSmsLogin: string, lightSmsPhone: string, lightSmsToken: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-light-sms")
  let req_body = {"dataSegmentCode": $data_segment_code, "lightSmsLogin": $light_sms_login, "lightSmsPhone": $light_sms_phone, "lightSmsToken": $light_sms_token, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportLightSms resource.
#
# DELETE /api/transport-light-sms/{id}
# operationId: api_transport-light-sms_id_delete
export def "transport-light-sms delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-light-sms/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportLightSms resource.
#
# GET /api/transport-light-sms/{id}
# operationId: api_transport-light-sms_id_get
export def "transport-light-sms get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, lightSmsLogin: string, lightSmsPhone: string, lightSmsToken: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-light-sms/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportLightSms resource.
#
# PUT /api/transport-light-sms/{id}
# operationId: api_transport-light-sms_id_put
export def "transport-light-sms update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --light-sms-login: string # The login for the LightSMS service. (nullable)
  --light-sms-phone: string # The sender phone number for the LightSMS service. (nullable)
  --light-sms-token: string # The token for the LightSMS service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, lightSmsLogin: string, lightSmsPhone: string, lightSmsToken: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-light-sms/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "lightSmsLogin": $light_sms_login, "lightSmsPhone": $light_sms_phone, "lightSmsToken": $light_sms_token, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportLineNotify resources.
#
# GET /api/transport-line-notify
# operationId: api_transport-line-notify_get_collection
export def "transport-line-notify get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, lineNotifyAccessToken: string, lineNotifyStickerId: string, lineNotifyStickerPackageId: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-line-notify" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportLineNotify resource.
#
# POST /api/transport-line-notify
# operationId: api_transport-line-notify_post
export def "transport-line-notify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --line-notify-access-token: string # The access token for the LINE Notify service. Stored in encrypted format. (nullable)
  --line-notify-sticker-id: string # The sticker ID value for the LINE Notify service. (nullable)
  --line-notify-sticker-package-id: string # The sticker package ID value for the LINE Notify service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, lineNotifyAccessToken: string, lineNotifyStickerId: string, lineNotifyStickerPackageId: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-line-notify")
  let req_body = {"dataSegmentCode": $data_segment_code, "lineNotifyAccessToken": $line_notify_access_token, "lineNotifyStickerId": $line_notify_sticker_id, "lineNotifyStickerPackageId": $line_notify_sticker_package_id, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportLineNotify resource.
#
# DELETE /api/transport-line-notify/{id}
# operationId: api_transport-line-notify_id_delete
export def "transport-line-notify delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-line-notify/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportLineNotify resource.
#
# GET /api/transport-line-notify/{id}
# operationId: api_transport-line-notify_id_get
export def "transport-line-notify get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, lineNotifyAccessToken: string, lineNotifyStickerId: string, lineNotifyStickerPackageId: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-line-notify/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportLineNotify resource.
#
# PUT /api/transport-line-notify/{id}
# operationId: api_transport-line-notify_id_put
export def "transport-line-notify update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --line-notify-access-token: string # The access token for the LINE Notify service. Stored in encrypted format. (nullable)
  --line-notify-sticker-id: string # The sticker ID value for the LINE Notify service. (nullable)
  --line-notify-sticker-package-id: string # The sticker package ID value for the LINE Notify service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, lineNotifyAccessToken: string, lineNotifyStickerId: string, lineNotifyStickerPackageId: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-line-notify/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "lineNotifyAccessToken": $line_notify_access_token, "lineNotifyStickerId": $line_notify_sticker_id, "lineNotifyStickerPackageId": $line_notify_sticker_package_id, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportLinkedIn resources.
#
# GET /api/transport-linked-in
# operationId: api_transport-linked-in_get_collection
export def "transport-linked-in get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, linkedInToken: string, linkedInUserId: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-linked-in" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportLinkedIn resource.
#
# POST /api/transport-linked-in
# operationId: api_transport-linked-in_post
export def "transport-linked-in create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --linked-in-token: string # The access token for the LinkedIn service. Stored in encrypted format. (nullable)
  --linked-in-user-id: string # The user ID for the LinkedIn service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, linkedInToken: string, linkedInUserId: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-linked-in")
  let req_body = {"dataSegmentCode": $data_segment_code, "linkedInToken": $linked_in_token, "linkedInUserId": $linked_in_user_id, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportLinkedIn resource.
#
# DELETE /api/transport-linked-in/{id}
# operationId: api_transport-linked-in_id_delete
export def "transport-linked-in delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-linked-in/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportLinkedIn resource.
#
# GET /api/transport-linked-in/{id}
# operationId: api_transport-linked-in_id_get
export def "transport-linked-in get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, linkedInToken: string, linkedInUserId: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-linked-in/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportLinkedIn resource.
#
# PUT /api/transport-linked-in/{id}
# operationId: api_transport-linked-in_id_put
export def "transport-linked-in update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --linked-in-token: string # The access token for the LinkedIn service. Stored in encrypted format. (nullable)
  --linked-in-user-id: string # The user ID for the LinkedIn service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, linkedInToken: string, linkedInUserId: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-linked-in/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "linkedInToken": $linked_in_token, "linkedInUserId": $linked_in_user_id, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportMailjet resources.
#
# GET /api/transport-mailjet
# operationId: api_transport-mailjet_get_collection
export def "transport-mailjet get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, mailjetFrom: string, mailjetToken: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-mailjet" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportMailjet resource.
#
# POST /api/transport-mailjet
# operationId: api_transport-mailjet_post
export def "transport-mailjet create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --mailjet-from: string # The alphanumeric sender ID for the MailJet service. (nullable)
  --mailjet-token: string # The SMS auth token for the MailJet service. Stored in encrypted format. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, mailjetFrom: string, mailjetToken: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-mailjet")
  let req_body = {"dataSegmentCode": $data_segment_code, "mailjetFrom": $mailjet_from, "mailjetToken": $mailjet_token, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportMailjet resource.
#
# DELETE /api/transport-mailjet/{id}
# operationId: api_transport-mailjet_id_delete
export def "transport-mailjet delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-mailjet/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportMailjet resource.
#
# GET /api/transport-mailjet/{id}
# operationId: api_transport-mailjet_id_get
export def "transport-mailjet get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, mailjetFrom: string, mailjetToken: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-mailjet/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportMailjet resource.
#
# PUT /api/transport-mailjet/{id}
# operationId: api_transport-mailjet_id_put
export def "transport-mailjet update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --mailjet-from: string # The alphanumeric sender ID for the MailJet service. (nullable)
  --mailjet-token: string # The SMS auth token for the MailJet service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, mailjetFrom: string, mailjetToken: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-mailjet/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "mailjetFrom": $mailjet_from, "mailjetToken": $mailjet_token, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportMastodon resources.
#
# GET /api/transport-mastodon
# operationId: api_transport-mastodon_get_collection
export def "transport-mastodon get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, mastodonAccessToken: string, mastodonHost: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-mastodon" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportMastodon resource.
#
# POST /api/transport-mastodon
# operationId: api_transport-mastodon_post
export def "transport-mastodon create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --mastodon-access-token: string # The access token for the Mastodon service. Stored in encrypted format. (nullable)
  --mastodon-host: string # The host name for the Mastodon service (omit the "https://" part). (nullable, format: hostname)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, mastodonAccessToken: string, mastodonHost: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-mastodon")
  let req_body = {"dataSegmentCode": $data_segment_code, "mastodonAccessToken": $mastodon_access_token, "mastodonHost": $mastodon_host, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportMastodon resource.
#
# DELETE /api/transport-mastodon/{id}
# operationId: api_transport-mastodon_id_delete
export def "transport-mastodon delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-mastodon/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportMastodon resource.
#
# GET /api/transport-mastodon/{id}
# operationId: api_transport-mastodon_id_get
export def "transport-mastodon get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, mastodonAccessToken: string, mastodonHost: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-mastodon/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportMastodon resource.
#
# PUT /api/transport-mastodon/{id}
# operationId: api_transport-mastodon_id_put
export def "transport-mastodon update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --mastodon-access-token: string # The access token for the Mastodon service. Stored in encrypted format. (nullable)
  --mastodon-host: string # The host name for the Mastodon service (omit the "https://" part). (nullable, format: hostname)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, mastodonAccessToken: string, mastodonHost: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-mastodon/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "mastodonAccessToken": $mastodon_access_token, "mastodonHost": $mastodon_host, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportMattermost resources.
#
# GET /api/transport-mattermost
# operationId: api_transport-mattermost_get_collection
export def "transport-mattermost get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, mattermostAccessToken: string, mattermostChannel: string, mattermostHost: string, mattermostPath: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-mattermost" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportMattermost resource.
#
# POST /api/transport-mattermost
# operationId: api_transport-mattermost_post
export def "transport-mattermost create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --mattermost-access-token: string # The access token for the Mattermost service. Stored in encrypted format. (nullable)
  --mattermost-channel: string # The default channel ID for the Mattermost service. (nullable)
  --mattermost-host: string # The host for the Mattermost service. (nullable)
  --mattermost-path: string # The optional path for the Mattermost service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, mattermostAccessToken: string, mattermostChannel: string, mattermostHost: string, mattermostPath: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-mattermost")
  let req_body = {"dataSegmentCode": $data_segment_code, "mattermostAccessToken": $mattermost_access_token, "mattermostChannel": $mattermost_channel, "mattermostHost": $mattermost_host, "mattermostPath": $mattermost_path, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportMattermost resource.
#
# DELETE /api/transport-mattermost/{id}
# operationId: api_transport-mattermost_id_delete
export def "transport-mattermost delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-mattermost/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportMattermost resource.
#
# GET /api/transport-mattermost/{id}
# operationId: api_transport-mattermost_id_get
export def "transport-mattermost get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, mattermostAccessToken: string, mattermostChannel: string, mattermostHost: string, mattermostPath: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-mattermost/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportMattermost resource.
#
# PUT /api/transport-mattermost/{id}
# operationId: api_transport-mattermost_id_put
export def "transport-mattermost update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --mattermost-access-token: string # The access token for the Mattermost service. Stored in encrypted format. (nullable)
  --mattermost-channel: string # The default channel ID for the Mattermost service. (nullable)
  --mattermost-host: string # The host for the Mattermost service. (nullable)
  --mattermost-path: string # The optional path for the Mattermost service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, mattermostAccessToken: string, mattermostChannel: string, mattermostHost: string, mattermostPath: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-mattermost/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "mattermostAccessToken": $mattermost_access_token, "mattermostChannel": $mattermost_channel, "mattermostHost": $mattermost_host, "mattermostPath": $mattermost_path, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportMercure resources.
#
# GET /api/transport-mercure
# operationId: api_transport-mercure_get_collection
export def "transport-mercure get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, mercureHubJwtToken: string, mercureHubUrl: string, mercureTopic: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-mercure" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportMercure resource.
#
# POST /api/transport-mercure
# operationId: api_transport-mercure_post
export def "transport-mercure create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --mercure-hub-jwt-token: string # The JWT token for the hub for the Mercure service. Stored in encrypted format. (nullable)
  --mercure-hub-url: string # The URL for the hub for the Mercure service. (nullable, format: uri)
  --mercure-topic: string # The optional topic for the Mercure service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, mercureHubJwtToken: string, mercureHubUrl: string, mercureTopic: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-mercure")
  let req_body = {"dataSegmentCode": $data_segment_code, "mercureHubJwtToken": $mercure_hub_jwt_token, "mercureHubUrl": $mercure_hub_url, "mercureTopic": $mercure_topic, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportMercure resource.
#
# DELETE /api/transport-mercure/{id}
# operationId: api_transport-mercure_id_delete
export def "transport-mercure delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-mercure/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportMercure resource.
#
# GET /api/transport-mercure/{id}
# operationId: api_transport-mercure_id_get
export def "transport-mercure get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, mercureHubJwtToken: string, mercureHubUrl: string, mercureTopic: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-mercure/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportMercure resource.
#
# PUT /api/transport-mercure/{id}
# operationId: api_transport-mercure_id_put
export def "transport-mercure update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --mercure-hub-jwt-token: string # The JWT token for the hub for the Mercure service. Stored in encrypted format. (nullable)
  --mercure-hub-url: string # The URL for the hub for the Mercure service. (nullable, format: uri)
  --mercure-topic: string # The optional topic for the Mercure service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, mercureHubJwtToken: string, mercureHubUrl: string, mercureTopic: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-mercure/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "mercureHubJwtToken": $mercure_hub_jwt_token, "mercureHubUrl": $mercure_hub_url, "mercureTopic": $mercure_topic, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportMessageBird resources.
#
# GET /api/transport-message-bird
# operationId: api_transport-message-bird_get_collection
export def "transport-message-bird get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, messageBirdFrom: string, messageBirdToken: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-message-bird" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportMessageBird resource.
#
# POST /api/transport-message-bird
# operationId: api_transport-message-bird_post
export def "transport-message-bird create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --message-bird-from: string # The sender value for the MessageBird service. (nullable)
  --message-bird-token: string # The token for the MessageBird service. Stored in encrypted format. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, messageBirdFrom: string, messageBirdToken: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-message-bird")
  let req_body = {"dataSegmentCode": $data_segment_code, "messageBirdFrom": $message_bird_from, "messageBirdToken": $message_bird_token, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportMessageBird resource.
#
# DELETE /api/transport-message-bird/{id}
# operationId: api_transport-message-bird_id_delete
export def "transport-message-bird delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-message-bird/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportMessageBird resource.
#
# GET /api/transport-message-bird/{id}
# operationId: api_transport-message-bird_id_get
export def "transport-message-bird get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, messageBirdFrom: string, messageBirdToken: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-message-bird/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportMessageBird resource.
#
# PUT /api/transport-message-bird/{id}
# operationId: api_transport-message-bird_id_put
export def "transport-message-bird update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --message-bird-from: string # The sender value for the MessageBird service. (nullable)
  --message-bird-token: string # The token for the MessageBird service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, messageBirdFrom: string, messageBirdToken: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-message-bird/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "messageBirdFrom": $message_bird_from, "messageBirdToken": $message_bird_token, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportMessageMedia resources.
#
# GET /api/transport-message-media
# operationId: api_transport-message-media_get_collection
export def "transport-message-media get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, messageMediaApiKey: string, messageMediaApiSecret: string, messageMediaFrom: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-message-media" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportMessageMedia resource.
#
# POST /api/transport-message-media
# operationId: api_transport-message-media_post
export def "transport-message-media create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --message-media-api-key: string # The API key for the MessageMedia service. (nullable)
  --message-media-api-secret: string # The API secret for the MessageMedia service. Stored in encrypted format. (nullable)
  --message-media-from: string # The optional registered sender ID for the MessageMedia service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, messageMediaApiKey: string, messageMediaApiSecret: string, messageMediaFrom: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-message-media")
  let req_body = {"dataSegmentCode": $data_segment_code, "messageMediaApiKey": $message_media_api_key, "messageMediaApiSecret": $message_media_api_secret, "messageMediaFrom": $message_media_from, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportMessageMedia resource.
#
# DELETE /api/transport-message-media/{id}
# operationId: api_transport-message-media_id_delete
export def "transport-message-media delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-message-media/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportMessageMedia resource.
#
# GET /api/transport-message-media/{id}
# operationId: api_transport-message-media_id_get
export def "transport-message-media get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, messageMediaApiKey: string, messageMediaApiSecret: string, messageMediaFrom: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-message-media/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportMessageMedia resource.
#
# PUT /api/transport-message-media/{id}
# operationId: api_transport-message-media_id_put
export def "transport-message-media update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --message-media-api-key: string # The API key for the MessageMedia service. (nullable)
  --message-media-api-secret: string # The API secret for the MessageMedia service. Stored in encrypted format. (nullable)
  --message-media-from: string # The optional registered sender ID for the MessageMedia service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, messageMediaApiKey: string, messageMediaApiSecret: string, messageMediaFrom: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-message-media/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "messageMediaApiKey": $message_media_api_key, "messageMediaApiSecret": $message_media_api_secret, "messageMediaFrom": $message_media_from, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportMicrosoftTeams resources.
#
# GET /api/transport-microsoft-teams
# operationId: api_transport-microsoft-teams_get_collection
export def "transport-microsoft-teams get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, microsoftTeamsPath: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-microsoft-teams" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportMicrosoftTeams resource.
#
# POST /api/transport-microsoft-teams
# operationId: api_transport-microsoft-teams_post
export def "transport-microsoft-teams create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --microsoft-teams-path: string # The path (has the following format: 'webhookb2/{uuid}@{uuid}/IncomingWebhook/{id}/{uuid}') for the Microsoft Teams service. Stored in encrypted format. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, microsoftTeamsPath: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-microsoft-teams")
  let req_body = {"dataSegmentCode": $data_segment_code, "microsoftTeamsPath": $microsoft_teams_path, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportMicrosoftTeams resource.
#
# DELETE /api/transport-microsoft-teams/{id}
# operationId: api_transport-microsoft-teams_id_delete
export def "transport-microsoft-teams delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-microsoft-teams/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportMicrosoftTeams resource.
#
# GET /api/transport-microsoft-teams/{id}
# operationId: api_transport-microsoft-teams_id_get
export def "transport-microsoft-teams get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, microsoftTeamsPath: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-microsoft-teams/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportMicrosoftTeams resource.
#
# PUT /api/transport-microsoft-teams/{id}
# operationId: api_transport-microsoft-teams_id_put
export def "transport-microsoft-teams update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --microsoft-teams-path: string # The path (has the following format: 'webhookb2/{uuid}@{uuid}/IncomingWebhook/{id}/{uuid}') for the Microsoft Teams service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, microsoftTeamsPath: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-microsoft-teams/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "microsoftTeamsPath": $microsoft_teams_path, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportMobyt resources.
#
# GET /api/transport-mobyt
# operationId: api_transport-mobyt_get_collection
export def "transport-mobyt get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, mobytAccessToken: string, mobytFrom: string, mobytTypeQuality: string, mobytUserKey: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-mobyt" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportMobyt resource.
#
# POST /api/transport-mobyt
# operationId: api_transport-mobyt_post
export def "transport-mobyt create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --mobyt-access-token: string # The access token for the Mobyt service. Stored in encrypted format. (nullable)
  --mobyt-from: string # The sender for the Mobyt service. (nullable)
  --mobyt-type-quality: string # The quality of your message: 'N' for high, 'L' for medium, 'LL' for low, for the Mobyt service. (nullable)
  --mobyt-user-key: string # The user key for the Mobyt service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, mobytAccessToken: string, mobytFrom: string, mobytTypeQuality: string, mobytUserKey: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-mobyt")
  let req_body = {"dataSegmentCode": $data_segment_code, "mobytAccessToken": $mobyt_access_token, "mobytFrom": $mobyt_from, "mobytTypeQuality": $mobyt_type_quality, "mobytUserKey": $mobyt_user_key, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportMobyt resource.
#
# DELETE /api/transport-mobyt/{id}
# operationId: api_transport-mobyt_id_delete
export def "transport-mobyt delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-mobyt/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportMobyt resource.
#
# GET /api/transport-mobyt/{id}
# operationId: api_transport-mobyt_id_get
export def "transport-mobyt get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, mobytAccessToken: string, mobytFrom: string, mobytTypeQuality: string, mobytUserKey: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-mobyt/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportMobyt resource.
#
# PUT /api/transport-mobyt/{id}
# operationId: api_transport-mobyt_id_put
export def "transport-mobyt update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --mobyt-access-token: string # The access token for the Mobyt service. Stored in encrypted format. (nullable)
  --mobyt-from: string # The sender for the Mobyt service. (nullable)
  --mobyt-type-quality: string # The quality of your message: 'N' for high, 'L' for medium, 'LL' for low, for the Mobyt service. (nullable)
  --mobyt-user-key: string # The user key for the Mobyt service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, mobytAccessToken: string, mobytFrom: string, mobytTypeQuality: string, mobytUserKey: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-mobyt/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "mobytAccessToken": $mobyt_access_token, "mobytFrom": $mobyt_from, "mobytTypeQuality": $mobyt_type_quality, "mobytUserKey": $mobyt_user_key, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportOctopush resources.
#
# GET /api/transport-octopush
# operationId: api_transport-octopush_get_collection
export def "transport-octopush get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, octopushApiKey: string, octopushFrom: string, octopushType: string, octopushUserLogin: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-octopush" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportOctopush resource.
#
# POST /api/transport-octopush
# operationId: api_transport-octopush_post
export def "transport-octopush create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --octopush-api-key: string # The API key for the Octopush service. Stored in encrypted format. (nullable)
  --octopush-from: string # The sender value for the Octopush service. (nullable)
  --octopush-type: string # The SMS type ('XXX' = SMS LowCost; 'FR' = SMS Premium; 'WWW' = SMS World) for the Octopush service. (nullable)
  --octopush-user-login: string # The user login (email) for the Octopush service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, octopushApiKey: string, octopushFrom: string, octopushType: string, octopushUserLogin: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-octopush")
  let req_body = {"dataSegmentCode": $data_segment_code, "octopushApiKey": $octopush_api_key, "octopushFrom": $octopush_from, "octopushType": $octopush_type, "octopushUserLogin": $octopush_user_login, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportOctopush resource.
#
# DELETE /api/transport-octopush/{id}
# operationId: api_transport-octopush_id_delete
export def "transport-octopush delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-octopush/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportOctopush resource.
#
# GET /api/transport-octopush/{id}
# operationId: api_transport-octopush_id_get
export def "transport-octopush get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, octopushApiKey: string, octopushFrom: string, octopushType: string, octopushUserLogin: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-octopush/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportOctopush resource.
#
# PUT /api/transport-octopush/{id}
# operationId: api_transport-octopush_id_put
export def "transport-octopush update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --octopush-api-key: string # The API key for the Octopush service. Stored in encrypted format. (nullable)
  --octopush-from: string # The sender value for the Octopush service. (nullable)
  --octopush-type: string # The SMS type ('XXX' = SMS LowCost; 'FR' = SMS Premium; 'WWW' = SMS World) for the Octopush service. (nullable)
  --octopush-user-login: string # The user login (email) for the Octopush service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, octopushApiKey: string, octopushFrom: string, octopushType: string, octopushUserLogin: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-octopush/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "octopushApiKey": $octopush_api_key, "octopushFrom": $octopush_from, "octopushType": $octopush_type, "octopushUserLogin": $octopush_user_login, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportOneSignal resources.
#
# GET /api/transport-one-signal
# operationId: api_transport-one-signal_get_collection
export def "transport-one-signal get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, oneSignalApiKey: string, oneSignalAppId: string, oneSignalDefaultRecipientId: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-one-signal" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportOneSignal resource.
#
# POST /api/transport-one-signal
# operationId: api_transport-one-signal_post
export def "transport-one-signal create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --one-signal-api-key: string # The API (auth) key for the One Signal service. Stored in encrypted format. (nullable)
  --one-signal-app-id: string # The App ID for the One Signal service. (nullable)
  --one-signal-default-recipient-id: string # The optional default recipient ID for the One Signal service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, oneSignalApiKey: string, oneSignalAppId: string, oneSignalDefaultRecipientId: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-one-signal")
  let req_body = {"dataSegmentCode": $data_segment_code, "oneSignalApiKey": $one_signal_api_key, "oneSignalAppId": $one_signal_app_id, "oneSignalDefaultRecipientId": $one_signal_default_recipient_id, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportOneSignal resource.
#
# DELETE /api/transport-one-signal/{id}
# operationId: api_transport-one-signal_id_delete
export def "transport-one-signal delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-one-signal/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportOneSignal resource.
#
# GET /api/transport-one-signal/{id}
# operationId: api_transport-one-signal_id_get
export def "transport-one-signal get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, oneSignalApiKey: string, oneSignalAppId: string, oneSignalDefaultRecipientId: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-one-signal/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportOneSignal resource.
#
# PUT /api/transport-one-signal/{id}
# operationId: api_transport-one-signal_id_put
export def "transport-one-signal update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --one-signal-api-key: string # The API (auth) key for the One Signal service. Stored in encrypted format. (nullable)
  --one-signal-app-id: string # The App ID for the One Signal service. (nullable)
  --one-signal-default-recipient-id: string # The optional default recipient ID for the One Signal service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, oneSignalApiKey: string, oneSignalAppId: string, oneSignalDefaultRecipientId: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-one-signal/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "oneSignalApiKey": $one_signal_api_key, "oneSignalAppId": $one_signal_app_id, "oneSignalDefaultRecipientId": $one_signal_default_recipient_id, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportOpsgenie resources.
#
# GET /api/transport-opsgenie
# operationId: api_transport-opsgenie_get_collection
export def "transport-opsgenie get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, opsgenieAlias: string, opsgenieApiKey: string, opsgenieEntity: string, opsgenieNote: string, opsgeniePriority: string, opsgenieUser: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-opsgenie" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportOpsgenie resource.
#
# POST /api/transport-opsgenie
# operationId: api_transport-opsgenie_post
export def "transport-opsgenie create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --opsgenie-alias: string # The alias for the Opsgenie service. (nullable)
  --opsgenie-api-key: string # The API key for the Opsgenie service. Stored in encrypted format. (nullable)
  --opsgenie-entity: string # The entity for the Opsgenie service. (nullable)
  --opsgenie-note: string # The note for the Opsgenie service. (nullable)
  --opsgenie-priority: string # The priority for the Opsgenie service. (nullable)
  --opsgenie-user: string # The user for the Opsgenie service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, opsgenieAlias: string, opsgenieApiKey: string, opsgenieEntity: string, opsgenieNote: string, opsgeniePriority: string, opsgenieUser: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-opsgenie")
  let req_body = {"dataSegmentCode": $data_segment_code, "opsgenieAlias": $opsgenie_alias, "opsgenieApiKey": $opsgenie_api_key, "opsgenieEntity": $opsgenie_entity, "opsgenieNote": $opsgenie_note, "opsgeniePriority": $opsgenie_priority, "opsgenieUser": $opsgenie_user, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportOpsgenie resource.
#
# DELETE /api/transport-opsgenie/{id}
# operationId: api_transport-opsgenie_id_delete
export def "transport-opsgenie delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-opsgenie/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportOpsgenie resource.
#
# GET /api/transport-opsgenie/{id}
# operationId: api_transport-opsgenie_id_get
export def "transport-opsgenie get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, opsgenieAlias: string, opsgenieApiKey: string, opsgenieEntity: string, opsgenieNote: string, opsgeniePriority: string, opsgenieUser: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-opsgenie/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportOpsgenie resource.
#
# PUT /api/transport-opsgenie/{id}
# operationId: api_transport-opsgenie_id_put
export def "transport-opsgenie update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --opsgenie-alias: string # The alias for the Opsgenie service. (nullable)
  --opsgenie-api-key: string # The API key for the Opsgenie service. Stored in encrypted format. (nullable)
  --opsgenie-entity: string # The entity for the Opsgenie service. (nullable)
  --opsgenie-note: string # The note for the Opsgenie service. (nullable)
  --opsgenie-priority: string # The priority for the Opsgenie service. (nullable)
  --opsgenie-user: string # The user for the Opsgenie service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, opsgenieAlias: string, opsgenieApiKey: string, opsgenieEntity: string, opsgenieNote: string, opsgeniePriority: string, opsgenieUser: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-opsgenie/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "opsgenieAlias": $opsgenie_alias, "opsgenieApiKey": $opsgenie_api_key, "opsgenieEntity": $opsgenie_entity, "opsgenieNote": $opsgenie_note, "opsgeniePriority": $opsgenie_priority, "opsgenieUser": $opsgenie_user, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportOrangeSms resources.
#
# GET /api/transport-orange-sms
# operationId: api_transport-orange-sms_get_collection
export def "transport-orange-sms get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, orangeSmsClientId: string, orangeSmsClientSecret: string, orangeSmsFrom: string, orangeSmsSenderName: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-orange-sms" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportOrangeSms resource.
#
# POST /api/transport-orange-sms
# operationId: api_transport-orange-sms_post
export def "transport-orange-sms create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --orange-sms-client-id: string # The app client ID for the Orange SMS service. (nullable)
  --orange-sms-client-secret: string # The app client secret for the Orange SMS service. Stored in encrypted format. (nullable)
  --orange-sms-from: string # The sender phone number for the Orange SMS service. (nullable)
  --orange-sms-sender-name: string # The sender name for the Orange SMS service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, orangeSmsClientId: string, orangeSmsClientSecret: string, orangeSmsFrom: string, orangeSmsSenderName: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-orange-sms")
  let req_body = {"dataSegmentCode": $data_segment_code, "orangeSmsClientId": $orange_sms_client_id, "orangeSmsClientSecret": $orange_sms_client_secret, "orangeSmsFrom": $orange_sms_from, "orangeSmsSenderName": $orange_sms_sender_name, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportOrangeSms resource.
#
# DELETE /api/transport-orange-sms/{id}
# operationId: api_transport-orange-sms_id_delete
export def "transport-orange-sms delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-orange-sms/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportOrangeSms resource.
#
# GET /api/transport-orange-sms/{id}
# operationId: api_transport-orange-sms_id_get
export def "transport-orange-sms get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, orangeSmsClientId: string, orangeSmsClientSecret: string, orangeSmsFrom: string, orangeSmsSenderName: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-orange-sms/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportOrangeSms resource.
#
# PUT /api/transport-orange-sms/{id}
# operationId: api_transport-orange-sms_id_put
export def "transport-orange-sms update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --orange-sms-client-id: string # The app client ID for the Orange SMS service. (nullable)
  --orange-sms-client-secret: string # The app client secret for the Orange SMS service. Stored in encrypted format. (nullable)
  --orange-sms-from: string # The sender phone number for the Orange SMS service. (nullable)
  --orange-sms-sender-name: string # The sender name for the Orange SMS service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, orangeSmsClientId: string, orangeSmsClientSecret: string, orangeSmsFrom: string, orangeSmsSenderName: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-orange-sms/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "orangeSmsClientId": $orange_sms_client_id, "orangeSmsClientSecret": $orange_sms_client_secret, "orangeSmsFrom": $orange_sms_from, "orangeSmsSenderName": $orange_sms_sender_name, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportOvhCloud resources.
#
# GET /api/transport-ovh-cloud
# operationId: api_transport-ovh-cloud_get_collection
export def "transport-ovh-cloud get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, ovhCloudApplicationKey: string, ovhCloudApplicationSecret: string, ovhCloudConsumerKey: string, ovhCloudSender: string, ovhCloudServiceName: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-ovh-cloud" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportOvhCloud resource.
#
# POST /api/transport-ovh-cloud
# operationId: api_transport-ovh-cloud_post
export def "transport-ovh-cloud create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --ovh-cloud-application-key: string # The application key for the OVHcloud service. (nullable)
  --ovh-cloud-application-secret: string # The application secret for the OVHcloud service. Stored in encrypted format. (nullable)
  --ovh-cloud-consumer-key: string # The consumer key for the OVHcloud service. (nullable)
  --ovh-cloud-sender: string # The optional sender for the OVHcloud service. (nullable)
  --ovh-cloud-service-name: string # The service name for the OVHcloud service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, ovhCloudApplicationKey: string, ovhCloudApplicationSecret: string, ovhCloudConsumerKey: string, ovhCloudSender: string, ovhCloudServiceName: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-ovh-cloud")
  let req_body = {"dataSegmentCode": $data_segment_code, "ovhCloudApplicationKey": $ovh_cloud_application_key, "ovhCloudApplicationSecret": $ovh_cloud_application_secret, "ovhCloudConsumerKey": $ovh_cloud_consumer_key, "ovhCloudSender": $ovh_cloud_sender, "ovhCloudServiceName": $ovh_cloud_service_name, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportOvhCloud resource.
#
# DELETE /api/transport-ovh-cloud/{id}
# operationId: api_transport-ovh-cloud_id_delete
export def "transport-ovh-cloud delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-ovh-cloud/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportOvhCloud resource.
#
# GET /api/transport-ovh-cloud/{id}
# operationId: api_transport-ovh-cloud_id_get
export def "transport-ovh-cloud get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, ovhCloudApplicationKey: string, ovhCloudApplicationSecret: string, ovhCloudConsumerKey: string, ovhCloudSender: string, ovhCloudServiceName: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-ovh-cloud/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportOvhCloud resource.
#
# PUT /api/transport-ovh-cloud/{id}
# operationId: api_transport-ovh-cloud_id_put
export def "transport-ovh-cloud update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --ovh-cloud-application-key: string # The application key for the OVHcloud service. (nullable)
  --ovh-cloud-application-secret: string # The application secret for the OVHcloud service. Stored in encrypted format. (nullable)
  --ovh-cloud-consumer-key: string # The consumer key for the OVHcloud service. (nullable)
  --ovh-cloud-sender: string # The optional sender for the OVHcloud service. (nullable)
  --ovh-cloud-service-name: string # The service name for the OVHcloud service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, ovhCloudApplicationKey: string, ovhCloudApplicationSecret: string, ovhCloudConsumerKey: string, ovhCloudSender: string, ovhCloudServiceName: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-ovh-cloud/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "ovhCloudApplicationKey": $ovh_cloud_application_key, "ovhCloudApplicationSecret": $ovh_cloud_application_secret, "ovhCloudConsumerKey": $ovh_cloud_consumer_key, "ovhCloudSender": $ovh_cloud_sender, "ovhCloudServiceName": $ovh_cloud_service_name, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportPagerDuty resources.
#
# GET /api/transport-pager-duty
# operationId: api_transport-pager-duty_get_collection
export def "transport-pager-duty get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, pagerDutyApiToken: string, pagerDutyDedupKey: string, pagerDutyEventAction: string, pagerDutyPayloadClass: string, pagerDutyPayloadComponent: string, pagerDutyPayloadGroup: string, pagerDutyPayloadSeverity: string, pagerDutyPayloadSource: string, pagerDutyRoutingKey: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-pager-duty" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportPagerDuty resource.
#
# POST /api/transport-pager-duty
# operationId: api_transport-pager-duty_post
export def "transport-pager-duty create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --pager-duty-api-token: string # The API token for the Pager Duty service. Stored in encrypted format. (nullable)
  --pager-duty-dedup-key: string # The dedup key for the Pager Duty service. (nullable)
  --pager-duty-event-action: string # The event action for the Pager Duty service. (nullable)
  --pager-duty-payload-class: string # The payload class for the Pager Duty service. (nullable)
  --pager-duty-payload-component: string # The payload component for the Pager Duty service. (nullable)
  --pager-duty-payload-group: string # The payload group for the Pager Duty service. (nullable)
  --pager-duty-payload-severity: string # The payload severity for the Pager Duty service. (nullable)
  --pager-duty-payload-source: string # The payload source for the Pager Duty service. (nullable)
  --pager-duty-routing-key: string # The routing key for the Pager Duty service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, pagerDutyApiToken: string, pagerDutyDedupKey: string, pagerDutyEventAction: string, pagerDutyPayloadClass: string, pagerDutyPayloadComponent: string, pagerDutyPayloadGroup: string, pagerDutyPayloadSeverity: string, pagerDutyPayloadSource: string, pagerDutyRoutingKey: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-pager-duty")
  let req_body = {"dataSegmentCode": $data_segment_code, "pagerDutyApiToken": $pager_duty_api_token, "pagerDutyDedupKey": $pager_duty_dedup_key, "pagerDutyEventAction": $pager_duty_event_action, "pagerDutyPayloadClass": $pager_duty_payload_class, "pagerDutyPayloadComponent": $pager_duty_payload_component, "pagerDutyPayloadGroup": $pager_duty_payload_group, "pagerDutyPayloadSeverity": $pager_duty_payload_severity, "pagerDutyPayloadSource": $pager_duty_payload_source, "pagerDutyRoutingKey": $pager_duty_routing_key, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportPagerDuty resource.
#
# DELETE /api/transport-pager-duty/{id}
# operationId: api_transport-pager-duty_id_delete
export def "transport-pager-duty delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-pager-duty/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportPagerDuty resource.
#
# GET /api/transport-pager-duty/{id}
# operationId: api_transport-pager-duty_id_get
export def "transport-pager-duty get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, pagerDutyApiToken: string, pagerDutyDedupKey: string, pagerDutyEventAction: string, pagerDutyPayloadClass: string, pagerDutyPayloadComponent: string, pagerDutyPayloadGroup: string, pagerDutyPayloadSeverity: string, pagerDutyPayloadSource: string, pagerDutyRoutingKey: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-pager-duty/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportPagerDuty resource.
#
# PUT /api/transport-pager-duty/{id}
# operationId: api_transport-pager-duty_id_put
export def "transport-pager-duty update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --pager-duty-api-token: string # The API token for the Pager Duty service. Stored in encrypted format. (nullable)
  --pager-duty-dedup-key: string # The dedup key for the Pager Duty service. (nullable)
  --pager-duty-event-action: string # The event action for the Pager Duty service. (nullable)
  --pager-duty-payload-class: string # The payload class for the Pager Duty service. (nullable)
  --pager-duty-payload-component: string # The payload component for the Pager Duty service. (nullable)
  --pager-duty-payload-group: string # The payload group for the Pager Duty service. (nullable)
  --pager-duty-payload-severity: string # The payload severity for the Pager Duty service. (nullable)
  --pager-duty-payload-source: string # The payload source for the Pager Duty service. (nullable)
  --pager-duty-routing-key: string # The routing key for the Pager Duty service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, pagerDutyApiToken: string, pagerDutyDedupKey: string, pagerDutyEventAction: string, pagerDutyPayloadClass: string, pagerDutyPayloadComponent: string, pagerDutyPayloadGroup: string, pagerDutyPayloadSeverity: string, pagerDutyPayloadSource: string, pagerDutyRoutingKey: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-pager-duty/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "pagerDutyApiToken": $pager_duty_api_token, "pagerDutyDedupKey": $pager_duty_dedup_key, "pagerDutyEventAction": $pager_duty_event_action, "pagerDutyPayloadClass": $pager_duty_payload_class, "pagerDutyPayloadComponent": $pager_duty_payload_component, "pagerDutyPayloadGroup": $pager_duty_payload_group, "pagerDutyPayloadSeverity": $pager_duty_payload_severity, "pagerDutyPayloadSource": $pager_duty_payload_source, "pagerDutyRoutingKey": $pager_duty_routing_key, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportPagerTree resources.
#
# GET /api/transport-pager-tree
# operationId: api_transport-pager-tree_get_collection
export def "transport-pager-tree get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, pagerTreeAccessToken: string, pagerTreeAccountUserId: string, pagerTreeRouterId: string, pagerTreeTeamId: string, pagerTreeUrgency: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-pager-tree" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportPagerTree resource.
#
# POST /api/transport-pager-tree
# operationId: api_transport-pager-tree_post
export def "transport-pager-tree create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --pager-tree-access-token: string # The access token for the Pager Tree service. Stored in encrypted format. (nullable)
  --pager-tree-account-user-id: string # The account user ID for the Pager Tree service. (Must supply either team ID, router ID or account user ID.) (nullable)
  --pager-tree-router-id: string # The router ID for the Pager Tree service. (Must supply either team ID, router ID or account user ID.) (nullable)
  --pager-tree-team-id: string # The team ID for the Pager Tree service. (Must supply either team ID, router ID or account user ID.) (nullable)
  --pager-tree-urgency: string # The urgency for the Pager Tree service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, pagerTreeAccessToken: string, pagerTreeAccountUserId: string, pagerTreeRouterId: string, pagerTreeTeamId: string, pagerTreeUrgency: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-pager-tree")
  let req_body = {"dataSegmentCode": $data_segment_code, "pagerTreeAccessToken": $pager_tree_access_token, "pagerTreeAccountUserId": $pager_tree_account_user_id, "pagerTreeRouterId": $pager_tree_router_id, "pagerTreeTeamId": $pager_tree_team_id, "pagerTreeUrgency": $pager_tree_urgency, "partition": $partition, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportPagerTree resource.
#
# DELETE /api/transport-pager-tree/{id}
# operationId: api_transport-pager-tree_id_delete
export def "transport-pager-tree delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-pager-tree/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportPagerTree resource.
#
# GET /api/transport-pager-tree/{id}
# operationId: api_transport-pager-tree_id_get
export def "transport-pager-tree get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, pagerTreeAccessToken: string, pagerTreeAccountUserId: string, pagerTreeRouterId: string, pagerTreeTeamId: string, pagerTreeUrgency: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-pager-tree/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportPagerTree resource.
#
# PUT /api/transport-pager-tree/{id}
# operationId: api_transport-pager-tree_id_put
export def "transport-pager-tree update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --pager-tree-access-token: string # The access token for the Pager Tree service. Stored in encrypted format. (nullable)
  --pager-tree-account-user-id: string # The account user ID for the Pager Tree service. (Must supply either team ID, router ID or account user ID.) (nullable)
  --pager-tree-router-id: string # The router ID for the Pager Tree service. (Must supply either team ID, router ID or account user ID.) (nullable)
  --pager-tree-team-id: string # The team ID for the Pager Tree service. (Must supply either team ID, router ID or account user ID.) (nullable)
  --pager-tree-urgency: string # The urgency for the Pager Tree service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, pagerTreeAccessToken: string, pagerTreeAccountUserId: string, pagerTreeRouterId: string, pagerTreeTeamId: string, pagerTreeUrgency: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-pager-tree/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "pagerTreeAccessToken": $pager_tree_access_token, "pagerTreeAccountUserId": $pager_tree_account_user_id, "pagerTreeRouterId": $pager_tree_router_id, "pagerTreeTeamId": $pager_tree_team_id, "pagerTreeUrgency": $pager_tree_urgency, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportPlivo resources.
#
# GET /api/transport-plivo
# operationId: api_transport-plivo_get_collection
export def "transport-plivo get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, plivoAuthId: string, plivoAuthToken: string, plivoFrom: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-plivo" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportPlivo resource.
#
# POST /api/transport-plivo
# operationId: api_transport-plivo_post
export def "transport-plivo create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --plivo-auth-id: string # The auth ID for the Plivo service. (nullable)
  --plivo-auth-token: string # The auth token for the Plivo service. Stored in encrypted format. (nullable)
  --plivo-from: string # The sender value for the Plivo service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, plivoAuthId: string, plivoAuthToken: string, plivoFrom: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-plivo")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "plivoAuthId": $plivo_auth_id, "plivoAuthToken": $plivo_auth_token, "plivoFrom": $plivo_from, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportPlivo resource.
#
# DELETE /api/transport-plivo/{id}
# operationId: api_transport-plivo_id_delete
export def "transport-plivo delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-plivo/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportPlivo resource.
#
# GET /api/transport-plivo/{id}
# operationId: api_transport-plivo_id_get
export def "transport-plivo get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, plivoAuthId: string, plivoAuthToken: string, plivoFrom: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-plivo/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportPlivo resource.
#
# PUT /api/transport-plivo/{id}
# operationId: api_transport-plivo_id_put
export def "transport-plivo update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --plivo-auth-id: string # The auth ID for the Plivo service. (nullable)
  --plivo-auth-token: string # The auth token for the Plivo service. Stored in encrypted format. (nullable)
  --plivo-from: string # The sender value for the Plivo service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, plivoAuthId: string, plivoAuthToken: string, plivoFrom: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-plivo/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "plivoAuthId": $plivo_auth_id, "plivoAuthToken": $plivo_auth_token, "plivoFrom": $plivo_from, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportPushbullet resources.
#
# GET /api/transport-pushbullet
# operationId: api_transport-pushbullet_get_collection
export def "transport-pushbullet get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, pushbulletAccessToken: string, pushbulletEmail: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-pushbullet" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportPushbullet resource.
#
# POST /api/transport-pushbullet
# operationId: api_transport-pushbullet_post
export def "transport-pushbullet create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --pushbullet-access-token: string # The access token for the Pushbullet service. Stored in encrypted format. (nullable)
  --pushbullet-email: string # The recipient email for the Pushbullet service. (nullable, format: email)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, pushbulletAccessToken: string, pushbulletEmail: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-pushbullet")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "pushbulletAccessToken": $pushbullet_access_token, "pushbulletEmail": $pushbullet_email, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportPushbullet resource.
#
# DELETE /api/transport-pushbullet/{id}
# operationId: api_transport-pushbullet_id_delete
export def "transport-pushbullet delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-pushbullet/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportPushbullet resource.
#
# GET /api/transport-pushbullet/{id}
# operationId: api_transport-pushbullet_id_get
export def "transport-pushbullet get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, pushbulletAccessToken: string, pushbulletEmail: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-pushbullet/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportPushbullet resource.
#
# PUT /api/transport-pushbullet/{id}
# operationId: api_transport-pushbullet_id_put
export def "transport-pushbullet update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --pushbullet-access-token: string # The access token for the Pushbullet service. Stored in encrypted format. (nullable)
  --pushbullet-email: string # The recipient email for the Pushbullet service. (nullable, format: email)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, pushbulletAccessToken: string, pushbulletEmail: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-pushbullet/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "pushbulletAccessToken": $pushbullet_access_token, "pushbulletEmail": $pushbullet_email, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportPushover resources.
#
# GET /api/transport-pushover
# operationId: api_transport-pushover_get_collection
export def "transport-pushover get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, pushoverAppToken: string, pushoverUserKey: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-pushover" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportPushover resource.
#
# POST /api/transport-pushover
# operationId: api_transport-pushover_post
export def "transport-pushover create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --pushover-app-token: string # The app token for the Pushover service. Stored in encrypted format. (nullable)
  --pushover-user-key: string # The user key for the Pushover service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, pushoverAppToken: string, pushoverUserKey: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-pushover")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "pushoverAppToken": $pushover_app_token, "pushoverUserKey": $pushover_user_key, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportPushover resource.
#
# DELETE /api/transport-pushover/{id}
# operationId: api_transport-pushover_id_delete
export def "transport-pushover delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-pushover/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportPushover resource.
#
# GET /api/transport-pushover/{id}
# operationId: api_transport-pushover_id_get
export def "transport-pushover get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, pushoverAppToken: string, pushoverUserKey: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-pushover/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportPushover resource.
#
# PUT /api/transport-pushover/{id}
# operationId: api_transport-pushover_id_put
export def "transport-pushover update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --pushover-app-token: string # The app token for the Pushover service. Stored in encrypted format. (nullable)
  --pushover-user-key: string # The user key for the Pushover service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, pushoverAppToken: string, pushoverUserKey: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-pushover/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "pushoverAppToken": $pushover_app_token, "pushoverUserKey": $pushover_user_key, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportPushy resources.
#
# GET /api/transport-pushy
# operationId: api_transport-pushy_get_collection
export def "transport-pushy get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, pushyApiKey: string, pushyTo: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-pushy" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportPushy resource.
#
# POST /api/transport-pushy
# operationId: api_transport-pushy_post
export def "transport-pushy create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --pushy-api-key: string # The API key for the Pushy service. Stored in encrypted format. (nullable)
  --pushy-to: string # The recipient ID for the Pushy service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, pushyApiKey: string, pushyTo: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-pushy")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "pushyApiKey": $pushy_api_key, "pushyTo": $pushy_to, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportPushy resource.
#
# DELETE /api/transport-pushy/{id}
# operationId: api_transport-pushy_id_delete
export def "transport-pushy delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-pushy/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportPushy resource.
#
# GET /api/transport-pushy/{id}
# operationId: api_transport-pushy_id_get
export def "transport-pushy get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, pushyApiKey: string, pushyTo: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-pushy/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportPushy resource.
#
# PUT /api/transport-pushy/{id}
# operationId: api_transport-pushy_id_put
export def "transport-pushy update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --pushy-api-key: string # The API key for the Pushy service. Stored in encrypted format. (nullable)
  --pushy-to: string # The recipient ID for the Pushy service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, pushyApiKey: string, pushyTo: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-pushy/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "pushyApiKey": $pushy_api_key, "pushyTo": $pushy_to, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportRingCentral resources.
#
# GET /api/transport-ring-central
# operationId: api_transport-ring-central_get_collection
export def "transport-ring-central get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, ringCentralApiToken: string, ringCentralFrom: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-ring-central" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportRingCentral resource.
#
# POST /api/transport-ring-central
# operationId: api_transport-ring-central_post
export def "transport-ring-central create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --ring-central-api-token: string # The API token for the Ring Central service. Stored in encrypted format. (nullable)
  --ring-central-from: string # The sender value for the Ring Central service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, ringCentralApiToken: string, ringCentralFrom: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-ring-central")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "ringCentralApiToken": $ring_central_api_token, "ringCentralFrom": $ring_central_from, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportRingCentral resource.
#
# DELETE /api/transport-ring-central/{id}
# operationId: api_transport-ring-central_id_delete
export def "transport-ring-central delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-ring-central/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportRingCentral resource.
#
# GET /api/transport-ring-central/{id}
# operationId: api_transport-ring-central_id_get
export def "transport-ring-central get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, ringCentralApiToken: string, ringCentralFrom: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-ring-central/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportRingCentral resource.
#
# PUT /api/transport-ring-central/{id}
# operationId: api_transport-ring-central_id_put
export def "transport-ring-central update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --ring-central-api-token: string # The API token for the Ring Central service. Stored in encrypted format. (nullable)
  --ring-central-from: string # The sender value for the Ring Central service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, ringCentralApiToken: string, ringCentralFrom: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-ring-central/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "ringCentralApiToken": $ring_central_api_token, "ringCentralFrom": $ring_central_from, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportRocketChat resources.
#
# GET /api/transport-rocket-chat
# operationId: api_transport-rocket-chat_get_collection
export def "transport-rocket-chat get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, rocketChatChannel: string, rocketChatToken: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-rocket-chat" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportRocketChat resource.
#
# POST /api/transport-rocket-chat
# operationId: api_transport-rocket-chat_post
export def "transport-rocket-chat create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --rocket-chat-channel: string # The channel for the Rocket Chat service. (nullable)
  --rocket-chat-token: string # The access token for the Rocket Chat service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, rocketChatChannel: string, rocketChatToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-rocket-chat")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "rocketChatChannel": $rocket_chat_channel, "rocketChatToken": $rocket_chat_token, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportRocketChat resource.
#
# DELETE /api/transport-rocket-chat/{id}
# operationId: api_transport-rocket-chat_id_delete
export def "transport-rocket-chat delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-rocket-chat/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportRocketChat resource.
#
# GET /api/transport-rocket-chat/{id}
# operationId: api_transport-rocket-chat_id_get
export def "transport-rocket-chat get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, rocketChatChannel: string, rocketChatToken: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-rocket-chat/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportRocketChat resource.
#
# PUT /api/transport-rocket-chat/{id}
# operationId: api_transport-rocket-chat_id_put
export def "transport-rocket-chat update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --rocket-chat-channel: string # The channel for the Rocket Chat service. (nullable)
  --rocket-chat-token: string # The access token for the Rocket Chat service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, rocketChatChannel: string, rocketChatToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-rocket-chat/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "rocketChatChannel": $rocket_chat_channel, "rocketChatToken": $rocket_chat_token, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportSendberry resources.
#
# GET /api/transport-sendberry
# operationId: api_transport-sendberry_get_collection
export def "transport-sendberry get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sendberryAuthKey: string, sendberryFrom: string, sendberryPassword: string, sendberryUsername: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-sendberry" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSendberry resource.
#
# POST /api/transport-sendberry
# operationId: api_transport-sendberry_post
export def "transport-sendberry create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --sendberry-auth-key: string # The auth key for the Sendberry service. (nullable)
  --sendberry-from: string # The sender name or phone number for the Sendberry service. (nullable)
  --sendberry-password: string # The password for the Sendberry service. Stored in encrypted format. (nullable)
  --sendberry-username: string # The username for the Sendberry service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sendberryAuthKey: string, sendberryFrom: string, sendberryPassword: string, sendberryUsername: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-sendberry")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "sendberryAuthKey": $sendberry_auth_key, "sendberryFrom": $sendberry_from, "sendberryPassword": $sendberry_password, "sendberryUsername": $sendberry_username, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportSendberry resource.
#
# DELETE /api/transport-sendberry/{id}
# operationId: api_transport-sendberry_id_delete
export def "transport-sendberry delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-sendberry/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportSendberry resource.
#
# GET /api/transport-sendberry/{id}
# operationId: api_transport-sendberry_id_get
export def "transport-sendberry get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sendberryAuthKey: string, sendberryFrom: string, sendberryPassword: string, sendberryUsername: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-sendberry/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSendberry resource.
#
# PUT /api/transport-sendberry/{id}
# operationId: api_transport-sendberry_id_put
export def "transport-sendberry update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --sendberry-auth-key: string # The auth key for the Sendberry service. (nullable)
  --sendberry-from: string # The sender name or phone number for the Sendberry service. (nullable)
  --sendberry-password: string # The password for the Sendberry service. Stored in encrypted format. (nullable)
  --sendberry-username: string # The username for the Sendberry service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sendberryAuthKey: string, sendberryFrom: string, sendberryPassword: string, sendberryUsername: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-sendberry/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "sendberryAuthKey": $sendberry_auth_key, "sendberryFrom": $sendberry_from, "sendberryPassword": $sendberry_password, "sendberryUsername": $sendberry_username, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportSendinblue resources.
#
# GET /api/transport-sendinblue
# operationId: api_transport-sendinblue_get_collection
export def "transport-sendinblue get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sendinblueApiKey: string, sendinblueSenderPhone: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-sendinblue" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSendinblue resource.
#
# POST /api/transport-sendinblue
# operationId: api_transport-sendinblue_post
export def "transport-sendinblue create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --sendinblue-api-key: string # The API key for the Sendinblue service. Stored in encrypted format. (nullable)
  --sendinblue-sender-phone: string # The sender phone number for the Sendinblue service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sendinblueApiKey: string, sendinblueSenderPhone: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-sendinblue")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "sendinblueApiKey": $sendinblue_api_key, "sendinblueSenderPhone": $sendinblue_sender_phone, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportSendinblue resource.
#
# DELETE /api/transport-sendinblue/{id}
# operationId: api_transport-sendinblue_id_delete
export def "transport-sendinblue delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-sendinblue/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportSendinblue resource.
#
# GET /api/transport-sendinblue/{id}
# operationId: api_transport-sendinblue_id_get
export def "transport-sendinblue get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sendinblueApiKey: string, sendinblueSenderPhone: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-sendinblue/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSendinblue resource.
#
# PUT /api/transport-sendinblue/{id}
# operationId: api_transport-sendinblue_id_put
export def "transport-sendinblue update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --sendinblue-api-key: string # The API key for the Sendinblue service. Stored in encrypted format. (nullable)
  --sendinblue-sender-phone: string # The sender phone number for the Sendinblue service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sendinblueApiKey: string, sendinblueSenderPhone: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-sendinblue/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "sendinblueApiKey": $sendinblue_api_key, "sendinblueSenderPhone": $sendinblue_sender_phone, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportSimpleTextin resources.
#
# GET /api/transport-simple-textin
# operationId: api_transport-simple-textin_get_collection
export def "transport-simple-textin get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, simpleTextinApiKey: string, simpleTextinFrom: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-simple-textin" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSimpleTextin resource.
#
# POST /api/transport-simple-textin
# operationId: api_transport-simple-textin_post
export def "transport-simple-textin create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --simple-textin-api-key: string # The API key for the SimpleTextin service. Stored in encrypted format. (nullable)
  --simple-textin-from: string # The from value for the SimpleTextin service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, simpleTextinApiKey: string, simpleTextinFrom: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-simple-textin")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "simpleTextinApiKey": $simple_textin_api_key, "simpleTextinFrom": $simple_textin_from, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportSimpleTextin resource.
#
# DELETE /api/transport-simple-textin/{id}
# operationId: api_transport-simple-textin_id_delete
export def "transport-simple-textin delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-simple-textin/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportSimpleTextin resource.
#
# GET /api/transport-simple-textin/{id}
# operationId: api_transport-simple-textin_id_get
export def "transport-simple-textin get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, simpleTextinApiKey: string, simpleTextinFrom: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-simple-textin/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSimpleTextin resource.
#
# PUT /api/transport-simple-textin/{id}
# operationId: api_transport-simple-textin_id_put
export def "transport-simple-textin update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --simple-textin-api-key: string # The API key for the SimpleTextin service. Stored in encrypted format. (nullable)
  --simple-textin-from: string # The from value for the SimpleTextin service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, simpleTextinApiKey: string, simpleTextinFrom: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-simple-textin/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "simpleTextinApiKey": $simple_textin_api_key, "simpleTextinFrom": $simple_textin_from, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportSinch resources.
#
# GET /api/transport-sinch
# operationId: api_transport-sinch_get_collection
export def "transport-sinch get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sinchAuthToken: string, sinchFrom: string, sinchServicePlanId: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-sinch" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSinch resource.
#
# POST /api/transport-sinch
# operationId: api_transport-sinch_post
export def "transport-sinch create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --sinch-auth-token: string # The auth token for the Sinch service. Stored in encrypted format. (nullable)
  --sinch-from: string # The sender for the Sinch service. (nullable)
  --sinch-service-plan-id: string # The service plan ID for the Sinch service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sinchAuthToken: string, sinchFrom: string, sinchServicePlanId: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-sinch")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "sinchAuthToken": $sinch_auth_token, "sinchFrom": $sinch_from, "sinchServicePlanId": $sinch_service_plan_id, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportSinch resource.
#
# DELETE /api/transport-sinch/{id}
# operationId: api_transport-sinch_id_delete
export def "transport-sinch delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-sinch/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportSinch resource.
#
# GET /api/transport-sinch/{id}
# operationId: api_transport-sinch_id_get
export def "transport-sinch get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sinchAuthToken: string, sinchFrom: string, sinchServicePlanId: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-sinch/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSinch resource.
#
# PUT /api/transport-sinch/{id}
# operationId: api_transport-sinch_id_put
export def "transport-sinch update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --sinch-auth-token: string # The auth token for the Sinch service. Stored in encrypted format. (nullable)
  --sinch-from: string # The sender for the Sinch service. (nullable)
  --sinch-service-plan-id: string # The service plan ID for the Sinch service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sinchAuthToken: string, sinchFrom: string, sinchServicePlanId: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-sinch/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "sinchAuthToken": $sinch_auth_token, "sinchFrom": $sinch_from, "sinchServicePlanId": $sinch_service_plan_id, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportSlack resources.
#
# GET /api/transport-slack
# operationId: api_transport-slack_get_collection
export def "transport-slack get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, slackChannel: string, slackToken: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-slack" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSlack resource.
#
# POST /api/transport-slack
# operationId: api_transport-slack_post
export def "transport-slack create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --slack-channel: string # The channel (channel, private group, or IM channel to send message to, it can be an encoded ID, or a name) for the Slack service. (nullable)
  --slack-token: string # The token for the Slack service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, slackChannel: string, slackToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-slack")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "slackChannel": $slack_channel, "slackToken": $slack_token, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportSlack resource.
#
# DELETE /api/transport-slack/{id}
# operationId: api_transport-slack_id_delete
export def "transport-slack delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-slack/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportSlack resource.
#
# GET /api/transport-slack/{id}
# operationId: api_transport-slack_id_get
export def "transport-slack get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, slackChannel: string, slackToken: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-slack/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSlack resource.
#
# PUT /api/transport-slack/{id}
# operationId: api_transport-slack_id_put
export def "transport-slack update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --slack-channel: string # The channel (channel, private group, or IM channel to send message to, it can be an encoded ID, or a name) for the Slack service. (nullable)
  --slack-token: string # The token for the Slack service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, slackChannel: string, slackToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-slack/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "slackChannel": $slack_channel, "slackToken": $slack_token, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportSmsBiuras resources.
#
# GET /api/transport-sms-biuras
# operationId: api_transport-sms-biuras_get_collection
export def "transport-sms-biuras get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsBiurasApiKey: string, smsBiurasFrom: string, smsBiurasUid: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-sms-biuras" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSmsBiuras resource.
#
# POST /api/transport-sms-biuras
# operationId: api_transport-sms-biuras_post
export def "transport-sms-biuras create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --sms-biuras-api-key: string # The API key for the SMSBIURAS service. Stored in encrypted format. (nullable)
  --sms-biuras-from: string # The sender for the SMSBIURAS service. (nullable)
  --sms-biuras-uid: string # The client code for the SMSBIURAS service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsBiurasApiKey: string, smsBiurasFrom: string, smsBiurasUid: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-sms-biuras")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "smsBiurasApiKey": $sms_biuras_api_key, "smsBiurasFrom": $sms_biuras_from, "smsBiurasUid": $sms_biuras_uid, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportSmsBiuras resource.
#
# DELETE /api/transport-sms-biuras/{id}
# operationId: api_transport-sms-biuras_id_delete
export def "transport-sms-biuras delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-sms-biuras/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportSmsBiuras resource.
#
# GET /api/transport-sms-biuras/{id}
# operationId: api_transport-sms-biuras_id_get
export def "transport-sms-biuras get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsBiurasApiKey: string, smsBiurasFrom: string, smsBiurasUid: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-sms-biuras/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSmsBiuras resource.
#
# PUT /api/transport-sms-biuras/{id}
# operationId: api_transport-sms-biuras_id_put
export def "transport-sms-biuras update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --sms-biuras-api-key: string # The API key for the SMSBIURAS service. Stored in encrypted format. (nullable)
  --sms-biuras-from: string # The sender for the SMSBIURAS service. (nullable)
  --sms-biuras-uid: string # The client code for the SMSBIURAS service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsBiurasApiKey: string, smsBiurasFrom: string, smsBiurasUid: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-sms-biuras/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "smsBiurasApiKey": $sms_biuras_api_key, "smsBiurasFrom": $sms_biuras_from, "smsBiurasUid": $sms_biuras_uid, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportSmsFactor resources.
#
# GET /api/transport-sms-factor
# operationId: api_transport-sms-factor_get_collection
export def "transport-sms-factor get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsFactorPushType: string, smsFactorSender: string, smsFactorToken: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-sms-factor" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSmsFactor resource.
#
# POST /api/transport-sms-factor
# operationId: api_transport-sms-factor_post
export def "transport-sms-factor create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --sms-factor-push-type: string # The push type for the SMSFactor service. (nullable)
  --sms-factor-sender: string # The sender value for the SMSFactor service. (nullable)
  --sms-factor-token: string # The token for the SMSFactor service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsFactorPushType: string, smsFactorSender: string, smsFactorToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-sms-factor")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "smsFactorPushType": $sms_factor_push_type, "smsFactorSender": $sms_factor_sender, "smsFactorToken": $sms_factor_token, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportSmsFactor resource.
#
# DELETE /api/transport-sms-factor/{id}
# operationId: api_transport-sms-factor_id_delete
export def "transport-sms-factor delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-sms-factor/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportSmsFactor resource.
#
# GET /api/transport-sms-factor/{id}
# operationId: api_transport-sms-factor_id_get
export def "transport-sms-factor get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsFactorPushType: string, smsFactorSender: string, smsFactorToken: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-sms-factor/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSmsFactor resource.
#
# PUT /api/transport-sms-factor/{id}
# operationId: api_transport-sms-factor_id_put
export def "transport-sms-factor update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --sms-factor-push-type: string # The push type for the SMSFactor service. (nullable)
  --sms-factor-sender: string # The sender value for the SMSFactor service. (nullable)
  --sms-factor-token: string # The token for the SMSFactor service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsFactorPushType: string, smsFactorSender: string, smsFactorToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-sms-factor/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "smsFactorPushType": $sms_factor_push_type, "smsFactorSender": $sms_factor_sender, "smsFactorToken": $sms_factor_token, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportSms77 resources.
#
# GET /api/transport-sms77
# operationId: api_transport-sms77_get_collection
export def "transport-sms77 get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sms77ApiKey: string, sms77From: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-sms77" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSms77 resource.
#
# POST /api/transport-sms77
# operationId: api_transport-sms77_post
export def "transport-sms77 create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --sms77-api-key: string # The API key for the Sms77 service. Stored in encrypted format. (nullable)
  --sms77-from: string # The optional sender for the Sms77 service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sms77ApiKey: string, sms77From: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-sms77")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "sms77ApiKey": $sms77_api_key, "sms77From": $sms77_from, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportSms77 resource.
#
# DELETE /api/transport-sms77/{id}
# operationId: api_transport-sms77_id_delete
export def "transport-sms77 delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-sms77/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportSms77 resource.
#
# GET /api/transport-sms77/{id}
# operationId: api_transport-sms77_id_get
export def "transport-sms77 get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sms77ApiKey: string, sms77From: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-sms77/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSms77 resource.
#
# PUT /api/transport-sms77/{id}
# operationId: api_transport-sms77_id_put
export def "transport-sms77 update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --sms77-api-key: string # The API key for the Sms77 service. Stored in encrypted format. (nullable)
  --sms77-from: string # The optional sender for the Sms77 service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sms77ApiKey: string, sms77From: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-sms77/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "sms77ApiKey": $sms77_api_key, "sms77From": $sms77_from, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportSmsapi resources.
#
# GET /api/transport-smsapi
# operationId: api_transport-smsapi_get_collection
export def "transport-smsapi get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsapiFrom: string, smsapiToken: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-smsapi" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSmsapi resource.
#
# POST /api/transport-smsapi
# operationId: api_transport-smsapi_post
export def "transport-smsapi create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --smsapi-from: string # The sender name for the SMS API service. (nullable)
  --smsapi-token: string # The API token for the SMS API service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsapiFrom: string, smsapiToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-smsapi")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "smsapiFrom": $smsapi_from, "smsapiToken": $smsapi_token, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportSmsapi resource.
#
# DELETE /api/transport-smsapi/{id}
# operationId: api_transport-smsapi_id_delete
export def "transport-smsapi delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-smsapi/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportSmsapi resource.
#
# GET /api/transport-smsapi/{id}
# operationId: api_transport-smsapi_id_get
export def "transport-smsapi get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsapiFrom: string, smsapiToken: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-smsapi/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSmsapi resource.
#
# PUT /api/transport-smsapi/{id}
# operationId: api_transport-smsapi_id_put
export def "transport-smsapi update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --smsapi-from: string # The sender name for the SMS API service. (nullable)
  --smsapi-token: string # The API token for the SMS API service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsapiFrom: string, smsapiToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-smsapi/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "smsapiFrom": $smsapi_from, "smsapiToken": $smsapi_token, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportSmsc resources.
#
# GET /api/transport-smsc
# operationId: api_transport-smsc_get_collection
export def "transport-smsc get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smscFrom: string, smscLogin: string, smscPassword: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-smsc" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSmsc resource.
#
# POST /api/transport-smsc
# operationId: api_transport-smsc_post
export def "transport-smsc create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --smsc-from: string # The sender (NB: text identity, not a phone number) for the Smsc service. (nullable)
  --smsc-login: string # The login for the Smsc service. (nullable)
  --smsc-password: string # The API password for the Smsc service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smscFrom: string, smscLogin: string, smscPassword: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-smsc")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "smscFrom": $smsc_from, "smscLogin": $smsc_login, "smscPassword": $smsc_password, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportSmsc resource.
#
# DELETE /api/transport-smsc/{id}
# operationId: api_transport-smsc_id_delete
export def "transport-smsc delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-smsc/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportSmsc resource.
#
# GET /api/transport-smsc/{id}
# operationId: api_transport-smsc_id_get
export def "transport-smsc get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smscFrom: string, smscLogin: string, smscPassword: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-smsc/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSmsc resource.
#
# PUT /api/transport-smsc/{id}
# operationId: api_transport-smsc_id_put
export def "transport-smsc update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --smsc-from: string # The sender (NB: text identity, not a phone number) for the Smsc service. (nullable)
  --smsc-login: string # The login for the Smsc service. (nullable)
  --smsc-password: string # The API password for the Smsc service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smscFrom: string, smscLogin: string, smscPassword: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-smsc/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "smscFrom": $smsc_from, "smscLogin": $smsc_login, "smscPassword": $smsc_password, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportSmsmode resources.
#
# GET /api/transport-smsmode
# operationId: api_transport-smsmode_get_collection
export def "transport-smsmode get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsmodeApiKey: string, smsmodeFrom: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-smsmode" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSmsmode resource.
#
# POST /api/transport-smsmode
# operationId: api_transport-smsmode_post
export def "transport-smsmode create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --smsmode-api-key: string # The API key for the Smsmode service. Stored in encrypted format. (nullable)
  --smsmode-from: string # The from value for the Smsmode service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsmodeApiKey: string, smsmodeFrom: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-smsmode")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "smsmodeApiKey": $smsmode_api_key, "smsmodeFrom": $smsmode_from, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportSmsmode resource.
#
# DELETE /api/transport-smsmode/{id}
# operationId: api_transport-smsmode_id_delete
export def "transport-smsmode delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-smsmode/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportSmsmode resource.
#
# GET /api/transport-smsmode/{id}
# operationId: api_transport-smsmode_id_get
export def "transport-smsmode get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsmodeApiKey: string, smsmodeFrom: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-smsmode/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSmsmode resource.
#
# PUT /api/transport-smsmode/{id}
# operationId: api_transport-smsmode_id_put
export def "transport-smsmode update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --smsmode-api-key: string # The API key for the Smsmode service. Stored in encrypted format. (nullable)
  --smsmode-from: string # The from value for the Smsmode service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsmodeApiKey: string, smsmodeFrom: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-smsmode/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "smsmodeApiKey": $smsmode_api_key, "smsmodeFrom": $smsmode_from, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportSpotHit resources.
#
# GET /api/transport-spot-hit
# operationId: api_transport-spot-hit_get_collection
export def "transport-spot-hit get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, spotHitFrom: string, spotHitToken: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-spot-hit" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSpotHit resource.
#
# POST /api/transport-spot-hit
# operationId: api_transport-spot-hit_post
export def "transport-spot-hit create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --spot-hit-from: string # The sender (3-11 letters, default is a 5 digits phone number) for the Spot-Hit service. (nullable)
  --spot-hit-token: string # The API token for the Spot-Hit service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, spotHitFrom: string, spotHitToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-spot-hit")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "spotHitFrom": $spot_hit_from, "spotHitToken": $spot_hit_token, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportSpotHit resource.
#
# DELETE /api/transport-spot-hit/{id}
# operationId: api_transport-spot-hit_id_delete
export def "transport-spot-hit delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-spot-hit/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportSpotHit resource.
#
# GET /api/transport-spot-hit/{id}
# operationId: api_transport-spot-hit_id_get
export def "transport-spot-hit get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, spotHitFrom: string, spotHitToken: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-spot-hit/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSpotHit resource.
#
# PUT /api/transport-spot-hit/{id}
# operationId: api_transport-spot-hit_id_put
export def "transport-spot-hit update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --spot-hit-from: string # The sender (3-11 letters, default is a 5 digits phone number) for the Spot-Hit service. (nullable)
  --spot-hit-token: string # The API token for the Spot-Hit service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, spotHitFrom: string, spotHitToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-spot-hit/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "spotHitFrom": $spot_hit_from, "spotHitToken": $spot_hit_token, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportTelegram resources.
#
# GET /api/transport-telegram
# operationId: api_transport-telegram_get_collection
export def "transport-telegram get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, telegramChatId: string, telegramToken: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-telegram" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportTelegram resource.
#
# POST /api/transport-telegram
# operationId: api_transport-telegram_post
export def "transport-telegram create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --telegram-chat-id: string # The chat ID for the Telegram service. (nullable)
  --telegram-token: string # The token for the Telegram service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, telegramChatId: string, telegramToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-telegram")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "telegramChatId": $telegram_chat_id, "telegramToken": $telegram_token, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportTelegram resource.
#
# DELETE /api/transport-telegram/{id}
# operationId: api_transport-telegram_id_delete
export def "transport-telegram delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-telegram/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportTelegram resource.
#
# GET /api/transport-telegram/{id}
# operationId: api_transport-telegram_id_get
export def "transport-telegram get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, telegramChatId: string, telegramToken: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-telegram/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportTelegram resource.
#
# PUT /api/transport-telegram/{id}
# operationId: api_transport-telegram_id_put
export def "transport-telegram update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --telegram-chat-id: string # The chat ID for the Telegram service. (nullable)
  --telegram-token: string # The token for the Telegram service. Stored in encrypted format. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, telegramChatId: string, telegramToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-telegram/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "telegramChatId": $telegram_chat_id, "telegramToken": $telegram_token, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportTelnyx resources.
#
# GET /api/transport-telnyx
# operationId: api_transport-telnyx_get_collection
export def "transport-telnyx get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, telnyxApiKey: string, telnyxFrom: string, telnyxMessagingProfileId: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-telnyx" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportTelnyx resource.
#
# POST /api/transport-telnyx
# operationId: api_transport-telnyx_post
export def "transport-telnyx create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --telnyx-api-key: string # The API key for the Telnyx service. Stored in encrypted format. (nullable)
  --telnyx-from: string # The from value for the Telnyx service. (nullable)
  --telnyx-messaging-profile-id: string # The messaging profile ID (You need this in order to show a name to the recipient instead of just the phone number) for the Telnyx service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, telnyxApiKey: string, telnyxFrom: string, telnyxMessagingProfileId: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-telnyx")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "telnyxApiKey": $telnyx_api_key, "telnyxFrom": $telnyx_from, "telnyxMessagingProfileId": $telnyx_messaging_profile_id, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportTelnyx resource.
#
# DELETE /api/transport-telnyx/{id}
# operationId: api_transport-telnyx_id_delete
export def "transport-telnyx delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-telnyx/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportTelnyx resource.
#
# GET /api/transport-telnyx/{id}
# operationId: api_transport-telnyx_id_get
export def "transport-telnyx get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, telnyxApiKey: string, telnyxFrom: string, telnyxMessagingProfileId: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-telnyx/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportTelnyx resource.
#
# PUT /api/transport-telnyx/{id}
# operationId: api_transport-telnyx_id_put
export def "transport-telnyx update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --telnyx-api-key: string # The API key for the Telnyx service. Stored in encrypted format. (nullable)
  --telnyx-from: string # The from value for the Telnyx service. (nullable)
  --telnyx-messaging-profile-id: string # The messaging profile ID (You need this in order to show a name to the recipient instead of just the phone number) for the Telnyx service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, telnyxApiKey: string, telnyxFrom: string, telnyxMessagingProfileId: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-telnyx/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "telnyxApiKey": $telnyx_api_key, "telnyxFrom": $telnyx_from, "telnyxMessagingProfileId": $telnyx_messaging_profile_id, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportTermii resources.
#
# GET /api/transport-termii
# operationId: api_transport-termii_get_collection
export def "transport-termii get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, termiiApiKey: string, termiiChannel: string, termiiFrom: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-termii" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportTermii resource.
#
# POST /api/transport-termii
# operationId: api_transport-termii_post
export def "transport-termii create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --termii-api-key: string # The API key for the Termii service. Stored in encrypted format. (nullable)
  --termii-channel: string # The channel for the Termii service. (nullable)
  --termii-from: string # The sender value for the Termii service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, termiiApiKey: string, termiiChannel: string, termiiFrom: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-termii")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "termiiApiKey": $termii_api_key, "termiiChannel": $termii_channel, "termiiFrom": $termii_from, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportTermii resource.
#
# DELETE /api/transport-termii/{id}
# operationId: api_transport-termii_id_delete
export def "transport-termii delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-termii/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportTermii resource.
#
# GET /api/transport-termii/{id}
# operationId: api_transport-termii_id_get
export def "transport-termii get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, termiiApiKey: string, termiiChannel: string, termiiFrom: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-termii/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportTermii resource.
#
# PUT /api/transport-termii/{id}
# operationId: api_transport-termii_id_put
export def "transport-termii update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --termii-api-key: string # The API key for the Termii service. Stored in encrypted format. (nullable)
  --termii-channel: string # The channel for the Termii service. (nullable)
  --termii-from: string # The sender value for the Termii service. (nullable)
  --transport-name: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, termiiApiKey: string, termiiChannel: string, termiiFrom: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-termii/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "termiiApiKey": $termii_api_key, "termiiChannel": $termii_channel, "termiiFrom": $termii_from, "transportName": $transport_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportTrello resources.
#
# GET /api/transport-trello
# operationId: api_transport-trello_get_collection
export def "transport-trello get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, trelloApiKey: string, trelloApiToken: string, trelloListId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-trello" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportTrello resource.
#
# POST /api/transport-trello
# operationId: api_transport-trello_post
export def "transport-trello create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
  --trello-api-key: string # The API key for the Trello service. (nullable)
  --trello-api-token: string # The API token for the Trello service. Stored in encrypted format. (nullable)
  --trello-list-id: string # The list ID for the Trello service. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, trelloApiKey: string, trelloApiToken: string, trelloListId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-trello")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "transportName": $transport_name, "trelloApiKey": $trello_api_key, "trelloApiToken": $trello_api_token, "trelloListId": $trello_list_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportTrello resource.
#
# DELETE /api/transport-trello/{id}
# operationId: api_transport-trello_id_delete
export def "transport-trello delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-trello/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportTrello resource.
#
# GET /api/transport-trello/{id}
# operationId: api_transport-trello_id_get
export def "transport-trello get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, trelloApiKey: string, trelloApiToken: string, trelloListId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-trello/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportTrello resource.
#
# PUT /api/transport-trello/{id}
# operationId: api_transport-trello_id_put
export def "transport-trello update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transport-name: string # The name of the transport. (nullable)
  --trello-api-key: string # The API key for the Trello service. (nullable)
  --trello-api-token: string # The API token for the Trello service. Stored in encrypted format. (nullable)
  --trello-list-id: string # The list ID for the Trello service. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, trelloApiKey: string, trelloApiToken: string, trelloListId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-trello/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "transportName": $transport_name, "trelloApiKey": $trello_api_key, "trelloApiToken": $trello_api_token, "trelloListId": $trello_list_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportTurboSms resources.
#
# GET /api/transport-turbo-sms
# operationId: api_transport-turbo-sms_get_collection
export def "transport-turbo-sms get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, turboSmsAuthToken: string, turboSmsFrom: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-turbo-sms" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportTurboSms resource.
#
# POST /api/transport-turbo-sms
# operationId: api_transport-turbo-sms_post
export def "transport-turbo-sms create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
  --turbo-sms-auth-token: string # The auth token for the TurboSms service. Stored in encrypted format. (nullable)
  --turbo-sms-from: string # The sender name (should be alphanumeric, max 20 characters and activated in your TurboSms account) for the TurboSms service. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, turboSmsAuthToken: string, turboSmsFrom: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-turbo-sms")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "transportName": $transport_name, "turboSmsAuthToken": $turbo_sms_auth_token, "turboSmsFrom": $turbo_sms_from} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportTurboSms resource.
#
# DELETE /api/transport-turbo-sms/{id}
# operationId: api_transport-turbo-sms_id_delete
export def "transport-turbo-sms delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-turbo-sms/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportTurboSms resource.
#
# GET /api/transport-turbo-sms/{id}
# operationId: api_transport-turbo-sms_id_get
export def "transport-turbo-sms get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, turboSmsAuthToken: string, turboSmsFrom: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-turbo-sms/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportTurboSms resource.
#
# PUT /api/transport-turbo-sms/{id}
# operationId: api_transport-turbo-sms_id_put
export def "transport-turbo-sms update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transport-name: string # The name of the transport. (nullable)
  --turbo-sms-auth-token: string # The auth token for the TurboSms service. Stored in encrypted format. (nullable)
  --turbo-sms-from: string # The sender name (should be alphanumeric, max 20 characters and activated in your TurboSms account) for the TurboSms service. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, turboSmsAuthToken: string, turboSmsFrom: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-turbo-sms/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "transportName": $transport_name, "turboSmsAuthToken": $turbo_sms_auth_token, "turboSmsFrom": $turbo_sms_from} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportTwilio resources.
#
# GET /api/transport-twilio
# operationId: api_transport-twilio_get_collection
export def "transport-twilio get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, twilioFrom: string, twilioSid: string, twilioToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-twilio" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportTwilio resource.
#
# POST /api/transport-twilio
# operationId: api_transport-twilio_post
export def "transport-twilio create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
  --twilio-from: string # The sender for the Twilio service. (nullable)
  --twilio-sid: string # The SID for the Twilio service. (nullable)
  --twilio-token: string # The token for the Twilio service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, twilioFrom: string, twilioSid: string, twilioToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-twilio")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "transportName": $transport_name, "twilioFrom": $twilio_from, "twilioSid": $twilio_sid, "twilioToken": $twilio_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportTwilio resource.
#
# DELETE /api/transport-twilio/{id}
# operationId: api_transport-twilio_id_delete
export def "transport-twilio delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-twilio/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportTwilio resource.
#
# GET /api/transport-twilio/{id}
# operationId: api_transport-twilio_id_get
export def "transport-twilio get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, twilioFrom: string, twilioSid: string, twilioToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-twilio/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportTwilio resource.
#
# PUT /api/transport-twilio/{id}
# operationId: api_transport-twilio_id_put
export def "transport-twilio update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transport-name: string # The name of the transport. (nullable)
  --twilio-from: string # The sender for the Twilio service. (nullable)
  --twilio-sid: string # The SID for the Twilio service. (nullable)
  --twilio-token: string # The token for the Twilio service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, twilioFrom: string, twilioSid: string, twilioToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-twilio/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "transportName": $transport_name, "twilioFrom": $twilio_from, "twilioSid": $twilio_sid, "twilioToken": $twilio_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportTwitter resources.
#
# GET /api/transport-twitter
# operationId: api_transport-twitter_get_collection
export def "transport-twitter get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, twitterAccessToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-twitter" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportTwitter resource.
#
# POST /api/transport-twitter
# operationId: api_transport-twitter_post
export def "transport-twitter create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
  --twitter-access-token: string # The access token for the Twitter service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, twitterAccessToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-twitter")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "transportName": $transport_name, "twitterAccessToken": $twitter_access_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportTwitter resource.
#
# DELETE /api/transport-twitter/{id}
# operationId: api_transport-twitter_id_delete
export def "transport-twitter delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-twitter/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportTwitter resource.
#
# GET /api/transport-twitter/{id}
# operationId: api_transport-twitter_id_get
export def "transport-twitter get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, twitterAccessToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-twitter/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportTwitter resource.
#
# PUT /api/transport-twitter/{id}
# operationId: api_transport-twitter_id_put
export def "transport-twitter update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transport-name: string # The name of the transport. (nullable)
  --twitter-access-token: string # The access token for the Twitter service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, twitterAccessToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-twitter/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "transportName": $transport_name, "twitterAccessToken": $twitter_access_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportVonage resources.
#
# GET /api/transport-vonage
# operationId: api_transport-vonage_get_collection
export def "transport-vonage get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, vonageFrom: string, vonageKey: string, vonageSecret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-vonage" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportVonage resource.
#
# POST /api/transport-vonage
# operationId: api_transport-vonage_post
export def "transport-vonage create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
  --vonage-from: string # The sender for the Vonage service. (nullable)
  --vonage-key: string # The key for the Vonage service. (nullable)
  --vonage-secret: string # The secret for the Vonage service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, vonageFrom: string, vonageKey: string, vonageSecret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-vonage")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "transportName": $transport_name, "vonageFrom": $vonage_from, "vonageKey": $vonage_key, "vonageSecret": $vonage_secret} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportVonage resource.
#
# DELETE /api/transport-vonage/{id}
# operationId: api_transport-vonage_id_delete
export def "transport-vonage delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-vonage/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportVonage resource.
#
# GET /api/transport-vonage/{id}
# operationId: api_transport-vonage_id_get
export def "transport-vonage get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, vonageFrom: string, vonageKey: string, vonageSecret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-vonage/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportVonage resource.
#
# PUT /api/transport-vonage/{id}
# operationId: api_transport-vonage_id_put
export def "transport-vonage update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transport-name: string # The name of the transport. (nullable)
  --vonage-from: string # The sender for the Vonage service. (nullable)
  --vonage-key: string # The key for the Vonage service. (nullable)
  --vonage-secret: string # The secret for the Vonage service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, vonageFrom: string, vonageKey: string, vonageSecret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-vonage/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "transportName": $transport_name, "vonageFrom": $vonage_from, "vonageKey": $vonage_key, "vonageSecret": $vonage_secret} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportWebhook resources.
#
# GET /api/transport-webhook
# operationId: api_transport-webhook_get_collection
export def "transport-webhook get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, httpMethodCode: string, id: string, mustBeEncryptedValue: string, partition: string, resourceOwner: string, transportName: string, webhookHeaders: list<string>, webhookUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-webhook" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportWebhook resource.
#
# POST /api/transport-webhook
# operationId: api_transport-webhook_post
export def "transport-webhook create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  http_method_code: string # The HTTP request method that must be used. (format: iri-reference)
  --must-be-encrypted-value: string # An optional and arbitrary secret value that must be stored in encrypted format, such as an access token. In the webhookUrl and/or webhookHeaders fields, use the special ENCRYPTED_VALUE placeholder (must be uppercase), which we will replace with the decrypted secret value when using the transport. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
  --webhook-headers: list<string> # The HTTP request headers, if any, for the Webhook service. To use the encrypted value: E.g., Authorization: Bearer ENCRYPTED_VALUE. (nullable)
  --webhook-url: string # The URL for the Webhook service. (nullable, format: uri)
]: any -> record<createdAt: string, dataSegmentCode: string, httpMethodCode: string, id: string, mustBeEncryptedValue: string, partition: string, resourceOwner: string, transportName: string, webhookHeaders: list<string>, webhookUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-webhook")
  let req_body = {"dataSegmentCode": $data_segment_code, "httpMethodCode": $http_method_code, "mustBeEncryptedValue": $must_be_encrypted_value, "partition": $partition, "transportName": $transport_name, "webhookHeaders": $webhook_headers, "webhookUrl": $webhook_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportWebhook resource.
#
# DELETE /api/transport-webhook/{id}
# operationId: api_transport-webhook_id_delete
export def "transport-webhook delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-webhook/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportWebhook resource.
#
# GET /api/transport-webhook/{id}
# operationId: api_transport-webhook_id_get
export def "transport-webhook get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, httpMethodCode: string, id: string, mustBeEncryptedValue: string, partition: string, resourceOwner: string, transportName: string, webhookHeaders: list<string>, webhookUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-webhook/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportWebhook resource.
#
# PUT /api/transport-webhook/{id}
# operationId: api_transport-webhook_id_put
export def "transport-webhook update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  http_method_code: string # The HTTP request method that must be used. (format: iri-reference)
  --must-be-encrypted-value: string # An optional and arbitrary secret value that must be stored in encrypted format, such as an access token. In the webhookUrl and/or webhookHeaders fields, use the special ENCRYPTED_VALUE placeholder (must be uppercase), which we will replace with the decrypted secret value when using the transport. (nullable)
  --transport-name: string # The name of the transport. (nullable)
  --webhook-headers: list<string> # The HTTP request headers, if any, for the Webhook service. To use the encrypted value: E.g., Authorization: Bearer ENCRYPTED_VALUE. (nullable)
  --webhook-url: string # The URL for the Webhook service. (nullable, format: uri)
]: any -> record<createdAt: string, dataSegmentCode: string, httpMethodCode: string, id: string, mustBeEncryptedValue: string, partition: string, resourceOwner: string, transportName: string, webhookHeaders: list<string>, webhookUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-webhook/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "httpMethodCode": $http_method_code, "mustBeEncryptedValue": $must_be_encrypted_value, "transportName": $transport_name, "webhookHeaders": $webhook_headers, "webhookUrl": $webhook_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportYunpian resources.
#
# GET /api/transport-yunpian
# operationId: api_transport-yunpian_get_collection
export def "transport-yunpian get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, yunpianApiKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-yunpian" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportYunpian resource.
#
# POST /api/transport-yunpian
# operationId: api_transport-yunpian_post
export def "transport-yunpian create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
  --yunpian-api-key: string # The API key for the Yunpian service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, yunpianApiKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-yunpian")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "transportName": $transport_name, "yunpianApiKey": $yunpian_api_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportYunpian resource.
#
# DELETE /api/transport-yunpian/{id}
# operationId: api_transport-yunpian_id_delete
export def "transport-yunpian delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-yunpian/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportYunpian resource.
#
# GET /api/transport-yunpian/{id}
# operationId: api_transport-yunpian_id_get
export def "transport-yunpian get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, yunpianApiKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-yunpian/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportYunpian resource.
#
# PUT /api/transport-yunpian/{id}
# operationId: api_transport-yunpian_id_put
export def "transport-yunpian update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transport-name: string # The name of the transport. (nullable)
  --yunpian-api-key: string # The API key for the Yunpian service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, yunpianApiKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-yunpian/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "transportName": $transport_name, "yunpianApiKey": $yunpian_api_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportZendesk resources.
#
# GET /api/transport-zendesk
# operationId: api_transport-zendesk_get_collection
export def "transport-zendesk get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, zendeskEmail: string, zendeskHost: string, zendeskToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-zendesk" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportZendesk resource.
#
# POST /api/transport-zendesk
# operationId: api_transport-zendesk_post
export def "transport-zendesk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
  --zendesk-email: string # The login email address for the Zendesk service. (nullable, format: email)
  --zendesk-host: string # The host name for the Zendesk service (domain.zendesk.com). (nullable, format: hostname)
  --zendesk-token: string # The token for the Zendesk service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, zendeskEmail: string, zendeskHost: string, zendeskToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-zendesk")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "transportName": $transport_name, "zendeskEmail": $zendesk_email, "zendeskHost": $zendesk_host, "zendeskToken": $zendesk_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportZendesk resource.
#
# DELETE /api/transport-zendesk/{id}
# operationId: api_transport-zendesk_id_delete
export def "transport-zendesk delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-zendesk/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportZendesk resource.
#
# GET /api/transport-zendesk/{id}
# operationId: api_transport-zendesk_id_get
export def "transport-zendesk get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, zendeskEmail: string, zendeskHost: string, zendeskToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-zendesk/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportZendesk resource.
#
# PUT /api/transport-zendesk/{id}
# operationId: api_transport-zendesk_id_put
export def "transport-zendesk update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transport-name: string # The name of the transport. (nullable)
  --zendesk-email: string # The login email address for the Zendesk service. (nullable, format: email)
  --zendesk-host: string # The host name for the Zendesk service (domain.zendesk.com). (nullable, format: hostname)
  --zendesk-token: string # The token for the Zendesk service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, zendeskEmail: string, zendeskHost: string, zendeskToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-zendesk/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "transportName": $transport_name, "zendeskEmail": $zendesk_email, "zendeskHost": $zendesk_host, "zendeskToken": $zendesk_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of TransportZulip resources.
#
# GET /api/transport-zulip
# operationId: api_transport-zulip_get_collection
export def "transport-zulip get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --data-segment-code: string # allows empty value
  --data-segment-code: list<string> # allows empty value
  --partition: string # allows empty value
  --partition: list<string> # allows empty value
  --properties: list<string> # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, zulipChannel: string, zulipEmail: string, zulipHost: string, zulipToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $data_segment_code "scalar") (serialize-qp "dataSegmentCode[]" $data_segment_code "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-zulip" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportZulip resource.
#
# POST /api/transport-zulip
# operationId: api_transport-zulip_post
export def "transport-zulip create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transport-name: string # The name of the transport. (nullable)
  --zulip-channel: string # The channel for the Zulip service. (nullable)
  --zulip-email: string # The email for the Zulip service. (nullable)
  --zulip-host: string # The host for the Zulip service. (nullable)
  --zulip-token: string # The token for the Zulip service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, zulipChannel: string, zulipEmail: string, zulipHost: string, zulipToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-zulip")
  let req_body = {"dataSegmentCode": $data_segment_code, "partition": $partition, "transportName": $transport_name, "zulipChannel": $zulip_channel, "zulipEmail": $zulip_email, "zulipHost": $zulip_host, "zulipToken": $zulip_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the TransportZulip resource.
#
# DELETE /api/transport-zulip/{id}
# operationId: api_transport-zulip_id_delete
export def "transport-zulip delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-zulip/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a TransportZulip resource.
#
# GET /api/transport-zulip/{id}
# operationId: api_transport-zulip_id_get
export def "transport-zulip get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, zulipChannel: string, zulipEmail: string, zulipHost: string, zulipToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-zulip/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportZulip resource.
#
# PUT /api/transport-zulip/{id}
# operationId: api_transport-zulip_id_put
export def "transport-zulip update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --data-segment-code: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transport-name: string # The name of the transport. (nullable)
  --zulip-channel: string # The channel for the Zulip service. (nullable)
  --zulip-email: string # The email for the Zulip service. (nullable)
  --zulip-host: string # The host for the Zulip service. (nullable)
  --zulip-token: string # The token for the Zulip service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, zulipChannel: string, zulipEmail: string, zulipHost: string, zulipToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transport-zulip/{id}"))
  let req_body = {"dataSegmentCode": $data_segment_code, "transportName": $transport_name, "zulipChannel": $zulip_channel, "zulipEmail": $zulip_email, "zulipHost": $zulip_host, "zulipToken": $zulip_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the collection of UserAccount resources.
#
# GET /api/user-account
# operationId: api_user-account_get_collection
export def "user-account get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --properties: list<string> # allows empty value
]: nothing -> table<accountLevelCode: string, creditsOveragePercentTripSwitch: int, email: string, firstName: string, id: string, isDelinquent: bool, lastName: string, timezoneCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/user-account" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of UserAccountLevelCode resources.
#
# GET /api/user-account-level-code
# operationId: api_user-account-level-code_get_collection
export def "user-account-level-code get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The collection page number (default: 1, allows empty value)
  --properties: list<string> # allows empty value
]: nothing -> table<codeName: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/user-account-level-code" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a UserAccountLevelCode resource.
#
# GET /api/user-account-level-code/{id}
# operationId: api_user-account-level-code_id_get
export def "user-account-level-code get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<codeName: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/user-account-level-code/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a UserAccount resource.
#
# GET /api/user-account/{id}
# operationId: api_user-account_id_get
export def "user-account get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<accountLevelCode: string, creditsOveragePercentTripSwitch: int, email: string, firstName: string, id: string, isDelinquent: bool, lastName: string, timezoneCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/user-account/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the UserAccount resource.
#
# PUT /api/user-account/{id}
# operationId: api_user-account_id_put
export def "user-account update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --credits-overage-percent-trip-switch: int # If the credits consumed in the billing period are this percentage above the account plan's included credits, cease further consumption of credits until the end of the billing period. Any integer between 1 and 1,000. Optional. Leave blank for no limit. (nullable)
]: any -> record<accountLevelCode: string, creditsOveragePercentTripSwitch: int, email: string, firstName: string, id: string, isDelinquent: bool, lastName: string, timezoneCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/user-account/{id}"))
  let req_body = {"creditsOveragePercentTripSwitch": $credits_overage_percent_trip_switch} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
