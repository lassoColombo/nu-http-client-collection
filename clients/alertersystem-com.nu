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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/ld+json" "text/html"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "alert-log collection" } } | get name | first)
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
export def "alert-log collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --monitor: string # allows empty value
  --monitor: list # allows empty value
  --alertService: string # allows empty value
  --alertService: list # allows empty value
  --alertLogStatusCode: string # allows empty value
  --alertLogStatusCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<alertLogErrorMessage: string, alertLogMessageId: string, alertLogStatusCode: string, alertService: string, createdAt: string, dataSegmentCode: string, id: string, monitor: string, partition: string, ping: string, resourceOwner: string, webhookResponseBody: string, webhookResponseHeaders: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "monitor" $monitor "scalar") (serialize-qp "monitor[]" $monitor "multi") (serialize-qp "alertService" $alertService "scalar") (serialize-qp "alertService[]" $alertService "multi") (serialize-qp "alertLogStatusCode" $alertLogStatusCode "scalar") (serialize-qp "alertLogStatusCode[]" $alertLogStatusCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/alert-log" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of AlertLogStatusCode resources.
#
# GET /api/alert-log-status-code
# operationId: api_alert-log-status-code_get_collection
export def "alert-log-status-code collection" [
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
  --properties: list # allows empty value
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
  let full_url = (build-url $base $"/api/alert-log-status-code/($id)")
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
  let full_url = (build-url $base $"/api/alert-log/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of AlertService resources.
#
# GET /api/alert-service
# operationId: api_alert-service_get_collection
export def "alert-service collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<alertServiceName: string, alertServiceNotes: string, alertServiceTransportCode: string, createdAt: string, creditsPerTransportAlert: int, dataSegmentCode: string, id: string, mediaObjects: list<string>, partition: string, recipientEmailAddress: string, recipientPhoneNumber: string, resourceOwner: string, transportAlerta: string, transportAllMySms: string, transportAmazonSns: string, transportBandwidth: string, transportChatwork: string, transportClickSend: string, transportClickatell: string, transportContactEveryone: string, transportDiscord: string, transportEmail: string, transportEngagespot: string, transportEsendex: string, transportExpo: string, transportFirebase: string, transportFortySixElks: string, transportFreeMobile: string, transportFreshdesk: string, transportGatewayApi: string, transportGitter: string, transportGoogleChat: string, transportGotify: string, transportHelpScout: string, transportInfobip: string, transportIqsms: string, transportKazInfoTeh: string, transportLightSms: string, transportLineNotify: string, transportLinkedIn: string, transportMailjet: string, transportMastodon: string, transportMattermost: string, transportMercure: string, transportMessageBird: string, transportMessageMedia: string, transportMicrosoftTeams: string, transportMobyt: string, transportOctopush: string, transportOneSignal: string, transportOpsgenie: string, transportOrangeSms: string, transportOvhCloud: string, transportPagerDuty: string, transportPagerTree: string, transportPlivo: string, transportPushbullet: string, transportPushover: string, transportPushy: string, transportRingCentral: string, transportRocketChat: string, transportSendberry: string, transportSendinblue: string, transportSimpleTextin: string, transportSinch: string, transportSlack: string, transportSms77: string, transportSmsBiuras: string, transportSmsFactor: string, transportSmsapi: string, transportSmsc: string, transportSmsmode: string, transportSpotHit: string, transportTelegram: string, transportTelnyx: string, transportTermii: string, transportTrello: string, transportTurboSms: string, transportTwilio: string, transportTwitter: string, transportVonage: string, transportWebhook: string, transportYunpian: string, transportZendesk: string, transportZulip: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/alert-service" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a AlertService resource.
#
# POST /api/alert-service
# operationId: api_alert-service_post
export def "alert-service post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --alertServiceName: string # The name of the alert service. Max 255 characters. (nullable)
  --alertServiceNotes: string # Notes about the alert service. Max 10,000 characters. Formatting using Markdown is allowed. HTML will be removed. (nullable)
  --alertServiceTransportCode: string # The transport of the alert service. (nullable, format: iri-reference)
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --mediaObjects: list # Media objects that must be sent with each alert. Only applicable when you use your own email alert services.
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --recipientEmailAddress: string # The email address where alerts will be sent. (nullable, format: email)
  --recipientPhoneNumber: string # The phone number where alerts will be sent. Ensure that the number format complies with the external transport service that will send the alert. (nullable)
  --transportAlerta: string # nullable, format: iri-reference
  --transportAllMySms: string # nullable, format: iri-reference
  --transportAmazonSns: string # nullable, format: iri-reference
  --transportBandwidth: string # nullable, format: iri-reference
  --transportChatwork: string # nullable, format: iri-reference
  --transportClickSend: string # nullable, format: iri-reference
  --transportClickatell: string # nullable, format: iri-reference
  --transportContactEveryone: string # nullable, format: iri-reference
  --transportDiscord: string # nullable, format: iri-reference
  --transportEmail: string # nullable, format: iri-reference
  --transportEngagespot: string # nullable, format: iri-reference
  --transportEsendex: string # nullable, format: iri-reference
  --transportExpo: string # nullable, format: iri-reference
  --transportFirebase: string # nullable, format: iri-reference
  --transportFortySixElks: string # nullable, format: iri-reference
  --transportFreeMobile: string # nullable, format: iri-reference
  --transportFreshdesk: string # nullable, format: iri-reference
  --transportGatewayApi: string # nullable, format: iri-reference
  --transportGitter: string # nullable, format: iri-reference
  --transportGoogleChat: string # nullable, format: iri-reference
  --transportGotify: string # nullable, format: iri-reference
  --transportHelpScout: string # nullable, format: iri-reference
  --transportInfobip: string # nullable, format: iri-reference
  --transportIqsms: string # nullable, format: iri-reference
  --transportKazInfoTeh: string # nullable, format: iri-reference
  --transportLightSms: string # nullable, format: iri-reference
  --transportLineNotify: string # nullable, format: iri-reference
  --transportLinkedIn: string # nullable, format: iri-reference
  --transportMailjet: string # nullable, format: iri-reference
  --transportMastodon: string # nullable, format: iri-reference
  --transportMattermost: string # nullable, format: iri-reference
  --transportMercure: string # nullable, format: iri-reference
  --transportMessageBird: string # nullable, format: iri-reference
  --transportMessageMedia: string # nullable, format: iri-reference
  --transportMicrosoftTeams: string # nullable, format: iri-reference
  --transportMobyt: string # nullable, format: iri-reference
  --transportOctopush: string # nullable, format: iri-reference
  --transportOneSignal: string # nullable, format: iri-reference
  --transportOpsgenie: string # nullable, format: iri-reference
  --transportOrangeSms: string # nullable, format: iri-reference
  --transportOvhCloud: string # nullable, format: iri-reference
  --transportPagerDuty: string # nullable, format: iri-reference
  --transportPagerTree: string # nullable, format: iri-reference
  --transportPlivo: string # nullable, format: iri-reference
  --transportPushbullet: string # nullable, format: iri-reference
  --transportPushover: string # nullable, format: iri-reference
  --transportPushy: string # nullable, format: iri-reference
  --transportRingCentral: string # nullable, format: iri-reference
  --transportRocketChat: string # nullable, format: iri-reference
  --transportSendberry: string # nullable, format: iri-reference
  --transportSendinblue: string # nullable, format: iri-reference
  --transportSimpleTextin: string # nullable, format: iri-reference
  --transportSinch: string # nullable, format: iri-reference
  --transportSlack: string # nullable, format: iri-reference
  --transportSms77: string # nullable, format: iri-reference
  --transportSmsBiuras: string # nullable, format: iri-reference
  --transportSmsFactor: string # nullable, format: iri-reference
  --transportSmsapi: string # nullable, format: iri-reference
  --transportSmsc: string # nullable, format: iri-reference
  --transportSmsmode: string # nullable, format: iri-reference
  --transportSpotHit: string # nullable, format: iri-reference
  --transportTelegram: string # nullable, format: iri-reference
  --transportTelnyx: string # nullable, format: iri-reference
  --transportTermii: string # nullable, format: iri-reference
  --transportTrello: string # nullable, format: iri-reference
  --transportTurboSms: string # nullable, format: iri-reference
  --transportTwilio: string # nullable, format: iri-reference
  --transportTwitter: string # nullable, format: iri-reference
  --transportVonage: string # nullable, format: iri-reference
  --transportWebhook: string # nullable, format: iri-reference
  --transportYunpian: string # nullable, format: iri-reference
  --transportZendesk: string # nullable, format: iri-reference
  --transportZulip: string # nullable, format: iri-reference
]: any -> record<alertServiceName: string, alertServiceNotes: string, alertServiceTransportCode: string, createdAt: string, creditsPerTransportAlert: int, dataSegmentCode: string, id: string, mediaObjects: list<string>, partition: string, recipientEmailAddress: string, recipientPhoneNumber: string, resourceOwner: string, transportAlerta: string, transportAllMySms: string, transportAmazonSns: string, transportBandwidth: string, transportChatwork: string, transportClickSend: string, transportClickatell: string, transportContactEveryone: string, transportDiscord: string, transportEmail: string, transportEngagespot: string, transportEsendex: string, transportExpo: string, transportFirebase: string, transportFortySixElks: string, transportFreeMobile: string, transportFreshdesk: string, transportGatewayApi: string, transportGitter: string, transportGoogleChat: string, transportGotify: string, transportHelpScout: string, transportInfobip: string, transportIqsms: string, transportKazInfoTeh: string, transportLightSms: string, transportLineNotify: string, transportLinkedIn: string, transportMailjet: string, transportMastodon: string, transportMattermost: string, transportMercure: string, transportMessageBird: string, transportMessageMedia: string, transportMicrosoftTeams: string, transportMobyt: string, transportOctopush: string, transportOneSignal: string, transportOpsgenie: string, transportOrangeSms: string, transportOvhCloud: string, transportPagerDuty: string, transportPagerTree: string, transportPlivo: string, transportPushbullet: string, transportPushover: string, transportPushy: string, transportRingCentral: string, transportRocketChat: string, transportSendberry: string, transportSendinblue: string, transportSimpleTextin: string, transportSinch: string, transportSlack: string, transportSms77: string, transportSmsBiuras: string, transportSmsFactor: string, transportSmsapi: string, transportSmsc: string, transportSmsmode: string, transportSpotHit: string, transportTelegram: string, transportTelnyx: string, transportTermii: string, transportTrello: string, transportTurboSms: string, transportTwilio: string, transportTwitter: string, transportVonage: string, transportWebhook: string, transportYunpian: string, transportZendesk: string, transportZulip: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/alert-service")
  let body = {alertServiceName: $alertServiceName, alertServiceNotes: $alertServiceNotes, alertServiceTransportCode: $alertServiceTransportCode, dataSegmentCode: $dataSegmentCode, mediaObjects: $mediaObjects, partition: $partition, recipientEmailAddress: $recipientEmailAddress, recipientPhoneNumber: $recipientPhoneNumber, transportAlerta: $transportAlerta, transportAllMySms: $transportAllMySms, transportAmazonSns: $transportAmazonSns, transportBandwidth: $transportBandwidth, transportChatwork: $transportChatwork, transportClickSend: $transportClickSend, transportClickatell: $transportClickatell, transportContactEveryone: $transportContactEveryone, transportDiscord: $transportDiscord, transportEmail: $transportEmail, transportEngagespot: $transportEngagespot, transportEsendex: $transportEsendex, transportExpo: $transportExpo, transportFirebase: $transportFirebase, transportFortySixElks: $transportFortySixElks, transportFreeMobile: $transportFreeMobile, transportFreshdesk: $transportFreshdesk, transportGatewayApi: $transportGatewayApi, transportGitter: $transportGitter, transportGoogleChat: $transportGoogleChat, transportGotify: $transportGotify, transportHelpScout: $transportHelpScout, transportInfobip: $transportInfobip, transportIqsms: $transportIqsms, transportKazInfoTeh: $transportKazInfoTeh, transportLightSms: $transportLightSms, transportLineNotify: $transportLineNotify, transportLinkedIn: $transportLinkedIn, transportMailjet: $transportMailjet, transportMastodon: $transportMastodon, transportMattermost: $transportMattermost, transportMercure: $transportMercure, transportMessageBird: $transportMessageBird, transportMessageMedia: $transportMessageMedia, transportMicrosoftTeams: $transportMicrosoftTeams, transportMobyt: $transportMobyt, transportOctopush: $transportOctopush, transportOneSignal: $transportOneSignal, transportOpsgenie: $transportOpsgenie, transportOrangeSms: $transportOrangeSms, transportOvhCloud: $transportOvhCloud, transportPagerDuty: $transportPagerDuty, transportPagerTree: $transportPagerTree, transportPlivo: $transportPlivo, transportPushbullet: $transportPushbullet, transportPushover: $transportPushover, transportPushy: $transportPushy, transportRingCentral: $transportRingCentral, transportRocketChat: $transportRocketChat, transportSendberry: $transportSendberry, transportSendinblue: $transportSendinblue, transportSimpleTextin: $transportSimpleTextin, transportSinch: $transportSinch, transportSlack: $transportSlack, transportSms77: $transportSms77, transportSmsBiuras: $transportSmsBiuras, transportSmsFactor: $transportSmsFactor, transportSmsapi: $transportSmsapi, transportSmsc: $transportSmsc, transportSmsmode: $transportSmsmode, transportSpotHit: $transportSpotHit, transportTelegram: $transportTelegram, transportTelnyx: $transportTelnyx, transportTermii: $transportTermii, transportTrello: $transportTrello, transportTurboSms: $transportTurboSms, transportTwilio: $transportTwilio, transportTwitter: $transportTwitter, transportVonage: $transportVonage, transportWebhook: $transportWebhook, transportYunpian: $transportYunpian, transportZendesk: $transportZendesk, transportZulip: $transportZulip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of AlertServiceTransportCode resources.
#
# GET /api/alert-service-transport-code
# operationId: api_alert-service-transport-code_get_collection
export def "alert-service-transport-code collection" [
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
  --properties: list # allows empty value
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
  let full_url = (build-url $base $"/api/alert-service-transport-code/($id)")
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
  let full_url = (build-url $base $"/api/alert-service/($id)")
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
  let full_url = (build-url $base $"/api/alert-service/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the AlertService resource.
#
# PUT /api/alert-service/{id}
# operationId: api_alert-service_id_put
export def "alert-service put" [
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
  --alertServiceName: string # The name of the alert service. Max 255 characters. (nullable)
  --alertServiceNotes: string # Notes about the alert service. Max 10,000 characters. Formatting using Markdown is allowed. HTML will be removed. (nullable)
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --mediaObjects: list # Media objects that must be sent with each alert. Only applicable when you use your own email alert services.
  --recipientEmailAddress: string # The email address where alerts will be sent. (nullable, format: email)
  --recipientPhoneNumber: string # The phone number where alerts will be sent. Ensure that the number format complies with the external transport service that will send the alert. (nullable)
  --transportAlerta: string # nullable, format: iri-reference
  --transportAllMySms: string # nullable, format: iri-reference
  --transportAmazonSns: string # nullable, format: iri-reference
  --transportBandwidth: string # nullable, format: iri-reference
  --transportChatwork: string # nullable, format: iri-reference
  --transportClickSend: string # nullable, format: iri-reference
  --transportClickatell: string # nullable, format: iri-reference
  --transportContactEveryone: string # nullable, format: iri-reference
  --transportDiscord: string # nullable, format: iri-reference
  --transportEmail: string # nullable, format: iri-reference
  --transportEngagespot: string # nullable, format: iri-reference
  --transportEsendex: string # nullable, format: iri-reference
  --transportExpo: string # nullable, format: iri-reference
  --transportFirebase: string # nullable, format: iri-reference
  --transportFortySixElks: string # nullable, format: iri-reference
  --transportFreeMobile: string # nullable, format: iri-reference
  --transportFreshdesk: string # nullable, format: iri-reference
  --transportGatewayApi: string # nullable, format: iri-reference
  --transportGitter: string # nullable, format: iri-reference
  --transportGoogleChat: string # nullable, format: iri-reference
  --transportGotify: string # nullable, format: iri-reference
  --transportHelpScout: string # nullable, format: iri-reference
  --transportInfobip: string # nullable, format: iri-reference
  --transportIqsms: string # nullable, format: iri-reference
  --transportKazInfoTeh: string # nullable, format: iri-reference
  --transportLightSms: string # nullable, format: iri-reference
  --transportLineNotify: string # nullable, format: iri-reference
  --transportLinkedIn: string # nullable, format: iri-reference
  --transportMailjet: string # nullable, format: iri-reference
  --transportMastodon: string # nullable, format: iri-reference
  --transportMattermost: string # nullable, format: iri-reference
  --transportMercure: string # nullable, format: iri-reference
  --transportMessageBird: string # nullable, format: iri-reference
  --transportMessageMedia: string # nullable, format: iri-reference
  --transportMicrosoftTeams: string # nullable, format: iri-reference
  --transportMobyt: string # nullable, format: iri-reference
  --transportOctopush: string # nullable, format: iri-reference
  --transportOneSignal: string # nullable, format: iri-reference
  --transportOpsgenie: string # nullable, format: iri-reference
  --transportOrangeSms: string # nullable, format: iri-reference
  --transportOvhCloud: string # nullable, format: iri-reference
  --transportPagerDuty: string # nullable, format: iri-reference
  --transportPagerTree: string # nullable, format: iri-reference
  --transportPlivo: string # nullable, format: iri-reference
  --transportPushbullet: string # nullable, format: iri-reference
  --transportPushover: string # nullable, format: iri-reference
  --transportPushy: string # nullable, format: iri-reference
  --transportRingCentral: string # nullable, format: iri-reference
  --transportRocketChat: string # nullable, format: iri-reference
  --transportSendberry: string # nullable, format: iri-reference
  --transportSendinblue: string # nullable, format: iri-reference
  --transportSimpleTextin: string # nullable, format: iri-reference
  --transportSinch: string # nullable, format: iri-reference
  --transportSlack: string # nullable, format: iri-reference
  --transportSms77: string # nullable, format: iri-reference
  --transportSmsBiuras: string # nullable, format: iri-reference
  --transportSmsFactor: string # nullable, format: iri-reference
  --transportSmsapi: string # nullable, format: iri-reference
  --transportSmsc: string # nullable, format: iri-reference
  --transportSmsmode: string # nullable, format: iri-reference
  --transportSpotHit: string # nullable, format: iri-reference
  --transportTelegram: string # nullable, format: iri-reference
  --transportTelnyx: string # nullable, format: iri-reference
  --transportTermii: string # nullable, format: iri-reference
  --transportTrello: string # nullable, format: iri-reference
  --transportTurboSms: string # nullable, format: iri-reference
  --transportTwilio: string # nullable, format: iri-reference
  --transportTwitter: string # nullable, format: iri-reference
  --transportVonage: string # nullable, format: iri-reference
  --transportWebhook: string # nullable, format: iri-reference
  --transportYunpian: string # nullable, format: iri-reference
  --transportZendesk: string # nullable, format: iri-reference
  --transportZulip: string # nullable, format: iri-reference
]: any -> record<alertServiceName: string, alertServiceNotes: string, alertServiceTransportCode: string, createdAt: string, creditsPerTransportAlert: int, dataSegmentCode: string, id: string, mediaObjects: list<string>, partition: string, recipientEmailAddress: string, recipientPhoneNumber: string, resourceOwner: string, transportAlerta: string, transportAllMySms: string, transportAmazonSns: string, transportBandwidth: string, transportChatwork: string, transportClickSend: string, transportClickatell: string, transportContactEveryone: string, transportDiscord: string, transportEmail: string, transportEngagespot: string, transportEsendex: string, transportExpo: string, transportFirebase: string, transportFortySixElks: string, transportFreeMobile: string, transportFreshdesk: string, transportGatewayApi: string, transportGitter: string, transportGoogleChat: string, transportGotify: string, transportHelpScout: string, transportInfobip: string, transportIqsms: string, transportKazInfoTeh: string, transportLightSms: string, transportLineNotify: string, transportLinkedIn: string, transportMailjet: string, transportMastodon: string, transportMattermost: string, transportMercure: string, transportMessageBird: string, transportMessageMedia: string, transportMicrosoftTeams: string, transportMobyt: string, transportOctopush: string, transportOneSignal: string, transportOpsgenie: string, transportOrangeSms: string, transportOvhCloud: string, transportPagerDuty: string, transportPagerTree: string, transportPlivo: string, transportPushbullet: string, transportPushover: string, transportPushy: string, transportRingCentral: string, transportRocketChat: string, transportSendberry: string, transportSendinblue: string, transportSimpleTextin: string, transportSinch: string, transportSlack: string, transportSms77: string, transportSmsBiuras: string, transportSmsFactor: string, transportSmsapi: string, transportSmsc: string, transportSmsmode: string, transportSpotHit: string, transportTelegram: string, transportTelnyx: string, transportTermii: string, transportTrello: string, transportTurboSms: string, transportTwilio: string, transportTwitter: string, transportVonage: string, transportWebhook: string, transportYunpian: string, transportZendesk: string, transportZulip: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/alert-service/($id)")
  let body = {alertServiceName: $alertServiceName, alertServiceNotes: $alertServiceNotes, dataSegmentCode: $dataSegmentCode, mediaObjects: $mediaObjects, recipientEmailAddress: $recipientEmailAddress, recipientPhoneNumber: $recipientPhoneNumber, transportAlerta: $transportAlerta, transportAllMySms: $transportAllMySms, transportAmazonSns: $transportAmazonSns, transportBandwidth: $transportBandwidth, transportChatwork: $transportChatwork, transportClickSend: $transportClickSend, transportClickatell: $transportClickatell, transportContactEveryone: $transportContactEveryone, transportDiscord: $transportDiscord, transportEmail: $transportEmail, transportEngagespot: $transportEngagespot, transportEsendex: $transportEsendex, transportExpo: $transportExpo, transportFirebase: $transportFirebase, transportFortySixElks: $transportFortySixElks, transportFreeMobile: $transportFreeMobile, transportFreshdesk: $transportFreshdesk, transportGatewayApi: $transportGatewayApi, transportGitter: $transportGitter, transportGoogleChat: $transportGoogleChat, transportGotify: $transportGotify, transportHelpScout: $transportHelpScout, transportInfobip: $transportInfobip, transportIqsms: $transportIqsms, transportKazInfoTeh: $transportKazInfoTeh, transportLightSms: $transportLightSms, transportLineNotify: $transportLineNotify, transportLinkedIn: $transportLinkedIn, transportMailjet: $transportMailjet, transportMastodon: $transportMastodon, transportMattermost: $transportMattermost, transportMercure: $transportMercure, transportMessageBird: $transportMessageBird, transportMessageMedia: $transportMessageMedia, transportMicrosoftTeams: $transportMicrosoftTeams, transportMobyt: $transportMobyt, transportOctopush: $transportOctopush, transportOneSignal: $transportOneSignal, transportOpsgenie: $transportOpsgenie, transportOrangeSms: $transportOrangeSms, transportOvhCloud: $transportOvhCloud, transportPagerDuty: $transportPagerDuty, transportPagerTree: $transportPagerTree, transportPlivo: $transportPlivo, transportPushbullet: $transportPushbullet, transportPushover: $transportPushover, transportPushy: $transportPushy, transportRingCentral: $transportRingCentral, transportRocketChat: $transportRocketChat, transportSendberry: $transportSendberry, transportSendinblue: $transportSendinblue, transportSimpleTextin: $transportSimpleTextin, transportSinch: $transportSinch, transportSlack: $transportSlack, transportSms77: $transportSms77, transportSmsBiuras: $transportSmsBiuras, transportSmsFactor: $transportSmsFactor, transportSmsapi: $transportSmsapi, transportSmsc: $transportSmsc, transportSmsmode: $transportSmsmode, transportSpotHit: $transportSpotHit, transportTelegram: $transportTelegram, transportTelnyx: $transportTelnyx, transportTermii: $transportTermii, transportTrello: $transportTrello, transportTurboSms: $transportTurboSms, transportTwilio: $transportTwilio, transportTwitter: $transportTwitter, transportVonage: $transportVonage, transportWebhook: $transportWebhook, transportYunpian: $transportYunpian, transportZendesk: $transportZendesk, transportZulip: $transportZulip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of CreditsConsumption resources.
#
# GET /api/credits-consumption
# operationId: api_credits-consumption_get_collection
export def "credits-consumption collection" [
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
  --properties: list # allows empty value
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
  let full_url = (build-url $base $"/api/credits-consumption/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of HttpMethodCode resources.
#
# GET /api/http-method-code
# operationId: api_http-method-code_get_collection
export def "http-method-code collection" [
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
  --properties: list # allows empty value
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
  let full_url = (build-url $base $"/api/http-method-code/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of MediaObject resources.
#
# GET /api/media-object
# operationId: api_media-object_get_collection
export def "media-object collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<contentUrl: string, createdAt: string, dataSegmentCode: string, fileSize: int, id: string, keywords: string, mimeType: string, originalName: string, partition: string, resourceOwner: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/media-object" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a MediaObject resource.
#
# POST /api/media-object
# operationId: api_media-object_post
export def "media-object post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (format: string)
  --file: string # format: binary
  --keywords: string # A string of keywords that can be used to search for a resource. Max 100 characters. (format: string)
  --partition: string # The unique id of the partition. Can be just the id or an IRI. (format: string)
]: any -> record<contentUrl: string, createdAt: string, dataSegmentCode: string, fileSize: int, id: string, keywords: string, mimeType: string, originalName: string, partition: string, resourceOwner: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/media-object")
  let body = {dataSegmentCode: $dataSegmentCode, file: $file, keywords: $keywords, partition: $partition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
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
  let full_url = (build-url $base $"/api/media-object/($id)")
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
  let full_url = (build-url $base $"/api/media-object/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of Monitor resources.
#
# GET /api/monitor
# operationId: api_monitor_get_collection
export def "monitor collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<alertPayloadExtended: string, alertPayloadShort: string, alertServices: list<string>, allowUnauthenticatedPings: bool, contentCheckMustNotExist: bool, contentCheckText: string, contentCheckUrl: string, contentCheckXpathFilter: string, createdAt: string, dataSegmentCode: string, graceSeconds: int, humanizedInterval: string, id: string, internalMonitorName: string, intervalDays: int, intervalHours: int, intervalMinutes: int, intervalMonths: int, intervalSeconds: int, intervalYears: int, isMonitorPaused: bool, lastPingAt: string, monitorName: string, monitorNotes: string, monitorStatusCode: string, monitorTypeCode: string, nextPingAt: string, partition: string, pingSecret: string, publicDescription: string, resourceOwner: string, startMonitorAt: string, startMonitorAtUtc: string, systemMessages: list<string>, timezoneCode: string, webResponseSecondsLimit: int, webResponseUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/monitor" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Monitor resource.
#
# POST /api/monitor
# operationId: api_monitor_post
export def "monitor post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --alertPayloadExtended: string # Payload that must be sent in the body of each alert when you use your own email or webhook alert services. This is the body for email alerts and the request body for webhook alerts. This text is not sent when using the built-in alert services. Sending user-supplied text via our own email server is too big a risk to our email reputation. Max 2 MB characters. (nullable)
  --alertPayloadShort: string # Payload that must be sent in the body of each alert when you use your own short message alert services. This also serves as the subject for email alerts. Not used for webhooks. This text is not sent when using the built-in alert services. Sending user-supplied text via our own email server is too big a risk to our email reputation. Max 100 characters. (nullable)
  --alertServices: list # The alert services that are related to this resource.
  --allowUnauthenticatedPings: oneof<nothing, bool> # Indicates that the monitor will accept pings that are not OAuth authenticated.
  --contentCheckMustNotExist: oneof<nothing, bool> # Indicates that the Web Content monitor must verify the absence of the text or the Xpath node, and dispatch an alert if it is present. The default behavior is to verify the presence of the text or the Xpath node, and dispatch an alert if it is absent.
  --contentCheckText: string # The text (case-insensitive) that must or must not be present at the contentCheckUrl. If contentCheckXpathFilter is supplied, then the only the text within that nodes is evaluated, otherwise text on the entire web page is evaluated. (nullable)
  --contentCheckUrl: string # The URL that the Web Content monitor type must evaluate for the specified conditions. (nullable, format: uri)
  --contentCheckXpathFilter: string # The Xpath filter (<a href="https://en.wikipedia.org/wiki/XPath">Xpath</a>, <a href="https://devhints.io/xpath">Xpath Cheatsheet</a>) that selects a specific node in the HTML of the target web page. If contentCheckText is supplied, then only the text within the selected node is evaluated. If contentCheckText is left empty, then the presence or the absence of the selected node is evaluated. (nullable)
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --graceSeconds: int # The number of grace seconds after expiry of the time when the next ping was expected, before raising an alert. The number of grace seconds to allow before classifying a Measured Monitor task duration as an anomaly. (nullable)
  --intervalDays: int # The number of days in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --intervalHours: int # The number of hours in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --intervalMinutes: int # The number of minutes in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --intervalMonths: int # The number of months in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --intervalSeconds: int # The number of seconds in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --intervalYears: int # The number of years in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --isMonitorPaused: oneof<nothing, bool> # Indicates that the monitor is paused and will not send alerts.
  --monitorName: string # The name of the monitor. Max 255 characters. (nullable)
  --monitorNotes: string # Notes about the monitor. Max 10,000 characters. Formatting using Markdown is allowed. HTML will be removed. (nullable)
  --monitorTypeCode: string # The type of the monitor. (nullable, format: iri-reference)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --publicDescription: string # A text description of the monitor that is accessible to unauthenticated users that receive an alert from the monitor. Formatting using Markdown is allowed. HTML will be removed. (nullable)
  --startMonitorAt: string # When to start the Regular Interval type monitor or Heartbeat type monitor, or when to send the first alert of the Scheduled Repeatable Alert monitor. Cannot be blank for a Regular Interval, Heartbeat, or Scheduled Repeatable Alert type monitor, must be blank for other monitors types. This date-time is always interpreted to be in the timezone of the monitor. Any UTC offset is ignored. (nullable, format: date-time)
  timezoneCode: string # The timezone of the monitor. Dates and times in alerts and reports will be in this time zone. (format: iri-reference)
  --webResponseSecondsLimit: int # The time in seconds that the Web Response monitor type must allow for the web page to respond. (nullable)
  --webResponseUrl: string # The URL that the Web Response monitor type must evaluate for the specified conditions. (nullable, format: uri)
]: any -> record<alertPayloadExtended: string, alertPayloadShort: string, alertServices: list<string>, allowUnauthenticatedPings: bool, contentCheckMustNotExist: bool, contentCheckText: string, contentCheckUrl: string, contentCheckXpathFilter: string, createdAt: string, dataSegmentCode: string, graceSeconds: int, humanizedInterval: string, id: string, internalMonitorName: string, intervalDays: int, intervalHours: int, intervalMinutes: int, intervalMonths: int, intervalSeconds: int, intervalYears: int, isMonitorPaused: bool, lastPingAt: string, monitorName: string, monitorNotes: string, monitorStatusCode: string, monitorTypeCode: string, nextPingAt: string, partition: string, pingSecret: string, publicDescription: string, resourceOwner: string, startMonitorAt: string, startMonitorAtUtc: string, systemMessages: list<string>, timezoneCode: string, webResponseSecondsLimit: int, webResponseUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/monitor")
  let body = {alertPayloadExtended: $alertPayloadExtended, alertPayloadShort: $alertPayloadShort, alertServices: $alertServices, allowUnauthenticatedPings: $allowUnauthenticatedPings, contentCheckMustNotExist: $contentCheckMustNotExist, contentCheckText: $contentCheckText, contentCheckUrl: $contentCheckUrl, contentCheckXpathFilter: $contentCheckXpathFilter, dataSegmentCode: $dataSegmentCode, graceSeconds: $graceSeconds, intervalDays: $intervalDays, intervalHours: $intervalHours, intervalMinutes: $intervalMinutes, intervalMonths: $intervalMonths, intervalSeconds: $intervalSeconds, intervalYears: $intervalYears, isMonitorPaused: $isMonitorPaused, monitorName: $monitorName, monitorNotes: $monitorNotes, monitorTypeCode: $monitorTypeCode, partition: $partition, publicDescription: $publicDescription, startMonitorAt: $startMonitorAt, timezoneCode: $timezoneCode, webResponseSecondsLimit: $webResponseSecondsLimit, webResponseUrl: $webResponseUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of MonitorStatusCode resources.
#
# GET /api/monitor-status-code
# operationId: api_monitor-status-code_get_collection
export def "monitor-status-code collection" [
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
  --properties: list # allows empty value
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
  let full_url = (build-url $base $"/api/monitor-status-code/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of MonitorStatusLog resources.
#
# GET /api/monitor-status-log
# operationId: api_monitor-status-log_get_collection
export def "monitor-status-log collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --monitor: string # allows empty value
  --monitor: list # allows empty value
  --monitorStatusCode: string # allows empty value
  --monitorStatusCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, monitor: string, monitorStatusCode: string, partition: string, ping: string, resourceOwner: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "monitor" $monitor "scalar") (serialize-qp "monitor[]" $monitor "multi") (serialize-qp "monitorStatusCode" $monitorStatusCode "scalar") (serialize-qp "monitorStatusCode[]" $monitorStatusCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
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
  let full_url = (build-url $base $"/api/monitor-status-log/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of MonitorTypeCode resources.
#
# GET /api/monitor-type-code
# operationId: api_monitor-type-code_get_collection
export def "monitor-type-code collection" [
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
  --properties: list # allows empty value
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
  let full_url = (build-url $base $"/api/monitor-type-code/($id)")
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
  let full_url = (build-url $base $"/api/monitor/($id)")
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
  let full_url = (build-url $base $"/api/monitor/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the Monitor resource.
#
# PUT /api/monitor/{id}
# operationId: api_monitor_id_put
export def "monitor put" [
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
  --alertPayloadExtended: string # Payload that must be sent in the body of each alert when you use your own email or webhook alert services. This is the body for email alerts and the request body for webhook alerts. This text is not sent when using the built-in alert services. Sending user-supplied text via our own email server is too big a risk to our email reputation. Max 2 MB characters. (nullable)
  --alertPayloadShort: string # Payload that must be sent in the body of each alert when you use your own short message alert services. This also serves as the subject for email alerts. Not used for webhooks. This text is not sent when using the built-in alert services. Sending user-supplied text via our own email server is too big a risk to our email reputation. Max 100 characters. (nullable)
  --alertServices: list # The alert services that are related to this resource.
  --allowUnauthenticatedPings: oneof<nothing, bool> # Indicates that the monitor will accept pings that are not OAuth authenticated.
  --contentCheckMustNotExist: oneof<nothing, bool> # Indicates that the Web Content monitor must verify the absence of the text or the Xpath node, and dispatch an alert if it is present. The default behavior is to verify the presence of the text or the Xpath node, and dispatch an alert if it is absent.
  --contentCheckText: string # The text (case-insensitive) that must or must not be present at the contentCheckUrl. If contentCheckXpathFilter is supplied, then the only the text within that nodes is evaluated, otherwise text on the entire web page is evaluated. (nullable)
  --contentCheckUrl: string # The URL that the Web Content monitor type must evaluate for the specified conditions. (nullable, format: uri)
  --contentCheckXpathFilter: string # The Xpath filter (<a href="https://en.wikipedia.org/wiki/XPath">Xpath</a>, <a href="https://devhints.io/xpath">Xpath Cheatsheet</a>) that selects a specific node in the HTML of the target web page. If contentCheckText is supplied, then only the text within the selected node is evaluated. If contentCheckText is left empty, then the presence or the absence of the selected node is evaluated. (nullable)
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --graceSeconds: int # The number of grace seconds after expiry of the time when the next ping was expected, before raising an alert. The number of grace seconds to allow before classifying a Measured Monitor task duration as an anomaly. (nullable)
  --intervalDays: int # The number of days in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --intervalHours: int # The number of hours in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --intervalMinutes: int # The number of minutes in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --intervalMonths: int # The number of months in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --intervalSeconds: int # The number of seconds in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --intervalYears: int # The number of years in the expected ping / run / measured / scheduled interval. Can be left blank. Can be specified together with any combination of the other interval fields. (nullable)
  --isMonitorPaused: oneof<nothing, bool> # Indicates that the monitor is paused and will not send alerts.
  --monitorName: string # The name of the monitor. Max 255 characters. (nullable)
  --monitorNotes: string # Notes about the monitor. Max 10,000 characters. Formatting using Markdown is allowed. HTML will be removed. (nullable)
  --publicDescription: string # A text description of the monitor that is accessible to unauthenticated users that receive an alert from the monitor. Formatting using Markdown is allowed. HTML will be removed. (nullable)
  --startMonitorAt: string # When to start the Regular Interval type monitor or Heartbeat type monitor, or when to send the first alert of the Scheduled Repeatable Alert monitor. Cannot be blank for a Regular Interval, Heartbeat, or Scheduled Repeatable Alert type monitor, must be blank for other monitors types. This date-time is always interpreted to be in the timezone of the monitor. Any UTC offset is ignored. (nullable, format: date-time)
  timezoneCode: string # The timezone of the monitor. Dates and times in alerts and reports will be in this time zone. (format: iri-reference)
  --webResponseSecondsLimit: int # The time in seconds that the Web Response monitor type must allow for the web page to respond. (nullable)
  --webResponseUrl: string # The URL that the Web Response monitor type must evaluate for the specified conditions. (nullable, format: uri)
]: any -> record<alertPayloadExtended: string, alertPayloadShort: string, alertServices: list<string>, allowUnauthenticatedPings: bool, contentCheckMustNotExist: bool, contentCheckText: string, contentCheckUrl: string, contentCheckXpathFilter: string, createdAt: string, dataSegmentCode: string, graceSeconds: int, humanizedInterval: string, id: string, internalMonitorName: string, intervalDays: int, intervalHours: int, intervalMinutes: int, intervalMonths: int, intervalSeconds: int, intervalYears: int, isMonitorPaused: bool, lastPingAt: string, monitorName: string, monitorNotes: string, monitorStatusCode: string, monitorTypeCode: string, nextPingAt: string, partition: string, pingSecret: string, publicDescription: string, resourceOwner: string, startMonitorAt: string, startMonitorAtUtc: string, systemMessages: list<string>, timezoneCode: string, webResponseSecondsLimit: int, webResponseUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/monitor/($id)")
  let body = {alertPayloadExtended: $alertPayloadExtended, alertPayloadShort: $alertPayloadShort, alertServices: $alertServices, allowUnauthenticatedPings: $allowUnauthenticatedPings, contentCheckMustNotExist: $contentCheckMustNotExist, contentCheckText: $contentCheckText, contentCheckUrl: $contentCheckUrl, contentCheckXpathFilter: $contentCheckXpathFilter, dataSegmentCode: $dataSegmentCode, graceSeconds: $graceSeconds, intervalDays: $intervalDays, intervalHours: $intervalHours, intervalMinutes: $intervalMinutes, intervalMonths: $intervalMonths, intervalSeconds: $intervalSeconds, intervalYears: $intervalYears, isMonitorPaused: $isMonitorPaused, monitorName: $monitorName, monitorNotes: $monitorNotes, publicDescription: $publicDescription, startMonitorAt: $startMonitorAt, timezoneCode: $timezoneCode, webResponseSecondsLimit: $webResponseSecondsLimit, webResponseUrl: $webResponseUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of Partition resources.
#
# GET /api/partition
# operationId: api_partition_get_collection
export def "partition collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<alertServices: list<string>, createdAt: string, dataSegmentCode: string, id: string, monitors: list<string>, partitionName: string, partitionNotes: string, resourceOwner: string, teamInvitations: list<string>, teamMembers: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/partition" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Partition resource.
#
# POST /api/partition
# operationId: api_partition_post
export def "partition post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --partitionName: string # The name of the partition. Max 255 characters. (nullable)
  --partitionNotes: string # Notes about the partition. Max 10,000 characters. Formatting using Markdown is allowed. HTML will be removed. (nullable)
]: any -> record<alertServices: list<string>, createdAt: string, dataSegmentCode: string, id: string, monitors: list<string>, partitionName: string, partitionNotes: string, resourceOwner: string, teamInvitations: list<string>, teamMembers: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/partition")
  let body = {dataSegmentCode: $dataSegmentCode, partitionName: $partitionName, partitionNotes: $partitionNotes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/partition/($id)")
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
  let full_url = (build-url $base $"/api/partition/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the Partition resource.
#
# PUT /api/partition/{id}
# operationId: api_partition_id_put
export def "partition put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --partitionName: string # The name of the partition. Max 255 characters. (nullable)
  --partitionNotes: string # Notes about the partition. Max 10,000 characters. Formatting using Markdown is allowed. HTML will be removed. (nullable)
]: any -> record<alertServices: list<string>, createdAt: string, dataSegmentCode: string, id: string, monitors: list<string>, partitionName: string, partitionNotes: string, resourceOwner: string, teamInvitations: list<string>, teamMembers: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/partition/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, partitionName: $partitionName, partitionNotes: $partitionNotes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of Ping resources.
#
# GET /api/ping
# operationId: api_ping_get_collection
export def "ping collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --monitor: string # allows empty value
  --monitor: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<alertLogs: list<string>, createdAt: string, dataSegmentCode: string, expectNextPingAt: string, expectNextPingAtEpoch: int, id: string, ipAddress: string, monitor: string, monitorStatusLog: string, partition: string, pingCustomCode: string, pingCustomPayload: string, pingMethodCode: string, resourceOwner: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "monitor" $monitor "scalar") (serialize-qp "monitor[]" $monitor "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ping" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Ping resource.
#
# POST /api/ping
# operationId: api_ping_post
export def "ping post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --expectNextPingAt: string # When to expect the next ping for a Last Ping monitor type. This date-time is always interpreted to be in the timezone of the monitor. Any UTC offset is ignored. Supply either "expectNextPingAt", or "expectNextPingAtEpoch", or a X_NEXT_PING request header, not more than one of those options. Must be blank for other monitor types. (nullable, format: date-time)
  --expectNextPingAtEpoch: int # When to expect the next ping for a Last Ping monitor type, expressed in epoch timestamp format. Supply either "expectNextPingAt", or "expectNextPingAtEpoch", or a X_NEXT_PING request header, not more than one of those options. Must be blank for other monitor types. (nullable)
  monitor: string # The monitor that is related to this resource instance. (format: iri-reference)
  --pingCustomCode: string # The client-supplied custom code that is appended to the ping. Only the first 10 characters are used and saved. (nullable)
  --pingCustomPayload: string # The client-supplied custom payload that is saved with the ping. Only the first 100 characters are saved. This value overrides the value of an monitor's alert payload, if the ping results in an alert. (nullable)
]: any -> record<alertLogs: list<string>, createdAt: string, dataSegmentCode: string, expectNextPingAt: string, expectNextPingAtEpoch: int, id: string, ipAddress: string, monitor: string, monitorStatusLog: string, partition: string, pingCustomCode: string, pingCustomPayload: string, pingMethodCode: string, resourceOwner: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/ping")
  let body = {expectNextPingAt: $expectNextPingAt, expectNextPingAtEpoch: $expectNextPingAtEpoch, monitor: $monitor, pingCustomCode: $pingCustomCode, pingCustomPayload: $pingCustomPayload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of PingMethodCode resources.
#
# GET /api/ping-method-code
# operationId: api_ping-method-code_get_collection
export def "ping-method-code collection" [
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
  --properties: list # allows empty value
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
  let full_url = (build-url $base $"/api/ping-method-code/($id)")
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
  let full_url = (build-url $base $"/api/ping/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of TeamInvitation resources.
#
# GET /api/team-invitation
# operationId: api_team-invitation_get_collection
export def "team-invitation collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --inviteeEmail: string # allows empty value
  --inviteeEmail: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, inviteeEmail: string, inviteeFirstName: string, inviteeLastName: string, partition: string, resourceOwner: string, statusAt: string, teamInvitationStatus: string, teamMemberRoleCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "inviteeEmail" $inviteeEmail "scalar") (serialize-qp "inviteeEmail[]" $inviteeEmail "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/team-invitation" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TeamInvitation resource.
#
# POST /api/team-invitation
# operationId: api_team-invitation_post
export def "team-invitation post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --inviteeEmail: string # The email address of the person that is being invited. (nullable, format: email)
  --inviteeFirstName: string # The first name of the person that is being invited. (nullable)
  --inviteeLastName: string # The last name of the person that is being invited. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --teamMemberRoleCode: string # The role of the team member on the team. (format: iri-reference)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, inviteeEmail: string, inviteeFirstName: string, inviteeLastName: string, partition: string, resourceOwner: string, statusAt: string, teamInvitationStatus: string, teamMemberRoleCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/team-invitation")
  let body = {dataSegmentCode: $dataSegmentCode, inviteeEmail: $inviteeEmail, inviteeFirstName: $inviteeFirstName, inviteeLastName: $inviteeLastName, partition: $partition, teamMemberRoleCode: $teamMemberRoleCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/team-invitation/($id)")
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
  let full_url = (build-url $base $"/api/team-invitation/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of TeamMember resources.
#
# GET /api/team-member
# operationId: api_team-member_get_collection
export def "team-member collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --userAccount: string # allows empty value
  --userAccount: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, teamMemberRoleCode: string, userAccount: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "userAccount" $userAccount "scalar") (serialize-qp "userAccount[]" $userAccount "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/team-member" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of TeamMemberRoleCode resources.
#
# GET /api/team-member-role-code
# operationId: api_team-member-role-code_get_collection
export def "team-member-role-code collection" [
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
  --properties: list # allows empty value
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
  let full_url = (build-url $base $"/api/team-member-role-code/($id)")
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
  let full_url = (build-url $base $"/api/team-member/($id)")
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
  let full_url = (build-url $base $"/api/team-member/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TeamMember resource.
#
# PUT /api/team-member/{id}
# operationId: api_team-member_id_put
export def "team-member put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --teamMemberRoleCode: string # The role of the team member on the team. (nullable, format: iri-reference)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, teamMemberRoleCode: string, userAccount: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/team-member/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, teamMemberRoleCode: $teamMemberRoleCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TimezoneCode resources.
#
# GET /api/timezone-code
# operationId: api_timezone-code_get_collection
export def "timezone-code collection" [
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
  --properties: list # allows empty value
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
  let full_url = (build-url $base $"/api/timezone-code/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the collection of TransportAlerta resources.
#
# GET /api/transport-alerta
# operationId: api_transport-alerta_get_collection
export def "transport-alerta collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<alertaApiKey: string, alertaCorrelate: string, alertaEnvironment: string, alertaEvent: string, alertaGroup: string, alertaHost: string, alertaOrigin: string, alertaResource: string, alertaService: string, alertaSeverity: string, alertaStatus: string, alertaTags: string, alertaType: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-alerta" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportAlerta resource.
#
# POST /api/transport-alerta
# operationId: api_transport-alerta_post
export def "transport-alerta post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --alertaApiKey: string # The API key for the Alerta service. (nullable)
  --alertaCorrelate: string # The comma-separated list of related event names for the Alerta service. (nullable)
  --alertaEnvironment: string # The environment value for the Alerta service. (nullable)
  --alertaEvent: string # The event value for the Alerta service. (nullable)
  --alertaGroup: string # The group value for the Alerta service. (nullable)
  --alertaHost: string # The host name for the Alerta service (omit the "https://" part). (nullable, format: hostname)
  --alertaOrigin: string # The origin value for the Alerta service. (nullable)
  --alertaResource: string # The resource value for the Alerta service. (nullable)
  --alertaService: string # The comma-separated list of affected services for the Alerta service. (nullable)
  --alertaSeverity: string # The severity value for the Alerta service. (nullable)
  --alertaStatus: string # The status value for the Alerta service. (nullable)
  --alertaTags: string # The comma-separated list of tags for the Alerta service. (nullable)
  --alertaType: string # The type value for the Alerta service. (nullable)
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<alertaApiKey: string, alertaCorrelate: string, alertaEnvironment: string, alertaEvent: string, alertaGroup: string, alertaHost: string, alertaOrigin: string, alertaResource: string, alertaService: string, alertaSeverity: string, alertaStatus: string, alertaTags: string, alertaType: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-alerta")
  let body = {alertaApiKey: $alertaApiKey, alertaCorrelate: $alertaCorrelate, alertaEnvironment: $alertaEnvironment, alertaEvent: $alertaEvent, alertaGroup: $alertaGroup, alertaHost: $alertaHost, alertaOrigin: $alertaOrigin, alertaResource: $alertaResource, alertaService: $alertaService, alertaSeverity: $alertaSeverity, alertaStatus: $alertaStatus, alertaTags: $alertaTags, alertaType: $alertaType, dataSegmentCode: $dataSegmentCode, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-alerta/($id)")
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
  let full_url = (build-url $base $"/api/transport-alerta/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportAlerta resource.
#
# PUT /api/transport-alerta/{id}
# operationId: api_transport-alerta_id_put
export def "transport-alerta put" [
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
  --alertaApiKey: string # The API key for the Alerta service. (nullable)
  --alertaCorrelate: string # The comma-separated list of related event names for the Alerta service. (nullable)
  --alertaEnvironment: string # The environment value for the Alerta service. (nullable)
  --alertaEvent: string # The event value for the Alerta service. (nullable)
  --alertaGroup: string # The group value for the Alerta service. (nullable)
  --alertaHost: string # The host name for the Alerta service (omit the "https://" part). (nullable, format: hostname)
  --alertaOrigin: string # The origin value for the Alerta service. (nullable)
  --alertaResource: string # The resource value for the Alerta service. (nullable)
  --alertaService: string # The comma-separated list of affected services for the Alerta service. (nullable)
  --alertaSeverity: string # The severity value for the Alerta service. (nullable)
  --alertaStatus: string # The status value for the Alerta service. (nullable)
  --alertaTags: string # The comma-separated list of tags for the Alerta service. (nullable)
  --alertaType: string # The type value for the Alerta service. (nullable)
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<alertaApiKey: string, alertaCorrelate: string, alertaEnvironment: string, alertaEvent: string, alertaGroup: string, alertaHost: string, alertaOrigin: string, alertaResource: string, alertaService: string, alertaSeverity: string, alertaStatus: string, alertaTags: string, alertaType: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-alerta/($id)")
  let body = {alertaApiKey: $alertaApiKey, alertaCorrelate: $alertaCorrelate, alertaEnvironment: $alertaEnvironment, alertaEvent: $alertaEvent, alertaGroup: $alertaGroup, alertaHost: $alertaHost, alertaOrigin: $alertaOrigin, alertaResource: $alertaResource, alertaService: $alertaService, alertaSeverity: $alertaSeverity, alertaStatus: $alertaStatus, alertaTags: $alertaTags, alertaType: $alertaType, dataSegmentCode: $dataSegmentCode, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportAllMySms resources.
#
# GET /api/transport-all-my-sms
# operationId: api_transport-all-my-sms_get_collection
export def "transport-all-my-sms collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<allMySmsApiKey: string, allMySmsFrom: string, allMySmsLogin: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-all-my-sms" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportAllMySms resource.
#
# POST /api/transport-all-my-sms
# operationId: api_transport-all-my-sms_post
export def "transport-all-my-sms post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --allMySmsApiKey: string # The API key for the Allmysms service. Stored in encrypted format. (nullable)
  --allMySmsFrom: string # The sender value (default 36180) for the Allmysms service. (nullable)
  --allMySmsLogin: string # The login credential for the Allmysms service. (nullable)
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<allMySmsApiKey: string, allMySmsFrom: string, allMySmsLogin: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-all-my-sms")
  let body = {allMySmsApiKey: $allMySmsApiKey, allMySmsFrom: $allMySmsFrom, allMySmsLogin: $allMySmsLogin, dataSegmentCode: $dataSegmentCode, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-all-my-sms/($id)")
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
  let full_url = (build-url $base $"/api/transport-all-my-sms/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportAllMySms resource.
#
# PUT /api/transport-all-my-sms/{id}
# operationId: api_transport-all-my-sms_id_put
export def "transport-all-my-sms put" [
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
  --allMySmsApiKey: string # The API key for the Allmysms service. Stored in encrypted format. (nullable)
  --allMySmsFrom: string # The sender value (default 36180) for the Allmysms service. (nullable)
  --allMySmsLogin: string # The login credential for the Allmysms service. (nullable)
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<allMySmsApiKey: string, allMySmsFrom: string, allMySmsLogin: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-all-my-sms/($id)")
  let body = {allMySmsApiKey: $allMySmsApiKey, allMySmsFrom: $allMySmsFrom, allMySmsLogin: $allMySmsLogin, dataSegmentCode: $dataSegmentCode, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportAmazonSns resources.
#
# GET /api/transport-amazon-sns
# operationId: api_transport-amazon-sns_get_collection
export def "transport-amazon-sns collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<amazonSnsAccessKey: string, amazonSnsRegion: string, amazonSnsSecretKey: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-amazon-sns" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportAmazonSns resource.
#
# POST /api/transport-amazon-sns
# operationId: api_transport-amazon-sns_post
export def "transport-amazon-sns post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --amazonSnsAccessKey: string # The access key for the Amazon SNS service. (nullable)
  --amazonSnsRegion: string # The region for the Amazon SNS service. (nullable)
  --amazonSnsSecretKey: string # The secret key for the Amazon SNS service. Stored in encrypted format. (nullable)
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<amazonSnsAccessKey: string, amazonSnsRegion: string, amazonSnsSecretKey: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-amazon-sns")
  let body = {amazonSnsAccessKey: $amazonSnsAccessKey, amazonSnsRegion: $amazonSnsRegion, amazonSnsSecretKey: $amazonSnsSecretKey, dataSegmentCode: $dataSegmentCode, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-amazon-sns/($id)")
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
  let full_url = (build-url $base $"/api/transport-amazon-sns/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportAmazonSns resource.
#
# PUT /api/transport-amazon-sns/{id}
# operationId: api_transport-amazon-sns_id_put
export def "transport-amazon-sns put" [
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
  --amazonSnsAccessKey: string # The access key for the Amazon SNS service. (nullable)
  --amazonSnsRegion: string # The region for the Amazon SNS service. (nullable)
  --amazonSnsSecretKey: string # The secret key for the Amazon SNS service. Stored in encrypted format. (nullable)
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<amazonSnsAccessKey: string, amazonSnsRegion: string, amazonSnsSecretKey: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-amazon-sns/($id)")
  let body = {amazonSnsAccessKey: $amazonSnsAccessKey, amazonSnsRegion: $amazonSnsRegion, amazonSnsSecretKey: $amazonSnsSecretKey, dataSegmentCode: $dataSegmentCode, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportBandwidth resources.
#
# GET /api/transport-bandwidth
# operationId: api_transport-bandwidth_get_collection
export def "transport-bandwidth collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<bandwidthAccountId: string, bandwidthApplicationId: string, bandwidthFrom: string, bandwidthPassword: string, bandwidthUsername: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-bandwidth" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportBandwidth resource.
#
# POST /api/transport-bandwidth
# operationId: api_transport-bandwidth_post
export def "transport-bandwidth post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --bandwidthAccountId: string # The account ID value for the Bandwidth service. (nullable)
  --bandwidthApplicationId: string # The application ID value for the Bandwidth service. (nullable)
  --bandwidthFrom: string # The from value for the Bandwidth service. (nullable)
  --bandwidthPassword: string # The password for the Bandwidth service. Stored in encrypted format. (nullable)
  --bandwidthUsername: string # The username for the Bandwidth service. (nullable)
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<bandwidthAccountId: string, bandwidthApplicationId: string, bandwidthFrom: string, bandwidthPassword: string, bandwidthUsername: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-bandwidth")
  let body = {bandwidthAccountId: $bandwidthAccountId, bandwidthApplicationId: $bandwidthApplicationId, bandwidthFrom: $bandwidthFrom, bandwidthPassword: $bandwidthPassword, bandwidthUsername: $bandwidthUsername, dataSegmentCode: $dataSegmentCode, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-bandwidth/($id)")
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
  let full_url = (build-url $base $"/api/transport-bandwidth/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportBandwidth resource.
#
# PUT /api/transport-bandwidth/{id}
# operationId: api_transport-bandwidth_id_put
export def "transport-bandwidth put" [
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
  --bandwidthAccountId: string # The account ID value for the Bandwidth service. (nullable)
  --bandwidthApplicationId: string # The application ID value for the Bandwidth service. (nullable)
  --bandwidthFrom: string # The from value for the Bandwidth service. (nullable)
  --bandwidthPassword: string # The password for the Bandwidth service. Stored in encrypted format. (nullable)
  --bandwidthUsername: string # The username for the Bandwidth service. (nullable)
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<bandwidthAccountId: string, bandwidthApplicationId: string, bandwidthFrom: string, bandwidthPassword: string, bandwidthUsername: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-bandwidth/($id)")
  let body = {bandwidthAccountId: $bandwidthAccountId, bandwidthApplicationId: $bandwidthApplicationId, bandwidthFrom: $bandwidthFrom, bandwidthPassword: $bandwidthPassword, bandwidthUsername: $bandwidthUsername, dataSegmentCode: $dataSegmentCode, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportChatwork resources.
#
# GET /api/transport-chatwork
# operationId: api_transport-chatwork_get_collection
export def "transport-chatwork collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<chatworkApiToken: string, chatworkRoomId: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-chatwork" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportChatwork resource.
#
# POST /api/transport-chatwork
# operationId: api_transport-chatwork_post
export def "transport-chatwork post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --chatworkApiToken: string # The API token for the Chatwork service. Stored in encrypted format. (nullable)
  --chatworkRoomId: string # The room ID for the Chatwork service. (nullable)
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<chatworkApiToken: string, chatworkRoomId: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-chatwork")
  let body = {chatworkApiToken: $chatworkApiToken, chatworkRoomId: $chatworkRoomId, dataSegmentCode: $dataSegmentCode, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-chatwork/($id)")
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
  let full_url = (build-url $base $"/api/transport-chatwork/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportChatwork resource.
#
# PUT /api/transport-chatwork/{id}
# operationId: api_transport-chatwork_id_put
export def "transport-chatwork put" [
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
  --chatworkApiToken: string # The API token for the Chatwork service. Stored in encrypted format. (nullable)
  --chatworkRoomId: string # The room ID for the Chatwork service. (nullable)
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<chatworkApiToken: string, chatworkRoomId: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-chatwork/($id)")
  let body = {chatworkApiToken: $chatworkApiToken, chatworkRoomId: $chatworkRoomId, dataSegmentCode: $dataSegmentCode, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportClickSend resources.
#
# GET /api/transport-click-send
# operationId: api_transport-click-send_get_collection
export def "transport-click-send collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<clickSendApiKey: string, clickSendApiUsername: string, clickSendFrom: string, clickSendFromEmail: string, clickSendListId: string, clickSendSource: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-click-send" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportClickSend resource.
#
# POST /api/transport-click-send
# operationId: api_transport-click-send_post
export def "transport-click-send post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --clickSendApiKey: string # The API key for the ClickSend service. Stored in encrypted format. (nullable)
  --clickSendApiUsername: string # The API username for the ClickSend service. (nullable)
  --clickSendFrom: string # The from value for the ClickSend service. (nullable)
  --clickSendFromEmail: string # The from email value where replies must be emailed for the ClickSend service. (nullable, format: email)
  --clickSendListId: string # The recipient list ID value for the ClickSend service. (nullable)
  --clickSendSource: string # The source method of sending value for the ClickSend service. (nullable)
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<clickSendApiKey: string, clickSendApiUsername: string, clickSendFrom: string, clickSendFromEmail: string, clickSendListId: string, clickSendSource: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-click-send")
  let body = {clickSendApiKey: $clickSendApiKey, clickSendApiUsername: $clickSendApiUsername, clickSendFrom: $clickSendFrom, clickSendFromEmail: $clickSendFromEmail, clickSendListId: $clickSendListId, clickSendSource: $clickSendSource, dataSegmentCode: $dataSegmentCode, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-click-send/($id)")
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
  let full_url = (build-url $base $"/api/transport-click-send/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportClickSend resource.
#
# PUT /api/transport-click-send/{id}
# operationId: api_transport-click-send_id_put
export def "transport-click-send put" [
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
  --clickSendApiKey: string # The API key for the ClickSend service. Stored in encrypted format. (nullable)
  --clickSendApiUsername: string # The API username for the ClickSend service. (nullable)
  --clickSendFrom: string # The from value for the ClickSend service. (nullable)
  --clickSendFromEmail: string # The from email value where replies must be emailed for the ClickSend service. (nullable, format: email)
  --clickSendListId: string # The recipient list ID value for the ClickSend service. (nullable)
  --clickSendSource: string # The source method of sending value for the ClickSend service. (nullable)
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<clickSendApiKey: string, clickSendApiUsername: string, clickSendFrom: string, clickSendFromEmail: string, clickSendListId: string, clickSendSource: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-click-send/($id)")
  let body = {clickSendApiKey: $clickSendApiKey, clickSendApiUsername: $clickSendApiUsername, clickSendFrom: $clickSendFrom, clickSendFromEmail: $clickSendFromEmail, clickSendListId: $clickSendListId, clickSendSource: $clickSendSource, dataSegmentCode: $dataSegmentCode, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportClickatell resources.
#
# GET /api/transport-clickatell
# operationId: api_transport-clickatell_get_collection
export def "transport-clickatell collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<clickatellAccessToken: string, clickatellFrom: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-clickatell" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportClickatell resource.
#
# POST /api/transport-clickatell
# operationId: api_transport-clickatell_post
export def "transport-clickatell post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --clickatellAccessToken: string # The access token for the Clickatell service. Stored in encrypted format. (nullable)
  --clickatellFrom: string # The from value for the Clickatell service. (nullable)
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<clickatellAccessToken: string, clickatellFrom: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-clickatell")
  let body = {clickatellAccessToken: $clickatellAccessToken, clickatellFrom: $clickatellFrom, dataSegmentCode: $dataSegmentCode, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-clickatell/($id)")
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
  let full_url = (build-url $base $"/api/transport-clickatell/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportClickatell resource.
#
# PUT /api/transport-clickatell/{id}
# operationId: api_transport-clickatell_id_put
export def "transport-clickatell put" [
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
  --clickatellAccessToken: string # The access token for the Clickatell service. Stored in encrypted format. (nullable)
  --clickatellFrom: string # The from value for the Clickatell service. (nullable)
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<clickatellAccessToken: string, clickatellFrom: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-clickatell/($id)")
  let body = {clickatellAccessToken: $clickatellAccessToken, clickatellFrom: $clickatellFrom, dataSegmentCode: $dataSegmentCode, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportContactEveryone resources.
#
# GET /api/transport-contact-everyone
# operationId: api_transport-contact-everyone_get_collection
export def "transport-contact-everyone collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<contactEveryoneCategory: string, contactEveryoneDiffusionName: string, contactEveryoneToken: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-contact-everyone" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportContactEveryone resource.
#
# POST /api/transport-contact-everyone
# operationId: api_transport-contact-everyone_post
export def "transport-contact-everyone post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --contactEveryoneCategory: string # The label of the category that will be displayed in the external service event logs of the ContactEveryone service. (nullable)
  --contactEveryoneDiffusionName: string # The label of the diffusion that will be displayed in the external service event logs of the ContactEveryone service. (nullable)
  --contactEveryoneToken: string # The token for the Contact Everyone service. Stored in encrypted format. (nullable)
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<contactEveryoneCategory: string, contactEveryoneDiffusionName: string, contactEveryoneToken: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-contact-everyone")
  let body = {contactEveryoneCategory: $contactEveryoneCategory, contactEveryoneDiffusionName: $contactEveryoneDiffusionName, contactEveryoneToken: $contactEveryoneToken, dataSegmentCode: $dataSegmentCode, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-contact-everyone/($id)")
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
  let full_url = (build-url $base $"/api/transport-contact-everyone/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportContactEveryone resource.
#
# PUT /api/transport-contact-everyone/{id}
# operationId: api_transport-contact-everyone_id_put
export def "transport-contact-everyone put" [
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
  --contactEveryoneCategory: string # The label of the category that will be displayed in the external service event logs of the ContactEveryone service. (nullable)
  --contactEveryoneDiffusionName: string # The label of the diffusion that will be displayed in the external service event logs of the ContactEveryone service. (nullable)
  --contactEveryoneToken: string # The token for the Contact Everyone service. Stored in encrypted format. (nullable)
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<contactEveryoneCategory: string, contactEveryoneDiffusionName: string, contactEveryoneToken: string, createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-contact-everyone/($id)")
  let body = {contactEveryoneCategory: $contactEveryoneCategory, contactEveryoneDiffusionName: $contactEveryoneDiffusionName, contactEveryoneToken: $contactEveryoneToken, dataSegmentCode: $dataSegmentCode, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportDiscord resources.
#
# GET /api/transport-discord
# operationId: api_transport-discord_get_collection
export def "transport-discord collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, discordToken: string, discordWebhookId: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-discord" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportDiscord resource.
#
# POST /api/transport-discord
# operationId: api_transport-discord_post
export def "transport-discord post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --discordToken: string # The token for the Discord service. Stored in encrypted format. (nullable)
  --discordWebhookId: string # The webhook ID for the Discord service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, discordToken: string, discordWebhookId: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-discord")
  let body = {dataSegmentCode: $dataSegmentCode, discordToken: $discordToken, discordWebhookId: $discordWebhookId, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-discord/($id)")
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
  let full_url = (build-url $base $"/api/transport-discord/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportDiscord resource.
#
# PUT /api/transport-discord/{id}
# operationId: api_transport-discord_id_put
export def "transport-discord put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --discordToken: string # The token for the Discord service. Stored in encrypted format. (nullable)
  --discordWebhookId: string # The webhook ID for the Discord service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, discordToken: string, discordWebhookId: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-discord/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, discordToken: $discordToken, discordWebhookId: $discordWebhookId, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportEmail resources.
#
# GET /api/transport-email
# operationId: api_transport-email_get_collection
export def "transport-email collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, emailFromAddress: string, emailFromName: string, emailPassword: string, emailPort: int, emailServer: string, emailUsername: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-email" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportEmail resource.
#
# POST /api/transport-email
# operationId: api_transport-email_post
export def "transport-email post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --emailFromAddress: string # The sender email address for the SMTP Email service. (nullable, format: email)
  --emailFromName: string # The sender name for the SMTP Email service. (nullable)
  --emailPassword: string # The password for the SMTP Email service. Stored in encrypted format. (nullable)
  --emailPort: int # The port for the SMTP Email service. (nullable)
  --emailServer: string # The server for the SMTP Email service. (nullable)
  --emailUsername: string # The username for the SMTP Email service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, emailFromAddress: string, emailFromName: string, emailPassword: string, emailPort: int, emailServer: string, emailUsername: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-email")
  let body = {dataSegmentCode: $dataSegmentCode, emailFromAddress: $emailFromAddress, emailFromName: $emailFromName, emailPassword: $emailPassword, emailPort: $emailPort, emailServer: $emailServer, emailUsername: $emailUsername, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-email/($id)")
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
  let full_url = (build-url $base $"/api/transport-email/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportEmail resource.
#
# PUT /api/transport-email/{id}
# operationId: api_transport-email_id_put
export def "transport-email put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --emailFromAddress: string # The sender email address for the SMTP Email service. (nullable, format: email)
  --emailFromName: string # The sender name for the SMTP Email service. (nullable)
  --emailPassword: string # The password for the SMTP Email service. Stored in encrypted format. (nullable)
  --emailPort: int # The port for the SMTP Email service. (nullable)
  --emailServer: string # The server for the SMTP Email service. (nullable)
  --emailUsername: string # The username for the SMTP Email service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, emailFromAddress: string, emailFromName: string, emailPassword: string, emailPort: int, emailServer: string, emailUsername: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-email/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, emailFromAddress: $emailFromAddress, emailFromName: $emailFromName, emailPassword: $emailPassword, emailPort: $emailPort, emailServer: $emailServer, emailUsername: $emailUsername, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportEngagespot resources.
#
# GET /api/transport-engagespot
# operationId: api_transport-engagespot_get_collection
export def "transport-engagespot collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, engagespotApiKey: string, engagespotCampaignName: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-engagespot" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportEngagespot resource.
#
# POST /api/transport-engagespot
# operationId: api_transport-engagespot_post
export def "transport-engagespot post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --engagespotApiKey: string # The API key for the EngageSpot service. Stored in encrypted format. (nullable)
  --engagespotCampaignName: string # The campaign name for the EngageSpot service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, engagespotApiKey: string, engagespotCampaignName: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-engagespot")
  let body = {dataSegmentCode: $dataSegmentCode, engagespotApiKey: $engagespotApiKey, engagespotCampaignName: $engagespotCampaignName, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-engagespot/($id)")
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
  let full_url = (build-url $base $"/api/transport-engagespot/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportEngagespot resource.
#
# PUT /api/transport-engagespot/{id}
# operationId: api_transport-engagespot_id_put
export def "transport-engagespot put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --engagespotApiKey: string # The API key for the EngageSpot service. Stored in encrypted format. (nullable)
  --engagespotCampaignName: string # The campaign name for the EngageSpot service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, engagespotApiKey: string, engagespotCampaignName: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-engagespot/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, engagespotApiKey: $engagespotApiKey, engagespotCampaignName: $engagespotCampaignName, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportEsendex resources.
#
# GET /api/transport-esendex
# operationId: api_transport-esendex_get_collection
export def "transport-esendex collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, esendexAccountReference: string, esendexFrom: string, esendexPassword: string, esendexUsername: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-esendex" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportEsendex resource.
#
# POST /api/transport-esendex
# operationId: api_transport-esendex_post
export def "transport-esendex post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --esendexAccountReference: string # The account reference that the message should be sent from for the Esendex service. (nullable)
  --esendexFrom: string # The alphanumeric originator for the message to appear to originate from for the Esendex service. (nullable)
  --esendexPassword: string # The API password for the Esendex service. Stored in encrypted format. (nullable)
  --esendexUsername: string # The account email for the Esendex service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, esendexAccountReference: string, esendexFrom: string, esendexPassword: string, esendexUsername: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-esendex")
  let body = {dataSegmentCode: $dataSegmentCode, esendexAccountReference: $esendexAccountReference, esendexFrom: $esendexFrom, esendexPassword: $esendexPassword, esendexUsername: $esendexUsername, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-esendex/($id)")
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
  let full_url = (build-url $base $"/api/transport-esendex/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportEsendex resource.
#
# PUT /api/transport-esendex/{id}
# operationId: api_transport-esendex_id_put
export def "transport-esendex put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --esendexAccountReference: string # The account reference that the message should be sent from for the Esendex service. (nullable)
  --esendexFrom: string # The alphanumeric originator for the message to appear to originate from for the Esendex service. (nullable)
  --esendexPassword: string # The API password for the Esendex service. Stored in encrypted format. (nullable)
  --esendexUsername: string # The account email for the Esendex service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, esendexAccountReference: string, esendexFrom: string, esendexPassword: string, esendexUsername: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-esendex/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, esendexAccountReference: $esendexAccountReference, esendexFrom: $esendexFrom, esendexPassword: $esendexPassword, esendexUsername: $esendexUsername, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportExpo resources.
#
# GET /api/transport-expo
# operationId: api_transport-expo_get_collection
export def "transport-expo collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, expoToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-expo" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportExpo resource.
#
# POST /api/transport-expo
# operationId: api_transport-expo_post
export def "transport-expo post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --expoToken: string # The token for the Expo service. Stored in encrypted format. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, expoToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-expo")
  let body = {dataSegmentCode: $dataSegmentCode, expoToken: $expoToken, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-expo/($id)")
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
  let full_url = (build-url $base $"/api/transport-expo/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportExpo resource.
#
# PUT /api/transport-expo/{id}
# operationId: api_transport-expo_id_put
export def "transport-expo put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --expoToken: string # The token for the Expo service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, expoToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-expo/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, expoToken: $expoToken, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportFirebase resources.
#
# GET /api/transport-firebase
# operationId: api_transport-firebase_get_collection
export def "transport-firebase collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, firebasePassword: string, firebaseUsername: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-firebase" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportFirebase resource.
#
# POST /api/transport-firebase
# operationId: api_transport-firebase_post
export def "transport-firebase post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --firebasePassword: string # The password for the Firebase service. Stored in encrypted format. (nullable)
  --firebaseUsername: string # The username for the Firebase service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, firebasePassword: string, firebaseUsername: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-firebase")
  let body = {dataSegmentCode: $dataSegmentCode, firebasePassword: $firebasePassword, firebaseUsername: $firebaseUsername, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-firebase/($id)")
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
  let full_url = (build-url $base $"/api/transport-firebase/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportFirebase resource.
#
# PUT /api/transport-firebase/{id}
# operationId: api_transport-firebase_id_put
export def "transport-firebase put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --firebasePassword: string # The password for the Firebase service. Stored in encrypted format. (nullable)
  --firebaseUsername: string # The username for the Firebase service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, firebasePassword: string, firebaseUsername: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-firebase/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, firebasePassword: $firebasePassword, firebaseUsername: $firebaseUsername, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportFortySixElks resources.
#
# GET /api/transport-forty-six-elks
# operationId: api_transport-forty-six-elks_get_collection
export def "transport-forty-six-elks collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, fortySixElksApiPassword: string, fortySixElksApiUsername: string, fortySixElksFrom: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-forty-six-elks" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportFortySixElks resource.
#
# POST /api/transport-forty-six-elks
# operationId: api_transport-forty-six-elks_post
export def "transport-forty-six-elks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --fortySixElksApiPassword: string # The API password for the 46elks service. Stored in encrypted format. (nullable)
  --fortySixElksApiUsername: string # The API username for the 46elks service. (nullable)
  --fortySixElksFrom: string # The alphanumeric originator for the message to appear to originate from for the 46elks service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, fortySixElksApiPassword: string, fortySixElksApiUsername: string, fortySixElksFrom: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-forty-six-elks")
  let body = {dataSegmentCode: $dataSegmentCode, fortySixElksApiPassword: $fortySixElksApiPassword, fortySixElksApiUsername: $fortySixElksApiUsername, fortySixElksFrom: $fortySixElksFrom, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-forty-six-elks/($id)")
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
  let full_url = (build-url $base $"/api/transport-forty-six-elks/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportFortySixElks resource.
#
# PUT /api/transport-forty-six-elks/{id}
# operationId: api_transport-forty-six-elks_id_put
export def "transport-forty-six-elks put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --fortySixElksApiPassword: string # The API password for the 46elks service. Stored in encrypted format. (nullable)
  --fortySixElksApiUsername: string # The API username for the 46elks service. (nullable)
  --fortySixElksFrom: string # The alphanumeric originator for the message to appear to originate from for the 46elks service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, fortySixElksApiPassword: string, fortySixElksApiUsername: string, fortySixElksFrom: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-forty-six-elks/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, fortySixElksApiPassword: $fortySixElksApiPassword, fortySixElksApiUsername: $fortySixElksApiUsername, fortySixElksFrom: $fortySixElksFrom, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportFreeMobile resources.
#
# GET /api/transport-free-mobile
# operationId: api_transport-free-mobile_get_collection
export def "transport-free-mobile collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, freeMobileApiKey: string, freeMobileLogin: string, freeMobilePhone: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-free-mobile" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportFreeMobile resource.
#
# POST /api/transport-free-mobile
# operationId: api_transport-free-mobile_post
export def "transport-free-mobile post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --freeMobileApiKey: string # The API key for the Free Mobile service. Stored in encrypted format. (nullable)
  --freeMobileLogin: string # The login for the Free Mobile service. (nullable)
  --freeMobilePhone: string # The phone number for the Free Mobile service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, freeMobileApiKey: string, freeMobileLogin: string, freeMobilePhone: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-free-mobile")
  let body = {dataSegmentCode: $dataSegmentCode, freeMobileApiKey: $freeMobileApiKey, freeMobileLogin: $freeMobileLogin, freeMobilePhone: $freeMobilePhone, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-free-mobile/($id)")
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
  let full_url = (build-url $base $"/api/transport-free-mobile/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportFreeMobile resource.
#
# PUT /api/transport-free-mobile/{id}
# operationId: api_transport-free-mobile_id_put
export def "transport-free-mobile put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --freeMobileApiKey: string # The API key for the Free Mobile service. Stored in encrypted format. (nullable)
  --freeMobileLogin: string # The login for the Free Mobile service. (nullable)
  --freeMobilePhone: string # The phone number for the Free Mobile service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, freeMobileApiKey: string, freeMobileLogin: string, freeMobilePhone: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-free-mobile/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, freeMobileApiKey: $freeMobileApiKey, freeMobileLogin: $freeMobileLogin, freeMobilePhone: $freeMobilePhone, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportFreshdesk resources.
#
# GET /api/transport-freshdesk
# operationId: api_transport-freshdesk_get_collection
export def "transport-freshdesk collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, freshdeskApiKey: string, freshdeskEmail: string, freshdeskHost: string, freshdeskPriority: string, freshdeskType: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-freshdesk" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportFreshdesk resource.
#
# POST /api/transport-freshdesk
# operationId: api_transport-freshdesk_post
export def "transport-freshdesk post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --freshdeskApiKey: string # The API key for the Freshdesk service. Stored in encrypted format. (nullable)
  --freshdeskEmail: string # The requester email address for the Freshdesk service. (nullable, format: email)
  --freshdeskHost: string # The host name for the Freshdesk service (domain.freshdesk.com). (nullable, format: hostname)
  --freshdeskPriority: string # The ticket priority for the Freshdesk service. (nullable)
  --freshdeskType: string # The ticket type for the Freshdesk service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, freshdeskApiKey: string, freshdeskEmail: string, freshdeskHost: string, freshdeskPriority: string, freshdeskType: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-freshdesk")
  let body = {dataSegmentCode: $dataSegmentCode, freshdeskApiKey: $freshdeskApiKey, freshdeskEmail: $freshdeskEmail, freshdeskHost: $freshdeskHost, freshdeskPriority: $freshdeskPriority, freshdeskType: $freshdeskType, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-freshdesk/($id)")
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
  let full_url = (build-url $base $"/api/transport-freshdesk/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportFreshdesk resource.
#
# PUT /api/transport-freshdesk/{id}
# operationId: api_transport-freshdesk_id_put
export def "transport-freshdesk put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --freshdeskApiKey: string # The API key for the Freshdesk service. Stored in encrypted format. (nullable)
  --freshdeskEmail: string # The requester email address for the Freshdesk service. (nullable, format: email)
  --freshdeskHost: string # The host name for the Freshdesk service (domain.freshdesk.com). (nullable, format: hostname)
  --freshdeskPriority: string # The ticket priority for the Freshdesk service. (nullable)
  --freshdeskType: string # The ticket type for the Freshdesk service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, freshdeskApiKey: string, freshdeskEmail: string, freshdeskHost: string, freshdeskPriority: string, freshdeskType: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-freshdesk/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, freshdeskApiKey: $freshdeskApiKey, freshdeskEmail: $freshdeskEmail, freshdeskHost: $freshdeskHost, freshdeskPriority: $freshdeskPriority, freshdeskType: $freshdeskType, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportGatewayApi resources.
#
# GET /api/transport-gateway-api
# operationId: api_transport-gateway-api_get_collection
export def "transport-gateway-api collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, gatewayApiFrom: string, gatewayApiToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-gateway-api" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportGatewayApi resource.
#
# POST /api/transport-gateway-api
# operationId: api_transport-gateway-api_post
export def "transport-gateway-api post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --gatewayApiFrom: string # The sender name for the Gateway API service. (nullable)
  --gatewayApiToken: string # The token for the Gateway API service. Stored in encrypted format. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, gatewayApiFrom: string, gatewayApiToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-gateway-api")
  let body = {dataSegmentCode: $dataSegmentCode, gatewayApiFrom: $gatewayApiFrom, gatewayApiToken: $gatewayApiToken, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-gateway-api/($id)")
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
  let full_url = (build-url $base $"/api/transport-gateway-api/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportGatewayApi resource.
#
# PUT /api/transport-gateway-api/{id}
# operationId: api_transport-gateway-api_id_put
export def "transport-gateway-api put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --gatewayApiFrom: string # The sender name for the Gateway API service. (nullable)
  --gatewayApiToken: string # The token for the Gateway API service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, gatewayApiFrom: string, gatewayApiToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-gateway-api/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, gatewayApiFrom: $gatewayApiFrom, gatewayApiToken: $gatewayApiToken, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportGitter resources.
#
# GET /api/transport-gitter
# operationId: api_transport-gitter_get_collection
export def "transport-gitter collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, gitterRoomId: string, gitterToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-gitter" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportGitter resource.
#
# POST /api/transport-gitter
# operationId: api_transport-gitter_post
export def "transport-gitter post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --gitterRoomId: string # The room ID for the Gitter service. (nullable)
  --gitterToken: string # The token for the Gitter service. Stored in encrypted format. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, gitterRoomId: string, gitterToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-gitter")
  let body = {dataSegmentCode: $dataSegmentCode, gitterRoomId: $gitterRoomId, gitterToken: $gitterToken, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-gitter/($id)")
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
  let full_url = (build-url $base $"/api/transport-gitter/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportGitter resource.
#
# PUT /api/transport-gitter/{id}
# operationId: api_transport-gitter_id_put
export def "transport-gitter put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --gitterRoomId: string # The room ID for the Gitter service. (nullable)
  --gitterToken: string # The token for the Gitter service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, gitterRoomId: string, gitterToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-gitter/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, gitterRoomId: $gitterRoomId, gitterToken: $gitterToken, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportGoogleChat resources.
#
# GET /api/transport-google-chat
# operationId: api_transport-google-chat_get_collection
export def "transport-google-chat collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, googleChatAccessKey: string, googleChatAccessToken: string, googleChatSpace: string, googleChatThreadKey: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-google-chat" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportGoogleChat resource.
#
# POST /api/transport-google-chat
# operationId: api_transport-google-chat_post
export def "transport-google-chat post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --googleChatAccessKey: string # The access key for the Google Chat service. (nullable)
  --googleChatAccessToken: string # The access token for the Google Chat service. Stored in encrypted format. (nullable)
  --googleChatSpace: string # The space name for the Google Chat service. (nullable)
  --googleChatThreadKey: string # The optional thread key for the Google Chat service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, googleChatAccessKey: string, googleChatAccessToken: string, googleChatSpace: string, googleChatThreadKey: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-google-chat")
  let body = {dataSegmentCode: $dataSegmentCode, googleChatAccessKey: $googleChatAccessKey, googleChatAccessToken: $googleChatAccessToken, googleChatSpace: $googleChatSpace, googleChatThreadKey: $googleChatThreadKey, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-google-chat/($id)")
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
  let full_url = (build-url $base $"/api/transport-google-chat/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportGoogleChat resource.
#
# PUT /api/transport-google-chat/{id}
# operationId: api_transport-google-chat_id_put
export def "transport-google-chat put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --googleChatAccessKey: string # The access key for the Google Chat service. (nullable)
  --googleChatAccessToken: string # The access token for the Google Chat service. Stored in encrypted format. (nullable)
  --googleChatSpace: string # The space name for the Google Chat service. (nullable)
  --googleChatThreadKey: string # The optional thread key for the Google Chat service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, googleChatAccessKey: string, googleChatAccessToken: string, googleChatSpace: string, googleChatThreadKey: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-google-chat/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, googleChatAccessKey: $googleChatAccessKey, googleChatAccessToken: $googleChatAccessToken, googleChatSpace: $googleChatSpace, googleChatThreadKey: $googleChatThreadKey, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportGotify resources.
#
# GET /api/transport-gotify
# operationId: api_transport-gotify_get_collection
export def "transport-gotify collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, gotifyApiUrl: string, gotifyAppToken: string, gotifyPriority: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-gotify" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportGotify resource.
#
# POST /api/transport-gotify
# operationId: api_transport-gotify_post
export def "transport-gotify post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --gotifyApiUrl: string # The API URL name for the Gotify service (https://example.com) - (do not include the path /message/createMessage). (nullable, format: uri)
  --gotifyAppToken: string # The app token for the Gotify service. Stored in encrypted format. (nullable)
  --gotifyPriority: string # The priority for the Gotify service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, gotifyApiUrl: string, gotifyAppToken: string, gotifyPriority: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-gotify")
  let body = {dataSegmentCode: $dataSegmentCode, gotifyApiUrl: $gotifyApiUrl, gotifyAppToken: $gotifyAppToken, gotifyPriority: $gotifyPriority, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-gotify/($id)")
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
  let full_url = (build-url $base $"/api/transport-gotify/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportGotify resource.
#
# PUT /api/transport-gotify/{id}
# operationId: api_transport-gotify_id_put
export def "transport-gotify put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --gotifyApiUrl: string # The API URL name for the Gotify service (https://example.com) - (do not include the path /message/createMessage). (nullable, format: uri)
  --gotifyAppToken: string # The app token for the Gotify service. Stored in encrypted format. (nullable)
  --gotifyPriority: string # The priority for the Gotify service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, gotifyApiUrl: string, gotifyAppToken: string, gotifyPriority: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-gotify/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, gotifyApiUrl: $gotifyApiUrl, gotifyAppToken: $gotifyAppToken, gotifyPriority: $gotifyPriority, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportHelpScout resources.
#
# GET /api/transport-help-scout
# operationId: api_transport-help-scout_get_collection
export def "transport-help-scout collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, helpScoutCustomerEmail: string, helpScoutMailboxId: int, helpScoutOauthToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-help-scout" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportHelpScout resource.
#
# POST /api/transport-help-scout
# operationId: api_transport-help-scout_post
export def "transport-help-scout post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --helpScoutCustomerEmail: string # The requester customer email address for the HelpScout service. (nullable, format: email)
  --helpScoutMailboxId: int # The mailbox ID for the HelpScout service. (nullable)
  --helpScoutOauthToken: string # The OAuth token for the HelpScout service. Stored in encrypted format. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, helpScoutCustomerEmail: string, helpScoutMailboxId: int, helpScoutOauthToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-help-scout")
  let body = {dataSegmentCode: $dataSegmentCode, helpScoutCustomerEmail: $helpScoutCustomerEmail, helpScoutMailboxId: $helpScoutMailboxId, helpScoutOauthToken: $helpScoutOauthToken, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-help-scout/($id)")
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
  let full_url = (build-url $base $"/api/transport-help-scout/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportHelpScout resource.
#
# PUT /api/transport-help-scout/{id}
# operationId: api_transport-help-scout_id_put
export def "transport-help-scout put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --helpScoutCustomerEmail: string # The requester customer email address for the HelpScout service. (nullable, format: email)
  --helpScoutMailboxId: int # The mailbox ID for the HelpScout service. (nullable)
  --helpScoutOauthToken: string # The OAuth token for the HelpScout service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, helpScoutCustomerEmail: string, helpScoutMailboxId: int, helpScoutOauthToken: string, id: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-help-scout/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, helpScoutCustomerEmail: $helpScoutCustomerEmail, helpScoutMailboxId: $helpScoutMailboxId, helpScoutOauthToken: $helpScoutOauthToken, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportInfobip resources.
#
# GET /api/transport-infobip
# operationId: api_transport-infobip_get_collection
export def "transport-infobip collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, infobipAuthToken: string, infobipFrom: string, infobipHost: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-infobip" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportInfobip resource.
#
# POST /api/transport-infobip
# operationId: api_transport-infobip_post
export def "transport-infobip post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --infobipAuthToken: string # The auth token for the Infobip service. Stored in encrypted format. (nullable)
  --infobipFrom: string # The sender value for the Infobip service. (nullable)
  --infobipHost: string # The host for the Infobip service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, infobipAuthToken: string, infobipFrom: string, infobipHost: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-infobip")
  let body = {dataSegmentCode: $dataSegmentCode, infobipAuthToken: $infobipAuthToken, infobipFrom: $infobipFrom, infobipHost: $infobipHost, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-infobip/($id)")
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
  let full_url = (build-url $base $"/api/transport-infobip/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportInfobip resource.
#
# PUT /api/transport-infobip/{id}
# operationId: api_transport-infobip_id_put
export def "transport-infobip put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --infobipAuthToken: string # The auth token for the Infobip service. Stored in encrypted format. (nullable)
  --infobipFrom: string # The sender value for the Infobip service. (nullable)
  --infobipHost: string # The host for the Infobip service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, infobipAuthToken: string, infobipFrom: string, infobipHost: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-infobip/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, infobipAuthToken: $infobipAuthToken, infobipFrom: $infobipFrom, infobipHost: $infobipHost, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportIqsms resources.
#
# GET /api/transport-iqsms
# operationId: api_transport-iqsms_get_collection
export def "transport-iqsms collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, iqsmsFrom: string, iqsmsLogin: string, iqsmsPassword: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-iqsms" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportIqsms resource.
#
# POST /api/transport-iqsms
# operationId: api_transport-iqsms_post
export def "transport-iqsms post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --iqsmsFrom: string # The sender value for the Iqsms service. (nullable)
  --iqsmsLogin: string # The login for the Iqsms service. (nullable)
  --iqsmsPassword: string # The password for the Iqsms service. Stored in encrypted format. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, iqsmsFrom: string, iqsmsLogin: string, iqsmsPassword: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-iqsms")
  let body = {dataSegmentCode: $dataSegmentCode, iqsmsFrom: $iqsmsFrom, iqsmsLogin: $iqsmsLogin, iqsmsPassword: $iqsmsPassword, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-iqsms/($id)")
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
  let full_url = (build-url $base $"/api/transport-iqsms/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportIqsms resource.
#
# PUT /api/transport-iqsms/{id}
# operationId: api_transport-iqsms_id_put
export def "transport-iqsms put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --iqsmsFrom: string # The sender value for the Iqsms service. (nullable)
  --iqsmsLogin: string # The login for the Iqsms service. (nullable)
  --iqsmsPassword: string # The password for the Iqsms service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, iqsmsFrom: string, iqsmsLogin: string, iqsmsPassword: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-iqsms/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, iqsmsFrom: $iqsmsFrom, iqsmsLogin: $iqsmsLogin, iqsmsPassword: $iqsmsPassword, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportKazInfoTeh resources.
#
# GET /api/transport-kaz-info-teh
# operationId: api_transport-kaz-info-teh_get_collection
export def "transport-kaz-info-teh collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, kazInfoTehFrom: string, kazInfoTehPassword: string, kazInfoTehUsername: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-kaz-info-teh" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportKazInfoTeh resource.
#
# POST /api/transport-kaz-info-teh
# operationId: api_transport-kaz-info-teh_post
export def "transport-kaz-info-teh post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --kazInfoTehFrom: string # The from value for the KazInfoTeh service. (nullable)
  --kazInfoTehPassword: string # The password for the KazInfoTeh service. Stored in encrypted format. (nullable)
  --kazInfoTehUsername: string # The username for the KazInfoTeh service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, kazInfoTehFrom: string, kazInfoTehPassword: string, kazInfoTehUsername: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-kaz-info-teh")
  let body = {dataSegmentCode: $dataSegmentCode, kazInfoTehFrom: $kazInfoTehFrom, kazInfoTehPassword: $kazInfoTehPassword, kazInfoTehUsername: $kazInfoTehUsername, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-kaz-info-teh/($id)")
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
  let full_url = (build-url $base $"/api/transport-kaz-info-teh/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportKazInfoTeh resource.
#
# PUT /api/transport-kaz-info-teh/{id}
# operationId: api_transport-kaz-info-teh_id_put
export def "transport-kaz-info-teh put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --kazInfoTehFrom: string # The from value for the KazInfoTeh service. (nullable)
  --kazInfoTehPassword: string # The password for the KazInfoTeh service. Stored in encrypted format. (nullable)
  --kazInfoTehUsername: string # The username for the KazInfoTeh service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, kazInfoTehFrom: string, kazInfoTehPassword: string, kazInfoTehUsername: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-kaz-info-teh/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, kazInfoTehFrom: $kazInfoTehFrom, kazInfoTehPassword: $kazInfoTehPassword, kazInfoTehUsername: $kazInfoTehUsername, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportLightSms resources.
#
# GET /api/transport-light-sms
# operationId: api_transport-light-sms_get_collection
export def "transport-light-sms collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, lightSmsLogin: string, lightSmsPhone: string, lightSmsToken: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-light-sms" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportLightSms resource.
#
# POST /api/transport-light-sms
# operationId: api_transport-light-sms_post
export def "transport-light-sms post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --lightSmsLogin: string # The login for the LightSMS service. (nullable)
  --lightSmsPhone: string # The sender phone number for the LightSMS service. (nullable)
  --lightSmsToken: string # The token for the LightSMS service. Stored in encrypted format. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, lightSmsLogin: string, lightSmsPhone: string, lightSmsToken: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-light-sms")
  let body = {dataSegmentCode: $dataSegmentCode, lightSmsLogin: $lightSmsLogin, lightSmsPhone: $lightSmsPhone, lightSmsToken: $lightSmsToken, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-light-sms/($id)")
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
  let full_url = (build-url $base $"/api/transport-light-sms/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportLightSms resource.
#
# PUT /api/transport-light-sms/{id}
# operationId: api_transport-light-sms_id_put
export def "transport-light-sms put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --lightSmsLogin: string # The login for the LightSMS service. (nullable)
  --lightSmsPhone: string # The sender phone number for the LightSMS service. (nullable)
  --lightSmsToken: string # The token for the LightSMS service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, lightSmsLogin: string, lightSmsPhone: string, lightSmsToken: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-light-sms/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, lightSmsLogin: $lightSmsLogin, lightSmsPhone: $lightSmsPhone, lightSmsToken: $lightSmsToken, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportLineNotify resources.
#
# GET /api/transport-line-notify
# operationId: api_transport-line-notify_get_collection
export def "transport-line-notify collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, lineNotifyAccessToken: string, lineNotifyStickerId: string, lineNotifyStickerPackageId: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-line-notify" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportLineNotify resource.
#
# POST /api/transport-line-notify
# operationId: api_transport-line-notify_post
export def "transport-line-notify post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --lineNotifyAccessToken: string # The access token for the LINE Notify service. Stored in encrypted format. (nullable)
  --lineNotifyStickerId: string # The sticker ID value for the LINE Notify service. (nullable)
  --lineNotifyStickerPackageId: string # The sticker package ID value for the LINE Notify service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, lineNotifyAccessToken: string, lineNotifyStickerId: string, lineNotifyStickerPackageId: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-line-notify")
  let body = {dataSegmentCode: $dataSegmentCode, lineNotifyAccessToken: $lineNotifyAccessToken, lineNotifyStickerId: $lineNotifyStickerId, lineNotifyStickerPackageId: $lineNotifyStickerPackageId, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-line-notify/($id)")
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
  let full_url = (build-url $base $"/api/transport-line-notify/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportLineNotify resource.
#
# PUT /api/transport-line-notify/{id}
# operationId: api_transport-line-notify_id_put
export def "transport-line-notify put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --lineNotifyAccessToken: string # The access token for the LINE Notify service. Stored in encrypted format. (nullable)
  --lineNotifyStickerId: string # The sticker ID value for the LINE Notify service. (nullable)
  --lineNotifyStickerPackageId: string # The sticker package ID value for the LINE Notify service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, lineNotifyAccessToken: string, lineNotifyStickerId: string, lineNotifyStickerPackageId: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-line-notify/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, lineNotifyAccessToken: $lineNotifyAccessToken, lineNotifyStickerId: $lineNotifyStickerId, lineNotifyStickerPackageId: $lineNotifyStickerPackageId, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportLinkedIn resources.
#
# GET /api/transport-linked-in
# operationId: api_transport-linked-in_get_collection
export def "transport-linked-in collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, linkedInToken: string, linkedInUserId: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-linked-in" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportLinkedIn resource.
#
# POST /api/transport-linked-in
# operationId: api_transport-linked-in_post
export def "transport-linked-in post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --linkedInToken: string # The access token for the LinkedIn service. Stored in encrypted format. (nullable)
  --linkedInUserId: string # The user ID for the LinkedIn service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, linkedInToken: string, linkedInUserId: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-linked-in")
  let body = {dataSegmentCode: $dataSegmentCode, linkedInToken: $linkedInToken, linkedInUserId: $linkedInUserId, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-linked-in/($id)")
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
  let full_url = (build-url $base $"/api/transport-linked-in/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportLinkedIn resource.
#
# PUT /api/transport-linked-in/{id}
# operationId: api_transport-linked-in_id_put
export def "transport-linked-in put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --linkedInToken: string # The access token for the LinkedIn service. Stored in encrypted format. (nullable)
  --linkedInUserId: string # The user ID for the LinkedIn service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, linkedInToken: string, linkedInUserId: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-linked-in/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, linkedInToken: $linkedInToken, linkedInUserId: $linkedInUserId, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportMailjet resources.
#
# GET /api/transport-mailjet
# operationId: api_transport-mailjet_get_collection
export def "transport-mailjet collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, mailjetFrom: string, mailjetToken: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-mailjet" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportMailjet resource.
#
# POST /api/transport-mailjet
# operationId: api_transport-mailjet_post
export def "transport-mailjet post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --mailjetFrom: string # The alphanumeric sender ID for the MailJet service. (nullable)
  --mailjetToken: string # The SMS auth token for the MailJet service. Stored in encrypted format. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, mailjetFrom: string, mailjetToken: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-mailjet")
  let body = {dataSegmentCode: $dataSegmentCode, mailjetFrom: $mailjetFrom, mailjetToken: $mailjetToken, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-mailjet/($id)")
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
  let full_url = (build-url $base $"/api/transport-mailjet/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportMailjet resource.
#
# PUT /api/transport-mailjet/{id}
# operationId: api_transport-mailjet_id_put
export def "transport-mailjet put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --mailjetFrom: string # The alphanumeric sender ID for the MailJet service. (nullable)
  --mailjetToken: string # The SMS auth token for the MailJet service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, mailjetFrom: string, mailjetToken: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-mailjet/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, mailjetFrom: $mailjetFrom, mailjetToken: $mailjetToken, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportMastodon resources.
#
# GET /api/transport-mastodon
# operationId: api_transport-mastodon_get_collection
export def "transport-mastodon collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, mastodonAccessToken: string, mastodonHost: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-mastodon" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportMastodon resource.
#
# POST /api/transport-mastodon
# operationId: api_transport-mastodon_post
export def "transport-mastodon post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --mastodonAccessToken: string # The access token for the Mastodon service. Stored in encrypted format. (nullable)
  --mastodonHost: string # The host name for the Mastodon service (omit the "https://" part). (nullable, format: hostname)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, mastodonAccessToken: string, mastodonHost: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-mastodon")
  let body = {dataSegmentCode: $dataSegmentCode, mastodonAccessToken: $mastodonAccessToken, mastodonHost: $mastodonHost, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-mastodon/($id)")
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
  let full_url = (build-url $base $"/api/transport-mastodon/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportMastodon resource.
#
# PUT /api/transport-mastodon/{id}
# operationId: api_transport-mastodon_id_put
export def "transport-mastodon put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --mastodonAccessToken: string # The access token for the Mastodon service. Stored in encrypted format. (nullable)
  --mastodonHost: string # The host name for the Mastodon service (omit the "https://" part). (nullable, format: hostname)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, mastodonAccessToken: string, mastodonHost: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-mastodon/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, mastodonAccessToken: $mastodonAccessToken, mastodonHost: $mastodonHost, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportMattermost resources.
#
# GET /api/transport-mattermost
# operationId: api_transport-mattermost_get_collection
export def "transport-mattermost collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, mattermostAccessToken: string, mattermostChannel: string, mattermostHost: string, mattermostPath: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-mattermost" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportMattermost resource.
#
# POST /api/transport-mattermost
# operationId: api_transport-mattermost_post
export def "transport-mattermost post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --mattermostAccessToken: string # The access token for the Mattermost service. Stored in encrypted format. (nullable)
  --mattermostChannel: string # The default channel ID for the Mattermost service. (nullable)
  --mattermostHost: string # The host for the Mattermost service. (nullable)
  --mattermostPath: string # The optional path for the Mattermost service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, mattermostAccessToken: string, mattermostChannel: string, mattermostHost: string, mattermostPath: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-mattermost")
  let body = {dataSegmentCode: $dataSegmentCode, mattermostAccessToken: $mattermostAccessToken, mattermostChannel: $mattermostChannel, mattermostHost: $mattermostHost, mattermostPath: $mattermostPath, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-mattermost/($id)")
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
  let full_url = (build-url $base $"/api/transport-mattermost/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportMattermost resource.
#
# PUT /api/transport-mattermost/{id}
# operationId: api_transport-mattermost_id_put
export def "transport-mattermost put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --mattermostAccessToken: string # The access token for the Mattermost service. Stored in encrypted format. (nullable)
  --mattermostChannel: string # The default channel ID for the Mattermost service. (nullable)
  --mattermostHost: string # The host for the Mattermost service. (nullable)
  --mattermostPath: string # The optional path for the Mattermost service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, mattermostAccessToken: string, mattermostChannel: string, mattermostHost: string, mattermostPath: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-mattermost/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, mattermostAccessToken: $mattermostAccessToken, mattermostChannel: $mattermostChannel, mattermostHost: $mattermostHost, mattermostPath: $mattermostPath, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportMercure resources.
#
# GET /api/transport-mercure
# operationId: api_transport-mercure_get_collection
export def "transport-mercure collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, mercureHubJwtToken: string, mercureHubUrl: string, mercureTopic: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-mercure" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportMercure resource.
#
# POST /api/transport-mercure
# operationId: api_transport-mercure_post
export def "transport-mercure post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --mercureHubJwtToken: string # The JWT token for the hub for the Mercure service. Stored in encrypted format. (nullable)
  --mercureHubUrl: string # The URL for the hub for the Mercure service. (nullable, format: uri)
  --mercureTopic: string # The optional topic for the Mercure service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, mercureHubJwtToken: string, mercureHubUrl: string, mercureTopic: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-mercure")
  let body = {dataSegmentCode: $dataSegmentCode, mercureHubJwtToken: $mercureHubJwtToken, mercureHubUrl: $mercureHubUrl, mercureTopic: $mercureTopic, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-mercure/($id)")
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
  let full_url = (build-url $base $"/api/transport-mercure/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportMercure resource.
#
# PUT /api/transport-mercure/{id}
# operationId: api_transport-mercure_id_put
export def "transport-mercure put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --mercureHubJwtToken: string # The JWT token for the hub for the Mercure service. Stored in encrypted format. (nullable)
  --mercureHubUrl: string # The URL for the hub for the Mercure service. (nullable, format: uri)
  --mercureTopic: string # The optional topic for the Mercure service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, mercureHubJwtToken: string, mercureHubUrl: string, mercureTopic: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-mercure/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, mercureHubJwtToken: $mercureHubJwtToken, mercureHubUrl: $mercureHubUrl, mercureTopic: $mercureTopic, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportMessageBird resources.
#
# GET /api/transport-message-bird
# operationId: api_transport-message-bird_get_collection
export def "transport-message-bird collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, messageBirdFrom: string, messageBirdToken: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-message-bird" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportMessageBird resource.
#
# POST /api/transport-message-bird
# operationId: api_transport-message-bird_post
export def "transport-message-bird post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --messageBirdFrom: string # The sender value for the MessageBird service. (nullable)
  --messageBirdToken: string # The token for the MessageBird service. Stored in encrypted format. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, messageBirdFrom: string, messageBirdToken: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-message-bird")
  let body = {dataSegmentCode: $dataSegmentCode, messageBirdFrom: $messageBirdFrom, messageBirdToken: $messageBirdToken, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-message-bird/($id)")
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
  let full_url = (build-url $base $"/api/transport-message-bird/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportMessageBird resource.
#
# PUT /api/transport-message-bird/{id}
# operationId: api_transport-message-bird_id_put
export def "transport-message-bird put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --messageBirdFrom: string # The sender value for the MessageBird service. (nullable)
  --messageBirdToken: string # The token for the MessageBird service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, messageBirdFrom: string, messageBirdToken: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-message-bird/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, messageBirdFrom: $messageBirdFrom, messageBirdToken: $messageBirdToken, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportMessageMedia resources.
#
# GET /api/transport-message-media
# operationId: api_transport-message-media_get_collection
export def "transport-message-media collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, messageMediaApiKey: string, messageMediaApiSecret: string, messageMediaFrom: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-message-media" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportMessageMedia resource.
#
# POST /api/transport-message-media
# operationId: api_transport-message-media_post
export def "transport-message-media post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --messageMediaApiKey: string # The API key for the MessageMedia service. (nullable)
  --messageMediaApiSecret: string # The API secret for the MessageMedia service. Stored in encrypted format. (nullable)
  --messageMediaFrom: string # The optional registered sender ID for the MessageMedia service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, messageMediaApiKey: string, messageMediaApiSecret: string, messageMediaFrom: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-message-media")
  let body = {dataSegmentCode: $dataSegmentCode, messageMediaApiKey: $messageMediaApiKey, messageMediaApiSecret: $messageMediaApiSecret, messageMediaFrom: $messageMediaFrom, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-message-media/($id)")
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
  let full_url = (build-url $base $"/api/transport-message-media/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportMessageMedia resource.
#
# PUT /api/transport-message-media/{id}
# operationId: api_transport-message-media_id_put
export def "transport-message-media put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --messageMediaApiKey: string # The API key for the MessageMedia service. (nullable)
  --messageMediaApiSecret: string # The API secret for the MessageMedia service. Stored in encrypted format. (nullable)
  --messageMediaFrom: string # The optional registered sender ID for the MessageMedia service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, messageMediaApiKey: string, messageMediaApiSecret: string, messageMediaFrom: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-message-media/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, messageMediaApiKey: $messageMediaApiKey, messageMediaApiSecret: $messageMediaApiSecret, messageMediaFrom: $messageMediaFrom, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportMicrosoftTeams resources.
#
# GET /api/transport-microsoft-teams
# operationId: api_transport-microsoft-teams_get_collection
export def "transport-microsoft-teams collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, microsoftTeamsPath: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-microsoft-teams" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportMicrosoftTeams resource.
#
# POST /api/transport-microsoft-teams
# operationId: api_transport-microsoft-teams_post
export def "transport-microsoft-teams post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --microsoftTeamsPath: string # The path (has the following format: 'webhookb2/{uuid}@{uuid}/IncomingWebhook/{id}/{uuid}') for the Microsoft Teams service. Stored in encrypted format. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, microsoftTeamsPath: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-microsoft-teams")
  let body = {dataSegmentCode: $dataSegmentCode, microsoftTeamsPath: $microsoftTeamsPath, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-microsoft-teams/($id)")
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
  let full_url = (build-url $base $"/api/transport-microsoft-teams/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportMicrosoftTeams resource.
#
# PUT /api/transport-microsoft-teams/{id}
# operationId: api_transport-microsoft-teams_id_put
export def "transport-microsoft-teams put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --microsoftTeamsPath: string # The path (has the following format: 'webhookb2/{uuid}@{uuid}/IncomingWebhook/{id}/{uuid}') for the Microsoft Teams service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, microsoftTeamsPath: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-microsoft-teams/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, microsoftTeamsPath: $microsoftTeamsPath, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportMobyt resources.
#
# GET /api/transport-mobyt
# operationId: api_transport-mobyt_get_collection
export def "transport-mobyt collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, mobytAccessToken: string, mobytFrom: string, mobytTypeQuality: string, mobytUserKey: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-mobyt" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportMobyt resource.
#
# POST /api/transport-mobyt
# operationId: api_transport-mobyt_post
export def "transport-mobyt post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --mobytAccessToken: string # The access token for the Mobyt service. Stored in encrypted format. (nullable)
  --mobytFrom: string # The sender for the Mobyt service. (nullable)
  --mobytTypeQuality: string # The quality of your message: 'N' for high, 'L' for medium, 'LL' for low, for the Mobyt service. (nullable)
  --mobytUserKey: string # The user key for the Mobyt service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, mobytAccessToken: string, mobytFrom: string, mobytTypeQuality: string, mobytUserKey: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-mobyt")
  let body = {dataSegmentCode: $dataSegmentCode, mobytAccessToken: $mobytAccessToken, mobytFrom: $mobytFrom, mobytTypeQuality: $mobytTypeQuality, mobytUserKey: $mobytUserKey, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-mobyt/($id)")
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
  let full_url = (build-url $base $"/api/transport-mobyt/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportMobyt resource.
#
# PUT /api/transport-mobyt/{id}
# operationId: api_transport-mobyt_id_put
export def "transport-mobyt put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --mobytAccessToken: string # The access token for the Mobyt service. Stored in encrypted format. (nullable)
  --mobytFrom: string # The sender for the Mobyt service. (nullable)
  --mobytTypeQuality: string # The quality of your message: 'N' for high, 'L' for medium, 'LL' for low, for the Mobyt service. (nullable)
  --mobytUserKey: string # The user key for the Mobyt service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, mobytAccessToken: string, mobytFrom: string, mobytTypeQuality: string, mobytUserKey: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-mobyt/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, mobytAccessToken: $mobytAccessToken, mobytFrom: $mobytFrom, mobytTypeQuality: $mobytTypeQuality, mobytUserKey: $mobytUserKey, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportOctopush resources.
#
# GET /api/transport-octopush
# operationId: api_transport-octopush_get_collection
export def "transport-octopush collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, octopushApiKey: string, octopushFrom: string, octopushType: string, octopushUserLogin: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-octopush" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportOctopush resource.
#
# POST /api/transport-octopush
# operationId: api_transport-octopush_post
export def "transport-octopush post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --octopushApiKey: string # The API key for the Octopush service. Stored in encrypted format. (nullable)
  --octopushFrom: string # The sender value for the Octopush service. (nullable)
  --octopushType: string # The SMS type ('XXX' = SMS LowCost; 'FR' = SMS Premium; 'WWW' = SMS World) for the Octopush service. (nullable)
  --octopushUserLogin: string # The user login (email) for the Octopush service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, octopushApiKey: string, octopushFrom: string, octopushType: string, octopushUserLogin: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-octopush")
  let body = {dataSegmentCode: $dataSegmentCode, octopushApiKey: $octopushApiKey, octopushFrom: $octopushFrom, octopushType: $octopushType, octopushUserLogin: $octopushUserLogin, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-octopush/($id)")
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
  let full_url = (build-url $base $"/api/transport-octopush/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportOctopush resource.
#
# PUT /api/transport-octopush/{id}
# operationId: api_transport-octopush_id_put
export def "transport-octopush put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --octopushApiKey: string # The API key for the Octopush service. Stored in encrypted format. (nullable)
  --octopushFrom: string # The sender value for the Octopush service. (nullable)
  --octopushType: string # The SMS type ('XXX' = SMS LowCost; 'FR' = SMS Premium; 'WWW' = SMS World) for the Octopush service. (nullable)
  --octopushUserLogin: string # The user login (email) for the Octopush service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, octopushApiKey: string, octopushFrom: string, octopushType: string, octopushUserLogin: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-octopush/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, octopushApiKey: $octopushApiKey, octopushFrom: $octopushFrom, octopushType: $octopushType, octopushUserLogin: $octopushUserLogin, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportOneSignal resources.
#
# GET /api/transport-one-signal
# operationId: api_transport-one-signal_get_collection
export def "transport-one-signal collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, oneSignalApiKey: string, oneSignalAppId: string, oneSignalDefaultRecipientId: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-one-signal" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportOneSignal resource.
#
# POST /api/transport-one-signal
# operationId: api_transport-one-signal_post
export def "transport-one-signal post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --oneSignalApiKey: string # The API (auth) key for the One Signal service. Stored in encrypted format. (nullable)
  --oneSignalAppId: string # The App ID for the One Signal service. (nullable)
  --oneSignalDefaultRecipientId: string # The optional default recipient ID for the One Signal service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, oneSignalApiKey: string, oneSignalAppId: string, oneSignalDefaultRecipientId: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-one-signal")
  let body = {dataSegmentCode: $dataSegmentCode, oneSignalApiKey: $oneSignalApiKey, oneSignalAppId: $oneSignalAppId, oneSignalDefaultRecipientId: $oneSignalDefaultRecipientId, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-one-signal/($id)")
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
  let full_url = (build-url $base $"/api/transport-one-signal/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportOneSignal resource.
#
# PUT /api/transport-one-signal/{id}
# operationId: api_transport-one-signal_id_put
export def "transport-one-signal put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --oneSignalApiKey: string # The API (auth) key for the One Signal service. Stored in encrypted format. (nullable)
  --oneSignalAppId: string # The App ID for the One Signal service. (nullable)
  --oneSignalDefaultRecipientId: string # The optional default recipient ID for the One Signal service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, oneSignalApiKey: string, oneSignalAppId: string, oneSignalDefaultRecipientId: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-one-signal/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, oneSignalApiKey: $oneSignalApiKey, oneSignalAppId: $oneSignalAppId, oneSignalDefaultRecipientId: $oneSignalDefaultRecipientId, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportOpsgenie resources.
#
# GET /api/transport-opsgenie
# operationId: api_transport-opsgenie_get_collection
export def "transport-opsgenie collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, opsgenieAlias: string, opsgenieApiKey: string, opsgenieEntity: string, opsgenieNote: string, opsgeniePriority: string, opsgenieUser: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-opsgenie" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportOpsgenie resource.
#
# POST /api/transport-opsgenie
# operationId: api_transport-opsgenie_post
export def "transport-opsgenie post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --opsgenieAlias: string # The alias for the Opsgenie service. (nullable)
  --opsgenieApiKey: string # The API key for the Opsgenie service. Stored in encrypted format. (nullable)
  --opsgenieEntity: string # The entity for the Opsgenie service. (nullable)
  --opsgenieNote: string # The note for the Opsgenie service. (nullable)
  --opsgeniePriority: string # The priority for the Opsgenie service. (nullable)
  --opsgenieUser: string # The user for the Opsgenie service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, opsgenieAlias: string, opsgenieApiKey: string, opsgenieEntity: string, opsgenieNote: string, opsgeniePriority: string, opsgenieUser: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-opsgenie")
  let body = {dataSegmentCode: $dataSegmentCode, opsgenieAlias: $opsgenieAlias, opsgenieApiKey: $opsgenieApiKey, opsgenieEntity: $opsgenieEntity, opsgenieNote: $opsgenieNote, opsgeniePriority: $opsgeniePriority, opsgenieUser: $opsgenieUser, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-opsgenie/($id)")
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
  let full_url = (build-url $base $"/api/transport-opsgenie/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportOpsgenie resource.
#
# PUT /api/transport-opsgenie/{id}
# operationId: api_transport-opsgenie_id_put
export def "transport-opsgenie put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --opsgenieAlias: string # The alias for the Opsgenie service. (nullable)
  --opsgenieApiKey: string # The API key for the Opsgenie service. Stored in encrypted format. (nullable)
  --opsgenieEntity: string # The entity for the Opsgenie service. (nullable)
  --opsgenieNote: string # The note for the Opsgenie service. (nullable)
  --opsgeniePriority: string # The priority for the Opsgenie service. (nullable)
  --opsgenieUser: string # The user for the Opsgenie service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, opsgenieAlias: string, opsgenieApiKey: string, opsgenieEntity: string, opsgenieNote: string, opsgeniePriority: string, opsgenieUser: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-opsgenie/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, opsgenieAlias: $opsgenieAlias, opsgenieApiKey: $opsgenieApiKey, opsgenieEntity: $opsgenieEntity, opsgenieNote: $opsgenieNote, opsgeniePriority: $opsgeniePriority, opsgenieUser: $opsgenieUser, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportOrangeSms resources.
#
# GET /api/transport-orange-sms
# operationId: api_transport-orange-sms_get_collection
export def "transport-orange-sms collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, orangeSmsClientId: string, orangeSmsClientSecret: string, orangeSmsFrom: string, orangeSmsSenderName: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-orange-sms" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportOrangeSms resource.
#
# POST /api/transport-orange-sms
# operationId: api_transport-orange-sms_post
export def "transport-orange-sms post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --orangeSmsClientId: string # The app client ID for the Orange SMS service. (nullable)
  --orangeSmsClientSecret: string # The app client secret for the Orange SMS service. Stored in encrypted format. (nullable)
  --orangeSmsFrom: string # The sender phone number for the Orange SMS service. (nullable)
  --orangeSmsSenderName: string # The sender name for the Orange SMS service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, orangeSmsClientId: string, orangeSmsClientSecret: string, orangeSmsFrom: string, orangeSmsSenderName: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-orange-sms")
  let body = {dataSegmentCode: $dataSegmentCode, orangeSmsClientId: $orangeSmsClientId, orangeSmsClientSecret: $orangeSmsClientSecret, orangeSmsFrom: $orangeSmsFrom, orangeSmsSenderName: $orangeSmsSenderName, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-orange-sms/($id)")
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
  let full_url = (build-url $base $"/api/transport-orange-sms/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportOrangeSms resource.
#
# PUT /api/transport-orange-sms/{id}
# operationId: api_transport-orange-sms_id_put
export def "transport-orange-sms put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --orangeSmsClientId: string # The app client ID for the Orange SMS service. (nullable)
  --orangeSmsClientSecret: string # The app client secret for the Orange SMS service. Stored in encrypted format. (nullable)
  --orangeSmsFrom: string # The sender phone number for the Orange SMS service. (nullable)
  --orangeSmsSenderName: string # The sender name for the Orange SMS service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, orangeSmsClientId: string, orangeSmsClientSecret: string, orangeSmsFrom: string, orangeSmsSenderName: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-orange-sms/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, orangeSmsClientId: $orangeSmsClientId, orangeSmsClientSecret: $orangeSmsClientSecret, orangeSmsFrom: $orangeSmsFrom, orangeSmsSenderName: $orangeSmsSenderName, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportOvhCloud resources.
#
# GET /api/transport-ovh-cloud
# operationId: api_transport-ovh-cloud_get_collection
export def "transport-ovh-cloud collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, ovhCloudApplicationKey: string, ovhCloudApplicationSecret: string, ovhCloudConsumerKey: string, ovhCloudSender: string, ovhCloudServiceName: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-ovh-cloud" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportOvhCloud resource.
#
# POST /api/transport-ovh-cloud
# operationId: api_transport-ovh-cloud_post
export def "transport-ovh-cloud post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --ovhCloudApplicationKey: string # The application key for the OVHcloud service. (nullable)
  --ovhCloudApplicationSecret: string # The application secret for the OVHcloud service. Stored in encrypted format. (nullable)
  --ovhCloudConsumerKey: string # The consumer key for the OVHcloud service. (nullable)
  --ovhCloudSender: string # The optional sender for the OVHcloud service. (nullable)
  --ovhCloudServiceName: string # The service name for the OVHcloud service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, ovhCloudApplicationKey: string, ovhCloudApplicationSecret: string, ovhCloudConsumerKey: string, ovhCloudSender: string, ovhCloudServiceName: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-ovh-cloud")
  let body = {dataSegmentCode: $dataSegmentCode, ovhCloudApplicationKey: $ovhCloudApplicationKey, ovhCloudApplicationSecret: $ovhCloudApplicationSecret, ovhCloudConsumerKey: $ovhCloudConsumerKey, ovhCloudSender: $ovhCloudSender, ovhCloudServiceName: $ovhCloudServiceName, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-ovh-cloud/($id)")
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
  let full_url = (build-url $base $"/api/transport-ovh-cloud/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportOvhCloud resource.
#
# PUT /api/transport-ovh-cloud/{id}
# operationId: api_transport-ovh-cloud_id_put
export def "transport-ovh-cloud put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --ovhCloudApplicationKey: string # The application key for the OVHcloud service. (nullable)
  --ovhCloudApplicationSecret: string # The application secret for the OVHcloud service. Stored in encrypted format. (nullable)
  --ovhCloudConsumerKey: string # The consumer key for the OVHcloud service. (nullable)
  --ovhCloudSender: string # The optional sender for the OVHcloud service. (nullable)
  --ovhCloudServiceName: string # The service name for the OVHcloud service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, ovhCloudApplicationKey: string, ovhCloudApplicationSecret: string, ovhCloudConsumerKey: string, ovhCloudSender: string, ovhCloudServiceName: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-ovh-cloud/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, ovhCloudApplicationKey: $ovhCloudApplicationKey, ovhCloudApplicationSecret: $ovhCloudApplicationSecret, ovhCloudConsumerKey: $ovhCloudConsumerKey, ovhCloudSender: $ovhCloudSender, ovhCloudServiceName: $ovhCloudServiceName, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportPagerDuty resources.
#
# GET /api/transport-pager-duty
# operationId: api_transport-pager-duty_get_collection
export def "transport-pager-duty collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, pagerDutyApiToken: string, pagerDutyDedupKey: string, pagerDutyEventAction: string, pagerDutyPayloadClass: string, pagerDutyPayloadComponent: string, pagerDutyPayloadGroup: string, pagerDutyPayloadSeverity: string, pagerDutyPayloadSource: string, pagerDutyRoutingKey: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-pager-duty" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportPagerDuty resource.
#
# POST /api/transport-pager-duty
# operationId: api_transport-pager-duty_post
export def "transport-pager-duty post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --pagerDutyApiToken: string # The API token for the Pager Duty service. Stored in encrypted format. (nullable)
  --pagerDutyDedupKey: string # The dedup key for the Pager Duty service. (nullable)
  --pagerDutyEventAction: string # The event action for the Pager Duty service. (nullable)
  --pagerDutyPayloadClass: string # The payload class for the Pager Duty service. (nullable)
  --pagerDutyPayloadComponent: string # The payload component for the Pager Duty service. (nullable)
  --pagerDutyPayloadGroup: string # The payload group for the Pager Duty service. (nullable)
  --pagerDutyPayloadSeverity: string # The payload severity for the Pager Duty service. (nullable)
  --pagerDutyPayloadSource: string # The payload source for the Pager Duty service. (nullable)
  --pagerDutyRoutingKey: string # The routing key for the Pager Duty service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, pagerDutyApiToken: string, pagerDutyDedupKey: string, pagerDutyEventAction: string, pagerDutyPayloadClass: string, pagerDutyPayloadComponent: string, pagerDutyPayloadGroup: string, pagerDutyPayloadSeverity: string, pagerDutyPayloadSource: string, pagerDutyRoutingKey: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-pager-duty")
  let body = {dataSegmentCode: $dataSegmentCode, pagerDutyApiToken: $pagerDutyApiToken, pagerDutyDedupKey: $pagerDutyDedupKey, pagerDutyEventAction: $pagerDutyEventAction, pagerDutyPayloadClass: $pagerDutyPayloadClass, pagerDutyPayloadComponent: $pagerDutyPayloadComponent, pagerDutyPayloadGroup: $pagerDutyPayloadGroup, pagerDutyPayloadSeverity: $pagerDutyPayloadSeverity, pagerDutyPayloadSource: $pagerDutyPayloadSource, pagerDutyRoutingKey: $pagerDutyRoutingKey, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-pager-duty/($id)")
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
  let full_url = (build-url $base $"/api/transport-pager-duty/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportPagerDuty resource.
#
# PUT /api/transport-pager-duty/{id}
# operationId: api_transport-pager-duty_id_put
export def "transport-pager-duty put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --pagerDutyApiToken: string # The API token for the Pager Duty service. Stored in encrypted format. (nullable)
  --pagerDutyDedupKey: string # The dedup key for the Pager Duty service. (nullable)
  --pagerDutyEventAction: string # The event action for the Pager Duty service. (nullable)
  --pagerDutyPayloadClass: string # The payload class for the Pager Duty service. (nullable)
  --pagerDutyPayloadComponent: string # The payload component for the Pager Duty service. (nullable)
  --pagerDutyPayloadGroup: string # The payload group for the Pager Duty service. (nullable)
  --pagerDutyPayloadSeverity: string # The payload severity for the Pager Duty service. (nullable)
  --pagerDutyPayloadSource: string # The payload source for the Pager Duty service. (nullable)
  --pagerDutyRoutingKey: string # The routing key for the Pager Duty service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, pagerDutyApiToken: string, pagerDutyDedupKey: string, pagerDutyEventAction: string, pagerDutyPayloadClass: string, pagerDutyPayloadComponent: string, pagerDutyPayloadGroup: string, pagerDutyPayloadSeverity: string, pagerDutyPayloadSource: string, pagerDutyRoutingKey: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-pager-duty/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, pagerDutyApiToken: $pagerDutyApiToken, pagerDutyDedupKey: $pagerDutyDedupKey, pagerDutyEventAction: $pagerDutyEventAction, pagerDutyPayloadClass: $pagerDutyPayloadClass, pagerDutyPayloadComponent: $pagerDutyPayloadComponent, pagerDutyPayloadGroup: $pagerDutyPayloadGroup, pagerDutyPayloadSeverity: $pagerDutyPayloadSeverity, pagerDutyPayloadSource: $pagerDutyPayloadSource, pagerDutyRoutingKey: $pagerDutyRoutingKey, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportPagerTree resources.
#
# GET /api/transport-pager-tree
# operationId: api_transport-pager-tree_get_collection
export def "transport-pager-tree collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, pagerTreeAccessToken: string, pagerTreeAccountUserId: string, pagerTreeRouterId: string, pagerTreeTeamId: string, pagerTreeUrgency: string, partition: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-pager-tree" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportPagerTree resource.
#
# POST /api/transport-pager-tree
# operationId: api_transport-pager-tree_post
export def "transport-pager-tree post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --pagerTreeAccessToken: string # The access token for the Pager Tree service. Stored in encrypted format. (nullable)
  --pagerTreeAccountUserId: string # The account user ID for the Pager Tree service. (Must supply either team ID, router ID or account user ID.) (nullable)
  --pagerTreeRouterId: string # The router ID for the Pager Tree service. (Must supply either team ID, router ID or account user ID.) (nullable)
  --pagerTreeTeamId: string # The team ID for the Pager Tree service. (Must supply either team ID, router ID or account user ID.) (nullable)
  --pagerTreeUrgency: string # The urgency for the Pager Tree service. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, pagerTreeAccessToken: string, pagerTreeAccountUserId: string, pagerTreeRouterId: string, pagerTreeTeamId: string, pagerTreeUrgency: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-pager-tree")
  let body = {dataSegmentCode: $dataSegmentCode, pagerTreeAccessToken: $pagerTreeAccessToken, pagerTreeAccountUserId: $pagerTreeAccountUserId, pagerTreeRouterId: $pagerTreeRouterId, pagerTreeTeamId: $pagerTreeTeamId, pagerTreeUrgency: $pagerTreeUrgency, partition: $partition, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-pager-tree/($id)")
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
  let full_url = (build-url $base $"/api/transport-pager-tree/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportPagerTree resource.
#
# PUT /api/transport-pager-tree/{id}
# operationId: api_transport-pager-tree_id_put
export def "transport-pager-tree put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --pagerTreeAccessToken: string # The access token for the Pager Tree service. Stored in encrypted format. (nullable)
  --pagerTreeAccountUserId: string # The account user ID for the Pager Tree service. (Must supply either team ID, router ID or account user ID.) (nullable)
  --pagerTreeRouterId: string # The router ID for the Pager Tree service. (Must supply either team ID, router ID or account user ID.) (nullable)
  --pagerTreeTeamId: string # The team ID for the Pager Tree service. (Must supply either team ID, router ID or account user ID.) (nullable)
  --pagerTreeUrgency: string # The urgency for the Pager Tree service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, pagerTreeAccessToken: string, pagerTreeAccountUserId: string, pagerTreeRouterId: string, pagerTreeTeamId: string, pagerTreeUrgency: string, partition: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-pager-tree/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, pagerTreeAccessToken: $pagerTreeAccessToken, pagerTreeAccountUserId: $pagerTreeAccountUserId, pagerTreeRouterId: $pagerTreeRouterId, pagerTreeTeamId: $pagerTreeTeamId, pagerTreeUrgency: $pagerTreeUrgency, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportPlivo resources.
#
# GET /api/transport-plivo
# operationId: api_transport-plivo_get_collection
export def "transport-plivo collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, plivoAuthId: string, plivoAuthToken: string, plivoFrom: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-plivo" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportPlivo resource.
#
# POST /api/transport-plivo
# operationId: api_transport-plivo_post
export def "transport-plivo post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --plivoAuthId: string # The auth ID for the Plivo service. (nullable)
  --plivoAuthToken: string # The auth token for the Plivo service. Stored in encrypted format. (nullable)
  --plivoFrom: string # The sender value for the Plivo service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, plivoAuthId: string, plivoAuthToken: string, plivoFrom: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-plivo")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, plivoAuthId: $plivoAuthId, plivoAuthToken: $plivoAuthToken, plivoFrom: $plivoFrom, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-plivo/($id)")
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
  let full_url = (build-url $base $"/api/transport-plivo/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportPlivo resource.
#
# PUT /api/transport-plivo/{id}
# operationId: api_transport-plivo_id_put
export def "transport-plivo put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --plivoAuthId: string # The auth ID for the Plivo service. (nullable)
  --plivoAuthToken: string # The auth token for the Plivo service. Stored in encrypted format. (nullable)
  --plivoFrom: string # The sender value for the Plivo service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, plivoAuthId: string, plivoAuthToken: string, plivoFrom: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-plivo/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, plivoAuthId: $plivoAuthId, plivoAuthToken: $plivoAuthToken, plivoFrom: $plivoFrom, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportPushbullet resources.
#
# GET /api/transport-pushbullet
# operationId: api_transport-pushbullet_get_collection
export def "transport-pushbullet collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, pushbulletAccessToken: string, pushbulletEmail: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-pushbullet" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportPushbullet resource.
#
# POST /api/transport-pushbullet
# operationId: api_transport-pushbullet_post
export def "transport-pushbullet post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --pushbulletAccessToken: string # The access token for the Pushbullet service. Stored in encrypted format. (nullable)
  --pushbulletEmail: string # The recipient email for the Pushbullet service. (nullable, format: email)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, pushbulletAccessToken: string, pushbulletEmail: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-pushbullet")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, pushbulletAccessToken: $pushbulletAccessToken, pushbulletEmail: $pushbulletEmail, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-pushbullet/($id)")
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
  let full_url = (build-url $base $"/api/transport-pushbullet/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportPushbullet resource.
#
# PUT /api/transport-pushbullet/{id}
# operationId: api_transport-pushbullet_id_put
export def "transport-pushbullet put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --pushbulletAccessToken: string # The access token for the Pushbullet service. Stored in encrypted format. (nullable)
  --pushbulletEmail: string # The recipient email for the Pushbullet service. (nullable, format: email)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, pushbulletAccessToken: string, pushbulletEmail: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-pushbullet/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, pushbulletAccessToken: $pushbulletAccessToken, pushbulletEmail: $pushbulletEmail, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportPushover resources.
#
# GET /api/transport-pushover
# operationId: api_transport-pushover_get_collection
export def "transport-pushover collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, pushoverAppToken: string, pushoverUserKey: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-pushover" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportPushover resource.
#
# POST /api/transport-pushover
# operationId: api_transport-pushover_post
export def "transport-pushover post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --pushoverAppToken: string # The app token for the Pushover service. Stored in encrypted format. (nullable)
  --pushoverUserKey: string # The user key for the Pushover service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, pushoverAppToken: string, pushoverUserKey: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-pushover")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, pushoverAppToken: $pushoverAppToken, pushoverUserKey: $pushoverUserKey, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-pushover/($id)")
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
  let full_url = (build-url $base $"/api/transport-pushover/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportPushover resource.
#
# PUT /api/transport-pushover/{id}
# operationId: api_transport-pushover_id_put
export def "transport-pushover put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --pushoverAppToken: string # The app token for the Pushover service. Stored in encrypted format. (nullable)
  --pushoverUserKey: string # The user key for the Pushover service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, pushoverAppToken: string, pushoverUserKey: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-pushover/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, pushoverAppToken: $pushoverAppToken, pushoverUserKey: $pushoverUserKey, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportPushy resources.
#
# GET /api/transport-pushy
# operationId: api_transport-pushy_get_collection
export def "transport-pushy collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, pushyApiKey: string, pushyTo: string, resourceOwner: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-pushy" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportPushy resource.
#
# POST /api/transport-pushy
# operationId: api_transport-pushy_post
export def "transport-pushy post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --pushyApiKey: string # The API key for the Pushy service. Stored in encrypted format. (nullable)
  --pushyTo: string # The recipient ID for the Pushy service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, pushyApiKey: string, pushyTo: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-pushy")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, pushyApiKey: $pushyApiKey, pushyTo: $pushyTo, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-pushy/($id)")
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
  let full_url = (build-url $base $"/api/transport-pushy/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportPushy resource.
#
# PUT /api/transport-pushy/{id}
# operationId: api_transport-pushy_id_put
export def "transport-pushy put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --pushyApiKey: string # The API key for the Pushy service. Stored in encrypted format. (nullable)
  --pushyTo: string # The recipient ID for the Pushy service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, pushyApiKey: string, pushyTo: string, resourceOwner: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-pushy/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, pushyApiKey: $pushyApiKey, pushyTo: $pushyTo, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportRingCentral resources.
#
# GET /api/transport-ring-central
# operationId: api_transport-ring-central_get_collection
export def "transport-ring-central collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, ringCentralApiToken: string, ringCentralFrom: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-ring-central" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportRingCentral resource.
#
# POST /api/transport-ring-central
# operationId: api_transport-ring-central_post
export def "transport-ring-central post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --ringCentralApiToken: string # The API token for the Ring Central service. Stored in encrypted format. (nullable)
  --ringCentralFrom: string # The sender value for the Ring Central service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, ringCentralApiToken: string, ringCentralFrom: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-ring-central")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, ringCentralApiToken: $ringCentralApiToken, ringCentralFrom: $ringCentralFrom, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-ring-central/($id)")
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
  let full_url = (build-url $base $"/api/transport-ring-central/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportRingCentral resource.
#
# PUT /api/transport-ring-central/{id}
# operationId: api_transport-ring-central_id_put
export def "transport-ring-central put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --ringCentralApiToken: string # The API token for the Ring Central service. Stored in encrypted format. (nullable)
  --ringCentralFrom: string # The sender value for the Ring Central service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, ringCentralApiToken: string, ringCentralFrom: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-ring-central/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, ringCentralApiToken: $ringCentralApiToken, ringCentralFrom: $ringCentralFrom, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportRocketChat resources.
#
# GET /api/transport-rocket-chat
# operationId: api_transport-rocket-chat_get_collection
export def "transport-rocket-chat collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, rocketChatChannel: string, rocketChatToken: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-rocket-chat" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportRocketChat resource.
#
# POST /api/transport-rocket-chat
# operationId: api_transport-rocket-chat_post
export def "transport-rocket-chat post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --rocketChatChannel: string # The channel for the Rocket Chat service. (nullable)
  --rocketChatToken: string # The access token for the Rocket Chat service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, rocketChatChannel: string, rocketChatToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-rocket-chat")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, rocketChatChannel: $rocketChatChannel, rocketChatToken: $rocketChatToken, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-rocket-chat/($id)")
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
  let full_url = (build-url $base $"/api/transport-rocket-chat/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportRocketChat resource.
#
# PUT /api/transport-rocket-chat/{id}
# operationId: api_transport-rocket-chat_id_put
export def "transport-rocket-chat put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --rocketChatChannel: string # The channel for the Rocket Chat service. (nullable)
  --rocketChatToken: string # The access token for the Rocket Chat service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, rocketChatChannel: string, rocketChatToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-rocket-chat/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, rocketChatChannel: $rocketChatChannel, rocketChatToken: $rocketChatToken, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportSendberry resources.
#
# GET /api/transport-sendberry
# operationId: api_transport-sendberry_get_collection
export def "transport-sendberry collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sendberryAuthKey: string, sendberryFrom: string, sendberryPassword: string, sendberryUsername: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-sendberry" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSendberry resource.
#
# POST /api/transport-sendberry
# operationId: api_transport-sendberry_post
export def "transport-sendberry post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --sendberryAuthKey: string # The auth key for the Sendberry service. (nullable)
  --sendberryFrom: string # The sender name or phone number for the Sendberry service. (nullable)
  --sendberryPassword: string # The password for the Sendberry service. Stored in encrypted format. (nullable)
  --sendberryUsername: string # The username for the Sendberry service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sendberryAuthKey: string, sendberryFrom: string, sendberryPassword: string, sendberryUsername: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-sendberry")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, sendberryAuthKey: $sendberryAuthKey, sendberryFrom: $sendberryFrom, sendberryPassword: $sendberryPassword, sendberryUsername: $sendberryUsername, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-sendberry/($id)")
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
  let full_url = (build-url $base $"/api/transport-sendberry/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSendberry resource.
#
# PUT /api/transport-sendberry/{id}
# operationId: api_transport-sendberry_id_put
export def "transport-sendberry put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --sendberryAuthKey: string # The auth key for the Sendberry service. (nullable)
  --sendberryFrom: string # The sender name or phone number for the Sendberry service. (nullable)
  --sendberryPassword: string # The password for the Sendberry service. Stored in encrypted format. (nullable)
  --sendberryUsername: string # The username for the Sendberry service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sendberryAuthKey: string, sendberryFrom: string, sendberryPassword: string, sendberryUsername: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-sendberry/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, sendberryAuthKey: $sendberryAuthKey, sendberryFrom: $sendberryFrom, sendberryPassword: $sendberryPassword, sendberryUsername: $sendberryUsername, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportSendinblue resources.
#
# GET /api/transport-sendinblue
# operationId: api_transport-sendinblue_get_collection
export def "transport-sendinblue collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sendinblueApiKey: string, sendinblueSenderPhone: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-sendinblue" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSendinblue resource.
#
# POST /api/transport-sendinblue
# operationId: api_transport-sendinblue_post
export def "transport-sendinblue post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --sendinblueApiKey: string # The API key for the Sendinblue service. Stored in encrypted format. (nullable)
  --sendinblueSenderPhone: string # The sender phone number for the Sendinblue service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sendinblueApiKey: string, sendinblueSenderPhone: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-sendinblue")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, sendinblueApiKey: $sendinblueApiKey, sendinblueSenderPhone: $sendinblueSenderPhone, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-sendinblue/($id)")
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
  let full_url = (build-url $base $"/api/transport-sendinblue/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSendinblue resource.
#
# PUT /api/transport-sendinblue/{id}
# operationId: api_transport-sendinblue_id_put
export def "transport-sendinblue put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --sendinblueApiKey: string # The API key for the Sendinblue service. Stored in encrypted format. (nullable)
  --sendinblueSenderPhone: string # The sender phone number for the Sendinblue service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sendinblueApiKey: string, sendinblueSenderPhone: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-sendinblue/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, sendinblueApiKey: $sendinblueApiKey, sendinblueSenderPhone: $sendinblueSenderPhone, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportSimpleTextin resources.
#
# GET /api/transport-simple-textin
# operationId: api_transport-simple-textin_get_collection
export def "transport-simple-textin collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, simpleTextinApiKey: string, simpleTextinFrom: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-simple-textin" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSimpleTextin resource.
#
# POST /api/transport-simple-textin
# operationId: api_transport-simple-textin_post
export def "transport-simple-textin post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --simpleTextinApiKey: string # The API key for the SimpleTextin service. Stored in encrypted format. (nullable)
  --simpleTextinFrom: string # The from value for the SimpleTextin service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, simpleTextinApiKey: string, simpleTextinFrom: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-simple-textin")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, simpleTextinApiKey: $simpleTextinApiKey, simpleTextinFrom: $simpleTextinFrom, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-simple-textin/($id)")
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
  let full_url = (build-url $base $"/api/transport-simple-textin/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSimpleTextin resource.
#
# PUT /api/transport-simple-textin/{id}
# operationId: api_transport-simple-textin_id_put
export def "transport-simple-textin put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --simpleTextinApiKey: string # The API key for the SimpleTextin service. Stored in encrypted format. (nullable)
  --simpleTextinFrom: string # The from value for the SimpleTextin service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, simpleTextinApiKey: string, simpleTextinFrom: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-simple-textin/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, simpleTextinApiKey: $simpleTextinApiKey, simpleTextinFrom: $simpleTextinFrom, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportSinch resources.
#
# GET /api/transport-sinch
# operationId: api_transport-sinch_get_collection
export def "transport-sinch collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sinchAuthToken: string, sinchFrom: string, sinchServicePlanId: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-sinch" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSinch resource.
#
# POST /api/transport-sinch
# operationId: api_transport-sinch_post
export def "transport-sinch post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --sinchAuthToken: string # The auth token for the Sinch service. Stored in encrypted format. (nullable)
  --sinchFrom: string # The sender for the Sinch service. (nullable)
  --sinchServicePlanId: string # The service plan ID for the Sinch service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sinchAuthToken: string, sinchFrom: string, sinchServicePlanId: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-sinch")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, sinchAuthToken: $sinchAuthToken, sinchFrom: $sinchFrom, sinchServicePlanId: $sinchServicePlanId, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-sinch/($id)")
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
  let full_url = (build-url $base $"/api/transport-sinch/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSinch resource.
#
# PUT /api/transport-sinch/{id}
# operationId: api_transport-sinch_id_put
export def "transport-sinch put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --sinchAuthToken: string # The auth token for the Sinch service. Stored in encrypted format. (nullable)
  --sinchFrom: string # The sender for the Sinch service. (nullable)
  --sinchServicePlanId: string # The service plan ID for the Sinch service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sinchAuthToken: string, sinchFrom: string, sinchServicePlanId: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-sinch/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, sinchAuthToken: $sinchAuthToken, sinchFrom: $sinchFrom, sinchServicePlanId: $sinchServicePlanId, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportSlack resources.
#
# GET /api/transport-slack
# operationId: api_transport-slack_get_collection
export def "transport-slack collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, slackChannel: string, slackToken: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-slack" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSlack resource.
#
# POST /api/transport-slack
# operationId: api_transport-slack_post
export def "transport-slack post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --slackChannel: string # The channel (channel, private group, or IM channel to send message to, it can be an encoded ID, or a name) for the Slack service. (nullable)
  --slackToken: string # The token for the Slack service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, slackChannel: string, slackToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-slack")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, slackChannel: $slackChannel, slackToken: $slackToken, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-slack/($id)")
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
  let full_url = (build-url $base $"/api/transport-slack/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSlack resource.
#
# PUT /api/transport-slack/{id}
# operationId: api_transport-slack_id_put
export def "transport-slack put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --slackChannel: string # The channel (channel, private group, or IM channel to send message to, it can be an encoded ID, or a name) for the Slack service. (nullable)
  --slackToken: string # The token for the Slack service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, slackChannel: string, slackToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-slack/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, slackChannel: $slackChannel, slackToken: $slackToken, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportSmsBiuras resources.
#
# GET /api/transport-sms-biuras
# operationId: api_transport-sms-biuras_get_collection
export def "transport-sms-biuras collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsBiurasApiKey: string, smsBiurasFrom: string, smsBiurasUid: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-sms-biuras" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSmsBiuras resource.
#
# POST /api/transport-sms-biuras
# operationId: api_transport-sms-biuras_post
export def "transport-sms-biuras post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --smsBiurasApiKey: string # The API key for the SMSBIURAS service. Stored in encrypted format. (nullable)
  --smsBiurasFrom: string # The sender for the SMSBIURAS service. (nullable)
  --smsBiurasUid: string # The client code for the SMSBIURAS service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsBiurasApiKey: string, smsBiurasFrom: string, smsBiurasUid: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-sms-biuras")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, smsBiurasApiKey: $smsBiurasApiKey, smsBiurasFrom: $smsBiurasFrom, smsBiurasUid: $smsBiurasUid, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-sms-biuras/($id)")
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
  let full_url = (build-url $base $"/api/transport-sms-biuras/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSmsBiuras resource.
#
# PUT /api/transport-sms-biuras/{id}
# operationId: api_transport-sms-biuras_id_put
export def "transport-sms-biuras put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --smsBiurasApiKey: string # The API key for the SMSBIURAS service. Stored in encrypted format. (nullable)
  --smsBiurasFrom: string # The sender for the SMSBIURAS service. (nullable)
  --smsBiurasUid: string # The client code for the SMSBIURAS service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsBiurasApiKey: string, smsBiurasFrom: string, smsBiurasUid: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-sms-biuras/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, smsBiurasApiKey: $smsBiurasApiKey, smsBiurasFrom: $smsBiurasFrom, smsBiurasUid: $smsBiurasUid, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportSmsFactor resources.
#
# GET /api/transport-sms-factor
# operationId: api_transport-sms-factor_get_collection
export def "transport-sms-factor collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsFactorPushType: string, smsFactorSender: string, smsFactorToken: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-sms-factor" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSmsFactor resource.
#
# POST /api/transport-sms-factor
# operationId: api_transport-sms-factor_post
export def "transport-sms-factor post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --smsFactorPushType: string # The push type for the SMSFactor service. (nullable)
  --smsFactorSender: string # The sender value for the SMSFactor service. (nullable)
  --smsFactorToken: string # The token for the SMSFactor service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsFactorPushType: string, smsFactorSender: string, smsFactorToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-sms-factor")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, smsFactorPushType: $smsFactorPushType, smsFactorSender: $smsFactorSender, smsFactorToken: $smsFactorToken, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-sms-factor/($id)")
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
  let full_url = (build-url $base $"/api/transport-sms-factor/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSmsFactor resource.
#
# PUT /api/transport-sms-factor/{id}
# operationId: api_transport-sms-factor_id_put
export def "transport-sms-factor put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --smsFactorPushType: string # The push type for the SMSFactor service. (nullable)
  --smsFactorSender: string # The sender value for the SMSFactor service. (nullable)
  --smsFactorToken: string # The token for the SMSFactor service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsFactorPushType: string, smsFactorSender: string, smsFactorToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-sms-factor/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, smsFactorPushType: $smsFactorPushType, smsFactorSender: $smsFactorSender, smsFactorToken: $smsFactorToken, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportSms77 resources.
#
# GET /api/transport-sms77
# operationId: api_transport-sms77_get_collection
export def "transport-sms77 collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sms77ApiKey: string, sms77From: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-sms77" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSms77 resource.
#
# POST /api/transport-sms77
# operationId: api_transport-sms77_post
export def "transport-sms77 post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --sms77ApiKey: string # The API key for the Sms77 service. Stored in encrypted format. (nullable)
  --sms77From: string # The optional sender for the Sms77 service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sms77ApiKey: string, sms77From: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-sms77")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, sms77ApiKey: $sms77ApiKey, sms77From: $sms77From, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-sms77/($id)")
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
  let full_url = (build-url $base $"/api/transport-sms77/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSms77 resource.
#
# PUT /api/transport-sms77/{id}
# operationId: api_transport-sms77_id_put
export def "transport-sms77 put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --sms77ApiKey: string # The API key for the Sms77 service. Stored in encrypted format. (nullable)
  --sms77From: string # The optional sender for the Sms77 service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, sms77ApiKey: string, sms77From: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-sms77/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, sms77ApiKey: $sms77ApiKey, sms77From: $sms77From, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportSmsapi resources.
#
# GET /api/transport-smsapi
# operationId: api_transport-smsapi_get_collection
export def "transport-smsapi collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsapiFrom: string, smsapiToken: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-smsapi" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSmsapi resource.
#
# POST /api/transport-smsapi
# operationId: api_transport-smsapi_post
export def "transport-smsapi post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --smsapiFrom: string # The sender name for the SMS API service. (nullable)
  --smsapiToken: string # The API token for the SMS API service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsapiFrom: string, smsapiToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-smsapi")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, smsapiFrom: $smsapiFrom, smsapiToken: $smsapiToken, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-smsapi/($id)")
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
  let full_url = (build-url $base $"/api/transport-smsapi/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSmsapi resource.
#
# PUT /api/transport-smsapi/{id}
# operationId: api_transport-smsapi_id_put
export def "transport-smsapi put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --smsapiFrom: string # The sender name for the SMS API service. (nullable)
  --smsapiToken: string # The API token for the SMS API service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsapiFrom: string, smsapiToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-smsapi/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, smsapiFrom: $smsapiFrom, smsapiToken: $smsapiToken, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportSmsc resources.
#
# GET /api/transport-smsc
# operationId: api_transport-smsc_get_collection
export def "transport-smsc collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smscFrom: string, smscLogin: string, smscPassword: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-smsc" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSmsc resource.
#
# POST /api/transport-smsc
# operationId: api_transport-smsc_post
export def "transport-smsc post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --smscFrom: string # The sender (NB: text identity, not a phone number) for the Smsc service. (nullable)
  --smscLogin: string # The login for the Smsc service. (nullable)
  --smscPassword: string # The API password for the Smsc service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smscFrom: string, smscLogin: string, smscPassword: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-smsc")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, smscFrom: $smscFrom, smscLogin: $smscLogin, smscPassword: $smscPassword, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-smsc/($id)")
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
  let full_url = (build-url $base $"/api/transport-smsc/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSmsc resource.
#
# PUT /api/transport-smsc/{id}
# operationId: api_transport-smsc_id_put
export def "transport-smsc put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --smscFrom: string # The sender (NB: text identity, not a phone number) for the Smsc service. (nullable)
  --smscLogin: string # The login for the Smsc service. (nullable)
  --smscPassword: string # The API password for the Smsc service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smscFrom: string, smscLogin: string, smscPassword: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-smsc/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, smscFrom: $smscFrom, smscLogin: $smscLogin, smscPassword: $smscPassword, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportSmsmode resources.
#
# GET /api/transport-smsmode
# operationId: api_transport-smsmode_get_collection
export def "transport-smsmode collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsmodeApiKey: string, smsmodeFrom: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-smsmode" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSmsmode resource.
#
# POST /api/transport-smsmode
# operationId: api_transport-smsmode_post
export def "transport-smsmode post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --smsmodeApiKey: string # The API key for the Smsmode service. Stored in encrypted format. (nullable)
  --smsmodeFrom: string # The from value for the Smsmode service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsmodeApiKey: string, smsmodeFrom: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-smsmode")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, smsmodeApiKey: $smsmodeApiKey, smsmodeFrom: $smsmodeFrom, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-smsmode/($id)")
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
  let full_url = (build-url $base $"/api/transport-smsmode/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSmsmode resource.
#
# PUT /api/transport-smsmode/{id}
# operationId: api_transport-smsmode_id_put
export def "transport-smsmode put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --smsmodeApiKey: string # The API key for the Smsmode service. Stored in encrypted format. (nullable)
  --smsmodeFrom: string # The from value for the Smsmode service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, smsmodeApiKey: string, smsmodeFrom: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-smsmode/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, smsmodeApiKey: $smsmodeApiKey, smsmodeFrom: $smsmodeFrom, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportSpotHit resources.
#
# GET /api/transport-spot-hit
# operationId: api_transport-spot-hit_get_collection
export def "transport-spot-hit collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, spotHitFrom: string, spotHitToken: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-spot-hit" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportSpotHit resource.
#
# POST /api/transport-spot-hit
# operationId: api_transport-spot-hit_post
export def "transport-spot-hit post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --spotHitFrom: string # The sender (3-11 letters, default is a 5 digits phone number) for the Spot-Hit service. (nullable)
  --spotHitToken: string # The API token for the Spot-Hit service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, spotHitFrom: string, spotHitToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-spot-hit")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, spotHitFrom: $spotHitFrom, spotHitToken: $spotHitToken, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-spot-hit/($id)")
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
  let full_url = (build-url $base $"/api/transport-spot-hit/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportSpotHit resource.
#
# PUT /api/transport-spot-hit/{id}
# operationId: api_transport-spot-hit_id_put
export def "transport-spot-hit put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --spotHitFrom: string # The sender (3-11 letters, default is a 5 digits phone number) for the Spot-Hit service. (nullable)
  --spotHitToken: string # The API token for the Spot-Hit service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, spotHitFrom: string, spotHitToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-spot-hit/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, spotHitFrom: $spotHitFrom, spotHitToken: $spotHitToken, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportTelegram resources.
#
# GET /api/transport-telegram
# operationId: api_transport-telegram_get_collection
export def "transport-telegram collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, telegramChatId: string, telegramToken: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-telegram" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportTelegram resource.
#
# POST /api/transport-telegram
# operationId: api_transport-telegram_post
export def "transport-telegram post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --telegramChatId: string # The chat ID for the Telegram service. (nullable)
  --telegramToken: string # The token for the Telegram service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, telegramChatId: string, telegramToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-telegram")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, telegramChatId: $telegramChatId, telegramToken: $telegramToken, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-telegram/($id)")
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
  let full_url = (build-url $base $"/api/transport-telegram/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportTelegram resource.
#
# PUT /api/transport-telegram/{id}
# operationId: api_transport-telegram_id_put
export def "transport-telegram put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --telegramChatId: string # The chat ID for the Telegram service. (nullable)
  --telegramToken: string # The token for the Telegram service. Stored in encrypted format. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, telegramChatId: string, telegramToken: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-telegram/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, telegramChatId: $telegramChatId, telegramToken: $telegramToken, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportTelnyx resources.
#
# GET /api/transport-telnyx
# operationId: api_transport-telnyx_get_collection
export def "transport-telnyx collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, telnyxApiKey: string, telnyxFrom: string, telnyxMessagingProfileId: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-telnyx" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportTelnyx resource.
#
# POST /api/transport-telnyx
# operationId: api_transport-telnyx_post
export def "transport-telnyx post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --telnyxApiKey: string # The API key for the Telnyx service. Stored in encrypted format. (nullable)
  --telnyxFrom: string # The from value for the Telnyx service. (nullable)
  --telnyxMessagingProfileId: string # The messaging profile ID (You need this in order to show a name to the recipient instead of just the phone number) for the Telnyx service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, telnyxApiKey: string, telnyxFrom: string, telnyxMessagingProfileId: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-telnyx")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, telnyxApiKey: $telnyxApiKey, telnyxFrom: $telnyxFrom, telnyxMessagingProfileId: $telnyxMessagingProfileId, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-telnyx/($id)")
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
  let full_url = (build-url $base $"/api/transport-telnyx/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportTelnyx resource.
#
# PUT /api/transport-telnyx/{id}
# operationId: api_transport-telnyx_id_put
export def "transport-telnyx put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --telnyxApiKey: string # The API key for the Telnyx service. Stored in encrypted format. (nullable)
  --telnyxFrom: string # The from value for the Telnyx service. (nullable)
  --telnyxMessagingProfileId: string # The messaging profile ID (You need this in order to show a name to the recipient instead of just the phone number) for the Telnyx service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, telnyxApiKey: string, telnyxFrom: string, telnyxMessagingProfileId: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-telnyx/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, telnyxApiKey: $telnyxApiKey, telnyxFrom: $telnyxFrom, telnyxMessagingProfileId: $telnyxMessagingProfileId, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportTermii resources.
#
# GET /api/transport-termii
# operationId: api_transport-termii_get_collection
export def "transport-termii collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, termiiApiKey: string, termiiChannel: string, termiiFrom: string, transportName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-termii" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportTermii resource.
#
# POST /api/transport-termii
# operationId: api_transport-termii_post
export def "transport-termii post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --termiiApiKey: string # The API key for the Termii service. Stored in encrypted format. (nullable)
  --termiiChannel: string # The channel for the Termii service. (nullable)
  --termiiFrom: string # The sender value for the Termii service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, termiiApiKey: string, termiiChannel: string, termiiFrom: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-termii")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, termiiApiKey: $termiiApiKey, termiiChannel: $termiiChannel, termiiFrom: $termiiFrom, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-termii/($id)")
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
  let full_url = (build-url $base $"/api/transport-termii/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportTermii resource.
#
# PUT /api/transport-termii/{id}
# operationId: api_transport-termii_id_put
export def "transport-termii put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --termiiApiKey: string # The API key for the Termii service. Stored in encrypted format. (nullable)
  --termiiChannel: string # The channel for the Termii service. (nullable)
  --termiiFrom: string # The sender value for the Termii service. (nullable)
  --transportName: string # The name of the transport. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, termiiApiKey: string, termiiChannel: string, termiiFrom: string, transportName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-termii/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, termiiApiKey: $termiiApiKey, termiiChannel: $termiiChannel, termiiFrom: $termiiFrom, transportName: $transportName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportTrello resources.
#
# GET /api/transport-trello
# operationId: api_transport-trello_get_collection
export def "transport-trello collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, trelloApiKey: string, trelloApiToken: string, trelloListId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-trello" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportTrello resource.
#
# POST /api/transport-trello
# operationId: api_transport-trello_post
export def "transport-trello post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
  --trelloApiKey: string # The API key for the Trello service. (nullable)
  --trelloApiToken: string # The API token for the Trello service. Stored in encrypted format. (nullable)
  --trelloListId: string # The list ID for the Trello service. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, trelloApiKey: string, trelloApiToken: string, trelloListId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-trello")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, transportName: $transportName, trelloApiKey: $trelloApiKey, trelloApiToken: $trelloApiToken, trelloListId: $trelloListId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-trello/($id)")
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
  let full_url = (build-url $base $"/api/transport-trello/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportTrello resource.
#
# PUT /api/transport-trello/{id}
# operationId: api_transport-trello_id_put
export def "transport-trello put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transportName: string # The name of the transport. (nullable)
  --trelloApiKey: string # The API key for the Trello service. (nullable)
  --trelloApiToken: string # The API token for the Trello service. Stored in encrypted format. (nullable)
  --trelloListId: string # The list ID for the Trello service. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, trelloApiKey: string, trelloApiToken: string, trelloListId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-trello/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, transportName: $transportName, trelloApiKey: $trelloApiKey, trelloApiToken: $trelloApiToken, trelloListId: $trelloListId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportTurboSms resources.
#
# GET /api/transport-turbo-sms
# operationId: api_transport-turbo-sms_get_collection
export def "transport-turbo-sms collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, turboSmsAuthToken: string, turboSmsFrom: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-turbo-sms" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportTurboSms resource.
#
# POST /api/transport-turbo-sms
# operationId: api_transport-turbo-sms_post
export def "transport-turbo-sms post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
  --turboSmsAuthToken: string # The auth token for the TurboSms service. Stored in encrypted format. (nullable)
  --turboSmsFrom: string # The sender name (should be alphanumeric, max 20 characters and activated in your TurboSms account) for the TurboSms service. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, turboSmsAuthToken: string, turboSmsFrom: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-turbo-sms")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, transportName: $transportName, turboSmsAuthToken: $turboSmsAuthToken, turboSmsFrom: $turboSmsFrom} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-turbo-sms/($id)")
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
  let full_url = (build-url $base $"/api/transport-turbo-sms/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportTurboSms resource.
#
# PUT /api/transport-turbo-sms/{id}
# operationId: api_transport-turbo-sms_id_put
export def "transport-turbo-sms put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transportName: string # The name of the transport. (nullable)
  --turboSmsAuthToken: string # The auth token for the TurboSms service. Stored in encrypted format. (nullable)
  --turboSmsFrom: string # The sender name (should be alphanumeric, max 20 characters and activated in your TurboSms account) for the TurboSms service. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, turboSmsAuthToken: string, turboSmsFrom: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-turbo-sms/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, transportName: $transportName, turboSmsAuthToken: $turboSmsAuthToken, turboSmsFrom: $turboSmsFrom} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportTwilio resources.
#
# GET /api/transport-twilio
# operationId: api_transport-twilio_get_collection
export def "transport-twilio collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, twilioFrom: string, twilioSid: string, twilioToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-twilio" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportTwilio resource.
#
# POST /api/transport-twilio
# operationId: api_transport-twilio_post
export def "transport-twilio post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
  --twilioFrom: string # The sender for the Twilio service. (nullable)
  --twilioSid: string # The SID for the Twilio service. (nullable)
  --twilioToken: string # The token for the Twilio service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, twilioFrom: string, twilioSid: string, twilioToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-twilio")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, transportName: $transportName, twilioFrom: $twilioFrom, twilioSid: $twilioSid, twilioToken: $twilioToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-twilio/($id)")
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
  let full_url = (build-url $base $"/api/transport-twilio/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportTwilio resource.
#
# PUT /api/transport-twilio/{id}
# operationId: api_transport-twilio_id_put
export def "transport-twilio put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transportName: string # The name of the transport. (nullable)
  --twilioFrom: string # The sender for the Twilio service. (nullable)
  --twilioSid: string # The SID for the Twilio service. (nullable)
  --twilioToken: string # The token for the Twilio service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, twilioFrom: string, twilioSid: string, twilioToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-twilio/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, transportName: $transportName, twilioFrom: $twilioFrom, twilioSid: $twilioSid, twilioToken: $twilioToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportTwitter resources.
#
# GET /api/transport-twitter
# operationId: api_transport-twitter_get_collection
export def "transport-twitter collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, twitterAccessToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-twitter" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportTwitter resource.
#
# POST /api/transport-twitter
# operationId: api_transport-twitter_post
export def "transport-twitter post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
  --twitterAccessToken: string # The access token for the Twitter service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, twitterAccessToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-twitter")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, transportName: $transportName, twitterAccessToken: $twitterAccessToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-twitter/($id)")
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
  let full_url = (build-url $base $"/api/transport-twitter/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportTwitter resource.
#
# PUT /api/transport-twitter/{id}
# operationId: api_transport-twitter_id_put
export def "transport-twitter put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transportName: string # The name of the transport. (nullable)
  --twitterAccessToken: string # The access token for the Twitter service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, twitterAccessToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-twitter/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, transportName: $transportName, twitterAccessToken: $twitterAccessToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportVonage resources.
#
# GET /api/transport-vonage
# operationId: api_transport-vonage_get_collection
export def "transport-vonage collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, vonageFrom: string, vonageKey: string, vonageSecret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-vonage" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportVonage resource.
#
# POST /api/transport-vonage
# operationId: api_transport-vonage_post
export def "transport-vonage post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
  --vonageFrom: string # The sender for the Vonage service. (nullable)
  --vonageKey: string # The key for the Vonage service. (nullable)
  --vonageSecret: string # The secret for the Vonage service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, vonageFrom: string, vonageKey: string, vonageSecret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-vonage")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, transportName: $transportName, vonageFrom: $vonageFrom, vonageKey: $vonageKey, vonageSecret: $vonageSecret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-vonage/($id)")
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
  let full_url = (build-url $base $"/api/transport-vonage/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportVonage resource.
#
# PUT /api/transport-vonage/{id}
# operationId: api_transport-vonage_id_put
export def "transport-vonage put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transportName: string # The name of the transport. (nullable)
  --vonageFrom: string # The sender for the Vonage service. (nullable)
  --vonageKey: string # The key for the Vonage service. (nullable)
  --vonageSecret: string # The secret for the Vonage service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, vonageFrom: string, vonageKey: string, vonageSecret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-vonage/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, transportName: $transportName, vonageFrom: $vonageFrom, vonageKey: $vonageKey, vonageSecret: $vonageSecret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportWebhook resources.
#
# GET /api/transport-webhook
# operationId: api_transport-webhook_get_collection
export def "transport-webhook collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, httpMethodCode: string, id: string, mustBeEncryptedValue: string, partition: string, resourceOwner: string, transportName: string, webhookHeaders: list<string>, webhookUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-webhook" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportWebhook resource.
#
# POST /api/transport-webhook
# operationId: api_transport-webhook_post
export def "transport-webhook post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  httpMethodCode: string # The HTTP request method that must be used. (format: iri-reference)
  --mustBeEncryptedValue: string # An optional and arbitrary secret value that must be stored in encrypted format, such as an access token. In the webhookUrl and/or webhookHeaders fields, use the special ENCRYPTED_VALUE placeholder (must be uppercase), which we will replace with the decrypted secret value when using the transport. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
  --webhookHeaders: list # The HTTP request headers, if any, for the Webhook service. To use the encrypted value:  E.g., Authorization: Bearer ENCRYPTED_VALUE. (nullable)
  --webhookUrl: string # The URL for the Webhook service. (nullable, format: uri)
]: any -> record<createdAt: string, dataSegmentCode: string, httpMethodCode: string, id: string, mustBeEncryptedValue: string, partition: string, resourceOwner: string, transportName: string, webhookHeaders: list<string>, webhookUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-webhook")
  let body = {dataSegmentCode: $dataSegmentCode, httpMethodCode: $httpMethodCode, mustBeEncryptedValue: $mustBeEncryptedValue, partition: $partition, transportName: $transportName, webhookHeaders: $webhookHeaders, webhookUrl: $webhookUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-webhook/($id)")
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
  let full_url = (build-url $base $"/api/transport-webhook/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportWebhook resource.
#
# PUT /api/transport-webhook/{id}
# operationId: api_transport-webhook_id_put
export def "transport-webhook put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  httpMethodCode: string # The HTTP request method that must be used. (format: iri-reference)
  --mustBeEncryptedValue: string # An optional and arbitrary secret value that must be stored in encrypted format, such as an access token. In the webhookUrl and/or webhookHeaders fields, use the special ENCRYPTED_VALUE placeholder (must be uppercase), which we will replace with the decrypted secret value when using the transport. (nullable)
  --transportName: string # The name of the transport. (nullable)
  --webhookHeaders: list # The HTTP request headers, if any, for the Webhook service. To use the encrypted value:  E.g., Authorization: Bearer ENCRYPTED_VALUE. (nullable)
  --webhookUrl: string # The URL for the Webhook service. (nullable, format: uri)
]: any -> record<createdAt: string, dataSegmentCode: string, httpMethodCode: string, id: string, mustBeEncryptedValue: string, partition: string, resourceOwner: string, transportName: string, webhookHeaders: list<string>, webhookUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-webhook/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, httpMethodCode: $httpMethodCode, mustBeEncryptedValue: $mustBeEncryptedValue, transportName: $transportName, webhookHeaders: $webhookHeaders, webhookUrl: $webhookUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportYunpian resources.
#
# GET /api/transport-yunpian
# operationId: api_transport-yunpian_get_collection
export def "transport-yunpian collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, yunpianApiKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-yunpian" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportYunpian resource.
#
# POST /api/transport-yunpian
# operationId: api_transport-yunpian_post
export def "transport-yunpian post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
  --yunpianApiKey: string # The API key for the Yunpian service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, yunpianApiKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-yunpian")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, transportName: $transportName, yunpianApiKey: $yunpianApiKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-yunpian/($id)")
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
  let full_url = (build-url $base $"/api/transport-yunpian/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportYunpian resource.
#
# PUT /api/transport-yunpian/{id}
# operationId: api_transport-yunpian_id_put
export def "transport-yunpian put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transportName: string # The name of the transport. (nullable)
  --yunpianApiKey: string # The API key for the Yunpian service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, yunpianApiKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-yunpian/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, transportName: $transportName, yunpianApiKey: $yunpianApiKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportZendesk resources.
#
# GET /api/transport-zendesk
# operationId: api_transport-zendesk_get_collection
export def "transport-zendesk collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, zendeskEmail: string, zendeskHost: string, zendeskToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-zendesk" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportZendesk resource.
#
# POST /api/transport-zendesk
# operationId: api_transport-zendesk_post
export def "transport-zendesk post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
  --zendeskEmail: string # The login email address for the Zendesk service. (nullable, format: email)
  --zendeskHost: string # The host name for the Zendesk service (domain.zendesk.com). (nullable, format: hostname)
  --zendeskToken: string # The token for the Zendesk service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, zendeskEmail: string, zendeskHost: string, zendeskToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-zendesk")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, transportName: $transportName, zendeskEmail: $zendeskEmail, zendeskHost: $zendeskHost, zendeskToken: $zendeskToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-zendesk/($id)")
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
  let full_url = (build-url $base $"/api/transport-zendesk/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportZendesk resource.
#
# PUT /api/transport-zendesk/{id}
# operationId: api_transport-zendesk_id_put
export def "transport-zendesk put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transportName: string # The name of the transport. (nullable)
  --zendeskEmail: string # The login email address for the Zendesk service. (nullable, format: email)
  --zendeskHost: string # The host name for the Zendesk service (domain.zendesk.com). (nullable, format: hostname)
  --zendeskToken: string # The token for the Zendesk service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, zendeskEmail: string, zendeskHost: string, zendeskToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-zendesk/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, transportName: $transportName, zendeskEmail: $zendeskEmail, zendeskHost: $zendeskHost, zendeskToken: $zendeskToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of TransportZulip resources.
#
# GET /api/transport-zulip
# operationId: api_transport-zulip_get_collection
export def "transport-zulip collection" [
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
  --dataSegmentCode: string # allows empty value
  --dataSegmentCode: list # allows empty value
  --partition: string # allows empty value
  --partition: list # allows empty value
  --properties: list # allows empty value
]: nothing -> table<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, zulipChannel: string, zulipEmail: string, zulipHost: string, zulipToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "dataSegmentCode" $dataSegmentCode "scalar") (serialize-qp "dataSegmentCode[]" $dataSegmentCode "multi") (serialize-qp "partition" $partition "scalar") (serialize-qp "partition[]" $partition "multi") (serialize-qp "properties[]" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transport-zulip" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a TransportZulip resource.
#
# POST /api/transport-zulip
# operationId: api_transport-zulip_post
export def "transport-zulip post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  partition: string # The partition that contains this resource instance. The resource cannot be moved to another partition. (format: iri-reference)
  --transportName: string # The name of the transport. (nullable)
  --zulipChannel: string # The channel for the Zulip service. (nullable)
  --zulipEmail: string # The email for the Zulip service. (nullable)
  --zulipHost: string # The host for the Zulip service. (nullable)
  --zulipToken: string # The token for the Zulip service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, zulipChannel: string, zulipEmail: string, zulipHost: string, zulipToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/transport-zulip")
  let body = {dataSegmentCode: $dataSegmentCode, partition: $partition, transportName: $transportName, zulipChannel: $zulipChannel, zulipEmail: $zulipEmail, zulipHost: $zulipHost, zulipToken: $zulipToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/transport-zulip/($id)")
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
  let full_url = (build-url $base $"/api/transport-zulip/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the TransportZulip resource.
#
# PUT /api/transport-zulip/{id}
# operationId: api_transport-zulip_id_put
export def "transport-zulip put" [
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
  --dataSegmentCode: string # User-provided string on which to segment and filter data. Max 50 characters. (nullable)
  --transportName: string # The name of the transport. (nullable)
  --zulipChannel: string # The channel for the Zulip service. (nullable)
  --zulipEmail: string # The email for the Zulip service. (nullable)
  --zulipHost: string # The host for the Zulip service. (nullable)
  --zulipToken: string # The token for the Zulip service. Stored in encrypted format. (nullable)
]: any -> record<createdAt: string, dataSegmentCode: string, id: string, partition: string, resourceOwner: string, transportName: string, zulipChannel: string, zulipEmail: string, zulipHost: string, zulipToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/transport-zulip/($id)")
  let body = {dataSegmentCode: $dataSegmentCode, transportName: $transportName, zulipChannel: $zulipChannel, zulipEmail: $zulipEmail, zulipHost: $zulipHost, zulipToken: $zulipToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the collection of UserAccount resources.
#
# GET /api/user-account
# operationId: api_user-account_get_collection
export def "user-account collection" [
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
  --properties: list # allows empty value
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
export def "user-account-level-code collection" [
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
  --properties: list # allows empty value
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
  let full_url = (build-url $base $"/api/user-account-level-code/($id)")
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
  let full_url = (build-url $base $"/api/user-account/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the UserAccount resource.
#
# PUT /api/user-account/{id}
# operationId: api_user-account_id_put
export def "user-account put" [
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
  --creditsOveragePercentTripSwitch: int # If the credits consumed in the billing period are this percentage above the account plan's included credits, cease further consumption of credits until the end of the billing period. Any integer between 1 and 1,000. Optional. Leave blank for no limit. (nullable)
]: any -> record<accountLevelCode: string, creditsOveragePercentTripSwitch: int, email: string, firstName: string, id: string, isDelinquent: bool, lastName: string, timezoneCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user-account/($id)")
  let body = {creditsOveragePercentTripSwitch: $creditsOveragePercentTripSwitch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
