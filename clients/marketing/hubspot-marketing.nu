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
    "query-hapikey" => { {headers: {}, query: $"hapikey=($token_val)"} }
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "private-app-legacy" => { {headers: {private-app-legacy: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.hubapi.com"] }
def auth-scheme-completer [] { ["query-hapikey" "bearer" "private-app-legacy"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "marketing-marketing-events-attendance-create create" } } | get name | first)
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
export def "marketing-marketing-events-attendance-create create" [
  externalEventId: string
  subscriberState: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --externalAccountId: string # The account id associated with the marketing event
  inputs: list # List of HubSpot contacts to subscribe to the marketing event — item shape: {interactionDateTime: int, properties?: record, vid?: int}
]: any -> record<completedAt: string, errors: table<category: record, context: record, errors: list, id: string, links: record, message: string, status: string, subCategory: record>, links: record, numErrors: int, requestedAt: string, results: table<vid: int>, startedAt: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "externalAccountId" $externalAccountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/marketing/v3/marketing-events/attendance/($externalEventId)/($subscriberState)/create" $qp)
  let body = {inputs: $inputs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Record
#
# POST /marketing/v3/marketing-events/attendance/{externalEventId}/{subscriberState}/email-create
# operationId: post-/marketing/v3/marketing-events/attendance/{externalEventId}/{subscriberState}/email-create_createByEmail
# --inputs item shape: {contactProperties?: record, email: string, interactionDateTime: int, properties?: record}
export def "marketing-marketing-events-attendance-email-create createByEmail" [
  externalEventId: string
  subscriberState: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --externalAccountId: string # The account id associated with the marketing event
  inputs: list # List of marketing event details to create or update — item shape: {contactProperties?: record, email: string, interactionDateTime: int, properties?: record}
]: any -> record<completedAt: string, errors: table<category: record, context: record, errors: list, id: string, links: record, message: string, status: string, subCategory: record>, links: record, numErrors: int, requestedAt: string, results: table<email: string, vid: int>, startedAt: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "externalAccountId" $externalAccountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/marketing/v3/marketing-events/attendance/($externalEventId)/($subscriberState)/email-create" $qp)
  let body = {inputs: $inputs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /marketing/v3/marketing-events/events
#
# operationId: post-/marketing/v3/marketing-events/events_create
# --customProperties item shape: {name: string, persistenceTimestamp?: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, source: "IMPORT"|"API"|"FORM"|"ANALYTICS"|"MIGRATION"|"SALESFORCE"|"INTEGRATION"|"CONTACTS_WEB"|"WAL_INCREMENTAL"|"TASK"|"EMAIL"|"WORKFLOWS"|"CALCULATED"|"SOCIAL"|"BATCH_UPDATE"|"SIGNALS"|"BIDEN"|"DEFAULT"|"COMPANIES"|"DEALS"|"ASSISTS"|"PRESENTATIONS"|"TALLY"|"SIDEKICK"|"CRM_UI"|"MERGE_CONTACTS"|"PORTAL_USER_ASSOCIATOR"|"INTEGRATIONS_PLATFORM"|"BCC_TO_CRM"|"FORWARD_TO_CRM"|"ENGAGEMENTS"|"SALES"|"HEISENBERG"|"LEADIN"|"GMAIL_INTEGRATION"|"ACADEMY"|"SALES_MESSAGES"|"AVATARS_SERVICE"|"MERGE_COMPANIES"|"SEQUENCES"|"COMPANY_FAMILIES"|"MOBILE_IOS"|"MOBILE_ANDROID"|"CONTACTS"|"ASSOCIATIONS"|"EXTENSION"|"SUCCESS"|"BOT"|"INTEGRATIONS_SYNC"|"AUTOMATION_PLATFORM"|"CONVERSATIONS"|"EMAIL_INTEGRATION"|"CONTENT_MEMBERSHIP"|"QUOTES"|"BET_ASSIGNMENT"|"QUOTAS"|"BET_CRM_CONNECTOR"|"MEETINGS"|"MERGE_OBJECTS"|"RECYCLING_BIN"|"ADS"|"AI_GROUP"|"COMMUNICATOR"|"SETTINGS"|"PROPERTY_SETTINGS"|"PIPELINE_SETTINGS"|"COMPANY_INSIGHTS"|"BEHAVIORAL_EVENTS"|"PAYMENTS"|"GOALS"|"PORTAL_OBJECT_SYNC"|"APPROVALS"|"FILE_MANAGER"|"MARKETPLACE"|"INTERNAL_PROCESSING"|"FORECASTING"|"SLACK_INTEGRATION"|"CRM_UI_BULK_ACTION"|"WORKFLOW_CONTACT_DELETE_ACTION", sourceId: string, sourceLabel: string, sourceMetadata: string, sourceVid: list, timestamp: int, updatedByUserId?: int, useTimestampAsPersistenceTimestamp?: bool, value: string}
export def "marketing-marketing-events-events create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --customProperties: list # A list of PropertyValues. These can be whatever kind of property names and values you want. However, they must already exist on the HubSpot account's definition of the MarketingEvent Object. If they don't they will be filtered out and not set. In order to do this you'll need to create a new PropertyGroup on the HubSpot account's MarketingEvent object for your specific app and create the Custom Property you want to track on that HubSpot account. Do not create any new default properties on the MarketingEvent object as that will apply to all HubSpot accounts. — item shape: {name: string, persistenceTimestamp?: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, source: "IMPORT"|"API"|"FORM"|"ANALYTICS"|"MIGRATION"|"SALESFORCE"|"INTEGRATION"|"CONTACTS_WEB"|"WAL_INCREMENTAL"|"TASK"|"EMAIL"|"WORKFLOWS"|"CALCULATED"|"SOCIAL"|"BATCH_UPDATE"|"SIGNALS"|"BIDEN"|"DEFAULT"|"COMPANIES"|"DEALS"|"ASSISTS"|"PRESENTATIONS"|"TALLY"|"SIDEKICK"|"CRM_UI"|"MERGE_CONTACTS"|"PORTAL_USER_ASSOCIATOR"|"INTEGRATIONS_PLATFORM"|"BCC_TO_CRM"|"FORWARD_TO_CRM"|"ENGAGEMENTS"|"SALES"|"HEISENBERG"|"LEADIN"|"GMAIL_INTEGRATION"|"ACADEMY"|"SALES_MESSAGES"|"AVATARS_SERVICE"|"MERGE_COMPANIES"|"SEQUENCES"|"COMPANY_FAMILIES"|"MOBILE_IOS"|"MOBILE_ANDROID"|"CONTACTS"|"ASSOCIATIONS"|"EXTENSION"|"SUCCESS"|"BOT"|"INTEGRATIONS_SYNC"|"AUTOMATION_PLATFORM"|"CONVERSATIONS"|"EMAIL_INTEGRATION"|"CONTENT_MEMBERSHIP"|"QUOTES"|"BET_ASSIGNMENT"|"QUOTAS"|"BET_CRM_CONNECTOR"|"MEETINGS"|"MERGE_OBJECTS"|"RECYCLING_BIN"|"ADS"|"AI_GROUP"|"COMMUNICATOR"|"SETTINGS"|"PROPERTY_SETTINGS"|"PIPELINE_SETTINGS"|"COMPANY_INSIGHTS"|"BEHAVIORAL_EVENTS"|"PAYMENTS"|"GOALS"|"PORTAL_OBJECT_SYNC"|"APPROVALS"|"FILE_MANAGER"|"MARKETPLACE"|"INTERNAL_PROCESSING"|"FORECASTING"|"SLACK_INTEGRATION"|"CRM_UI_BULK_ACTION"|"WORKFLOW_CONTACT_DELETE_ACTION", sourceId: string, sourceLabel: string, sourceMetadata: string, sourceVid: list, timestamp: int, updatedByUserId?: int, useTimestampAsPersistenceTimestamp?: bool, value: string}
  --endDateTime: string # The end date and time of the marketing event. (format: date-time)
  --eventCancelled: oneof<nothing, bool> # Indicates if the marketing event has been cancelled.  Defaults to `false`
  --eventDescription: string # The description of the marketing event.
  eventName: string # The name of the marketing event.
  eventOrganizer: string # The name of the organizer of the marketing event.
  --eventType: string # Describes what type of event this is.  For example: `WEBINAR`, `CONFERENCE`, `WORKSHOP`
  --eventUrl: string # A URL in the external event application where the marketing event can be managed.
  externalAccountId: string # The accountId that is associated with this marketing event in the external event application.
  externalEventId: string # The id of the marketing event in the external event application.
  --startDateTime: string # The start date and time of the marketing event. (format: date-time)
]: any -> record<customProperties: table<name: string, persistenceTimestamp: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, source: string, sourceId: string, sourceLabel: string, sourceMetadata: string, sourceVid: list, timestamp: int, updatedByUserId: int, useTimestampAsPersistenceTimestamp: bool, value: string>, endDateTime: string, eventCancelled: bool, eventDescription: string, eventName: string, eventOrganizer: string, eventType: string, eventUrl: string, startDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/v3/marketing-events/events")
  let body = {customProperties: $customProperties, endDateTime: $endDateTime, eventCancelled: $eventCancelled, eventDescription: $eventDescription, eventName: $eventName, eventOrganizer: $eventOrganizer, eventType: $eventType, eventUrl: $eventUrl, externalAccountId: $externalAccountId, externalEventId: $externalEventId, startDateTime: $startDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /marketing/v3/marketing-events/events/delete
#
# operationId: post-/marketing/v3/marketing-events/events/delete_archiveBatch
# --inputs item shape: {appId: int, externalAccountId: string, externalEventId: string}
export def "marketing-marketing-events-events-delete archiveBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  inputs: list # item shape: {appId: int, externalAccountId: string, externalEventId: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/v3/marketing-events/events/delete")
  let body = {inputs: $inputs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search for marketing events
#
# GET /marketing/v3/marketing-events/events/search
# operationId: get-/marketing/v3/marketing-events/events/search_doSearch
export def "marketing-marketing-events-events-search doSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # The id of the marketing event in the external event application
]: nothing -> record<results: table<appId: int, externalAccountId: string, externalEventId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/marketing/v3/marketing-events/events/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /marketing/v3/marketing-events/events/upsert
#
# operationId: post-/marketing/v3/marketing-events/events/upsert_doUpsert
# --inputs item shape: {customProperties?: list, endDateTime?: string, eventCancelled?: bool, eventDescription?: string, eventName: string, eventOrganizer: string, eventType?: string, eventUrl?: string, externalAccountId: string, externalEventId: string, startDateTime?: string}
export def "marketing-marketing-events-events-upsert doUpsert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  inputs: list # item shape: {customProperties?: list, endDateTime?: string, eventCancelled?: bool, eventDescription?: string, eventName: string, eventOrganizer: string, eventType?: string, eventUrl?: string, externalAccountId: string, externalEventId: string, startDateTime?: string}
]: any -> record<completedAt: string, errors: table<category: record, context: record, errors: list, id: string, links: record, message: string, status: string, subCategory: record>, links: record, numErrors: int, requestedAt: string, results: table<createdAt: string, customProperties: list, endDateTime: string, eventCancelled: bool, eventDescription: string, eventName: string, eventOrganizer: string, eventType: string, eventUrl: string, id: string, startDateTime: string, updatedAt: string>, startedAt: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/v3/marketing-events/events/upsert")
  let body = {inputs: $inputs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /marketing/v3/marketing-events/events/{externalEventId}
#
# operationId: delete-/marketing/v3/marketing-events/events/{externalEventId}_archive
export def "marketing-marketing-events-events archive" [
  externalEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --externalAccountId: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "externalAccountId" $externalAccountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/marketing/v3/marketing-events/events/($externalEventId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /marketing/v3/marketing-events/events/{externalEventId}
#
# operationId: get-/marketing/v3/marketing-events/events/{externalEventId}_getById
export def "marketing-marketing-events-events get" [
  externalEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --externalAccountId: string
]: nothing -> record<attendees: int, cancellations: int, createdAt: string, customProperties: table<name: string, persistenceTimestamp: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, source: string, sourceId: string, sourceLabel: string, sourceMetadata: string, sourceVid: list, timestamp: int, updatedByUserId: int, useTimestampAsPersistenceTimestamp: bool, value: string>, endDateTime: string, eventCancelled: bool, eventDescription: string, eventName: string, eventOrganizer: string, eventType: string, eventUrl: string, externalEventId: string, id: string, noShows: int, registrants: int, startDateTime: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "externalAccountId" $externalAccountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/marketing/v3/marketing-events/events/($externalEventId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /marketing/v3/marketing-events/events/{externalEventId}
#
# operationId: patch-/marketing/v3/marketing-events/events/{externalEventId}_update
# --customProperties item shape: {name: string, persistenceTimestamp?: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, source: "IMPORT"|"API"|"FORM"|"ANALYTICS"|"MIGRATION"|"SALESFORCE"|"INTEGRATION"|"CONTACTS_WEB"|"WAL_INCREMENTAL"|"TASK"|"EMAIL"|"WORKFLOWS"|"CALCULATED"|"SOCIAL"|"BATCH_UPDATE"|"SIGNALS"|"BIDEN"|"DEFAULT"|"COMPANIES"|"DEALS"|"ASSISTS"|"PRESENTATIONS"|"TALLY"|"SIDEKICK"|"CRM_UI"|"MERGE_CONTACTS"|"PORTAL_USER_ASSOCIATOR"|"INTEGRATIONS_PLATFORM"|"BCC_TO_CRM"|"FORWARD_TO_CRM"|"ENGAGEMENTS"|"SALES"|"HEISENBERG"|"LEADIN"|"GMAIL_INTEGRATION"|"ACADEMY"|"SALES_MESSAGES"|"AVATARS_SERVICE"|"MERGE_COMPANIES"|"SEQUENCES"|"COMPANY_FAMILIES"|"MOBILE_IOS"|"MOBILE_ANDROID"|"CONTACTS"|"ASSOCIATIONS"|"EXTENSION"|"SUCCESS"|"BOT"|"INTEGRATIONS_SYNC"|"AUTOMATION_PLATFORM"|"CONVERSATIONS"|"EMAIL_INTEGRATION"|"CONTENT_MEMBERSHIP"|"QUOTES"|"BET_ASSIGNMENT"|"QUOTAS"|"BET_CRM_CONNECTOR"|"MEETINGS"|"MERGE_OBJECTS"|"RECYCLING_BIN"|"ADS"|"AI_GROUP"|"COMMUNICATOR"|"SETTINGS"|"PROPERTY_SETTINGS"|"PIPELINE_SETTINGS"|"COMPANY_INSIGHTS"|"BEHAVIORAL_EVENTS"|"PAYMENTS"|"GOALS"|"PORTAL_OBJECT_SYNC"|"APPROVALS"|"FILE_MANAGER"|"MARKETPLACE"|"INTERNAL_PROCESSING"|"FORECASTING"|"SLACK_INTEGRATION"|"CRM_UI_BULK_ACTION"|"WORKFLOW_CONTACT_DELETE_ACTION", sourceId: string, sourceLabel: string, sourceMetadata: string, sourceVid: list, timestamp: int, updatedByUserId?: int, useTimestampAsPersistenceTimestamp?: bool, value: string}
export def "marketing-marketing-events-events update" [
  externalEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --externalAccountId: string
  --customProperties: list # A list of PropertyValues. These can be whatever kind of property names and values you want. However, they must already exist on the HubSpot account's definition of the MarketingEvent Object. If they don't they will be filtered out and not set. In order to do this you'll need to create a new PropertyGroup on the HubSpot account's MarketingEvent object for your specific app and create the Custom Property you want to track on that HubSpot account. Do not create any new default properties on the MarketingEvent object as that will apply to all HubSpot accounts. — item shape: {name: string, persistenceTimestamp?: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, source: "IMPORT"|"API"|"FORM"|"ANALYTICS"|"MIGRATION"|"SALESFORCE"|"INTEGRATION"|"CONTACTS_WEB"|"WAL_INCREMENTAL"|"TASK"|"EMAIL"|"WORKFLOWS"|"CALCULATED"|"SOCIAL"|"BATCH_UPDATE"|"SIGNALS"|"BIDEN"|"DEFAULT"|"COMPANIES"|"DEALS"|"ASSISTS"|"PRESENTATIONS"|"TALLY"|"SIDEKICK"|"CRM_UI"|"MERGE_CONTACTS"|"PORTAL_USER_ASSOCIATOR"|"INTEGRATIONS_PLATFORM"|"BCC_TO_CRM"|"FORWARD_TO_CRM"|"ENGAGEMENTS"|"SALES"|"HEISENBERG"|"LEADIN"|"GMAIL_INTEGRATION"|"ACADEMY"|"SALES_MESSAGES"|"AVATARS_SERVICE"|"MERGE_COMPANIES"|"SEQUENCES"|"COMPANY_FAMILIES"|"MOBILE_IOS"|"MOBILE_ANDROID"|"CONTACTS"|"ASSOCIATIONS"|"EXTENSION"|"SUCCESS"|"BOT"|"INTEGRATIONS_SYNC"|"AUTOMATION_PLATFORM"|"CONVERSATIONS"|"EMAIL_INTEGRATION"|"CONTENT_MEMBERSHIP"|"QUOTES"|"BET_ASSIGNMENT"|"QUOTAS"|"BET_CRM_CONNECTOR"|"MEETINGS"|"MERGE_OBJECTS"|"RECYCLING_BIN"|"ADS"|"AI_GROUP"|"COMMUNICATOR"|"SETTINGS"|"PROPERTY_SETTINGS"|"PIPELINE_SETTINGS"|"COMPANY_INSIGHTS"|"BEHAVIORAL_EVENTS"|"PAYMENTS"|"GOALS"|"PORTAL_OBJECT_SYNC"|"APPROVALS"|"FILE_MANAGER"|"MARKETPLACE"|"INTERNAL_PROCESSING"|"FORECASTING"|"SLACK_INTEGRATION"|"CRM_UI_BULK_ACTION"|"WORKFLOW_CONTACT_DELETE_ACTION", sourceId: string, sourceLabel: string, sourceMetadata: string, sourceVid: list, timestamp: int, updatedByUserId?: int, useTimestampAsPersistenceTimestamp?: bool, value: string}
  --endDateTime: string # The end date and time of the marketing event. (format: date-time)
  --eventCancelled: oneof<nothing, bool> # Indicates if the marketing event has been cancelled. Defaults to `false`
  --eventDescription: string # The description of the marketing event.
  --eventName: string # The name of the marketing event.
  --eventOrganizer: string # The name of the organizer of the marketing event.
  --eventType: string # Describes what type of event this is.  For example: `WEBINAR`, `CONFERENCE`, `WORKSHOP`
  --eventUrl: string # A URL in the external event application where the marketing event can be managed.
  --startDateTime: string # The start date and time of the marketing event. (format: date-time)
]: any -> record<createdAt: string, customProperties: table<name: string, persistenceTimestamp: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, source: string, sourceId: string, sourceLabel: string, sourceMetadata: string, sourceVid: list, timestamp: int, updatedByUserId: int, useTimestampAsPersistenceTimestamp: bool, value: string>, endDateTime: string, eventCancelled: bool, eventDescription: string, eventName: string, eventOrganizer: string, eventType: string, eventUrl: string, id: string, startDateTime: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "externalAccountId" $externalAccountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/marketing/v3/marketing-events/events/($externalEventId)" $qp)
  let body = {customProperties: $customProperties, endDateTime: $endDateTime, eventCancelled: $eventCancelled, eventDescription: $eventDescription, eventName: $eventName, eventOrganizer: $eventOrganizer, eventType: $eventType, eventUrl: $eventUrl, startDateTime: $startDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /marketing/v3/marketing-events/events/{externalEventId}
#
# operationId: put-/marketing/v3/marketing-events/events/{externalEventId}_replace
# --customProperties item shape: {name: string, persistenceTimestamp?: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, source: "IMPORT"|"API"|"FORM"|"ANALYTICS"|"MIGRATION"|"SALESFORCE"|"INTEGRATION"|"CONTACTS_WEB"|"WAL_INCREMENTAL"|"TASK"|"EMAIL"|"WORKFLOWS"|"CALCULATED"|"SOCIAL"|"BATCH_UPDATE"|"SIGNALS"|"BIDEN"|"DEFAULT"|"COMPANIES"|"DEALS"|"ASSISTS"|"PRESENTATIONS"|"TALLY"|"SIDEKICK"|"CRM_UI"|"MERGE_CONTACTS"|"PORTAL_USER_ASSOCIATOR"|"INTEGRATIONS_PLATFORM"|"BCC_TO_CRM"|"FORWARD_TO_CRM"|"ENGAGEMENTS"|"SALES"|"HEISENBERG"|"LEADIN"|"GMAIL_INTEGRATION"|"ACADEMY"|"SALES_MESSAGES"|"AVATARS_SERVICE"|"MERGE_COMPANIES"|"SEQUENCES"|"COMPANY_FAMILIES"|"MOBILE_IOS"|"MOBILE_ANDROID"|"CONTACTS"|"ASSOCIATIONS"|"EXTENSION"|"SUCCESS"|"BOT"|"INTEGRATIONS_SYNC"|"AUTOMATION_PLATFORM"|"CONVERSATIONS"|"EMAIL_INTEGRATION"|"CONTENT_MEMBERSHIP"|"QUOTES"|"BET_ASSIGNMENT"|"QUOTAS"|"BET_CRM_CONNECTOR"|"MEETINGS"|"MERGE_OBJECTS"|"RECYCLING_BIN"|"ADS"|"AI_GROUP"|"COMMUNICATOR"|"SETTINGS"|"PROPERTY_SETTINGS"|"PIPELINE_SETTINGS"|"COMPANY_INSIGHTS"|"BEHAVIORAL_EVENTS"|"PAYMENTS"|"GOALS"|"PORTAL_OBJECT_SYNC"|"APPROVALS"|"FILE_MANAGER"|"MARKETPLACE"|"INTERNAL_PROCESSING"|"FORECASTING"|"SLACK_INTEGRATION"|"CRM_UI_BULK_ACTION"|"WORKFLOW_CONTACT_DELETE_ACTION", sourceId: string, sourceLabel: string, sourceMetadata: string, sourceVid: list, timestamp: int, updatedByUserId?: int, useTimestampAsPersistenceTimestamp?: bool, value: string}
export def "marketing-marketing-events-events replace" [
  externalEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --customProperties: list # A list of PropertyValues. These can be whatever kind of property names and values you want. However, they must already exist on the HubSpot account's definition of the MarketingEvent Object. If they don't they will be filtered out and not set. In order to do this you'll need to create a new PropertyGroup on the HubSpot account's MarketingEvent object for your specific app and create the Custom Property you want to track on that HubSpot account. Do not create any new default properties on the MarketingEvent object as that will apply to all HubSpot accounts. — item shape: {name: string, persistenceTimestamp?: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, source: "IMPORT"|"API"|"FORM"|"ANALYTICS"|"MIGRATION"|"SALESFORCE"|"INTEGRATION"|"CONTACTS_WEB"|"WAL_INCREMENTAL"|"TASK"|"EMAIL"|"WORKFLOWS"|"CALCULATED"|"SOCIAL"|"BATCH_UPDATE"|"SIGNALS"|"BIDEN"|"DEFAULT"|"COMPANIES"|"DEALS"|"ASSISTS"|"PRESENTATIONS"|"TALLY"|"SIDEKICK"|"CRM_UI"|"MERGE_CONTACTS"|"PORTAL_USER_ASSOCIATOR"|"INTEGRATIONS_PLATFORM"|"BCC_TO_CRM"|"FORWARD_TO_CRM"|"ENGAGEMENTS"|"SALES"|"HEISENBERG"|"LEADIN"|"GMAIL_INTEGRATION"|"ACADEMY"|"SALES_MESSAGES"|"AVATARS_SERVICE"|"MERGE_COMPANIES"|"SEQUENCES"|"COMPANY_FAMILIES"|"MOBILE_IOS"|"MOBILE_ANDROID"|"CONTACTS"|"ASSOCIATIONS"|"EXTENSION"|"SUCCESS"|"BOT"|"INTEGRATIONS_SYNC"|"AUTOMATION_PLATFORM"|"CONVERSATIONS"|"EMAIL_INTEGRATION"|"CONTENT_MEMBERSHIP"|"QUOTES"|"BET_ASSIGNMENT"|"QUOTAS"|"BET_CRM_CONNECTOR"|"MEETINGS"|"MERGE_OBJECTS"|"RECYCLING_BIN"|"ADS"|"AI_GROUP"|"COMMUNICATOR"|"SETTINGS"|"PROPERTY_SETTINGS"|"PIPELINE_SETTINGS"|"COMPANY_INSIGHTS"|"BEHAVIORAL_EVENTS"|"PAYMENTS"|"GOALS"|"PORTAL_OBJECT_SYNC"|"APPROVALS"|"FILE_MANAGER"|"MARKETPLACE"|"INTERNAL_PROCESSING"|"FORECASTING"|"SLACK_INTEGRATION"|"CRM_UI_BULK_ACTION"|"WORKFLOW_CONTACT_DELETE_ACTION", sourceId: string, sourceLabel: string, sourceMetadata: string, sourceVid: list, timestamp: int, updatedByUserId?: int, useTimestampAsPersistenceTimestamp?: bool, value: string}
  --endDateTime: string # The end date and time of the marketing event. (format: date-time)
  --eventCancelled: oneof<nothing, bool> # Indicates if the marketing event has been cancelled.  Defaults to `false`
  --eventDescription: string # The description of the marketing event.
  eventName: string # The name of the marketing event.
  eventOrganizer: string # The name of the organizer of the marketing event.
  --eventType: string # Describes what type of event this is.  For example: `WEBINAR`, `CONFERENCE`, `WORKSHOP`
  --eventUrl: string # A URL in the external event application where the marketing event can be managed.
  externalAccountId: string # The accountId that is associated with this marketing event in the external event application.
  --body-externalEventId: string # The id of the marketing event in the external event application.
  --startDateTime: string # The start date and time of the marketing event. (format: date-time)
]: any -> record<createdAt: string, customProperties: table<name: string, persistenceTimestamp: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, source: string, sourceId: string, sourceLabel: string, sourceMetadata: string, sourceVid: list, timestamp: int, updatedByUserId: int, useTimestampAsPersistenceTimestamp: bool, value: string>, endDateTime: string, eventCancelled: bool, eventDescription: string, eventName: string, eventOrganizer: string, eventType: string, eventUrl: string, id: string, startDateTime: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/marketing/v3/marketing-events/events/($externalEventId)")
  let body = {customProperties: $customProperties, endDateTime: $endDateTime, eventCancelled: $eventCancelled, eventDescription: $eventDescription, eventName: $eventName, eventOrganizer: $eventOrganizer, eventType: $eventType, eventUrl: $eventUrl, externalAccountId: $externalAccountId, externalEventId: $body_externalEventId, startDateTime: $startDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /marketing/v3/marketing-events/events/{externalEventId}/cancel
#
# operationId: post-/marketing/v3/marketing-events/events/{externalEventId}/cancel_doCancel
export def "marketing-marketing-events-events-cancel doCancel" [
  externalEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --externalAccountId: string
]: nothing -> record<customProperties: table<name: string, persistenceTimestamp: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, source: string, sourceId: string, sourceLabel: string, sourceMetadata: string, sourceVid: list, timestamp: int, updatedByUserId: int, useTimestampAsPersistenceTimestamp: bool, value: string>, endDateTime: string, eventCancelled: bool, eventDescription: string, eventName: string, eventOrganizer: string, eventType: string, eventUrl: string, startDateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "externalAccountId" $externalAccountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/marketing/v3/marketing-events/events/($externalEventId)/cancel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /marketing/v3/marketing-events/events/{externalEventId}/complete
#
# operationId: post-/marketing/v3/marketing-events/events/{externalEventId}/complete_complete
export def "marketing-marketing-events-events-complete complete" [
  externalEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --externalAccountId: string
  endDateTime: string # format: date-time
  startDateTime: string # format: date-time
]: any -> record<customProperties: table<name: string, persistenceTimestamp: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, source: string, sourceId: string, sourceLabel: string, sourceMetadata: string, sourceVid: list, timestamp: int, updatedByUserId: int, useTimestampAsPersistenceTimestamp: bool, value: string>, endDateTime: string, eventCancelled: bool, eventDescription: string, eventName: string, eventOrganizer: string, eventType: string, eventUrl: string, startDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "externalAccountId" $externalAccountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/marketing/v3/marketing-events/events/($externalEventId)/complete" $qp)
  let body = {endDateTime: $endDateTime, startDateTime: $startDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /marketing/v3/marketing-events/events/{externalEventId}/{subscriberState}/email-upsert
#
# operationId: post-/marketing/v3/marketing-events/events/{externalEventId}/{subscriberState}/email-upsert_doEmailUpsertById
# --inputs item shape: {contactProperties?: record, email: string, interactionDateTime: int, properties?: record}
export def "marketing-marketing-events-events-email-upsert doEmailUpsertById" [
  externalEventId: string
  subscriberState: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --externalAccountId: string
  inputs: list # List of marketing event details to create or update — item shape: {contactProperties?: record, email: string, interactionDateTime: int, properties?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "externalAccountId" $externalAccountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/marketing/v3/marketing-events/events/($externalEventId)/($subscriberState)/email-upsert" $qp)
  let body = {inputs: $inputs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /marketing/v3/marketing-events/events/{externalEventId}/{subscriberState}/upsert
#
# operationId: post-/marketing/v3/marketing-events/events/{externalEventId}/{subscriberState}/upsert_doUpsertById
# --inputs item shape: {interactionDateTime: int, properties?: record, vid?: int}
export def "marketing-marketing-events-events-upsert doUpsertById" [
  externalEventId: string
  subscriberState: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --externalAccountId: string
  inputs: list # List of HubSpot contacts to subscribe to the marketing event — item shape: {interactionDateTime: int, properties?: record, vid?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "externalAccountId" $externalAccountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/marketing/v3/marketing-events/events/($externalEventId)/($subscriberState)/upsert" $qp)
  let body = {inputs: $inputs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /marketing/v3/marketing-events/{appId}/settings
#
# operationId: get-/marketing/v3/marketing-events/{appId}/settings_getAll
export def "marketing-marketing-events-settings get" [
  appId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<appId: int, eventDetailsUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/marketing/v3/marketing-events/($appId)/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /marketing/v3/marketing-events/{appId}/settings
#
# operationId: post-/marketing/v3/marketing-events/{appId}/settings_create
export def "marketing-marketing-events-settings create" [
  appId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  eventDetailsUrl: string # The url that will be used to fetch marketing event details by id. Must contain a `%s` character sequence that will be substituted with the event id. For example: `https://my.event.app/events/%s`
]: any -> record<appId: int, eventDetailsUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/marketing/v3/marketing-events/($appId)/settings")
  let body = {eventDetailsUrl: $eventDetailsUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
