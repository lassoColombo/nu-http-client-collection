# Auto-generated client for Marketing Events Extension vv3
# Source: https://api.apis.guru/v2/specs/hubapi.com/marketing/v3/openapi.json
# Auth: --token flag or $env.MARKETING_EVENTS_EXTENSION_TOKEN

const BASE_URL = "https://api.hubapi.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o MARKETING_EVENTS_EXTENSION_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-hapikey" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "hapikey")=(encode-path-segment $token_val)", location: "query"} }
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "private-app-legacy" => { {scheme: $scheme, headers: {private-app-legacy: $token_val}, query: "", location: "header"} }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.hubapi.com"] }
def auth-scheme-completer [] { ["query-hapikey" "bearer" "private-app-legacy"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "marketing-marketing-events-attendance-create create-external-subscriber-state" } } | get name | first)
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
export def "marketing-marketing-events-attendance-create create-external-subscriber-state" [
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
  if ($external_event_id | is-empty) { error make --unspanned { msg: "path parameter 'externalEventId' must be non-empty" } }
  if ($subscriber_state | is-empty) { error make --unspanned { msg: "path parameter 'subscriberState' must be non-empty" } }
  let qp = [(serialize-qp "externalAccountId" $external_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({external_event_id: (encode-path-segment $external_event_id), subscriber_state: (encode-path-segment $subscriber_state)} | format pattern "/marketing/v3/marketing-events/attendance/{external_event_id}/{subscriber_state}/create") $qp $auth.query)
  let req_body = {"inputs": $inputs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"externalAccountId": $external_account_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Record
#
# POST /marketing/v3/marketing-events/attendance/{externalEventId}/{subscriberState}/email-create
# operationId: post-/marketing/v3/marketing-events/attendance/{externalEventId}/{subscriberState}/email-create_createByEmail
# --inputs item shape: {contactProperties?: record, email: string, interactionDateTime: int, properties?: record}
export def "marketing-marketing-events-attendance-email-create create-external-subscriber-state" [
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
  if ($external_event_id | is-empty) { error make --unspanned { msg: "path parameter 'externalEventId' must be non-empty" } }
  if ($subscriber_state | is-empty) { error make --unspanned { msg: "path parameter 'subscriberState' must be non-empty" } }
  let qp = [(serialize-qp "externalAccountId" $external_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({external_event_id: (encode-path-segment $external_event_id), subscriber_state: (encode-path-segment $subscriber_state)} | format pattern "/marketing/v3/marketing-events/attendance/{external_event_id}/{subscriber_state}/email-create") $qp $auth.query)
  let req_body = {"inputs": $inputs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"externalAccountId": $external_account_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# POST /marketing/v3/marketing-events/events
#
# operationId: post-/marketing/v3/marketing-events/events_create
# --customProperties item shape: {name: string, persistenceTimestamp?: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, ... (9 more fields)}
export def "marketing-marketing-events-events create" [
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
  let full_url = (build-url $base "/marketing/v3/marketing-events/events" $auth.query)
  let req_body = {"customProperties": $custom_properties, "endDateTime": $end_date_time, "eventCancelled": $event_cancelled, "eventDescription": $event_description, "eventName": $event_name, "eventOrganizer": $event_organizer, "eventType": $event_type, "eventUrl": $event_url, "externalAccountId": $external_account_id, "externalEventId": $external_event_id, "startDateTime": $start_date_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/marketing/v3/marketing-events/events/delete" $auth.query)
  let req_body = {"inputs": $inputs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full []
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
  let full_url = (build-url $base "/marketing/v3/marketing-events/events/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/marketing/v3/marketing-events/events/upsert" $auth.query)
  let req_body = {"inputs": $inputs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# DELETE /marketing/v3/marketing-events/events/{externalEventId}
#
# operationId: delete-/marketing/v3/marketing-events/events/{externalEventId}_archive
export def "marketing-marketing-events-events delete-external-archive" [
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
  if ($external_event_id | is-empty) { error make --unspanned { msg: "path parameter 'externalEventId' must be non-empty" } }
  let qp = [(serialize-qp "externalAccountId" $external_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({external_event_id: (encode-path-segment $external_event_id)} | format pattern "/marketing/v3/marketing-events/events/{external_event_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"externalAccountId": $external_account_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# GET /marketing/v3/marketing-events/events/{externalEventId}
#
# operationId: get-/marketing/v3/marketing-events/events/{externalEventId}_getById
export def "marketing-marketing-events-events get-external" [
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
  if ($external_event_id | is-empty) { error make --unspanned { msg: "path parameter 'externalEventId' must be non-empty" } }
  let qp = [(serialize-qp "externalAccountId" $external_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({external_event_id: (encode-path-segment $external_event_id)} | format pattern "/marketing/v3/marketing-events/events/{external_event_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"externalAccountId": $external_account_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# PATCH /marketing/v3/marketing-events/events/{externalEventId}
#
# operationId: patch-/marketing/v3/marketing-events/events/{externalEventId}_update
# --customProperties item shape: {name: string, persistenceTimestamp?: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, ... (9 more fields)}
export def "marketing-marketing-events-events update-external-by-external-event-id" [
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
  if ($external_event_id | is-empty) { error make --unspanned { msg: "path parameter 'externalEventId' must be non-empty" } }
  let qp = [(serialize-qp "externalAccountId" $external_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({external_event_id: (encode-path-segment $external_event_id)} | format pattern "/marketing/v3/marketing-events/events/{external_event_id}") $qp $auth.query)
  let req_body = {"customProperties": $custom_properties, "endDateTime": $end_date_time, "eventCancelled": $event_cancelled, "eventDescription": $event_description, "eventName": $event_name, "eventOrganizer": $event_organizer, "eventType": $event_type, "eventUrl": $event_url, "startDateTime": $start_date_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"externalAccountId": $external_account_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# PUT /marketing/v3/marketing-events/events/{externalEventId}
#
# operationId: put-/marketing/v3/marketing-events/events/{externalEventId}_replace
# --customProperties item shape: {name: string, persistenceTimestamp?: int, requestId: string, selectedByUser: bool, selectedByUserTimestamp: int, ... (9 more fields)}
export def "marketing-marketing-events-events update-external-by-external-event-id-1" [
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
  if ($external_event_id | is-empty) { error make --unspanned { msg: "path parameter 'externalEventId' must be non-empty" } }
  let full_url = (build-url $base ({external_event_id: (encode-path-segment $external_event_id)} | format pattern "/marketing/v3/marketing-events/events/{external_event_id}") $auth.query)
  let req_body = {"customProperties": $custom_properties, "endDateTime": $end_date_time, "eventCancelled": $event_cancelled, "eventDescription": $event_description, "eventName": $event_name, "eventOrganizer": $event_organizer, "eventType": $event_type, "eventUrl": $event_url, "externalAccountId": $external_account_id, "externalEventId": $body_external_event_id, "startDateTime": $start_date_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# POST /marketing/v3/marketing-events/events/{externalEventId}/cancel
#
# operationId: post-/marketing/v3/marketing-events/events/{externalEventId}/cancel_doCancel
export def "marketing-marketing-events-events-cancel create-external-do" [
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
  if ($external_event_id | is-empty) { error make --unspanned { msg: "path parameter 'externalEventId' must be non-empty" } }
  let qp = [(serialize-qp "externalAccountId" $external_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({external_event_id: (encode-path-segment $external_event_id)} | format pattern "/marketing/v3/marketing-events/events/{external_event_id}/cancel") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"externalAccountId": $external_account_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# POST /marketing/v3/marketing-events/events/{externalEventId}/complete
#
# operationId: post-/marketing/v3/marketing-events/events/{externalEventId}/complete_complete
export def "marketing-marketing-events-events-complete create-external" [
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
  if ($external_event_id | is-empty) { error make --unspanned { msg: "path parameter 'externalEventId' must be non-empty" } }
  let qp = [(serialize-qp "externalAccountId" $external_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({external_event_id: (encode-path-segment $external_event_id)} | format pattern "/marketing/v3/marketing-events/events/{external_event_id}/complete") $qp $auth.query)
  let req_body = {"endDateTime": $end_date_time, "startDateTime": $start_date_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"externalAccountId": $external_account_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# POST /marketing/v3/marketing-events/events/{externalEventId}/{subscriberState}/email-upsert
#
# operationId: post-/marketing/v3/marketing-events/events/{externalEventId}/{subscriberState}/email-upsert_doEmailUpsertById
# --inputs item shape: {contactProperties?: record, email: string, interactionDateTime: int, properties?: record}
export def "marketing-marketing-events-events-email-upsert create-external-subscriber-state-do" [
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
  if ($external_event_id | is-empty) { error make --unspanned { msg: "path parameter 'externalEventId' must be non-empty" } }
  if ($subscriber_state | is-empty) { error make --unspanned { msg: "path parameter 'subscriberState' must be non-empty" } }
  let qp = [(serialize-qp "externalAccountId" $external_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({external_event_id: (encode-path-segment $external_event_id), subscriber_state: (encode-path-segment $subscriber_state)} | format pattern "/marketing/v3/marketing-events/events/{external_event_id}/{subscriber_state}/email-upsert") $qp $auth.query)
  let req_body = {"inputs": $inputs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"externalAccountId": $external_account_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full []
}

# POST /marketing/v3/marketing-events/events/{externalEventId}/{subscriberState}/upsert
#
# operationId: post-/marketing/v3/marketing-events/events/{externalEventId}/{subscriberState}/upsert_doUpsertById
# --inputs item shape: {interactionDateTime: int, properties?: record, vid?: int}
export def "marketing-marketing-events-events-upsert create-external-subscriber-state-do" [
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
  if ($external_event_id | is-empty) { error make --unspanned { msg: "path parameter 'externalEventId' must be non-empty" } }
  if ($subscriber_state | is-empty) { error make --unspanned { msg: "path parameter 'subscriberState' must be non-empty" } }
  let qp = [(serialize-qp "externalAccountId" $external_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({external_event_id: (encode-path-segment $external_event_id), subscriber_state: (encode-path-segment $subscriber_state)} | format pattern "/marketing/v3/marketing-events/events/{external_event_id}/{subscriber_state}/upsert") $qp $auth.query)
  let req_body = {"inputs": $inputs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"externalAccountId": $external_account_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full []
}

# GET /marketing/v3/marketing-events/{appId}/settings
#
# operationId: get-/marketing/v3/marketing-events/{appId}/settings_getAll
export def "marketing-marketing-events-settings get-app-list" [
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
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/marketing/v3/marketing-events/{app_id}/settings") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /marketing/v3/marketing-events/{appId}/settings
#
# operationId: post-/marketing/v3/marketing-events/{appId}/settings_create
export def "marketing-marketing-events-settings create-app" [
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
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/marketing/v3/marketing-events/{app_id}/settings") $auth.query)
  let req_body = {"eventDetailsUrl": $event_details_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
