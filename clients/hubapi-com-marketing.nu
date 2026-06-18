# Auto-generated client for Marketing Events Extension vv3
# Source: https://api.apis.guru/v2/specs/hubapi.com/marketing/v3/openapi.json
# Auth: --token flag or $env.MARKETING_EVENTS_EXTENSION_TOKEN

const BASE_URL = "https://api.hubapi.com"
const DEFAULT_AUTH = "query-hapikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MARKETING_EVENTS_EXTENSION_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-hapikey" => { {headers: {}, query: $"(encode-path-segment "hapikey")=(encode-path-segment $token_val)"} }
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "private-app-legacy" => { {headers: {private-app-legacy: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.hubapi.com"] }
def auth-scheme-completer [] { ["query-hapikey" "bearer" "private-app-legacy"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "marketing-marketing-events-attendance-create create-{external-id}-{subscriber-state}" } } | get name | first)
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

# Record
#
# POST /marketing/v3/marketing-events/attendance/{externalEventId}/{subscriberState}/create
# operationId: post-/marketing/v3/marketing-events/attendance/{externalEventId}/{subscriberState}/create_create
# --inputs item shape: {interactionDateTime: int, properties?: record, vid?: int}
export def "marketing-marketing-events-attendance-create create-{external-id}-{subscriber-state}" [
  external_event_id: string
  subscriber_state: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-account-id: string # The account id associated with the marketing event
  inputs: list # List of HubSpot contacts to subscribe to the marketing event — item shape: {interactionDateTime: int, properties?: record, vid?: int}
]: any -> record<completedAt: string, errors: table<category: record, context: record, errors: list, id: string, links: record, message: string, status: string, subCategory: record>, links: record, numErrors: int, requestedAt: string, results: table<vid: int>, startedAt: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "externalAccountId" $external_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({external_event_id: (encode-path-segment $external_event_id), subscriber_state: (encode-path-segment $subscriber_state)} | format pattern "/marketing/v3/marketing-events/attendance/{external_event_id}/{subscriber_state}/create") $qp)
  let req_body = {"inputs": $inputs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Record
#
# POST /marketing/v3/marketing-events/attendance/{externalEventId}/{subscriberState}/email-create
# operationId: post-/marketing/v3/marketing-events/attendance/{externalEventId}/{subscriberState}/email-create_createByEmail
# --inputs item shape: {contactProperties?: record, email: string, interactionDateTime: int, properties?: record}
export def "marketing-marketing-events-attendance-email-create create-{external-id}-{subscriber-state}" [
  external_event_id: string
  subscriber_state: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-account-id: string # The account id associated with the marketing event
  inputs: list # List of marketing event details to create or update — item shape: {contactProperties?: record, email: string, interactionDateTime: int, properties?: record}
]: any -> record<completedAt: string, errors: table<category: record, context: record, errors: list, id: string, links: record, message: string, status: string, subCategory: record>, links: record, numErrors: int, requestedAt: string, results: table<email: string, vid: int>, startedAt: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "externalAccountId" $external_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({external_event_id: (encode-path-segment $external_event_id), subscriber_state: (encode-path-segment $subscriber_state)} | format pattern "/marketing/v3/marketing-events/attendance/{external_event_id}/{subscriber_state}/email-create") $qp)
  let req_body = {"inputs": $inputs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# POST /marketing/v3/marketing-events/events
#
# operationId: post-/marketing/v3/marketing-events/events_create
# --customProperties item shape: {name: string, persistenceTimestamp?: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, ... (9 more fields)}
export def "marketing-marketing-events-events create-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-properties: list # A list of PropertyValues. These can be whatever kind of property names and values you want. However, they must already exist on the HubSpot account's definition of the MarketingEvent Object. If they don't they will be filtered out and not set. In order to do this you'll need to create a new PropertyGroup on the HubSpot account's MarketingEvent object for your specific app and create the Custom Property you want to track on that HubSpot account. Do not create any new default properties on the MarketingEvent object as that will apply to all HubSpot accounts. — item shape: {name: string, persistenceTimestamp?: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, ... (9 more fields)}
  --end-date-time: string # The end date and time of the marketing event. (format: date-time)
  --event-cancelled: oneof<nothing, bool> # Indicates if the marketing event has been cancelled. Defaults to `false`
  --event-description: string # The description of the marketing event.
  event_name: string # The name of the marketing event.
  event_organizer: string # The name of the organizer of the marketing event.
  --event-type: string # Describes what type of event this is. For example: `WEBINAR`, `CONFERENCE`, `WORKSHOP`
  --event-url: string # A URL in the external event application where the marketing event can be managed.
  external_account_id: string # The accountId that is associated with this marketing event in the external event application.
  external_event_id: string # The id of the marketing event in the external event application.
  --start-date-time: string # The start date and time of the marketing event. (format: date-time)
]: any -> record<customProperties: table<name: string, persistenceTimestamp: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, source: string, sourceId: string, sourceLabel: string, sourceMetadata: string, sourceVid: list, timestamp: int, updatedByUserId: int, useTimestampAsPersistenceTimestamp: bool, value: string>, endDateTime: string, eventCancelled: bool, eventDescription: string, eventName: string, eventOrganizer: string, eventType: string, eventUrl: string, startDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/v3/marketing-events/events")
  let req_body = {"customProperties": $custom_properties, "endDateTime": $end_date_time, "eventCancelled": $event_cancelled, "eventDescription": $event_description, "eventName": $event_name, "eventOrganizer": $event_organizer, "eventType": $event_type, "eventUrl": $event_url, "externalAccountId": $external_account_id, "externalEventId": $external_event_id, "startDateTime": $start_date_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# POST /marketing/v3/marketing-events/events/delete
#
# operationId: post-/marketing/v3/marketing-events/events/delete_archiveBatch
# --inputs item shape: {appId: int, externalAccountId: string, externalEventId: string}
export def "marketing-marketing-events-events-delete create-archive-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  inputs: list # item shape: {appId: int, externalAccountId: string, externalEventId: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/v3/marketing-events/events/delete")
  let req_body = {"inputs": $inputs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Search for marketing events
#
# GET /marketing/v3/marketing-events/events/search
# operationId: get-/marketing/v3/marketing-events/events/search_doSearch
export def "marketing-marketing-events-events-search get-do" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The id of the marketing event in the external event application
]: nothing -> record<results: table<appId: int, externalAccountId: string, externalEventId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/marketing/v3/marketing-events/events/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# POST /marketing/v3/marketing-events/events/upsert
#
# operationId: post-/marketing/v3/marketing-events/events/upsert_doUpsert
# --inputs item shape: {customProperties?: list, endDateTime?: string, eventCancelled?: bool, eventDescription?: string, eventName: string, eventOrganizer: string, eventType?: string, eventUrl?: string, externalAccountId: string, externalEventId: string, startDateTime?: string}
export def "marketing-marketing-events-events-upsert create-do" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  inputs: list # item shape: {customProperties?: list, endDateTime?: string, eventCancelled?: bool, eventDescription?: string, eventName: string, eventOrganizer: string, eventType?: string, eventUrl?: string, externalAccountId: string, externalEventId: string, startDateTime?: string}
]: any -> record<completedAt: string, errors: table<category: record, context: record, errors: list, id: string, links: record, message: string, status: string, subCategory: record>, links: record, numErrors: int, requestedAt: string, results: table<createdAt: string, customProperties: list, endDateTime: string, eventCancelled: bool, eventDescription: string, eventName: string, eventOrganizer: string, eventType: string, eventUrl: string, id: string, startDateTime: string, updatedAt: string>, startedAt: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/v3/marketing-events/events/upsert")
  let req_body = {"inputs": $inputs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# DELETE /marketing/v3/marketing-events/events/{externalEventId}
#
# operationId: delete-/marketing/v3/marketing-events/events/{externalEventId}_archive
export def "marketing-marketing-events-events delete-{external-id}-archive" [
  external_event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-account-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "externalAccountId" $external_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({external_event_id: (encode-path-segment $external_event_id)} | format pattern "/marketing/v3/marketing-events/events/{external_event_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GET /marketing/v3/marketing-events/events/{externalEventId}
#
# operationId: get-/marketing/v3/marketing-events/events/{externalEventId}_getById
export def "marketing-marketing-events-events get-{external-id}-get" [
  external_event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-account-id: string
]: nothing -> record<attendees: int, cancellations: int, createdAt: string, customProperties: table<name: string, persistenceTimestamp: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, source: string, sourceId: string, sourceLabel: string, sourceMetadata: string, sourceVid: list, timestamp: int, updatedByUserId: int, useTimestampAsPersistenceTimestamp: bool, value: string>, endDateTime: string, eventCancelled: bool, eventDescription: string, eventName: string, eventOrganizer: string, eventType: string, eventUrl: string, externalEventId: string, id: string, noShows: int, registrants: int, startDateTime: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "externalAccountId" $external_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({external_event_id: (encode-path-segment $external_event_id)} | format pattern "/marketing/v3/marketing-events/events/{external_event_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# PATCH /marketing/v3/marketing-events/events/{externalEventId}
#
# operationId: patch-/marketing/v3/marketing-events/events/{externalEventId}_update
# --customProperties item shape: {name: string, persistenceTimestamp?: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, ... (9 more fields)}
export def "marketing-marketing-events-events update-{external-id}-update-by-externalEventId" [
  external_event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-account-id: string
  --custom-properties: list # A list of PropertyValues. These can be whatever kind of property names and values you want. However, they must already exist on the HubSpot account's definition of the MarketingEvent Object. If they don't they will be filtered out and not set. In order to do this you'll need to create a new PropertyGroup on the HubSpot account's MarketingEvent object for your specific app and create the Custom Property you want to track on that HubSpot account. Do not create any new default properties on the MarketingEvent object as that will apply to all HubSpot accounts. — item shape: {name: string, persistenceTimestamp?: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, ... (9 more fields)}
  --end-date-time: string # The end date and time of the marketing event. (format: date-time)
  --event-cancelled: oneof<nothing, bool> # Indicates if the marketing event has been cancelled. Defaults to `false`
  --event-description: string # The description of the marketing event.
  --event-name: string # The name of the marketing event.
  --event-organizer: string # The name of the organizer of the marketing event.
  --event-type: string # Describes what type of event this is. For example: `WEBINAR`, `CONFERENCE`, `WORKSHOP`
  --event-url: string # A URL in the external event application where the marketing event can be managed.
  --start-date-time: string # The start date and time of the marketing event. (format: date-time)
]: any -> record<createdAt: string, customProperties: table<name: string, persistenceTimestamp: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, source: string, sourceId: string, sourceLabel: string, sourceMetadata: string, sourceVid: list, timestamp: int, updatedByUserId: int, useTimestampAsPersistenceTimestamp: bool, value: string>, endDateTime: string, eventCancelled: bool, eventDescription: string, eventName: string, eventOrganizer: string, eventType: string, eventUrl: string, id: string, startDateTime: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "externalAccountId" $external_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({external_event_id: (encode-path-segment $external_event_id)} | format pattern "/marketing/v3/marketing-events/events/{external_event_id}") $qp)
  let req_body = {"customProperties": $custom_properties, "endDateTime": $end_date_time, "eventCancelled": $event_cancelled, "eventDescription": $event_description, "eventName": $event_name, "eventOrganizer": $event_organizer, "eventType": $event_type, "eventUrl": $event_url, "startDateTime": $start_date_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# PUT /marketing/v3/marketing-events/events/{externalEventId}
#
# operationId: put-/marketing/v3/marketing-events/events/{externalEventId}_replace
# --customProperties item shape: {name: string, persistenceTimestamp?: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, ... (9 more fields)}
export def "marketing-marketing-events-events update-{external-id}-update-by-externalEventId-1" [
  external_event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-properties: list # A list of PropertyValues. These can be whatever kind of property names and values you want. However, they must already exist on the HubSpot account's definition of the MarketingEvent Object. If they don't they will be filtered out and not set. In order to do this you'll need to create a new PropertyGroup on the HubSpot account's MarketingEvent object for your specific app and create the Custom Property you want to track on that HubSpot account. Do not create any new default properties on the MarketingEvent object as that will apply to all HubSpot accounts. — item shape: {name: string, persistenceTimestamp?: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, ... (9 more fields)}
  --end-date-time: string # The end date and time of the marketing event. (format: date-time)
  --event-cancelled: oneof<nothing, bool> # Indicates if the marketing event has been cancelled. Defaults to `false`
  --event-description: string # The description of the marketing event.
  event_name: string # The name of the marketing event.
  event_organizer: string # The name of the organizer of the marketing event.
  --event-type: string # Describes what type of event this is. For example: `WEBINAR`, `CONFERENCE`, `WORKSHOP`
  --event-url: string # A URL in the external event application where the marketing event can be managed.
  external_account_id: string # The accountId that is associated with this marketing event in the external event application.
  --body-external-event-id: string # The id of the marketing event in the external event application.
  --start-date-time: string # The start date and time of the marketing event. (format: date-time)
]: any -> record<createdAt: string, customProperties: table<name: string, persistenceTimestamp: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, source: string, sourceId: string, sourceLabel: string, sourceMetadata: string, sourceVid: list, timestamp: int, updatedByUserId: int, useTimestampAsPersistenceTimestamp: bool, value: string>, endDateTime: string, eventCancelled: bool, eventDescription: string, eventName: string, eventOrganizer: string, eventType: string, eventUrl: string, id: string, startDateTime: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({external_event_id: (encode-path-segment $external_event_id)} | format pattern "/marketing/v3/marketing-events/events/{external_event_id}"))
  let req_body = {"customProperties": $custom_properties, "endDateTime": $end_date_time, "eventCancelled": $event_cancelled, "eventDescription": $event_description, "eventName": $event_name, "eventOrganizer": $event_organizer, "eventType": $event_type, "eventUrl": $event_url, "externalAccountId": $external_account_id, "externalEventId": $body_external_event_id, "startDateTime": $start_date_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# POST /marketing/v3/marketing-events/events/{externalEventId}/cancel
#
# operationId: post-/marketing/v3/marketing-events/events/{externalEventId}/cancel_doCancel
export def "marketing-marketing-events-events-cancel create-{external-id}-do" [
  external_event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-account-id: string
]: nothing -> record<customProperties: table<name: string, persistenceTimestamp: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, source: string, sourceId: string, sourceLabel: string, sourceMetadata: string, sourceVid: list, timestamp: int, updatedByUserId: int, useTimestampAsPersistenceTimestamp: bool, value: string>, endDateTime: string, eventCancelled: bool, eventDescription: string, eventName: string, eventOrganizer: string, eventType: string, eventUrl: string, startDateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "externalAccountId" $external_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({external_event_id: (encode-path-segment $external_event_id)} | format pattern "/marketing/v3/marketing-events/events/{external_event_id}/cancel") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# POST /marketing/v3/marketing-events/events/{externalEventId}/complete
#
# operationId: post-/marketing/v3/marketing-events/events/{externalEventId}/complete_complete
export def "marketing-marketing-events-events-complete create-{external-id}" [
  external_event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-account-id: string
  end_date_time: string # format: date-time
  start_date_time: string # format: date-time
]: any -> record<customProperties: table<name: string, persistenceTimestamp: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, source: string, sourceId: string, sourceLabel: string, sourceMetadata: string, sourceVid: list, timestamp: int, updatedByUserId: int, useTimestampAsPersistenceTimestamp: bool, value: string>, endDateTime: string, eventCancelled: bool, eventDescription: string, eventName: string, eventOrganizer: string, eventType: string, eventUrl: string, startDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "externalAccountId" $external_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({external_event_id: (encode-path-segment $external_event_id)} | format pattern "/marketing/v3/marketing-events/events/{external_event_id}/complete") $qp)
  let req_body = {"endDateTime": $end_date_time, "startDateTime": $start_date_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# POST /marketing/v3/marketing-events/events/{externalEventId}/{subscriberState}/email-upsert
#
# operationId: post-/marketing/v3/marketing-events/events/{externalEventId}/{subscriberState}/email-upsert_doEmailUpsertById
# --inputs item shape: {contactProperties?: record, email: string, interactionDateTime: int, properties?: record}
export def "marketing-marketing-events-events-email-upsert create-{external-id}-{subscriber-state}-do" [
  external_event_id: string
  subscriber_state: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-account-id: string
  inputs: list # List of marketing event details to create or update — item shape: {contactProperties?: record, email: string, interactionDateTime: int, properties?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "externalAccountId" $external_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({external_event_id: (encode-path-segment $external_event_id), subscriber_state: (encode-path-segment $subscriber_state)} | format pattern "/marketing/v3/marketing-events/events/{external_event_id}/{subscriber_state}/email-upsert") $qp)
  let req_body = {"inputs": $inputs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# POST /marketing/v3/marketing-events/events/{externalEventId}/{subscriberState}/upsert
#
# operationId: post-/marketing/v3/marketing-events/events/{externalEventId}/{subscriberState}/upsert_doUpsertById
# --inputs item shape: {interactionDateTime: int, properties?: record, vid?: int}
export def "marketing-marketing-events-events-upsert create-{external-id}-{subscriber-state}-do" [
  external_event_id: string
  subscriber_state: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-account-id: string
  inputs: list # List of HubSpot contacts to subscribe to the marketing event — item shape: {interactionDateTime: int, properties?: record, vid?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "externalAccountId" $external_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({external_event_id: (encode-path-segment $external_event_id), subscriber_state: (encode-path-segment $subscriber_state)} | format pattern "/marketing/v3/marketing-events/events/{external_event_id}/{subscriber_state}/upsert") $qp)
  let req_body = {"inputs": $inputs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# GET /marketing/v3/marketing-events/{appId}/settings
#
# operationId: get-/marketing/v3/marketing-events/{appId}/settings_getAll
export def "marketing-marketing-events-settings get-{app-id}-get-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<appId: int, eventDetailsUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/marketing/v3/marketing-events/{app_id}/settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# POST /marketing/v3/marketing-events/{appId}/settings
#
# operationId: post-/marketing/v3/marketing-events/{appId}/settings_create
export def "marketing-marketing-events-settings create-{app-id}-create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  event_details_url: string # The url that will be used to fetch marketing event details by id. Must contain a `%s` character sequence that will be substituted with the event id. For example: `https://my.event.app/events/%s`
]: any -> record<appId: int, eventDetailsUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/marketing/v3/marketing-events/{app_id}/settings"))
  let req_body = {"eventDetailsUrl": $event_details_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
