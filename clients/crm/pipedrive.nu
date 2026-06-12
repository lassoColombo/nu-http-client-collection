# Auto-generated client for Pipedrive API v1 v1.0.0
# Source: https://developers.pipedrive.com/docs/api/v1/openapi.yaml
# Auth: --token flag or $env.PIPEDRIVE_API_V1_TOKEN

const BASE_URL = "https://api.pipedrive.com/v1"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PIPEDRIVE_API_V1_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "x-api-token" => { {headers: {x-api-token: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.pipedrive.com/v1" "https://oauth.pipedrive.com"] }
def auth-scheme-completer [] { ["basic" "x-api-token" "bearer"] }

# Completers for enum parameters
def icon-key-completer [] { ["addressbook" "bell" "brush" "bubble" "bulb" "calendar" "call" "camera" "car" "cart" "checkbox" "clip" "cogs" "deadline" "document" "downarrow" "email" "finish" "key" "linegraph" "loop" "lunch" "meeting" "padlock" "picture" "plane" "presentation" "pricetag" "scissors" "search" "shuffle" "signpost" "smartphone" "sound" "suitcase" "task" "truck" "uparrow" "wifi" "world"] }
def outcome-completer [] { ["busy" "connected" "left_message" "left_voicemail" "no_answer" "wrong_number"] }
def provider-type-completer [] { ["facebook" "other" "whatsapp"] }
def status-completer [] { ["delivered" "failed" "read" "sent"] }
def status-completer-1 [] { ["all_not_deleted" "deleted" "lost" "open" "won"] }
def owned-by-you-completer [] { ["0" "1"] }
def status-completer-2 [] { ["lost" "open" "won"] }
def interval-completer [] { ["day" "month" "quarter" "week"] }
def exclude-deals-completer [] { ["0" "1"] }
def field-type-completer [] { ["address" "date" "daterange" "double" "enum" "monetary" "org" "people" "phone" "set" "text" "time" "timerange" "user" "varchar" "varchar_auto" "visible_to"] }
def file-type-completer [] { ["gdoc" "gdraw" "gform" "gsheet" "gslides"] }
def item-type-completer [] { ["deal" "organization" "person"] }
def remote-location-completer [] { ["googledrive"] }
def type-completer [] { ["activity" "deals" "leads" "org" "people" "products" "projects"] }
def interval-completer-1 [] { ["monthly" "quarterly" "weekly" "yearly"] }
def typename-completer [] { ["activities_added" "activities_completed" "deals_progressed" "deals_started" "deals_won"] }
def assigneetype-completer [] { ["company" "person" "team"] }
def expected-outcometracking-metric-completer [] { ["quantity" "sum"] }
def sort-completer [] { ["add_time" "creator_id" "expected_close_date" "id" "next_activity_id" "owner_id" "title" "update_time" "was_seen"] }
def fields-completer [] { ["custom_fields" "notes" "title"] }
def include-fields-completer [] { ["lead.was_seen"] }
def color-completer [] { ["blue" "brown" "dark-gray" "gray" "green" "orange" "pink" "purple" "red" "yellow"] }
def order-by-completer [] { ["active_flag" "id" "manager_id" "name"] }
def skip-users-completer [] { ["0" "1"] }
def include-body-completer [] { ["0" "1"] }
def folder-completer [] { ["archive" "drafts" "inbox" "sent"] }
def pinned-to-lead-flag-completer [] { ["0" "1"] }
def pinned-to-deal-flag-completer [] { ["0" "1"] }
def pinned-to-organization-flag-completer [] { ["0" "1"] }
def pinned-to-person-flag-completer [] { ["0" "1"] }
def pinned-to-project-flag-completer [] { ["0" "1"] }
def pinned-to-task-flag-completer [] { ["0" "1"] }
def grant-type-completer [] { ["authorization_code" "refresh_token"] }
def type-completer-1 [] { ["parent" "related"] }
def app-completer [] { ["account_settings" "campaigns" "global" "projects" "sales"] }
def everyone-completer [] { ["0" "1"] }
def get-summary-completer [] { ["0" "1"] }
def field-type-completer-1 [] { ["address" "date" "daterange" "double" "enum" "monetary" "org" "people" "phone" "set" "text" "time" "timerange" "user" "varchar" "varchar_auto"] }
def items-completer [] { ["activity" "activityType" "deal" "file" "filter" "note" "organization" "person" "pipeline" "product" "stage" "user"] }
def setting-key-completer [] { ["deal_default_visibility" "lead_default_visibility" "org_default_visibility" "person_default_visibility" "product_default_visibility"] }
def value-completer [] { ["1" "3" "5" "7"] }
def done-completer [] { ["0" "1"] }
def search-by-email-completer [] { ["0" "1"] }
def event-action-completer [] { ["*" "change" "create" "delete"] }
def event-object-completer [] { ["*" "activity" "deal" "lead" "note" "organization" "person" "pipeline" "product" "stage" "user"] }
def version-completer [] { ["1.0" "2.0"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "activity-fields get" } } | get name | first)
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

# Get all activity fields
#
# GET /activityFields
# operationId: getActivityFields
export def "activity-fields get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: list<record>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/activityFields")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all activity types
#
# GET /activityTypes
# operationId: getActivityTypes
export def "activity-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: table<id: int, name: string, icon_key: string, color: string, order_nr: int, key_string: string, active_flag: bool, is_custom_flag: bool, add_time: string, update_time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/activityTypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add new activity type
#
# POST /activityTypes
# operationId: addActivityType
export def "activity-types addActivityType" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the activity type (e.g. call)
  icon_key: string@icon-key-completer # Icon graphic to use for representing this activity type
  --color: string # A designated color for the activity type in 6-character HEX format (e.g. `FFFFFF` for white, `000000` for black) (e.g. FFFFFF)
]: any -> record<success: bool, data: record<id: int, name: string, icon_key: string, color: string, order_nr: int, key_string: string, active_flag: bool, is_custom_flag: bool, add_time: string, update_time: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/activityTypes")
  let body = {name: $name, icon_key: $icon_key, color: $color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an activity type
#
# DELETE /activityTypes/{id}
# operationId: deleteActivityType
export def "activity-types delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: int, name: string, icon_key: string, color: string, order_nr: int, key_string: string, active_flag: bool, is_custom_flag: bool, add_time: string, update_time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activityTypes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an activity type
#
# PUT /activityTypes/{id}
# operationId: updateActivityType
export def "activity-types updateActivityType" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the activity type
  --icon-key: string@icon-key-completer # Icon graphic to use for representing this activity type
  --color: string # A designated color for the activity type in 6-character HEX format (e.g. `FFFFFF` for white, `000000` for black)
  --order-nr: int # An order number for this activity type. Order numbers should be used to order the types in the activity type selections.
]: any -> record<success: bool, data: record<id: int, name: string, icon_key: string, color: string, order_nr: int, key_string: string, active_flag: bool, is_custom_flag: bool, add_time: string, update_time: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activityTypes/($id)")
  let body = {name: $name, icon_key: $icon_key, color: $color, order_nr: $order_nr} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all add-ons for a single company
#
# GET /billing/subscriptions/addons
# operationId: getCompanyAddons
export def "billing-subscriptions-addons get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/billing/subscriptions/addons")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a call log
#
# POST /callLogs
# operationId: addCallLog
export def "call-logs addCallLog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-id: int # The ID of the owner of the call log. Please note that a user without account settings access cannot create call logs for other users.
  --activity-id: int # If specified, this activity will be converted into a call log, with the information provided. When this field is used, you don't need to specify `deal_id`, `person_id` or `org_id`, as they will be ignored in favor of the values already available in the activity. The `activity_id` must refer to a `call` type activity.
  --subject: string # The name of the activity this call is attached to
  --duration: string # The duration of the call in seconds
  outcome: string@outcome-completer # Describes the outcome of the call
  --from-phone-number: string # The number that made the call
  to_phone_number: string # The number called
  start_time: string # The date and time of the start of the call in UTC. Format: YYYY-MM-DD HH:MM:SS. (format: date-time)
  end_time: string # The date and time of the end of the call in UTC. Format: YYYY-MM-DD HH:MM:SS. (format: date-time)
  --person-id: int # The ID of the person this call is associated with
  --org-id: int # The ID of the organization this call is associated with
  --deal-id: int # The ID of the deal this call is associated with. A call log can be associated with either a deal or a lead, but not both at once.
  --lead-id: string # The ID of the lead in the UUID format this call is associated with. A call log can be associated with either a deal or a lead, but not both at once. (format: uuid)
  --note: string # The note for the call log in HTML format
]: any -> record<success: bool, data: record<user_id: int, activity_id: int, subject: string, duration: string, outcome: string, from_phone_number: string, to_phone_number: string, start_time: string, end_time: string, person_id: int, org_id: int, deal_id: int, lead_id: string, note: string, id: string, has_recording: bool, company_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/callLogs")
  let body = {user_id: $user_id, activity_id: $activity_id, subject: $subject, duration: $duration, outcome: $outcome, from_phone_number: $from_phone_number, to_phone_number: $to_phone_number, start_time: $start_time, end_time: $end_time, person_id: $person_id, org_id: $org_id, deal_id: $deal_id, lead_id: $lead_id, note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all call logs assigned to a particular user
#
# GET /callLogs
# operationId: getUserCallLogs
export def "call-logs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # For pagination, the limit of entries to be returned. The upper limit is 50.
]: nothing -> record<success: bool, data: table<user_id: int, activity_id: int, subject: string, duration: string, outcome: string, from_phone_number: string, to_phone_number: string, start_time: string, end_time: string, person_id: int, org_id: int, deal_id: int, lead_id: string, note: string, id: string, has_recording: bool, company_id: int>, additional_data: record<pagination: record<start: int, limit: int, more_items_in_collection: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/callLogs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a call log
#
# DELETE /callLogs/{id}
# operationId: deleteCallLog
export def "call-logs delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/callLogs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details of a call log
#
# GET /callLogs/{id}
# operationId: getCallLog
export def "call-logs get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<user_id: int, activity_id: int, subject: string, duration: string, outcome: string, from_phone_number: string, to_phone_number: string, start_time: string, end_time: string, person_id: int, org_id: int, deal_id: int, lead_id: string, note: string, id: string, has_recording: bool, company_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/callLogs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Attach an audio file to the call log
#
# POST /callLogs/{id}/recordings
# operationId: addCallLogAudioFile
export def "call-logs-recordings addCallLogAudioFile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: string # Audio file supported by the HTML5 specification (format: binary)
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/callLogs/($id)/recordings")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Add a channel
#
# POST /channels
# DEPRECATED
# operationId: addChannel
@deprecated
export def "channels addChannel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the channel (e.g. My Channel)
  provider_channel_id: string # The channel ID
  --avatar-url: string # The URL for an icon that represents your channel (format: url)
  --template-support: oneof<nothing, bool> # If true, enables templates logic on UI. Requires getTemplates endpoint implemented. Find out more [here](https://pipedrive.readme.io/docs/implementing-messaging-app-extension). (default: false)
  --provider-type: string@provider-type-completer # It controls the icons (like the icon next to the conversation) (default: other)
]: any -> record<success: bool, data: record<id: string, name: string, avatar_url: string, provider_channel_id: string, marketplace_client_id: string, pd_company_id: int, pd_user_id: int, created_at: string, provider_type: string, template_support: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels")
  let body = {name: $name, provider_channel_id: $provider_channel_id, avatar_url: $avatar_url, template_support: $template_support, provider_type: $provider_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a channel
#
# DELETE /channels/{id}
# DEPRECATED
# operationId: deleteChannel
@deprecated
export def "channels delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Receives an incoming message
#
# POST /channels/messages/receive
# DEPRECATED
# operationId: receiveMessage
# --attachments item shape: {id: string, type: string, name?: string, size?: float, url: string, preview_url?: string, link_expires?: bool}
@deprecated
export def "channels-messages-receive receiveMessage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string # The ID of the message
  channel_id: string # The channel ID as in the provider
  sender_id: string # The ID of the provider's user that sent the message
  conversation_id: string # The ID of the conversation
  message: string # The body of the message
  status: string@status-completer # The status of the message
  created_at: string # The date and time when the message was created in the provider, in UTC. Format: YYYY-MM-DD HH:MM (format: date-time)
  --reply-by: string # The date and time when the message can no longer receive a reply, in UTC. Format: YYYY-MM-DD HH:MM (format: date-time)
  --conversation-link: string # A URL that can open the conversation in the provider's side (format: url)
  --attachments: list # The list of attachments available in the message — item shape: {id: string, type: string, name?: string, size?: float, url: string, preview_url?: string, link_expires?: bool}
]: any -> record<success: bool, data: record<id: string, channel_id: string, sender_id: string, conversation_id: string, message: string, status: string, created_at: string, reply_by: string, conversation_link: string, attachments: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels/messages/receive")
  let body = {id: $id, channel_id: $channel_id, sender_id: $sender_id, conversation_id: $conversation_id, message: $message, status: $status, created_at: $created_at, reply_by: $reply_by, conversation_link: $conversation_link, attachments: $attachments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a conversation
#
# DELETE /channels/{channel-id}/conversations/{conversation-id}
# DEPRECATED
# operationId: deleteConversation
@deprecated
export def "channels-conversations delete" [
  channel_id: string
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/conversations/($conversation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all supported currencies
#
# GET /currencies
# operationId: getCurrencies
export def "currencies get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --term: string # Optional search term that is searched for from currency's name and/or code
]: nothing -> record<success: bool, data: table<id: int, code: string, name: string, decimal_points: int, symbol: string, active_flag: bool, is_custom_flag: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "term" $term "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/currencies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all archived deals
#
# GET /deals/archived
# DEPRECATED
# operationId: getArchivedDeals
@deprecated
export def "deals-archived get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-id: int # If supplied, only deals matching the given user will be returned. However, `filter_id` and `owned_by_you` takes precedence over `user_id` when supplied.
  --filter-id: int # The ID of the filter to use
  --person-id: int # If supplied, only deals linked to the specified person are returned. If filter_id is provided, this is ignored.
  --org-id: int # If supplied, only deals linked to the specified organization are returned. If filter_id is provided, this is ignored.
  --product-id: int # If supplied, only deals linked to the specified product are returned. If filter_id is provided, this is ignored.
  --pipeline-id: int # If supplied, only deals in the specified pipeline are returned. If filter_id is provided, this is ignored.
  --stage-id: int # If supplied, only deals in the specified stage are returned. If filter_id is provided, this is ignored.
  --status: string@status-completer-1 # Only fetch deals with a specific status. If omitted, all not deleted deals are returned. If set to deleted, deals that have been deleted up to 30 days ago will be included. (default: all_not_deleted)
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
  --qp-sort: string # The field names and sorting mode separated by a comma (`field_name_1 ASC`, `field_name_2 DESC`). Only first-level field keys are supported (no nested keys).
  --owned-by-you: float@owned-by-you-completer # When supplied, only deals owned by you are returned. However, `filter_id` takes precedence over `owned_by_you` when both are supplied.
]: nothing -> record<success: bool, data: table<id: int, creator_user_id: record, user_id: record, person_id: record, org_id: record, stage_id: int, title: string, value: float, currency: string, add_time: string, update_time: string, stage_change_time: string, active: bool, deleted: bool, is_archived: bool, status: string, probability: float, next_activity_date: string, next_activity_time: string, next_activity_id: int, last_activity_id: int, last_activity_date: string, lost_reason: string, visible_to: string, close_time: string, pipeline_id: int, won_time: string, first_won_time: string, lost_time: string, products_count: int, files_count: int, notes_count: int, followers_count: int, email_messages_count: int, activities_count: int, done_activities_count: int, undone_activities_count: int, participants_count: int, expected_close_date: string, last_incoming_mail_time: string, last_outgoing_mail_time: string, label: string, stage_order_nr: int, person_name: string, org_name: string, next_activity_subject: string, next_activity_type: string, next_activity_duration: string, next_activity_note: string, formatted_value: string, weighted_value: float, formatted_weighted_value: string, weighted_value_currency: string, rotten_time: string, owner_name: string, cc_email: string, org_hidden: bool, person_hidden: bool, origin: string, origin_id: string, channel: int, channel_id: string, arr: float, mrr: float, acv: float, arr_currency: string, mrr_currency: string, acv_currency: string>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>, related_objects: record<user: record<USER_ID: record>, organization: record<ORGANIZATION_ID: record>, person: record<PERSON_ID: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "filter_id" $filter_id "scalar") (serialize-qp "person_id" $person_id "scalar") (serialize-qp "org_id" $org_id "scalar") (serialize-qp "product_id" $product_id "scalar") (serialize-qp "pipeline_id" $pipeline_id "scalar") (serialize-qp "stage_id" $stage_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "owned_by_you" $owned_by_you "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deals/archived" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get deals summary
#
# GET /deals/summary
# operationId: getDealsSummary
export def "deals-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-2 # Only fetch deals with a specific status. open = Open, won = Won, lost = Lost.
  --filter-id: int # <code>user_id</code> will not be considered. Only deals matching the given filter will be returned.
  --user-id: int # Only deals matching the given user will be returned. `user_id` will not be considered if you use `filter_id`.
  --pipeline-id: int # Only deals within the given pipeline will be returned
  --stage-id: int # Only deals within the given stage will be returned
]: nothing -> record<success: bool, data: record<values_total: record<value: float, count: int, value_converted: float, value_formatted: string, value_converted_formatted: string>, weighted_values_total: record<value: float, count: int, value_formatted: string>, total_count: int, total_currency_converted_value: float, total_weighted_currency_converted_value: float, total_currency_converted_value_formatted: string, total_weighted_currency_converted_value_formatted: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "filter_id" $filter_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "pipeline_id" $pipeline_id "scalar") (serialize-qp "stage_id" $stage_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deals/summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get archived deals summary
#
# GET /deals/summary/archived
# DEPRECATED
# operationId: getArchivedDealsSummary
@deprecated
export def "deals-summary-archived get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-2 # Only fetch deals with a specific status. open = Open, won = Won, lost = Lost.
  --filter-id: int # <code>user_id</code> will not be considered. Only deals matching the given filter will be returned.
  --user-id: int # Only deals matching the given user will be returned. `user_id` will not be considered if you use `filter_id`.
  --pipeline-id: int # Only deals within the given pipeline will be returned
  --stage-id: int # Only deals within the given stage will be returned
]: nothing -> record<success: bool, data: record<values_total: record<value: float, count: int, value_converted: float, value_formatted: string, value_converted_formatted: string>, weighted_values_total: record<value: float, count: int, value_formatted: string>, total_count: int, total_currency_converted_value: float, total_weighted_currency_converted_value: float, total_currency_converted_value_formatted: string, total_weighted_currency_converted_value_formatted: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "filter_id" $filter_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "pipeline_id" $pipeline_id "scalar") (serialize-qp "stage_id" $stage_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deals/summary/archived" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get deals timeline
#
# GET /deals/timeline
# operationId: getDealsTimeline
export def "deals-timeline get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # The date when the first interval starts. Format: YYYY-MM-DD. (format: date)
  --interval: string@interval-completer # The type of the interval<table><tr><th>Value</th><th>Description</th></tr><tr><td>`day`</td><td>Day</td></tr><tr><td>`week`</td><td>A full week (7 days) starting from `start_date`</td></tr><tr><td>`month`</td><td>A full month (depending on the number of days in given month) starting from `start_date`</td></tr><tr><td>`quarter`</td><td>A full quarter (3 months) starting from `start_date`</td></tr></table>
  --amount: int # The number of given intervals, starting from `start_date`, to fetch. E.g. 3 (months).
  --field-key: string # The date field key which deals will be retrieved from
  --user-id: int # If supplied, only deals matching the given user will be returned
  --pipeline-id: int # If supplied, only deals matching the given pipeline will be returned
  --filter-id: int # If supplied, only deals matching the given filter will be returned
  --exclude-deals: float@exclude-deals-completer # Whether to exclude deals list (1) or not (0). Note that when deals are excluded, the timeline summary (counts and values) is still returned.
  --totals-convert-currency: string # The 3-letter currency code of any of the supported currencies. When supplied, `totals_converted` is returned per each interval which contains the currency-converted total amounts in the given currency. You may also set this parameter to `default_currency` in which case the user's default currency is used.
]: nothing -> record<success: bool, data: record<period_start: string, period_end: string, deals: list<record>, totals: record<count: int, values: record, weighted_values: record, open_count: int, open_values: record, weighted_open_values: record, won_count: int, won_values: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "field_key" $field_key "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "pipeline_id" $pipeline_id "scalar") (serialize-qp "filter_id" $filter_id "scalar") (serialize-qp "exclude_deals" $exclude_deals "scalar") (serialize-qp "totals_convert_currency" $totals_convert_currency "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deals/timeline" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get archived deals timeline
#
# GET /deals/timeline/archived
# DEPRECATED
# operationId: getArchivedDealsTimeline
@deprecated
export def "deals-timeline-archived get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # The date when the first interval starts. Format: YYYY-MM-DD. (format: date)
  --interval: string@interval-completer # The type of the interval<table><tr><th>Value</th><th>Description</th></tr><tr><td>`day`</td><td>Day</td></tr><tr><td>`week`</td><td>A full week (7 days) starting from `start_date`</td></tr><tr><td>`month`</td><td>A full month (depending on the number of days in given month) starting from `start_date`</td></tr><tr><td>`quarter`</td><td>A full quarter (3 months) starting from `start_date`</td></tr></table>
  --amount: int # The number of given intervals, starting from `start_date`, to fetch. E.g. 3 (months).
  --field-key: string # The date field key which deals will be retrieved from
  --user-id: int # If supplied, only deals matching the given user will be returned
  --pipeline-id: int # If supplied, only deals matching the given pipeline will be returned
  --filter-id: int # If supplied, only deals matching the given filter will be returned
  --exclude-deals: float@exclude-deals-completer # Whether to exclude deals list (1) or not (0). Note that when deals are excluded, the timeline summary (counts and values) is still returned.
  --totals-convert-currency: string # The 3-letter currency code of any of the supported currencies. When supplied, `totals_converted` is returned per each interval which contains the currency-converted total amounts in the given currency. You may also set this parameter to `default_currency` in which case the user's default currency is used.
]: nothing -> record<success: bool, data: record<period_start: string, period_end: string, deals: list<record>, totals: record<count: int, values: record, weighted_values: record, open_count: int, open_values: record, weighted_open_values: record, won_count: int, won_values: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "field_key" $field_key "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "pipeline_id" $pipeline_id "scalar") (serialize-qp "filter_id" $filter_id "scalar") (serialize-qp "exclude_deals" $exclude_deals "scalar") (serialize-qp "totals_convert_currency" $totals_convert_currency "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deals/timeline/archived" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List updates about deal field values
#
# GET /deals/{id}/changelog
# operationId: getDealChangelog
export def "deals-changelog get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # For pagination, the marker (an opaque string value) representing the first item on the next page
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: table<field_key: string, old_value: string, new_value: string, actor_user_id: int, time: string, change_source: string, change_source_user_agent: string, is_bulk_update_flag: bool>, additional_data: record<next_cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deals/($id)/changelog" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Duplicate deal
#
# POST /deals/{id}/duplicate
# operationId: duplicateDeal
export def "deals-duplicate duplicateDeal" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: int, creator_user_id: int, user_id: int, person_id: int, org_id: int, stage_id: int, title: string, value: float, currency: string, add_time: string, update_time: string, stage_change_time: string, active: bool, deleted: bool, is_archived: bool, status: string, probability: float, next_activity_date: string, next_activity_time: string, next_activity_id: int, last_activity_id: int, last_activity_date: string, lost_reason: string, visible_to: string, close_time: string, pipeline_id: int, won_time: string, first_won_time: string, lost_time: string, products_count: int, files_count: int, notes_count: int, followers_count: int, email_messages_count: int, activities_count: int, done_activities_count: int, undone_activities_count: int, participants_count: int, expected_close_date: string, last_incoming_mail_time: string, last_outgoing_mail_time: string, label: string, stage_order_nr: int, person_name: string, org_name: string, next_activity_subject: string, next_activity_type: string, next_activity_duration: string, next_activity_note: string, formatted_value: string, weighted_value: float, formatted_weighted_value: string, weighted_value_currency: string, rotten_time: string, owner_name: string, cc_email: string, org_hidden: bool, person_hidden: bool, origin: string, origin_id: string, channel: int, channel_id: string, arr: float, mrr: float, acv: float, arr_currency: string, mrr_currency: string, acv_currency: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deals/($id)/duplicate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List files attached to a deal
#
# GET /deals/{id}/files
# operationId: getDealFiles
export def "deals-files get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page. Please note that a maximum value of 100 is allowed.
  --qp-sort: string # Supported fields: `id`, `update_time`
]: nothing -> record<success: bool, data: table<id: int, user_id: int, deal_id: int, person_id: int, org_id: int, product_id: int, activity_id: int, lead_id: string, add_time: string, update_time: string, file_name: string, file_size: int, active_flag: bool, inline_flag: bool, remote_location: string, remote_id: string, cid: string, s3_bucket: string, mail_message_id: string, mail_template_id: string, deal_name: string, person_name: string, org_name: string, product_name: string, lead_name: string, url: string, name: string, description: string>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deals/($id)/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List updates about a deal
#
# GET /deals/{id}/flow
# operationId: getDealUpdates
export def "deals-flow get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
  --all-changes: string # Whether to show custom field updates or not. 1 = Include custom field changes. If omitted returns changes without custom field updates.
  --items: string # A comma-separated string for filtering out item specific updates. (Possible values - call, activity, plannedActivity, change, note, deal, file, dealChange, personChange, organizationChange, follower, dealFollower, personFollower, organizationFollower, participant, comment, mailMessage, mailMessageWithAttachment, invoice, document, marketing_campaign_stat, marketing_status_change).
]: nothing -> record<success: bool, data: table<object: string, timestamp: string, data: record>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>, related_objects: record<deal: record<DEAL_ID: record>, organization: record<ORGANIZATION_ID: record>, user: record<USER_ID: record>, person: record<PERSON_ID: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "all_changes" $all_changes "scalar") (serialize-qp "items" $items "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deals/($id)/flow" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List updates about participants of a deal
#
# GET /deals/{id}/participantsChangelog
# operationId: getDealParticipantsChangelog
export def "deals-participants-changelog get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Items shown per page
  --cursor: string # For pagination, the marker (an opaque string value) representing the first item on the next page
]: nothing -> record<success: bool, data: list<record>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deals/($id)/participantsChangelog" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List followers of a deal
#
# GET /deals/{id}/followers
# operationId: getDealFollowers
export def "deals-followers get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: table<user_id: int, id: int, deal_id: int, add_time: string>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deals/($id)/followers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a follower to a deal
#
# POST /deals/{id}/followers
# operationId: addDealFollower
export def "deals-followers addDealFollower" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: int # The ID of the user
]: any -> record<success: bool, data: record<user_id: int, id: int, deal_id: int, add_time: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deals/($id)/followers")
  let body = {user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a follower from a deal
#
# DELETE /deals/{id}/followers/{follower_id}
# operationId: deleteDealFollower
export def "deals-followers delete" [
  id: int
  follower_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deals/($id)/followers/($follower_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List mail messages associated with a deal
#
# GET /deals/{id}/mailMessages
# operationId: getDealMailMessages
export def "deals-mail-messages get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: table<object: string, timestamp: string, data: record>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deals/($id)/mailMessages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merge two deals
#
# PUT /deals/{id}/merge
# operationId: mergeDeals
export def "deals-merge mergeDeals" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  merge_with_id: int # The ID of the deal that the deal will be merged with
]: any -> record<success: bool, data: record<merge_what_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deals/($id)/merge")
  let body = {merge_with_id: $merge_with_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List participants of a deal
#
# GET /deals/{id}/participants
# operationId: getDealParticipants
export def "deals-participants get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: table<id: int, person_id: record, add_time: string, active_flag: bool, related_item_data: record, person: record, added_by_user_id: record, related_item_type: string, related_item_id: int>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>, related_objects: record<user: record<USER_ID: record>, organization: record<ORGANIZATION_ID: record>, person: record<PERSON_ID: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deals/($id)/participants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a participant to a deal
#
# POST /deals/{id}/participants
# operationId: addDealParticipant
export def "deals-participants addDealParticipant" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  person_id: int # The ID of the person
]: any -> record<success: bool, data: record<id: int, person_id: record<active_flag: bool, name: string, email: list, phone: list, owner_id: int, company_id: int, value: int>, add_time: string, active_flag: bool, related_item_data: record<deal_id: int, title: string>, person: record, added_by_user_id: record<success: bool, data: record>, related_item_type: string, related_item_id: int>, related_objects: record<user: record<USER_ID: record>, person: record<PERSON_ID: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deals/($id)/participants")
  let body = {person_id: $person_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a participant from a deal
#
# DELETE /deals/{id}/participants/{deal_participant_id}
# operationId: deleteDealParticipant
export def "deals-participants delete" [
  id: int
  deal_participant_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deals/($id)/participants/($deal_participant_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List permitted users
#
# GET /deals/{id}/permittedUsers
# operationId: getDealUsers
export def "deals-permitted-users get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deals/($id)/permittedUsers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all deal fields
#
# GET /dealFields
# operationId: getDealFields
export def "deal-fields list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: list<record>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dealFields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new deal field
#
# POST /dealFields
# operationId: addDealField
export def "deal-fields addDealField" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the field
  --options: list # When `field_type` is either set or enum, possible options must be supplied as a JSON-encoded sequential array of objects. Example: `[{"label":"New Item"}]`
  --add-visible-flag: oneof<nothing, bool> # Whether the field is available in the 'add new' modal or not (both in the web and mobile app) (default: true)
  field_type: string@field-type-completer # The type of the field<table><tr><th>Value</th><th>Description</th></tr><tr><td>`address`</td><td>Address field</td></tr><tr><td>`date`</td><td>Date (format YYYY-MM-DD)</td></tr><tr><td>`daterange`</td><td>Date-range field (has a start date and end date value, both YYYY-MM-DD)</td></tr><tr><td>`double`</td><td>Numeric value</td></tr><tr><td>`enum`</td><td>Options field with a single possible chosen option</td></tr><tr></tr><tr><td>`monetary`</td><td>Monetary field (has a numeric value and a currency value)</td></tr><tr><td>`org`</td><td>Organization field (contains an organization ID which is stored on the same account)</td></tr><tr><td>`people`</td><td>Person field (contains a person ID which is stored on the same account)</td></tr><tr><td>`phone`</td><td>Phone field (up to 255 numbers and/or characters)</td></tr><tr><td>`set`</td><td>Options field with a possibility of having multiple chosen options</td></tr><tr><td>`text`</td><td>Long text (up to 65k characters)</td></tr><tr><td>`time`</td><td>Time field (format HH:MM:SS)</td></tr><tr><td>`timerange`</td><td>Time-range field (has a start time and end time value, both HH:MM:SS)</td></tr><tr><td>`user`</td><td>User field (contains a user ID of another Pipedrive user)</td></tr><tr><td>`varchar`</td><td>Text (up to 255 characters)</td></tr><tr><td>`varchar_auto`</td><td>Autocomplete text (up to 255 characters)</td></tr><tr><td>`visible_to`</td><td>System field that keeps item's visibility setting</td></tr></table>
]: any -> record<success: bool, data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dealFields")
  let body = {name: $name, options: $options, add_visible_flag: $add_visible_flag, field_type: $field_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete multiple deal fields in bulk
#
# DELETE /dealFields
# operationId: deleteDealFields
export def "deal-fields delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # The comma-separated field IDs to delete
]: nothing -> record<success: bool, data: record<id: list<int>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dealFields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one deal field
#
# GET /dealFields/{id}
# operationId: getDealField
export def "deal-fields get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dealFields/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a deal field
#
# DELETE /dealFields/{id}
# operationId: deleteDealField
export def "deal-fields delete-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dealFields/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a deal field
#
# PUT /dealFields/{id}
# operationId: updateDealField
export def "deal-fields updateDealField" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the field
  --options: list # When `field_type` is either set or enum, possible options must be supplied as a JSON-encoded sequential array of objects. All active items must be supplied and already existing items must have their ID supplied. New items only require a label. Example: `[{"id":123,"label":"Existing Item"},{"label":"New Item"}]`
  --add-visible-flag: oneof<nothing, bool> # Whether the field is available in 'add new' modal or not (both in web and mobile app) (default: true)
]: any -> record<success: bool, data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dealFields/($id)")
  let body = {name: $name, options: $options, add_visible_flag: $add_visible_flag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all files
#
# GET /files
# operationId: getFiles
export def "files list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page. Please note that a maximum value of 100 is allowed.
  --qp-sort: string # Supported fields: `id`, `update_time`
]: nothing -> record<success: bool, data: table<id: int, user_id: int, deal_id: int, person_id: int, org_id: int, product_id: int, activity_id: int, lead_id: string, project_id: int, add_time: string, update_time: string, file_name: string, file_size: int, active_flag: bool, inline_flag: bool, remote_location: string, remote_id: string, cid: string, s3_bucket: string, mail_message_id: string, mail_template_id: string, deal_name: string, person_name: string, org_name: string, product_name: string, lead_name: string, project_name: string, url: string, name: string, description: string>, additional_data: record<pagination: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add file
#
# POST /files
# operationId: addFile
export def "files addFile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: string # A single file, supplied in the multipart/form-data encoding and contained within the given boundaries (format: binary)
  --deal-id: int # The ID of the deal to associate file(s) with
  --person-id: int # The ID of the person to associate file(s) with
  --org-id: int # The ID of the organization to associate file(s) with
  --product-id: int # The ID of the product to associate file(s) with
  --activity-id: int # The ID of the activity to associate file(s) with
  --lead-id: string # The ID of the lead to associate file(s) with (format: uuid)
  --project-id: int # The ID of the project to associate file(s) with
]: any -> record<success: bool, data: record<id: int, user_id: int, deal_id: int, person_id: int, org_id: int, product_id: int, activity_id: int, lead_id: string, project_id: int, add_time: string, update_time: string, file_name: string, file_size: int, active_flag: bool, inline_flag: bool, remote_location: string, remote_id: string, cid: string, s3_bucket: string, mail_message_id: string, mail_template_id: string, deal_name: string, person_name: string, org_name: string, product_name: string, lead_name: string, project_name: string, url: string, name: string, description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files")
  let body = {file: $file, deal_id: $deal_id, person_id: $person_id, org_id: $org_id, product_id: $product_id, activity_id: $activity_id, lead_id: $lead_id, project_id: $project_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Create a remote file and link it to an item
#
# POST /files/remote
# operationId: addFileAndLinkIt
export def "files-remote addFileAndLinkIt" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file_type: string@file-type-completer # The file type
  title: string # The title of the file
  item_type: string@item-type-completer # The item type
  item_id: int # The ID of the item to associate the file with
  remote_location: string@remote-location-completer # The location type to send the file to. Only `googledrive` is supported at the moment.
]: any -> record<success: bool, data: record<id: int, user_id: int, deal_id: int, person_id: int, org_id: int, product_id: int, activity_id: int, lead_id: string, project_id: int, add_time: string, update_time: string, file_name: string, file_size: int, active_flag: bool, inline_flag: bool, remote_location: string, remote_id: string, cid: string, s3_bucket: string, mail_message_id: string, mail_template_id: string, deal_name: string, person_name: string, org_name: string, product_name: string, lead_name: string, project_name: string, url: string, name: string, description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files/remote")
  let body = {file_type: $file_type, title: $title, item_type: $item_type, item_id: $item_id, remote_location: $remote_location} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Link a remote file to an item
#
# POST /files/remoteLink
# operationId: linkFileToItem
export def "files-remote-link linkFileToItem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  item_type: string@item-type-completer # The item type
  item_id: int # The ID of the item to associate the file with
  remote_id: string # The remote item ID
  remote_location: string@remote-location-completer # The location type to send the file to. Only `googledrive` is supported at the moment.
]: any -> record<success: bool, data: record<id: int, user_id: int, deal_id: int, person_id: int, org_id: int, product_id: int, activity_id: int, lead_id: string, project_id: int, add_time: string, update_time: string, file_name: string, file_size: int, active_flag: bool, inline_flag: bool, remote_location: string, remote_id: string, cid: string, s3_bucket: string, mail_message_id: string, mail_template_id: string, deal_name: string, person_name: string, org_name: string, product_name: string, lead_name: string, project_name: string, url: string, name: string, description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files/remoteLink")
  let body = {item_type: $item_type, item_id: $item_id, remote_id: $remote_id, remote_location: $remote_location} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a file
#
# DELETE /files/{id}
# operationId: deleteFile
export def "files delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one file
#
# GET /files/{id}
# operationId: getFile
export def "files get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: int, user_id: int, deal_id: int, person_id: int, org_id: int, product_id: int, activity_id: int, lead_id: string, project_id: int, add_time: string, update_time: string, file_name: string, file_size: int, active_flag: bool, inline_flag: bool, remote_location: string, remote_id: string, cid: string, s3_bucket: string, mail_message_id: string, mail_template_id: string, deal_name: string, person_name: string, org_name: string, product_name: string, lead_name: string, project_name: string, url: string, name: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update file details
#
# PUT /files/{id}
# operationId: updateFile
export def "files updateFile" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The visible name of the file
  --description: string # The description of the file
]: any -> record<success: bool, data: record<id: int, user_id: int, deal_id: int, person_id: int, org_id: int, product_id: int, activity_id: int, lead_id: string, project_id: int, add_time: string, update_time: string, file_name: string, file_size: int, active_flag: bool, inline_flag: bool, remote_location: string, remote_id: string, cid: string, s3_bucket: string, mail_message_id: string, mail_template_id: string, deal_name: string, person_name: string, org_name: string, product_name: string, lead_name: string, project_name: string, url: string, name: string, description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($id)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Download one file
#
# GET /files/{id}/download
# operationId: downloadFile
export def "files-download downloadFile" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($id)/download")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete multiple filters in bulk
#
# DELETE /filters
# operationId: deleteFilters
export def "filters delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # The comma-separated filter IDs to delete
]: nothing -> record<success: bool, data: record<id: list<int>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/filters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all filters
#
# GET /filters
# operationId: getFilters
export def "filters list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer # The types of filters to fetch
]: nothing -> record<success: bool, data: table<id: int, name: string, filter_code: string, is_editable: bool, active_flag: bool, type: string, temporary_flag: bool, user_id: int, add_time: string, update_time: string, visible_to: record, last_used_time: string, custom_view_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/filters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new filter
#
# POST /filters
# operationId: addFilter
export def "filters addFilter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-field-code: oneof<nothing, bool> # If set to `true`, each condition in the response includes a `field_code` field identifying the field by its code name
  name: string # The name of the filter
  conditions: record # The conditions of the filter as a JSON object. Please note that a maximum of 16 conditions is allowed per filter and `date` values must be supplied in the `YYYY-MM-DD` format. It requires a minimum structure as follows: `{"glue":"and","conditions":[{"glue":"and","conditions": [CONDITION_OBJECTS]},{"glue":"or","conditions":[CONDITION_OBJECTS]}]}`. Replace `CONDITION_OBJECTS` with JSON objects of the following structure: `{"object":"","field_id":"", "operator":"","value":"", "extra_value":""}` or leave the array empty. Depending on the object type you should use another API endpoint to get `field_id`. There are five types of objects you can choose from: `"person"`, `"deal"`, `"organization"`, `"product"`, `"activity"` and you can use these types of operators depending on what type of a field you have: `"IS NOT NULL"`, `"IS NULL"`, `"<="`, `">="`, `"<"`, `">"`, `"!="`, `"="`, `"LIKE '$%'"`, `"LIKE '%$%'"`, `"NOT LIKE '$%'"`. To get a better understanding of how filters work try creating them directly from the Pipedrive application.
  type: string # The type of filter to create
]: any -> record<success: bool, data: record<id: int, name: string, filter_code: string, is_editable: bool, active_flag: bool, type: string, temporary_flag: bool, user_id: int, add_time: string, update_time: string, visible_to: record, last_used_time: string, custom_view_id: int, conditions: record<glue: string, conditions: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_field_code" $include_field_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/filters" $qp)
  let body = {name: $name, conditions: $conditions, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all filter helpers
#
# GET /filters/helpers
# operationId: getFilterHelpers
export def "filters-helpers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/filters/helpers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a filter
#
# DELETE /filters/{id}
# operationId: deleteFilter
export def "filters delete-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/filters/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one filter
#
# GET /filters/{id}
# operationId: getFilter
export def "filters get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-field-code: oneof<nothing, bool> # If set to `true`, each condition in the response includes a `field_code` field identifying the field by its code name
]: nothing -> record<success: bool, data: record<id: int, name: string, filter_code: string, is_editable: bool, active_flag: bool, type: string, temporary_flag: bool, user_id: int, add_time: string, update_time: string, visible_to: record, last_used_time: string, custom_view_id: int, conditions: record<glue: string, conditions: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_field_code" $include_field_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/filters/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update filter
#
# PUT /filters/{id}
# operationId: updateFilter
export def "filters updateFilter" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-field-code: oneof<nothing, bool> # If set to `true`, each condition in the response includes a `field_code` field identifying the field by its code name
  --name: string # The name of the filter
  conditions: record # The conditions of the filter as a JSON object. Please note that a maximum of 16 conditions is allowed per filter and `date` values must be supplied in the `YYYY-MM-DD` format. It requires a minimum structure as follows: `{"glue":"and","conditions":[{"glue":"and","conditions": [CONDITION_OBJECTS]},{"glue":"or","conditions":[CONDITION_OBJECTS]}]}`. Replace `CONDITION_OBJECTS` with JSON objects of the following structure: `{"object":"","field_id":"", "operator":"","value":"", "extra_value":""}` or leave the array empty. Depending on the object type you should use another API endpoint to get `field_id`. There are five types of objects you can choose from: `"person"`, `"deal"`, `"organization"`, `"product"`, `"activity"` and you can use these types of operators depending on what type of a field you have: `"IS NOT NULL"`, `"IS NULL"`, `"<="`, `">="`, `"<"`, `">"`, `"!="`, `"="`, `"LIKE '$%'"`, `"LIKE '%$%'"`, `"NOT LIKE '$%'"`. To get a better understanding of how filters work try creating them directly from the Pipedrive application.
]: any -> record<success: bool, data: record<id: int, name: string, filter_code: string, is_editable: bool, active_flag: bool, type: string, temporary_flag: bool, user_id: int, add_time: string, update_time: string, visible_to: record, last_used_time: string, custom_view_id: int, conditions: record<glue: string, conditions: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_field_code" $include_field_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/filters/($id)" $qp)
  let body = {name: $name, conditions: $conditions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a new goal
#
# POST /goals
# operationId: addGoal
export def "goals addGoal" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # The title of the goal
  assignee: record # Who this goal is assigned to. It requires the following JSON structure: `{ "id": "1", "type": "person" }`. `type` can be either `person`, `company` or `team`. ID of the assignee person, company or team.
  type: record # The type of the goal. It requires the following JSON structure: `{ "name": "deals_started", "params": { "pipeline_id": [1, 2], "activity_type_id": [9] } }`. Type can be one of: `deals_won`, `deals_progressed`, `activities_completed`, `activities_added`, `deals_started` or `revenue_forecast`. `params` can include `pipeline_id`, `stage_id` or `activity_type_id`. `stage_id` is related to only `deals_progressed` type of goals and `activity_type_id` to `activities_completed` or `activities_added` types of goals. The `pipeline_id` and `activity_type_id` need to be given as an array of integers. To track the goal in all pipelines, set `pipeline_id` as `null` and similarly, to track the goal for all activities, set `activity_type_id` as `null`.”
  expected_outcome: record # The expected outcome of the goal. Expected outcome can be tracked either by `quantity` or by `sum`. It requires the following JSON structure: `{ "target": "50", "tracking_metric": "quantity" }` or `{ "target": "50", "tracking_metric": "sum", "currency_id": 1 }`. `currency_id` should only be added to `sum` type of goals.
  duration: record # The date when the goal starts and ends. It requires the following JSON structure: `{ "start": "2019-01-01", "end": "2022-12-31" }`. Date in format of YYYY-MM-DD. "end" can be set to `null` for an infinite, open-ended goal.
  interval: string@interval-completer-1 # The interval of the goal
]: any -> record<success: bool, data: record<goal: record<id: string, owner_id: int, title: string, type: record, assignee: record, interval: string, duration: record, expected_outcome: record, is_active: bool, report_ids: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/goals")
  let body = {title: $title, assignee: $assignee, type: $type, expected_outcome: $expected_outcome, duration: $duration, interval: $interval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find goals
#
# GET /goals/find
# operationId: getGoals
export def "goals-find get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --typename: string@typename-completer # The type of the goal. If provided, everyone's goals will be returned.
  --title: string # The title of the goal
  --is-active: oneof<nothing, bool> # Whether the goal is active or not (default: true)
  --assigneeid: int # The ID of the user who's goal to fetch. When omitted, only your goals will be returned.
  --assigneetype: string@assigneetype-completer # The type of the goal's assignee. If provided, everyone's goals will be returned.
  --expected-outcometarget: float # The numeric value of the outcome. If provided, everyone's goals will be returned.
  --expected-outcometracking-metric: string@expected-outcometracking-metric-completer # The tracking metric of the expected outcome of the goal. If provided, everyone's goals will be returned.
  --expected-outcomecurrency-id: int # The numeric ID of the goal's currency. Only applicable to goals with `expected_outcome.tracking_metric` with value `sum`. If provided, everyone's goals will be returned.
  --typeparamspipeline-id: list # An array of pipeline IDs or `null` for all pipelines. If provided, everyone's goals will be returned.
  --typeparamsstage-id: int # The ID of the stage. Applicable to only `deals_progressed` type of goals. If provided, everyone's goals will be returned.
  --typeparamsactivity-type-id: list # An array of IDs or `null` for all activity types. Only applicable for `activities_completed` and/or `activities_added` types of goals. If provided, everyone's goals will be returned.
  --periodstart: string # The start date of the period for which to find goals. Date in format of YYYY-MM-DD. When `period.start` is provided, `period.end` must be provided too. (format: date)
  --periodend: string # The end date of the period for which to find goals. Date in format of YYYY-MM-DD. (format: date)
]: nothing -> record<success: bool, data: record<goals: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type.name" $typename "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "is_active" $is_active "scalar") (serialize-qp "assignee.id" $assigneeid "scalar") (serialize-qp "assignee.type" $assigneetype "scalar") (serialize-qp "expected_outcome.target" $expected_outcometarget "scalar") (serialize-qp "expected_outcome.tracking_metric" $expected_outcometracking_metric "scalar") (serialize-qp "expected_outcome.currency_id" $expected_outcomecurrency_id "scalar") (serialize-qp "type.params.pipeline_id" $typeparamspipeline_id "multi") (serialize-qp "type.params.stage_id" $typeparamsstage_id "scalar") (serialize-qp "type.params.activity_type_id" $typeparamsactivity_type_id "multi") (serialize-qp "period.start" $periodstart "scalar") (serialize-qp "period.end" $periodend "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/goals/find" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update existing goal
#
# PUT /goals/{id}
# operationId: updateGoal
export def "goals updateGoal" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # The title of the goal
  --assignee: record # Who this goal is assigned to. It requires the following JSON structure: `{ "id": "1", "type": "person" }`. `type` can be either `person`, `company` or `team`. ID of the assignee person, company or team.
  --type: record # The type of the goal. It requires the following JSON structure: `{ "name": "deals_started", "params": { "pipeline_id": [1, 2], "activity_type_id": [9] } }`. Type can be one of: `deals_won`, `deals_progressed`, `activities_completed`, `activities_added`, `deals_started` or `revenue_forecast`. `params` can include `pipeline_id`, `stage_id` or `activity_type_id`. `stage_id` is related to only `deals_progressed` type of goals and `activity_type_id` to `activities_completed` or `activities_added` types of goals. The `pipeline_id` and `activity_type_id` need to be given as an array of integers. To track the goal in all pipelines, set `pipeline_id` as `null` and similarly, to track the goal for all activities, set `activity_type_id` as `null`.”
  --expected-outcome: record # The expected outcome of the goal. Expected outcome can be tracked either by `quantity` or by `sum`. It requires the following JSON structure: `{ "target": "50", "tracking_metric": "quantity" }` or `{ "target": "50", "tracking_metric": "sum", "currency_id": 1 }`. `currency_id` should only be added to `sum` type of goals.
  --duration: record # The date when the goal starts and ends. It requires the following JSON structure: `{ "start": "2019-01-01", "end": "2022-12-31" }`. Date in format of YYYY-MM-DD. "end" can be set to `null` for an infinite, open-ended goal.
  --interval: string@interval-completer-1 # The interval of the goal
]: any -> record<success: bool, data: record<goal: record<id: string, owner_id: int, title: string, type: record, assignee: record, interval: string, duration: record, expected_outcome: record, is_active: bool, report_ids: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/goals/($id)")
  let body = {title: $title, assignee: $assignee, type: $type, expected_outcome: $expected_outcome, duration: $duration, interval: $interval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete existing goal
#
# DELETE /goals/{id}
# operationId: deleteGoal
export def "goals delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/goals/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get result of a goal
#
# GET /goals/{id}/results
# operationId: getGoalResult
export def "goals-results get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --periodstart: string # The start date of the period for which to find the goal's progress. Format: YYYY-MM-DD. This date must be the same or after the goal duration start date.  (format: date)
  --periodend: string # The end date of the period for which to find the goal's progress. Format: YYYY-MM-DD. This date must be the same or before the goal duration end date.  (format: date)
]: nothing -> record<success: bool, data: record<progress: int, goal: record<id: string, owner_id: int, title: string, type: record, assignee: record, interval: string, duration: record, expected_outcome: record, is_active: bool, report_ids: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period.start" $periodstart "scalar") (serialize-qp "period.end" $periodend "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($id)/results" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all leads
#
# GET /leads
# operationId: getLeads
export def "leads list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # For pagination, the limit of entries to be returned. If not provided, 100 items will be returned. (e.g. 100)
  --start: int # For pagination, the position that represents the first result for the page (e.g. 0)
  --owner-id: int # If supplied, only leads matching the given user will be returned. However, `filter_id` takes precedence over `owner_id` when supplied. (e.g. 1)
  --person-id: int # If supplied, only leads matching the given person will be returned. However, `filter_id` takes precedence over `person_id` when supplied. (e.g. 1)
  --organization-id: int # If supplied, only leads matching the given organization will be returned. However, `filter_id` takes precedence over `organization_id` when supplied. (e.g. 1)
  --filter-id: int # The ID of the filter to use (e.g. 1)
  --updated-since: string # If set, only leads with an `update_time` later than or equal to this time are returned. In ISO 8601 format, e.g. 2025-01-01T10:20:00Z. (e.g. 2025-01-01T10:20:00Z)
  --qp-sort: string@sort-completer # The field names and sorting mode separated by a comma (`field_name_1 ASC`, `field_name_2 DESC`). Only first-level field keys are supported (no nested keys).
]: nothing -> record<success: bool, data: table<id: string, title: string, owner_id: int, creator_id: int, label_ids: list, person_id: int, organization_id: int, source_name: string, origin: string, origin_id: string, channel: int, channel_id: string, source_deal_id: int, is_archived: bool, was_seen: bool, value: record, expected_close_date: string, next_activity_id: int, add_time: string, update_time: string, visible_to: string, cc_email: string>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "owner_id" $owner_id "scalar") (serialize-qp "person_id" $person_id "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "filter_id" $filter_id "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a lead
#
# POST /leads
# operationId: addLead
# --value shape: {amount: float, currency: string}
export def "leads addLead" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string # The name of the lead
  --owner-id: int # The ID of the user which will be the owner of the created lead. If not provided, the user making the request will be used.
  --label-ids: list # The IDs of the lead labels which will be associated with the lead
  --person-id: int # The ID of a person which this lead will be linked to. If the person does not exist yet, it needs to be created first. This property is required unless `organization_id` is specified.
  --organization-id: int # The ID of an organization which this lead will be linked to. If the organization does not exist yet, it needs to be created first. This property is required unless `person_id` is specified.
  --value: record # The potential value of the lead represented by a JSON object: `{ "amount": 200, "currency": "EUR" }`. Both amount and currency are required. (nullable) — shape: {amount: float, currency: string}
  --expected-close-date: string # The date of when the deal which will be created from the lead is expected to be closed. In ISO 8601 format: YYYY-MM-DD. (format: date)
  --visible-to: string # The visibility of the lead. If omitted, the visibility will be set to the default visibility setting of this item type for the authorized user. Read more about visibility groups <a href="https://support.pipedrive.com/en/article/visibility-groups" target="_blank" rel="noopener noreferrer">here</a>.<h4>Light / Growth and Professional plans</h4><table><tr><th style="width: 40px">Value</th><th>Description</th></tr><tr><td>`1`</td><td>Owner &amp; followers</td><tr><td>`3`</td><td>Entire company</td></tr></table><h4>Premium / Ultimate plan</h4><table><tr><th style="width: 40px">Value</th><th>Description</th></tr><tr><td>`1`</td><td>Owner only</td><tr><td>`3`</td><td>Owner's visibility group</td></tr><tr><td>`5`</td><td>Owner's visibility group and sub-groups</td></tr><tr><td>`7`</td><td>Entire company</td></tr></table>
  --was-seen: oneof<nothing, bool> # A flag indicating whether the lead was seen by someone in the Pipedrive UI
  --origin-id: string # The optional ID to further distinguish the origin of the lead - e.g. Which API integration created this lead. If omitted, `origin_id` will be set to null. (nullable)
  --channel: int # The ID of Marketing channel this lead was created from. Provided value must be one of the channels configured for your company. You can fetch allowed values with <a href="https://developers.pipedrive.com/docs/api/v1/DealFields#getDealField" target="_blank" rel="noopener noreferrer">GET /v1/dealFields</a>. If omitted, channel will be set to null. (nullable)
  --channel-id: string # The optional ID to further distinguish the Marketing channel. If omitted, `channel_id` will be set to null. (nullable)
]: any -> record<success: bool, data: record<id: string, title: string, owner_id: int, creator_id: int, label_ids: list<string>, person_id: int, organization_id: int, source_name: string, origin: string, origin_id: string, channel: int, channel_id: string, source_deal_id: int, is_archived: bool, was_seen: bool, value: record<amount: float, currency: string>, expected_close_date: string, next_activity_id: int, add_time: string, update_time: string, visible_to: string, cc_email: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/leads")
  let body = {title: $title, owner_id: $owner_id, label_ids: $label_ids, person_id: $person_id, organization_id: $organization_id, value: $value, expected_close_date: $expected_close_date, visible_to: $visible_to, was_seen: $was_seen, origin_id: $origin_id, channel: $channel, channel_id: $channel_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all archived leads
#
# GET /leads/archived
# operationId: getArchivedLeads
export def "leads-archived get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # For pagination, the limit of entries to be returned. If not provided, 100 items will be returned. (e.g. 100)
  --start: int # For pagination, the position that represents the first result for the page (e.g. 0)
  --owner-id: int # If supplied, only leads matching the given user will be returned. However, `filter_id` takes precedence over `owner_id` when supplied. (e.g. 1)
  --person-id: int # If supplied, only leads matching the given person will be returned. However, `filter_id` takes precedence over `person_id` when supplied. (e.g. 1)
  --organization-id: int # If supplied, only leads matching the given organization will be returned. However, `filter_id` takes precedence over `organization_id` when supplied. (e.g. 1)
  --filter-id: int # The ID of the filter to use (e.g. 1)
  --qp-sort: string@sort-completer # The field names and sorting mode separated by a comma (`field_name_1 ASC`, `field_name_2 DESC`). Only first-level field keys are supported (no nested keys).
]: nothing -> record<success: bool, data: table<id: string, title: string, owner_id: int, creator_id: int, label_ids: list, person_id: int, organization_id: int, source_name: string, origin: string, origin_id: string, channel: int, channel_id: string, source_deal_id: int, is_archived: bool, was_seen: bool, value: record, expected_close_date: string, next_activity_id: int, add_time: string, update_time: string, visible_to: string, cc_email: string>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "owner_id" $owner_id "scalar") (serialize-qp "person_id" $person_id "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "filter_id" $filter_id "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leads/archived" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one lead
#
# GET /leads/{id}
# operationId: getLead
export def "leads get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: string, title: string, owner_id: int, creator_id: int, label_ids: list<string>, person_id: int, organization_id: int, source_name: string, origin: string, origin_id: string, channel: int, channel_id: string, source_deal_id: int, is_archived: bool, was_seen: bool, value: record<amount: float, currency: string>, expected_close_date: string, next_activity_id: int, add_time: string, update_time: string, visible_to: string, cc_email: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/leads/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a lead
#
# PATCH /leads/{id}
# operationId: updateLead
# --value shape: {amount: float, currency: string}
export def "leads updateLead" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # The name of the lead (nullable)
  --owner-id: int # The ID of the user which will be the owner of the created lead. If not provided, the user making the request will be used.
  --label-ids: list # The IDs of the lead labels which will be associated with the lead
  --person-id: int # The ID of a person which this lead will be linked to. If the person does not exist yet, it needs to be created first. A lead always has to be linked to a person or organization or both.  (nullable)
  --organization-id: int # The ID of an organization which this lead will be linked to. If the organization does not exist yet, it needs to be created first. A lead always has to be linked to a person or organization or both. (nullable)
  --is-archived: oneof<nothing, bool> # A flag indicating whether the lead is archived or not
  --value: record # The potential value of the lead represented by a JSON object: `{ "amount": 200, "currency": "EUR" }`. Both amount and currency are required. (nullable) — shape: {amount: float, currency: string}
  --expected-close-date: string # The date of when the deal which will be created from the lead is expected to be closed. In ISO 8601 format: YYYY-MM-DD. (nullable, format: date)
  --visible-to: string # The visibility of the lead. If omitted, the visibility will be set to the default visibility setting of this item type for the authorized user. Read more about visibility groups <a href="https://support.pipedrive.com/en/article/visibility-groups" target="_blank" rel="noopener noreferrer">here</a>.<h4>Light / Growth and Professional plans</h4><table><tr><th style="width: 40px">Value</th><th>Description</th></tr><tr><td>`1`</td><td>Owner &amp; followers</td><tr><td>`3`</td><td>Entire company</td></tr></table><h4>Premium / Ultimate plan</h4><table><tr><th style="width: 40px">Value</th><th>Description</th></tr><tr><td>`1`</td><td>Owner only</td><tr><td>`3`</td><td>Owner's visibility group</td></tr><tr><td>`5`</td><td>Owner's visibility group and sub-groups</td></tr><tr><td>`7`</td><td>Entire company</td></tr></table>
  --was-seen: oneof<nothing, bool> # A flag indicating whether the lead was seen by someone in the Pipedrive UI
  --channel: int # The ID of Marketing channel this lead was created from. Provided value must be one of the channels configured for your company which you can fetch with <a href="https://developers.pipedrive.com/docs/api/v1/DealFields#getDealField" target="_blank" rel="noopener noreferrer">GET /v1/dealFields</a>. (nullable)
  --channel-id: string # The optional ID to further distinguish the Marketing channel. (nullable)
]: any -> record<success: bool, data: record<id: string, title: string, owner_id: int, creator_id: int, label_ids: list<string>, person_id: int, organization_id: int, source_name: string, origin: string, origin_id: string, channel: int, channel_id: string, source_deal_id: int, is_archived: bool, was_seen: bool, value: record<amount: float, currency: string>, expected_close_date: string, next_activity_id: int, add_time: string, update_time: string, visible_to: string, cc_email: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/leads/($id)")
  let body = {title: $title, owner_id: $owner_id, label_ids: $label_ids, person_id: $person_id, organization_id: $organization_id, is_archived: $is_archived, value: $value, expected_close_date: $expected_close_date, visible_to: $visible_to, was_seen: $was_seen, channel: $channel, channel_id: $channel_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a lead
#
# DELETE /leads/{id}
# operationId: deleteLead
export def "leads delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/leads/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List permitted users
#
# GET /leads/{id}/permittedUsers
# operationId: getLeadUsers
export def "leads-permitted-users get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/leads/($id)/permittedUsers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search leads
#
# GET /leads/search
# operationId: searchLeads
export def "leads-search searchLeads" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --term: string # The search term to look for. Minimum 2 characters (or 1 if using `exact_match`). Please note that the search term has to be URL encoded.
  --qp-fields: string@fields-completer # A comma-separated string array. The fields to perform the search from. Defaults to all of them.
  --exact-match: oneof<nothing, bool> # When enabled, only full exact matches against the given term are returned. It is <b>not</b> case sensitive.
  --person-id: int # Will filter leads by the provided person ID. The upper limit of found leads associated with the person is 2000.
  --organization-id: int # Will filter leads by the provided organization ID. The upper limit of found leads associated with the organization is 2000.
  --include-fields: string@include-fields-completer # Supports including optional fields in the results which are not provided by default
  --start: int # Pagination start. Note that the pagination is based on main results and does not include related items when using `search_for_related_items` parameter. (default: 0)
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: record<items: list<record>>, additional_data: record<pagination: record<start: int, limit: int, more_items_in_collection: bool, next_start: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "term" $term "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "exact_match" $exact_match "scalar") (serialize-qp "person_id" $person_id "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "include_fields" $include_fields "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leads/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all lead fields
#
# GET /leadFields
# operationId: getLeadFields
export def "lead-fields get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: list<record>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leadFields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all lead labels
#
# GET /leadLabels
# operationId: getLeadLabels
export def "lead-labels get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: table<id: string, name: string, color: string, add_time: string, update_time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/leadLabels")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a lead label
#
# POST /leadLabels
# operationId: addLeadLabel
export def "lead-labels addLeadLabel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the lead label
  color: string@color-completer # The color of the label. Only a subset of colors can be used.
]: any -> record<success: bool, data: record<id: string, name: string, color: string, add_time: string, update_time: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/leadLabels")
  let body = {name: $name, color: $color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a lead label
#
# PATCH /leadLabels/{id}
# operationId: updateLeadLabel
export def "lead-labels updateLeadLabel" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the lead label
  --color: string@color-completer # The color of the label. Only a subset of colors can be used.
]: any -> record<success: bool, data: record<id: string, name: string, color: string, add_time: string, update_time: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/leadLabels/($id)")
  let body = {name: $name, color: $color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a lead label
#
# DELETE /leadLabels/{id}
# operationId: deleteLeadLabel
export def "lead-labels delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/leadLabels/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all lead sources
#
# GET /leadSources
# operationId: getLeadSources
export def "lead-sources get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/leadSources")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all teams
#
# GET /legacyTeams
# DEPRECATED
# operationId: getTeams
@deprecated
export def "legacy-teams list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order-by: string@order-by-completer # The field name to sort returned teams by (default: id)
  --skip-users: float@skip-users-completer # When enabled, the teams will not include IDs of member users (default: 0)
]: nothing -> record<success: bool, data: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_by" $order_by "scalar") (serialize-qp "skip_users" $skip_users "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/legacyTeams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new team
#
# POST /legacyTeams
# DEPRECATED
# operationId: addTeam
@deprecated
export def "legacy-teams addTeam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The team name
  --description: string # The team description
  manager_id: int # The team manager ID
  --users: list # The list of user IDs
]: any -> record<success: bool, data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/legacyTeams")
  let body = {name: $name, description: $description, manager_id: $manager_id, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single team
#
# GET /legacyTeams/{id}
# DEPRECATED
# operationId: getTeam
@deprecated
export def "legacy-teams get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --skip-users: float@skip-users-completer # When enabled, the teams will not include IDs of member users (default: 0)
]: nothing -> record<success: bool, data: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip_users" $skip_users "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/legacyTeams/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a team
#
# PUT /legacyTeams/{id}
# DEPRECATED
# operationId: updateTeam
@deprecated
export def "legacy-teams updateTeam" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The team name
  --description: string # The team description
  --manager-id: int # The team manager ID
  --users: list # The list of user IDs
  --active-flag: any # Flag that indicates whether the team is active
  --deleted-flag: any # Flag that indicates whether the team is deleted
]: any -> record<success: bool, data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legacyTeams/($id)")
  let body = {name: $name, description: $description, manager_id: $manager_id, users: $users, active_flag: $active_flag, deleted_flag: $deleted_flag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all users in a team
#
# GET /legacyTeams/{id}/users
# DEPRECATED
# operationId: getTeamUsers
@deprecated
export def "legacy-teams-users get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legacyTeams/($id)/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add users to a team
#
# POST /legacyTeams/{id}/users
# DEPRECATED
# operationId: addTeamUser
@deprecated
export def "legacy-teams-users addTeamUser" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  users: list # The list of user IDs
]: any -> record<success: bool, data: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legacyTeams/($id)/users")
  let body = {users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete users from a team
#
# DELETE /legacyTeams/{id}/users
# DEPRECATED
# operationId: deleteTeamUser
@deprecated
export def "legacy-teams-users delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  users: list # The list of user IDs
]: any -> record<success: bool, data: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legacyTeams/($id)/users")
  let body = {users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all teams of a user
#
# GET /legacyTeams/user/{id}
# DEPRECATED
# operationId: getUserTeams
@deprecated
export def "legacy-teams-user get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order-by: string@order-by-completer # The field name to sort returned teams by (default: id)
  --skip-users: float@skip-users-completer # When enabled, the teams will not include IDs of member users (default: 0)
]: nothing -> record<success: bool, data: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_by" $order_by "scalar") (serialize-qp "skip_users" $skip_users "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/legacyTeams/user/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one mail message
#
# GET /mailbox/mailMessages/{id}
# operationId: getMailMessage
export def "mailbox-mail-messages get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-body: float@include-body-completer # Whether to include the full message body or not. `0` = Don't include, `1` = Include. (default: 0)
]: nothing -> record<success: bool, statusCode: int, statusText: string, service: string, data: record<id: int, from: list<record>, to: list<record>, cc: list<record>, bcc: list<record>, body_url: string, account_id: string, user_id: int, mail_thread_id: int, subject: string, snippet: string, mail_tracking_status: string, mail_link_tracking_enabled_flag: record, read_flag: record, draft: string, draft_flag: record, synced_flag: record, deleted_flag: record, has_body_flag: record, sent_flag: record, sent_from_pipedrive_flag: record, smart_bcc_flag: record, message_time: string, add_time: string, update_time: string, has_attachments_flag: record, has_inline_attachments_flag: record, has_real_attachments_flag: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_body" $include_body "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mailbox/mailMessages/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get mail threads
#
# GET /mailbox/mailThreads
# operationId: getMailThreads
export def "mailbox-mail-threads list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --folder: string@folder-completer # The type of folder to fetch (default: inbox)
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: table<id: int, account_id: string, user_id: int, subject: string, snippet: string, read_flag: record, mail_tracking_status: string, has_attachments_flag: record, has_inline_attachments_flag: record, has_real_attachments_flag: record, deleted_flag: record, synced_flag: record, smart_bcc_flag: record, mail_link_tracking_enabled_flag: record, parties: record, drafts_parties: list, folders: list, version: float, snippet_draft: string, snippet_sent: string, message_count: int, has_draft_flag: float, has_sent_flag: float, archived_flag: record, shared_flag: record, external_deleted_flag: record, first_message_to_me_flag: record, last_message_timestamp: string, first_message_timestamp: string, last_message_sent_timestamp: string, last_message_received_timestamp: string, add_time: string, update_time: string, deal_id: int, deal_status: string, lead_id: string, all_messages_sent_flag: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "folder" $folder "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mailbox/mailThreads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete mail thread
#
# DELETE /mailbox/mailThreads/{id}
# operationId: deleteMailThread
export def "mailbox-mail-threads delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mailbox/mailThreads/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one mail thread
#
# GET /mailbox/mailThreads/{id}
# operationId: getMailThread
export def "mailbox-mail-threads get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mailbox/mailThreads/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update mail thread details
#
# PUT /mailbox/mailThreads/{id}
# operationId: updateMailThreadDetails
export def "mailbox-mail-threads updateMailThreadDetails" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deal-id: int # The ID of the deal this thread is associated with
  --lead-id: string # The ID of the lead this thread is associated with (format: uuid)
  --shared-flag: any # Whether this thread is shared with other users in your company
  --read-flag: any # Whether this thread is read or unread
  --archived-flag: any # Whether this thread is archived or not. You can only archive threads that belong to Inbox folder. Archived threads will disappear from Inbox.
]: any -> record<success: bool, data: record<id: int, account_id: string, user_id: int, subject: string, snippet: string, read_flag: record, mail_tracking_status: string, has_attachments_flag: record, has_inline_attachments_flag: record, has_real_attachments_flag: record, deleted_flag: record, synced_flag: record, smart_bcc_flag: record, mail_link_tracking_enabled_flag: record, parties: record<to: list, from: list>, drafts_parties: list<record>, folders: list<string>, version: float, snippet_draft: string, snippet_sent: string, message_count: int, has_draft_flag: float, has_sent_flag: float, archived_flag: record, shared_flag: record, external_deleted_flag: record, first_message_to_me_flag: record, last_message_timestamp: string, first_message_timestamp: string, last_message_sent_timestamp: string, last_message_received_timestamp: string, add_time: string, update_time: string, deal_id: int, deal_status: string, lead_id: string, all_messages_sent_flag: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mailbox/mailThreads/($id)")
  let body = {deal_id: $deal_id, lead_id: $lead_id, shared_flag: $shared_flag, read_flag: $read_flag, archived_flag: $archived_flag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get all mail messages of mail thread
#
# GET /mailbox/mailThreads/{id}/mailMessages
# operationId: getMailThreadMessages
export def "mailbox-mail-threads-mail-messages get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: table<id: int, account_id: string, user_id: int, subject: string, snippet: string, read_flag: record, mail_tracking_status: string, has_attachments_flag: record, has_inline_attachments_flag: record, has_real_attachments_flag: record, deleted_flag: record, synced_flag: record, smart_bcc_flag: record, mail_link_tracking_enabled_flag: record, from: list, to: list, cc: list, bcc: list, body_url: string, mail_thread_id: int, draft: string, has_body_flag: float, sent_flag: float, sent_from_pipedrive_flag: float, message_time: string, add_time: string, update_time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mailbox/mailThreads/($id)/mailMessages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Link a user with the installed video call integration
#
# POST /meetings/userProviderLinks
# operationId: saveUserProviderLink
export def "meetings-user-provider-links saveUserProviderLink" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_provider_id: string # Unique identifier linking a user to the installed integration. Generated by the integration. (format: uuid, e.g. 1e3943c9-6395-462b-b432-1f252c017f3d)
  user_id: int # Pipedrive user ID (e.g. 123)
  company_id: int # Pipedrive company ID (e.g. 456)
  marketplace_client_id: string # Pipedrive Marketplace client ID of the installed integration (e.g. 57da5c3c55a82bb4)
]: any -> record<success: bool, data: record<message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/meetings/userProviderLinks")
  let body = {user_provider_id: $user_provider_id, user_id: $user_id, company_id: $company_id, marketplace_client_id: $marketplace_client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the link between a user and the installed video call integration
#
# DELETE /meetings/userProviderLinks/{id}
# operationId: deleteUserProviderLink
export def "meetings-user-provider-links delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/meetings/userProviderLinks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all notes
#
# GET /notes
# operationId: getNotes
export def "notes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-id: int # The ID of the user whose notes to fetch. If omitted, notes by all users will be returned.
  --lead-id: string # The ID of the lead which notes to fetch. If omitted, notes about all leads will be returned. (format: uuid)
  --deal-id: int # The ID of the deal which notes to fetch. If omitted, notes about all deals will be returned.
  --person-id: int # The ID of the person whose notes to fetch. If omitted, notes about all persons will be returned.
  --org-id: int # The ID of the organization which notes to fetch. If omitted, notes about all organizations will be returned.
  --project-id: int # The ID of the project which notes to fetch. If omitted, notes about all projects will be returned.
  --task-id: int # The ID of the task which notes to fetch. If omitted, notes about all tasks will be returned.
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
  --qp-sort: string # The field names and sorting mode separated by a comma (`field_name_1 ASC`, `field_name_2 DESC`). Only first-level field keys are supported (no nested keys). Supported fields: `id`, `user_id`, `deal_id`, `person_id`, `org_id`, `content`, `add_time`, `update_time`.
  --start-date: string # The date in format of YYYY-MM-DD from which notes to fetch (format: date)
  --end-date: string # The date in format of YYYY-MM-DD until which notes to fetch to (format: date)
  --updated-since: string # If set, only notes with an `update_time` later than or equal to this time are returned. In RFC3339 format, e.g. 2025-01-01T10:20:00Z. (format: date-time, e.g. 2025-01-01T10:20:00Z)
  --pinned-to-lead-flag: float@pinned-to-lead-flag-completer # If set, the results are filtered by note to lead pinning state
  --pinned-to-deal-flag: float@pinned-to-deal-flag-completer # If set, the results are filtered by note to deal pinning state
  --pinned-to-organization-flag: float@pinned-to-organization-flag-completer # If set, the results are filtered by note to organization pinning state
  --pinned-to-person-flag: float@pinned-to-person-flag-completer # If set, the results are filtered by note to person pinning state
  --pinned-to-project-flag: float@pinned-to-project-flag-completer # If set, the results are filtered by note to project pinning state
  --pinned-to-task-flag: float@pinned-to-task-flag-completer # If set, the results are filtered by note to task pinning state
]: nothing -> record<success: bool, data: table<id: int, active_flag: bool, add_time: string, content: string, deal: record, lead_id: string, deal_id: int, last_update_user_id: int, org_id: int, organization: record, person: record, person_id: int, project_id: int, project: record, task_id: int, task: record, pinned_to_deal_flag: bool, pinned_to_organization_flag: bool, pinned_to_person_flag: bool, pinned_to_project_flag: bool, pinned_to_task_flag: bool, update_time: string, user: record, user_id: int>, additional_data: record<pagination: record<next_start: int, start: int, limit: int, more_items_in_collection: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "deal_id" $deal_id "scalar") (serialize-qp "person_id" $person_id "scalar") (serialize-qp "org_id" $org_id "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "task_id" $task_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "pinned_to_lead_flag" $pinned_to_lead_flag "scalar") (serialize-qp "pinned_to_deal_flag" $pinned_to_deal_flag "scalar") (serialize-qp "pinned_to_organization_flag" $pinned_to_organization_flag "scalar") (serialize-qp "pinned_to_person_flag" $pinned_to_person_flag "scalar") (serialize-qp "pinned_to_project_flag" $pinned_to_project_flag "scalar") (serialize-qp "pinned_to_task_flag" $pinned_to_task_flag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a note
#
# POST /notes
# operationId: addNote
export def "notes addNote" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string # The content of the note in HTML format. Subject to sanitization on the back-end.
  --lead-id: string # The ID of the lead the note will be attached to. This property is required unless one of (`deal_id/person_id/org_id/project_id/task_id`) is specified. (format: uuid)
  --deal-id: int # The ID of the deal the note will be attached to. This property is required unless one of (`lead_id/person_id/org_id/project_id/task_id`) is specified.
  --person-id: int # The ID of the person this note will be attached to. This property is required unless one of (`deal_id/lead_id/org_id/project_id/task_id`) is specified.
  --org-id: int # The ID of the organization this note will be attached to. This property is required unless one of (`deal_id/lead_id/person_id/project_id/task_id`) is specified.
  --project-id: int # The ID of the project the note will be attached to. This property is required unless one of (`deal_id/lead_id/person_id/org_id/task_id`) is specified.
  --task-id: int # The ID of the task the note will be attached to. This property is required unless one of (`deal_id/lead_id/person_id/org_id/project_id`) is specified.
  --user-id: int # The ID of the user who will be marked as the author of the note. Only an admin can change the author.
  --add-time: string # The optional creation date & time of the note in UTC. Can be set in the past or in the future. Format: YYYY-MM-DD HH:MM:SS
  --pinned-to-lead-flag: any # If set, the results are filtered by note to lead pinning state (`lead_id` is also required)
  --pinned-to-deal-flag: any # If set, the results are filtered by note to deal pinning state (`deal_id` is also required)
  --pinned-to-organization-flag: any # If set, the results are filtered by note to organization pinning state (`org_id` is also required)
  --pinned-to-person-flag: any # If set, the results are filtered by note to person pinning state (`person_id` is also required)
  --pinned-to-project-flag: any # If set, the results are filtered by note to project pinning state (`project_id` is also required)
  --pinned-to-task-flag: any # If set, the results are filtered by note to task pinning state (`task_id` is also required)
]: any -> record<success: bool, data: record<id: int, active_flag: bool, add_time: string, content: string, deal: record<title: string>, lead_id: string, deal_id: int, last_update_user_id: int, org_id: int, organization: record<name: string>, person: record<name: string>, person_id: int, project_id: int, project: record<title: string>, task_id: int, task: record<title: string>, pinned_to_deal_flag: bool, pinned_to_organization_flag: bool, pinned_to_person_flag: bool, pinned_to_project_flag: bool, pinned_to_task_flag: bool, update_time: string, user: record<email: string, icon_url: string, is_you: bool, name: string>, user_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notes")
  let body = {content: $content, lead_id: $lead_id, deal_id: $deal_id, person_id: $person_id, org_id: $org_id, project_id: $project_id, task_id: $task_id, user_id: $user_id, add_time: $add_time, pinned_to_lead_flag: $pinned_to_lead_flag, pinned_to_deal_flag: $pinned_to_deal_flag, pinned_to_organization_flag: $pinned_to_organization_flag, pinned_to_person_flag: $pinned_to_person_flag, pinned_to_project_flag: $pinned_to_project_flag, pinned_to_task_flag: $pinned_to_task_flag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a note
#
# DELETE /notes/{id}
# operationId: deleteNote
export def "notes delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one note
#
# GET /notes/{id}
# operationId: getNote
export def "notes get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: int, active_flag: bool, add_time: string, content: string, deal: record<title: string>, lead_id: string, deal_id: int, last_update_user_id: int, org_id: int, organization: record<name: string>, person: record<name: string>, person_id: int, project_id: int, project: record<title: string>, task_id: int, task: record<title: string>, pinned_to_deal_flag: bool, pinned_to_organization_flag: bool, pinned_to_person_flag: bool, pinned_to_project_flag: bool, pinned_to_task_flag: bool, update_time: string, user: record<email: string, icon_url: string, is_you: bool, name: string>, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a note
#
# PUT /notes/{id}
# operationId: updateNote
export def "notes updateNote" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content: string # The content of the note in HTML format. Subject to sanitization on the back-end.
  --lead-id: string # The ID of the lead the note will be attached to (format: uuid)
  --deal-id: int # The ID of the deal the note will be attached to
  --person-id: int # The ID of the person the note will be attached to
  --org-id: int # The ID of the organization the note will be attached to
  --project-id: int # The ID of the project the note will be attached to
  --task-id: int # The ID of the task the note will be attached to
  --user-id: int # The ID of the user who will be marked as the author of the note. Only an admin can change the author.
  --add-time: string # The optional creation date & time of the note in UTC. Can be set in the past or in the future. Format: YYYY-MM-DD HH:MM:SS
  --pinned-to-lead-flag: any # If set, the results are filtered by note to lead pinning state (`lead_id` is also required)
  --pinned-to-deal-flag: any # If set, the results are filtered by note to deal pinning state (`deal_id` is also required)
  --pinned-to-organization-flag: any # If set, the results are filtered by note to organization pinning state (`org_id` is also required)
  --pinned-to-person-flag: any # If set, the results are filtered by note to person pinning state (`person_id` is also required)
  --pinned-to-project-flag: any # If set, the results are filtered by note to project pinning state (`project_id` is also required)
  --pinned-to-task-flag: any # If set, the results are filtered by note to task pinning state (`task_id` is also required)
]: any -> record<success: bool, data: record<id: int, active_flag: bool, add_time: string, content: string, deal: record<title: string>, lead_id: string, deal_id: int, last_update_user_id: int, org_id: int, organization: record<name: string>, person: record<name: string>, person_id: int, project_id: int, project: record<title: string>, task_id: int, task: record<title: string>, pinned_to_deal_flag: bool, pinned_to_organization_flag: bool, pinned_to_person_flag: bool, pinned_to_project_flag: bool, pinned_to_task_flag: bool, update_time: string, user: record<email: string, icon_url: string, is_you: bool, name: string>, user_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notes/($id)")
  let body = {content: $content, lead_id: $lead_id, deal_id: $deal_id, person_id: $person_id, org_id: $org_id, project_id: $project_id, task_id: $task_id, user_id: $user_id, add_time: $add_time, pinned_to_lead_flag: $pinned_to_lead_flag, pinned_to_deal_flag: $pinned_to_deal_flag, pinned_to_organization_flag: $pinned_to_organization_flag, pinned_to_person_flag: $pinned_to_person_flag, pinned_to_project_flag: $pinned_to_project_flag, pinned_to_task_flag: $pinned_to_task_flag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all comments for a note
#
# GET /notes/{id}/comments
# operationId: getNoteComments
export def "notes-comments list" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: table<uuid: string, active_flag: bool, add_time: string, update_time: string, content: string, object_id: string, object_type: string, user_id: int, updater_id: int, company_id: int>, additional_data: record<pagination: record<next_start: int, start: int, limit: int, more_items_in_collection: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/notes/($id)/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a comment to a note
#
# POST /notes/{id}/comments
# operationId: addNoteComment
export def "notes-comments addNoteComment" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string # The content of the comment in HTML format. Subject to sanitization on the back-end.
]: any -> record<success: bool, data: record<uuid: string, active_flag: bool, add_time: string, update_time: string, content: string, object_id: string, object_type: string, user_id: int, updater_id: int, company_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notes/($id)/comments")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get one comment
#
# GET /notes/{id}/comments/{commentId}
# operationId: getComment
export def "notes-comments get" [
  id: int
  commentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<uuid: string, active_flag: bool, add_time: string, update_time: string, content: string, object_id: string, object_type: string, user_id: int, updater_id: int, company_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notes/($id)/comments/($commentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a comment related to a note
#
# PUT /notes/{id}/comments/{commentId}
# operationId: updateCommentForNote
export def "notes-comments updateCommentForNote" [
  id: int
  commentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string # The content of the comment in HTML format. Subject to sanitization on the back-end.
]: any -> record<success: bool, data: record<uuid: string, active_flag: bool, add_time: string, update_time: string, content: string, object_id: string, object_type: string, user_id: int, updater_id: int, company_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notes/($id)/comments/($commentId)")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a comment related to a note
#
# DELETE /notes/{id}/comments/{commentId}
# operationId: deleteComment
export def "notes-comments delete" [
  id: int
  commentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notes/($id)/comments/($commentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all note fields
#
# GET /noteFields
# operationId: getNoteFields
export def "note-fields get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: list<record>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/noteFields")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Requesting authorization
#
# GET /oauth/authorize
# operationId: authorize
export def "oauth-authorize authorize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # The client ID provided to you by the Pipedrive Marketplace when you register your app
  --redirect-uri: string # The callback URL you provided when you registered your app. Authorization code will be sent to that URL (if it matches with the value you entered in the registration form) if a user approves the app install. Or, if a customer declines, the corresponding error will also be sent to this URL.
  --state: string # You may pass any random string as the state parameter and the same string will be returned to your app after a user authorizes access. It may be used to store the user's session ID from your app or distinguish different responses. Using state may increase security; see RFC-6749.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://oauth.pipedrive.com")
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth/authorize" $qp)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Getting the tokens
#
# POST /oauth/token
# operationId: get-tokens
export def "oauth-token get-tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Base 64 encoded string containing the `client_id` and `client_secret` values. The header value should be `Basic <base64(client_id:client_secret)>`.
  --grant-type: string@grant-type-completer # Since you are trying to exchange an authorization code for a pair of tokens, you must use the value "authorization_code" (default: authorization_code)
  --code: string # The authorization code that you received after the user confirmed app installation
  --redirect-uri: string # The callback URL you provided when you registered your app
]: any -> record<access_token: string, token_type: string, refresh_token: string, scope: string, expires_in: int, api_domain: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://oauth.pipedrive.com")
  let full_url = (build-url $base "/oauth/token")
  let body = {grant_type: $grant_type, code: $code, redirect_uri: $redirect_uri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Refreshing the tokens
#
# POST /oauth/token/
# operationId: refresh-tokens
export def "oauth-token refresh-tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Base 64 encoded string containing the `client_id` and `client_secret` values. The header value should be `Basic <base64(client_id:client_secret)>`.
  --grant-type: string@grant-type-completer # Since you are to refresh your access_token, you must use the value "refresh_token" (default: refresh_token)
  --refresh-token: string # The refresh token that you received after you exchanged the authorization code
]: any -> record<access_token: string, token_type: string, refresh_token: string, scope: string, expires_in: int, api_domain: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://oauth.pipedrive.com")
  let full_url = (build-url $base "/oauth/token/")
  let body = {grant_type: $grant_type, refresh_token: $refresh_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List updates about organization field values
#
# GET /organizations/{id}/changelog
# operationId: getOrganizationChangelog
export def "organizations-changelog get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # For pagination, the marker (an opaque string value) representing the first item on the next page
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: table<field_key: string, old_value: string, new_value: string, actor_user_id: int, time: string, change_source: string, change_source_user_agent: string, is_bulk_update_flag: bool>, additional_data: record<next_cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($id)/changelog" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List files attached to an organization
#
# GET /organizations/{id}/files
# operationId: getOrganizationFiles
export def "organizations-files get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page. Please note that a maximum value of 100 is allowed.
  --qp-sort: string # Supported fields: `id`, `update_time`
]: nothing -> record<success: bool, data: table<id: int, user_id: int, deal_id: int, person_id: int, org_id: int, product_id: int, activity_id: int, lead_id: string, add_time: string, update_time: string, file_name: string, file_size: int, active_flag: bool, inline_flag: bool, remote_location: string, remote_id: string, cid: string, s3_bucket: string, mail_message_id: string, mail_template_id: string, deal_name: string, person_name: string, org_name: string, product_name: string, lead_name: string, url: string, name: string, description: string>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($id)/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List updates about an organization
#
# GET /organizations/{id}/flow
# operationId: getOrganizationUpdates
export def "organizations-flow get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
  --all-changes: string # Whether to show custom field updates or not. 1 = Include custom field changes. If omitted, returns changes without custom field updates.
  --items: string # A comma-separated string for filtering out item specific updates. (Possible values - activity, plannedActivity, note, file, change, deal, follower, participant, mailMessage, mailMessageWithAttachment, invoice, activityFile, document).
]: nothing -> record<success: bool, data: table<object: string, timestamp: string, data: record>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>, related_objects: record<organization: record<ORGANIZATION_ID: record>, user: record<USER_ID: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "all_changes" $all_changes "scalar") (serialize-qp "items" $items "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($id)/flow" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List followers of an organization
#
# GET /organizations/{id}/followers
# operationId: getOrganizationFollowers
export def "organizations-followers get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: table<org_id: int, user_id: int, id: int, add_time: string>, additional_data: record<pagination: record<start: int, limit: int, more_items_in_collection: bool, next_start: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/followers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a follower to an organization
#
# POST /organizations/{id}/followers
# operationId: addOrganizationFollower
export def "organizations-followers addOrganizationFollower" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: int # The ID of the user
]: any -> record<success: bool, data: record<org_id: int, user_id: int, id: int, add_time: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/followers")
  let body = {user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a follower from an organization
#
# DELETE /organizations/{id}/followers/{follower_id}
# operationId: deleteOrganizationFollower
export def "organizations-followers delete" [
  id: int
  follower_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/followers/($follower_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List mail messages associated with an organization
#
# GET /organizations/{id}/mailMessages
# operationId: getOrganizationMailMessages
export def "organizations-mail-messages get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: table<object: string, timestamp: string, data: record>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($id)/mailMessages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merge two organizations
#
# PUT /organizations/{id}/merge
# operationId: mergeOrganizations
export def "organizations-merge mergeOrganizations" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  merge_with_id: int # The ID of the organization that the organization will be merged with
]: any -> record<success: bool, data: record<id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/merge")
  let body = {merge_with_id: $merge_with_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List permitted users
#
# GET /organizations/{id}/permittedUsers
# operationId: getOrganizationUsers
export def "organizations-permitted-users get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: list<float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/permittedUsers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all organization fields
#
# GET /organizationFields
# operationId: getOrganizationFields
export def "organization-fields list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: list<record>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organizationFields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new organization field
#
# POST /organizationFields
# operationId: addOrganizationField
export def "organization-fields addOrganizationField" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the field
  --options: list # When `field_type` is either set or enum, possible options must be supplied as a JSON-encoded sequential array of objects. Example: `[{"label":"New Item"}]`
  --add-visible-flag: oneof<nothing, bool> # Whether the field is available in the 'add new' modal or not (both in the web and mobile app) (default: true)
  field_type: string@field-type-completer # The type of the field<table><tr><th>Value</th><th>Description</th></tr><tr><td>`address`</td><td>Address field</td></tr><tr><td>`date`</td><td>Date (format YYYY-MM-DD)</td></tr><tr><td>`daterange`</td><td>Date-range field (has a start date and end date value, both YYYY-MM-DD)</td></tr><tr><td>`double`</td><td>Numeric value</td></tr><tr><td>`enum`</td><td>Options field with a single possible chosen option</td></tr><tr></tr><tr><td>`monetary`</td><td>Monetary field (has a numeric value and a currency value)</td></tr><tr><td>`org`</td><td>Organization field (contains an organization ID which is stored on the same account)</td></tr><tr><td>`people`</td><td>Person field (contains a person ID which is stored on the same account)</td></tr><tr><td>`phone`</td><td>Phone field (up to 255 numbers and/or characters)</td></tr><tr><td>`set`</td><td>Options field with a possibility of having multiple chosen options</td></tr><tr><td>`text`</td><td>Long text (up to 65k characters)</td></tr><tr><td>`time`</td><td>Time field (format HH:MM:SS)</td></tr><tr><td>`timerange`</td><td>Time-range field (has a start time and end time value, both HH:MM:SS)</td></tr><tr><td>`user`</td><td>User field (contains a user ID of another Pipedrive user)</td></tr><tr><td>`varchar`</td><td>Text (up to 255 characters)</td></tr><tr><td>`varchar_auto`</td><td>Autocomplete text (up to 255 characters)</td></tr><tr><td>`visible_to`</td><td>System field that keeps item's visibility setting</td></tr></table>
]: any -> record<success: bool, data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organizationFields")
  let body = {name: $name, options: $options, add_visible_flag: $add_visible_flag, field_type: $field_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete multiple organization fields in bulk
#
# DELETE /organizationFields
# operationId: deleteOrganizationFields
export def "organization-fields delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # The comma-separated field IDs to delete
]: nothing -> record<success: bool, data: record<id: list<int>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organizationFields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one organization field
#
# GET /organizationFields/{id}
# operationId: getOrganizationField
export def "organization-fields get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizationFields/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an organization field
#
# DELETE /organizationFields/{id}
# operationId: deleteOrganizationField
export def "organization-fields delete-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizationFields/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an organization field
#
# PUT /organizationFields/{id}
# operationId: updateOrganizationField
export def "organization-fields updateOrganizationField" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the field
  --options: list # When `field_type` is either set or enum, possible options must be supplied as a JSON-encoded sequential array of objects. All active items must be supplied and already existing items must have their ID supplied. New items only require a label. Example: `[{"id":123,"label":"Existing Item"},{"label":"New Item"}]`
  --add-visible-flag: oneof<nothing, bool> # Whether the field is available in 'add new' modal or not (both in web and mobile app) (default: true)
]: any -> record<success: bool, data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizationFields/($id)")
  let body = {name: $name, options: $options, add_visible_flag: $add_visible_flag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all relationships for organization
#
# GET /organizationRelationships
# operationId: getOrganizationRelationships
export def "organization-relationships list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --org-id: int # The ID of the organization to get relationships for
]: nothing -> record<success: bool, data: table<related_organization_name: string>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>, related_objects: record<organization: record<ORGANIZATION_ID: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org_id" $org_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organizationRelationships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an organization relationship
#
# POST /organizationRelationships
# operationId: addOrganizationRelationship
export def "organization-relationships addOrganizationRelationship" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --org-id: int # The ID of the base organization for the returned calculated values
  type: string@type-completer-1 # The type of organization relationship
  rel_owner_org_id: int # The owner of the relationship. If type is `parent`, then the owner is the parent and the linked organization is the daughter.
  rel_linked_org_id: int # The linked organization in the relationship. If type is `parent`, then the linked organization is the daughter.
]: any -> record<success: bool, data: record<id: int, type: string, rel_owner_org_id: record<name: string, people_count: int, owner_id: int, address: string, cc_email: string, value: int>, rel_linked_org_id: record<name: string, people_count: int, owner_id: int, address: string, cc_email: string, value: int>, add_time: string, update_time: string, active_flag: string>, related_objects: record<organization: record<ORGANIZATION_ID: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organizationRelationships")
  let body = {org_id: $org_id, type: $type, rel_owner_org_id: $rel_owner_org_id, rel_linked_org_id: $rel_linked_org_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an organization relationship
#
# DELETE /organizationRelationships/{id}
# operationId: deleteOrganizationRelationship
export def "organization-relationships delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizationRelationships/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one organization relationship
#
# GET /organizationRelationships/{id}
# operationId: getOrganizationRelationship
export def "organization-relationships get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --org-id: int # The ID of the base organization for the returned calculated values
]: nothing -> record<success: bool, data: record<id: int, type: string, rel_owner_org_id: record<name: string, people_count: int, owner_id: int, address: string, cc_email: string, value: int>, rel_linked_org_id: record<name: string, people_count: int, owner_id: int, address: string, cc_email: string, value: int>, add_time: string, update_time: string, active_flag: string, calculated_type: string, calculated_related_org_id: int>, related_objects: record<organization: record<ORGANIZATION_ID: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org_id" $org_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizationRelationships/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an organization relationship
#
# PUT /organizationRelationships/{id}
# operationId: updateOrganizationRelationship
export def "organization-relationships updateOrganizationRelationship" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --org-id: int # The ID of the base organization for the returned calculated values
  --type: string@type-completer-1 # The type of organization relationship
  --rel-owner-org-id: int # The owner of this relationship. If type is `parent`, then the owner is the parent and the linked organization is the daughter.
  --rel-linked-org-id: int # The linked organization in this relationship. If type is `parent`, then the linked organization is the daughter.
]: any -> record<success: bool, data: record<id: int, type: string, rel_owner_org_id: record<name: string, people_count: int, owner_id: int, address: string, cc_email: string, value: int>, rel_linked_org_id: record<name: string, people_count: int, owner_id: int, address: string, cc_email: string, value: int>, add_time: string, update_time: string, active_flag: string>, related_objects: record<organization: record<ORGANIZATION_ID: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizationRelationships/($id)")
  let body = {org_id: $org_id, type: $type, rel_owner_org_id: $rel_owner_org_id, rel_linked_org_id: $rel_linked_org_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all permission sets
#
# GET /permissionSets
# operationId: getPermissionSets
export def "permission-sets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --app: string@app-completer # The app to filter the permission sets by
]: nothing -> record<success: bool, data: table<id: string, name: string, description: string, app: string, type: string, assignment_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app" $app "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/permissionSets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one permission set
#
# GET /permissionSets/{id}
# operationId: getPermissionSet
export def "permission-sets get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, app: string, type: string, assignment_count: int, contents: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/permissionSets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List permission set assignments
#
# GET /permissionSets/{id}/assignments
# operationId: getPermissionSetAssignments
export def "permission-sets-assignments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: table<user_id: int, permission_set_id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/permissionSets/($id)/assignments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List updates about person field values
#
# GET /persons/{id}/changelog
# operationId: getPersonChangelog
export def "persons-changelog get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # For pagination, the marker (an opaque string value) representing the first item on the next page
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: table<field_key: string, old_value: string, new_value: string, actor_user_id: int, time: string, change_source: string, change_source_user_agent: string, is_bulk_update_flag: bool>, additional_data: record<next_cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/persons/($id)/changelog" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List files attached to a person
#
# GET /persons/{id}/files
# operationId: getPersonFiles
export def "persons-files get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page. Please note that a maximum value of 100 is allowed.
  --qp-sort: string # Supported fields: `id`, `update_time`
]: nothing -> record<success: bool, data: table<id: int, user_id: int, deal_id: int, person_id: int, org_id: int, product_id: int, activity_id: int, lead_id: string, add_time: string, update_time: string, file_name: string, file_size: int, active_flag: bool, inline_flag: bool, remote_location: string, remote_id: string, cid: string, s3_bucket: string, mail_message_id: string, mail_template_id: string, deal_name: string, person_name: string, org_name: string, product_name: string, lead_name: string, url: string, name: string, description: string>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/persons/($id)/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List updates about a person
#
# GET /persons/{id}/flow
# operationId: getPersonUpdates
export def "persons-flow get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
  --all-changes: string # Whether to show custom field updates or not. 1 = Include custom field changes. If omitted returns changes without custom field updates.
  --items: string # A comma-separated string for filtering out item specific updates. (Possible values - call, activity, plannedActivity, change, note, deal, file, dealChange, personChange, organizationChange, follower, dealFollower, personFollower, organizationFollower, participant, comment, mailMessage, mailMessageWithAttachment, invoice, document, marketing_campaign_stat, marketing_status_change).
]: nothing -> record<success: bool, data: table<object: string, timestamp: string, data: record>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>, related_objects: record<deal: record<DEAL_ID: record>, organization: record<ORGANIZATION_ID: record>, user: record<USER_ID: record>, person: record<PERSON_ID: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "all_changes" $all_changes "scalar") (serialize-qp "items" $items "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/persons/($id)/flow" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List followers of a person
#
# GET /persons/{id}/followers
# operationId: getPersonFollowers
export def "persons-followers get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: table<user_id: int, id: int, deal_id: int, add_time: string>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/persons/($id)/followers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a follower to a person
#
# POST /persons/{id}/followers
# operationId: addPersonFollower
export def "persons-followers addPersonFollower" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: int # The ID of the user
]: any -> record<success: bool, data: record<user_id: int, id: int, person_id: int, add_time: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/persons/($id)/followers")
  let body = {user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a follower from a person
#
# DELETE /persons/{id}/followers/{follower_id}
# operationId: deletePersonFollower
export def "persons-followers delete" [
  id: int
  follower_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/persons/($id)/followers/($follower_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List mail messages associated with a person
#
# GET /persons/{id}/mailMessages
# operationId: getPersonMailMessages
export def "persons-mail-messages get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: table<object: string, timestamp: string, data: record>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/persons/($id)/mailMessages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merge two persons
#
# PUT /persons/{id}/merge
# operationId: mergePersons
export def "persons-merge mergePersons" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  merge_with_id: int # The ID of the person that will not be overwritten. This person’s data will be prioritized in case of conflict with the other person.
]: any -> record<success: bool, data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/persons/($id)/merge")
  let body = {merge_with_id: $merge_with_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List permitted users
#
# GET /persons/{id}/permittedUsers
# operationId: getPersonUsers
export def "persons-permitted-users get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: list<float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/persons/($id)/permittedUsers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete person picture
#
# DELETE /persons/{id}/picture
# operationId: deletePersonPicture
export def "persons-picture delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/persons/($id)/picture")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add person picture
#
# POST /persons/{id}/picture
# operationId: addPersonPicture
export def "persons-picture addPersonPicture" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: string # One image supplied in the multipart/form-data encoding (format: binary)
  --crop-x: int # X coordinate to where start cropping form (in pixels)
  --crop-y: int # Y coordinate to where start cropping form (in pixels)
  --crop-width: int # The width of the cropping area (in pixels)
  --crop-height: int # The height of the cropping area (in pixels)
]: any -> record<success: bool, data: record<PICTURE_ID: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/persons/($id)/picture")
  let body = {file: $file, crop_x: $crop_x, crop_y: $crop_y, crop_width: $crop_width, crop_height: $crop_height} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# List products associated with a person
#
# GET /persons/{id}/products
# operationId: getPersonProducts
export def "persons-products get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: table<DEAL_ID: record>, additional_data: record<pagination: record<start: int, limit: int, more_items_in_collection: bool, next_start: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/persons/($id)/products" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all person fields
#
# GET /personFields
# operationId: getPersonFields
export def "person-fields list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: list<record>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/personFields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new person field
#
# POST /personFields
# operationId: addPersonField
export def "person-fields addPersonField" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the field
  --options: list # When `field_type` is either set or enum, possible options must be supplied as a JSON-encoded sequential array of objects. Example: `[{"label":"New Item"}]`
  --add-visible-flag: oneof<nothing, bool> # Whether the field is available in the 'add new' modal or not (both in the web and mobile app) (default: true)
  field_type: string@field-type-completer # The type of the field<table><tr><th>Value</th><th>Description</th></tr><tr><td>`address`</td><td>Address field</td></tr><tr><td>`date`</td><td>Date (format YYYY-MM-DD)</td></tr><tr><td>`daterange`</td><td>Date-range field (has a start date and end date value, both YYYY-MM-DD)</td></tr><tr><td>`double`</td><td>Numeric value</td></tr><tr><td>`enum`</td><td>Options field with a single possible chosen option</td></tr><tr></tr><tr><td>`monetary`</td><td>Monetary field (has a numeric value and a currency value)</td></tr><tr><td>`org`</td><td>Organization field (contains an organization ID which is stored on the same account)</td></tr><tr><td>`people`</td><td>Person field (contains a person ID which is stored on the same account)</td></tr><tr><td>`phone`</td><td>Phone field (up to 255 numbers and/or characters)</td></tr><tr><td>`set`</td><td>Options field with a possibility of having multiple chosen options</td></tr><tr><td>`text`</td><td>Long text (up to 65k characters)</td></tr><tr><td>`time`</td><td>Time field (format HH:MM:SS)</td></tr><tr><td>`timerange`</td><td>Time-range field (has a start time and end time value, both HH:MM:SS)</td></tr><tr><td>`user`</td><td>User field (contains a user ID of another Pipedrive user)</td></tr><tr><td>`varchar`</td><td>Text (up to 255 characters)</td></tr><tr><td>`varchar_auto`</td><td>Autocomplete text (up to 255 characters)</td></tr><tr><td>`visible_to`</td><td>System field that keeps item's visibility setting</td></tr></table>
]: any -> record<success: bool, data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/personFields")
  let body = {name: $name, options: $options, add_visible_flag: $add_visible_flag, field_type: $field_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete multiple person fields in bulk
#
# DELETE /personFields
# operationId: deletePersonFields
export def "person-fields delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # The comma-separated field IDs to delete
]: nothing -> record<success: bool, data: record<id: list<int>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/personFields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one person field
#
# GET /personFields/{id}
# operationId: getPersonField
export def "person-fields get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/personFields/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a person field
#
# DELETE /personFields/{id}
# operationId: deletePersonField
export def "person-fields delete-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/personFields/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a person field
#
# PUT /personFields/{id}
# operationId: updatePersonField
export def "person-fields updatePersonField" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the field
  --options: list # When `field_type` is either set or enum, possible options must be supplied as a JSON-encoded sequential array of objects. All active items must be supplied and already existing items must have their ID supplied. New items only require a label. Example: `[{"id":123,"label":"Existing Item"},{"label":"New Item"}]`
  --add-visible-flag: oneof<nothing, bool> # Whether the field is available in 'add new' modal or not (both in web and mobile app) (default: true)
]: any -> record<success: bool, data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/personFields/($id)")
  let body = {name: $name, options: $options, add_visible_flag: $add_visible_flag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get deals conversion rates in pipeline
#
# GET /pipelines/{id}/conversion_statistics
# operationId: getPipelineConversionStatistics
export def "pipelines-conversion-statistics get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # The start of the period. Date in format of YYYY-MM-DD. (format: date)
  --end-date: string # The end of the period. Date in format of YYYY-MM-DD. (format: date)
  --user-id: int # The ID of the user who's pipeline metrics statistics to fetch. If omitted, the authorized user will be used.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pipelines/($id)/conversion_statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get deals in a pipeline
#
# GET /pipelines/{id}/deals
# DEPRECATED
# operationId: getPipelineDeals
@deprecated
export def "pipelines-deals get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter-id: int # If supplied, only deals matching the given filter will be returned
  --user-id: int # If supplied, `filter_id` will not be considered and only deals owned by the given user will be returned. If omitted, deals owned by the authorized user will be returned.
  --everyone: float@everyone-completer # If supplied, `filter_id` and `user_id` will not be considered – instead, deals owned by everyone will be returned
  --stage-id: int # If supplied, only deals within the given stage will be returned
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
  --get-summary: float@get-summary-completer # Whether to include a summary of the pipeline in the `additional_data` or not
  --totals-convert-currency: string # The 3-letter currency code of any of the supported currencies. When supplied, `per_stages_converted` is returned inside `deals_summary` inside `additional_data` which contains the currency-converted total amounts in the given currency per each stage. You may also set this parameter to `default_currency` in which case users default currency is used. Only works when `get_summary` parameter flag is enabled.
]: nothing -> record<success: bool, data: table<id: int, creator_user_id: int, user_id: int, person_id: int, org_id: int, stage_id: int, title: string, value: float, currency: string, add_time: string, update_time: string, stage_change_time: string, active: bool, deleted: bool, is_archived: bool, status: string, probability: float, next_activity_date: string, next_activity_time: string, next_activity_id: int, last_activity_id: int, last_activity_date: string, lost_reason: string, visible_to: string, close_time: string, pipeline_id: int, won_time: string, first_won_time: string, lost_time: string, products_count: int, files_count: int, notes_count: int, followers_count: int, email_messages_count: int, activities_count: int, done_activities_count: int, undone_activities_count: int, participants_count: int, expected_close_date: string, last_incoming_mail_time: string, last_outgoing_mail_time: string, label: string, stage_order_nr: int, person_name: string, org_name: string, next_activity_subject: string, next_activity_type: string, next_activity_duration: string, next_activity_note: string, formatted_value: string, weighted_value: float, formatted_weighted_value: string, weighted_value_currency: string, rotten_time: string, owner_name: string, cc_email: string, org_hidden: bool, person_hidden: bool, origin: string, origin_id: string, channel: int, channel_id: string, arr: float, mrr: float, acv: float, arr_currency: string, mrr_currency: string, acv_currency: string>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter_id" $filter_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "everyone" $everyone "scalar") (serialize-qp "stage_id" $stage_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "get_summary" $get_summary "scalar") (serialize-qp "totals_convert_currency" $totals_convert_currency "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pipelines/($id)/deals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get deals movements in pipeline
#
# GET /pipelines/{id}/movement_statistics
# operationId: getPipelineMovementStatistics
export def "pipelines-movement-statistics get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # The start of the period. Date in format of YYYY-MM-DD. (format: date)
  --end-date: string # The end of the period. Date in format of YYYY-MM-DD. (format: date)
  --user-id: int # The ID of the user who's pipeline statistics to fetch. If omitted, the authorized user will be used.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pipelines/($id)/movement_statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get deals where a product is attached to
#
# GET /products/{id}/deals
# operationId: getProductDeals
export def "products-deals get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
  --status: string@status-completer-1 # Only fetch deals with a specific status. If omitted, all not deleted deals are returned. If set to deleted, deals that have been deleted up to 30 days ago will be included. (default: all_not_deleted)
]: nothing -> record<success: bool, data: table<id: int, creator_user_id: record, user_id: record, person_id: record, org_id: record, stage_id: int, title: string, value: float, currency: string, add_time: string, update_time: string, stage_change_time: string, active: bool, deleted: bool, is_archived: bool, status: string, probability: float, next_activity_date: string, next_activity_time: string, next_activity_id: int, last_activity_id: int, last_activity_date: string, lost_reason: string, visible_to: string, close_time: string, pipeline_id: int, won_time: string, first_won_time: string, lost_time: string, products_count: int, files_count: int, notes_count: int, followers_count: int, email_messages_count: int, activities_count: int, done_activities_count: int, undone_activities_count: int, participants_count: int, expected_close_date: string, last_incoming_mail_time: string, last_outgoing_mail_time: string, label: string, stage_order_nr: int, person_name: string, org_name: string, next_activity_subject: string, next_activity_type: string, next_activity_duration: string, next_activity_note: string, formatted_value: string, weighted_value: float, formatted_weighted_value: string, weighted_value_currency: string, rotten_time: string, owner_name: string, cc_email: string, org_hidden: bool, person_hidden: bool, origin: string, origin_id: string, channel: int, channel_id: string, arr: float, mrr: float, acv: float, arr_currency: string, mrr_currency: string, acv_currency: string>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>, related_objects: record<organization: record<ORGANIZATION_ID: record>, person: record<PERSON_ID: record>, user: record<USER_ID: record>, stage: record<id: int, order_nr: int, name: string, active_flag: bool, deal_probability: int, pipeline_id: int, rotten_flag: bool, rotten_days: int, add_time: string, update_time: string>, pipeline: record<id: int, name: string, url_title: string, order_nr: int, active: bool, deal_probability: bool, add_time: string, update_time: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/products/($id)/deals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List files attached to a product
#
# GET /products/{id}/files
# operationId: getProductFiles
export def "products-files get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page. Please note that a maximum value of 100 is allowed.
  --qp-sort: string # Supported fields: `id`, `update_time`
]: nothing -> record<success: bool, data: table<id: int, product_id: int, add_time: string, update_time: string, file_name: string, file_size: int, active_flag: bool, inline_flag: bool, remote_location: string, remote_id: string, s3_bucket: string, product_name: string, url: string, name: string, description: string>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/products/($id)/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List followers of a product
#
# GET /products/{id}/followers
# operationId: getProductFollowers
export def "products-followers get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: table<user_id: int, id: int, product_id: int, add_time: string>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/products/($id)/followers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a follower to a product
#
# POST /products/{id}/followers
# operationId: addProductFollower
export def "products-followers addProductFollower" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: int # The ID of the user
]: any -> record<success: bool, data: record<user_id: int, id: int, product_id: int, add_time: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/($id)/followers")
  let body = {user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a follower from a product
#
# DELETE /products/{id}/followers/{follower_id}
# operationId: deleteProductFollower
export def "products-followers delete" [
  id: int
  follower_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/($id)/followers/($follower_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List permitted users
#
# GET /products/{id}/permittedUsers
# operationId: getProductUsers
export def "products-permitted-users get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/($id)/permittedUsers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete multiple product fields in bulk
#
# DELETE /productFields
# operationId: deleteProductFields
export def "product-fields delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # The comma-separated field IDs to delete
]: nothing -> record<success: bool, data: record<id: list<int>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/productFields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all product fields
#
# GET /productFields
# operationId: getProductFields
export def "product-fields list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: list<record>, additional_data: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/productFields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new product field
#
# POST /productFields
# operationId: addProductField
export def "product-fields addProductField" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the field
  --options: list # When `field_type` is either `set` or `enum`, possible options must be supplied as a JSON-encoded sequential array, for example:</br>`[{"label":"red"}, {"label":"blue"}, {"label":"lilac"}]`
  field_type: string@field-type-completer-1 # The type of the field<table><tr><th>Value</th><th>Description</th></tr><tr><td>`varchar`</td><td>Text (up to 255 characters)</td><tr><td>`varchar_auto`</td><td>Autocomplete text (up to 255 characters)</td><tr><td>`text`</td><td>Long text (up to 65k characters)</td><tr><td>`double`</td><td>Numeric value</td><tr><td>`monetary`</td><td>Monetary field (has a numeric value and a currency value)</td><tr><td>`date`</td><td>Date (format YYYY-MM-DD)</td><tr><td>`set`</td><td>Options field with a possibility of having multiple chosen options</td><tr><td>`enum`</td><td>Options field with a single possible chosen option</td><tr><td>`user`</td><td>User field (contains a user ID of another Pipedrive user)</td><tr><td>`org`</td><td>Organization field (contains an organization ID which is stored on the same account)</td><tr><td>`people`</td><td>Person field (contains a product ID which is stored on the same account)</td><tr><td>`phone`</td><td>Phone field (up to 255 numbers and/or characters)</td><tr><td>`time`</td><td>Time field (format HH:MM:SS)</td><tr><td>`timerange`</td><td>Time-range field (has a start time and end time value, both HH:MM:SS)</td><tr><td>`daterange`</td><td>Date-range field (has a start date and end date value, both YYYY-MM-DD)</td><tr><td>`address`</td><td>Address field</dd></table>
]: any -> record<success: bool, data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/productFields")
  let body = {name: $name, options: $options, field_type: $field_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a product field
#
# DELETE /productFields/{id}
# operationId: deleteProductField
export def "product-fields delete-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/productFields/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one product field
#
# GET /productFields/{id}
# operationId: getProductField
export def "product-fields get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/productFields/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a product field
#
# PUT /productFields/{id}
# operationId: updateProductField
export def "product-fields updateProductField" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the field
  --options: list # When `field_type` is either set or enum, possible options on update must be supplied as an array of objects each containing id and label, for example: [{"id":1, "label":"red"},{"id":2, "label":"blue"},{"id":3, "label":"lilac"}]
]: any -> record<success: bool, data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/productFields/($id)")
  let body = {name: $name, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all projects
#
# GET /projects
# operationId: getProjects
export def "projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # For pagination, the marker (an opaque string value) representing the first item on the next page
  --limit: int # For pagination, the limit of entries to be returned. If not provided, 100 items will be returned. (e.g. 100)
  --filter-id: int # The ID of the filter to use
  --status: string # If supplied, includes only projects with the specified statuses. Possible values are `open`, `completed`, `canceled` and `deleted`. By default `deleted` projects are not returned. (e.g. open,completed)
  --phase-id: int # If supplied, only projects in specified phase are returned
  --include-archived: oneof<nothing, bool> # If supplied with `true` then archived projects are also included in the response. By default only not archived projects are returned.
]: nothing -> record<success: bool, data: table<id: int>, additional_data: record<next_cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter_id" $filter_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "phase_id" $phase_id "scalar") (serialize-qp "include_archived" $include_archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a project
#
# POST /projects
# operationId: addProject
export def "projects addProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string # The title of the project
  --board-id: float # The ID of the board this project is associated with
  --phase-id: float # The ID of the phase this project is associated with
  --description: string # The description of the project
  --status: string # The status of the project
  --owner-id: float # The ID of a project owner
  --start-date: string # The start date of the project. Format: YYYY-MM-DD. (format: date)
  --end-date: string # The end date of the project. Format: YYYY-MM-DD. (format: date)
  --deal-ids: list # An array of IDs of the deals this project is associated with
  --org-id: float # The ID of the organization this project is associated with
  --person-id: float # The ID of the person this project is associated with
  --labels: list # An array of IDs of the labels this project has
  --health-status: int # The health status of the project (nullable)
  --template-id: float # The ID of the template the project will be based on
]: any -> record<success: bool, data: record<id: int>, additional_data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects")
  let body = {title: $title, board_id: $board_id, phase_id: $phase_id, description: $description, status: $status, owner_id: $owner_id, start_date: $start_date, end_date: $end_date, deal_ids: $deal_ids, org_id: $org_id, person_id: $person_id, labels: $labels, health_status: $health_status, template_id: $template_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get details of a project
#
# GET /projects/{id}
# operationId: getProject
export def "projects get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: int>, additional_data: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a project
#
# PUT /projects/{id}
# operationId: updateProject
export def "projects updateProject" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # The title of the project
  --board-id: float # The ID of the board this project is associated with
  --phase-id: float # The ID of the phase this project is associated with
  --description: string # The description of the project
  --status: string # The status of the project
  --owner-id: float # The ID of a project owner
  --start-date: string # The start date of the project. Format: YYYY-MM-DD. (format: date)
  --end-date: string # The end date of the project. Format: YYYY-MM-DD. (format: date)
  --deal-ids: list # An array of IDs of the deals this project is associated with
  --org-id: float # The ID of the organization this project is associated with
  --person-id: float # The ID of the person this project is associated with
  --labels: list # An array of IDs of the labels this project has
  --health-status: int # The health status of the project (nullable)
]: any -> record<success: bool, data: record<id: int>, additional_data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)")
  let body = {title: $title, board_id: $board_id, phase_id: $phase_id, description: $description, status: $status, owner_id: $owner_id, start_date: $start_date, end_date: $end_date, deal_ids: $deal_ids, org_id: $org_id, person_id: $person_id, labels: $labels, health_status: $health_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a project
#
# DELETE /projects/{id}
# operationId: deleteProject
export def "projects delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<success: bool, data: record<id: int>>, additional_data: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive a project
#
# POST /projects/{id}/archive
# operationId: archiveProject
export def "projects-archive archiveProject" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: int>, additional_data: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/archive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns project plan
#
# GET /projects/{id}/plan
# operationId: getProjectPlan
export def "projects-plan get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: table<item_id: float, item_type: string, phase_id: float, group_id: float>, additional_data: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/plan")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update activity in project plan
#
# PUT /projects/{id}/plan/activities/{activityId}
# operationId: putProjectPlanActivity
export def "projects-plan-activities put" [
  id: int
  activityId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --phase-id: float # The ID of a phase on a project board
  --group-id: float # The ID of a group on a project board
]: any -> record<success: bool, data: record<item_id: float, item_type: string, phase_id: float, group_id: float>, additional_data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/plan/activities/($activityId)")
  let body = {phase_id: $phase_id, group_id: $group_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update task in project plan
#
# PUT /projects/{id}/plan/tasks/{taskId}
# operationId: putProjectPlanTask
export def "projects-plan-tasks put" [
  id: int
  taskId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --phase-id: float # The ID of a phase on a project board
  --group-id: float # The ID of a group on a project board
]: any -> record<success: bool, data: record<item_id: float, item_type: string, phase_id: float, group_id: float>, additional_data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/plan/tasks/($taskId)")
  let body = {phase_id: $phase_id, group_id: $group_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns project groups
#
# GET /projects/{id}/groups
# operationId: getProjectGroups
export def "projects-groups get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: table<id: float, name: string, order_nr: float>, additional_data: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns project tasks
#
# GET /projects/{id}/tasks
# operationId: getProjectTasks
export def "projects-tasks get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: list<record>, additional_data: record<next_cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/tasks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns project activities
#
# GET /projects/{id}/activities
# operationId: getProjectActivities
export def "projects-activities get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: table<due_date: string, due_time: string, duration: string, deal_id: int, lead_id: string, person_id: int, project_id: int, org_id: int, location: string, public_description: string, id: int, done: bool, subject: string, type: string, user_id: int, busy_flag: bool, company_id: int, conference_meeting_client: string, conference_meeting_url: string, conference_meeting_id: string, add_time: string, marked_as_done_time: string, active_flag: bool, update_time: string, update_user_id: int, source_timezone: string, location_subpremise: string, location_street_number: string, location_route: string, location_sublocality: string, location_locality: string, location_admin_area_level_1: string, location_admin_area_level_2: string, location_country: string, location_postal_code: string, location_formatted_address: string>, additional_data: record<next_cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/activities")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all project boards
#
# GET /projects/boards
# operationId: getProjectsBoards
export def "projects-boards list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: table<id: int, name: string, order_nr: float, add_time: string, update_time: string>, additional_data: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects/boards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details of a board
#
# GET /projects/boards/{id}
# operationId: getProjectsBoard
export def "projects-boards get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: int, name: string, order_nr: float, add_time: string, update_time: string>, additional_data: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/boards/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project phases
#
# GET /projects/phases
# operationId: getProjectsPhases
export def "projects-phases list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --board-id: int # ID of the board for which phases are requested (e.g. 1)
]: nothing -> record<success: bool, data: table<id: int, name: string, board_id: float, order_nr: float, add_time: string, update_time: string>, additional_data: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "board_id" $board_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects/phases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details of a phase
#
# GET /projects/phases/{id}
# operationId: getProjectsPhase
export def "projects-phases get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: int, name: string, board_id: float, order_nr: float, add_time: string, update_time: string>, additional_data: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/phases/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all project templates
#
# GET /projectTemplates
# operationId: getProjectTemplates
export def "project-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # For pagination, the marker (an opaque string value) representing the first item on the next page
  --limit: int # For pagination, the limit of entries to be returned. If not provided, up to 500 items will be returned. (e.g. 500)
]: nothing -> record<success: bool, data: table<id: float, title: string, description: string, projects_board_id: float, owner_id: float, add_time: string, update_time: string>, additional_data: record<next_cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projectTemplates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details of a template
#
# GET /projectTemplates/{id}
# operationId: getProjectTemplate
export def "project-templates get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: float, title: string, description: string, projects_board_id: float, owner_id: float, add_time: string, update_time: string>, additional_data: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projectTemplates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get recents
#
# GET /recents
# operationId: getRecents
export def "recents get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since-timestamp: string # The timestamp in UTC. Format: YYYY-MM-DD HH:MM:SS.
  --items: string@items-completer # Multiple selection of item types to include in the query (optional)
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: list<any>, additional_data: record<since_timestamp: string, last_timestamp_on_page: string, pagination: record<start: int, limit: int, more_items_in_collection: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since_timestamp" $since_timestamp "scalar") (serialize-qp "items" $items "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all roles
#
# GET /roles
# operationId: getRoles
export def "roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: table<level: int>, additional_data: record<pagination: record<start: int, limit: int, more_items_in_collection: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a role
#
# POST /roles
# operationId: addRole
export def "roles addRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the role
  --parent-role-id: int # The ID of the parent role (nullable)
]: any -> record<success: bool, data: record<id: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles")
  let body = {name: $name, parent_role_id: $parent_role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a role
#
# DELETE /roles/{id}
# operationId: deleteRole
export def "roles delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one role
#
# GET /roles/{id}
# operationId: getRole
export def "roles get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<parent_role_id: int, name: string, id: int, active_flag: bool, assignment_count: string, sub_role_count: string>, additional_data: record<settings: record<deal_default_visibility: float, lead_default_visibility: float, org_default_visibility: float, person_default_visibility: float, product_default_visibility: float, deal_access_level: float, org_access_level: float, person_access_level: float, product_access_level: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update role details
#
# PUT /roles/{id}
# operationId: updateRole
export def "roles updateRole" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parent-role-id: int # The ID of the parent role (nullable)
  --name: string # The name of the role
]: any -> record<success: bool, data: record<id: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/roles/($id)")
  let body = {parent_role_id: $parent_role_id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a role assignment
#
# DELETE /roles/{id}/assignments
# operationId: deleteRoleAssignment
export def "roles-assignments delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: int # The ID of the user
]: any -> record<success: bool, data: record<id: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/roles/($id)/assignments")
  let body = {user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List role assignments
#
# GET /roles/{id}/assignments
# operationId: getRoleAssignments
export def "roles-assignments get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: table<parent_role_id: int, name: string, user_id: int, role_id: int, active_flag: bool, type: string>, additional_data: record<pagination: record<start: int, limit: int, more_items_in_collection: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/roles/($id)/assignments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add role assignment
#
# POST /roles/{id}/assignments
# operationId: addRoleAssignment
export def "roles-assignments addRoleAssignment" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: int # The ID of the user
]: any -> record<success: bool, data: record<user_id: int, role_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/roles/($id)/assignments")
  let body = {user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List role settings
#
# GET /roles/{id}/settings
# operationId: getRoleSettings
export def "roles-settings get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<deal_default_visibility: float, lead_default_visibility: float, org_default_visibility: float, person_default_visibility: float, product_default_visibility: float, deal_access_level: float, org_access_level: float, person_access_level: float, product_access_level: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/roles/($id)/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or update role setting
#
# POST /roles/{id}/settings
# operationId: addOrUpdateRoleSetting
export def "roles-settings addOrUpdateRoleSetting" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  setting_key: string@setting-key-completer
  value: int@value-completer # Possible values for the `default_visibility` setting depending on the subscription plan:<br> <table class='role-setting'> <caption><b>Light / Growth and Professional plans</b></caption> <tr><th><b>Value</b></th><th><b>Description</b></th></tr> <tr><td>`1`</td><td>Owner & Followers</td></tr> <tr><td>`3`</td><td>Entire company</td></tr> </table> <br> <table class='role-setting'> <caption><b>Premium / Ultimate plan</b></caption> <tr><th><b>Value</b></th><th><b>Description</b></th></tr> <tr><td>`1`</td><td>Owner only</td></tr> <tr><td>`3`</td><td>Owner&#39;s visibility group</td></tr> <tr><td>`5`</td><td>Owner&#39;s visibility group and sub-groups</td></tr> <tr><td>`7`</td><td>Entire company</td></tr> </table> <br> Read more about visibility groups <a href='https://support.pipedrive.com/en/article/visibility-groups'>here</a>.
]: any -> record<success: bool, data: record<id: int, deal_default_visibility: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/roles/($id)/settings")
  let body = {setting_key: $setting_key, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List pipeline visibility for a role
#
# GET /roles/{id}/pipelines
# operationId: getRolePipelines
export def "roles-pipelines get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --visible: oneof<nothing, bool> # Whether to return the visible or hidden pipelines for the role (default: true)
]: nothing -> record<success: bool, data: record<pipeline_ids: list<float>, visible: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "visible" $visible "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/roles/($id)/pipelines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update pipeline visibility for a role
#
# PUT /roles/{id}/pipelines
# operationId: updateRolePipelines
export def "roles-pipelines updateRolePipelines" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  visible_pipeline_ids: record # The pipeline IDs to make the pipelines visible (add) and/or hidden (remove) for the specified role. It requires the following JSON structure: `{ "add": "[1]", "remove": "[3, 4]" }`.
]: any -> record<success: bool, data: record<pipeline_ids: list<float>, visible: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/roles/($id)/pipelines")
  let body = {visible_pipeline_ids: $visible_pipeline_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get deals in a stage
#
# GET /stages/{id}/deals
# DEPRECATED
# operationId: getStageDeals
@deprecated
export def "stages-deals get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter-id: int # If supplied, only deals matching the given filter will be returned
  --user-id: int # If supplied, `filter_id` will not be considered and only deals owned by the given user will be returned. If omitted, deals owned by the authorized user will be returned.
  --everyone: float@everyone-completer # If supplied, `filter_id` and `user_id` will not be considered – instead, deals owned by everyone will be returned
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: table<id: int, creator_user_id: int, user_id: int, person_id: int, org_id: int, stage_id: int, title: string, value: float, currency: string, add_time: string, update_time: string, stage_change_time: string, active: bool, deleted: bool, is_archived: bool, status: string, probability: float, next_activity_date: string, next_activity_time: string, next_activity_id: int, last_activity_id: int, last_activity_date: string, lost_reason: string, visible_to: string, close_time: string, pipeline_id: int, won_time: string, first_won_time: string, lost_time: string, products_count: int, files_count: int, notes_count: int, followers_count: int, email_messages_count: int, activities_count: int, done_activities_count: int, undone_activities_count: int, participants_count: int, expected_close_date: string, last_incoming_mail_time: string, last_outgoing_mail_time: string, label: string, stage_order_nr: int, person_name: string, org_name: string, next_activity_subject: string, next_activity_type: string, next_activity_duration: string, next_activity_note: string, formatted_value: string, weighted_value: float, formatted_weighted_value: string, weighted_value_currency: string, rotten_time: string, owner_name: string, cc_email: string, org_hidden: bool, person_hidden: bool, origin: string, origin_id: string, channel: int, channel_id: string, arr: float, mrr: float, acv: float, arr_currency: string, mrr_currency: string, acv_currency: string>, additional_data: record<start: int, limit: int, more_items_in_collection: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter_id" $filter_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "everyone" $everyone "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/stages/($id)/deals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all tasks
#
# GET /tasks
# operationId: getTasks
export def "tasks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # For pagination, the marker (an opaque string value) representing the first item on the next page
  --limit: int # For pagination, the limit of entries to be returned. If not provided, up to 500 items will be returned. (e.g. 500)
  --assignee-id: int # If supplied, only tasks that are assigned to this user are returned
  --project-id: int # If supplied, only tasks that are assigned to this project are returned
  --parent-task-id: int # If `null` is supplied then only parent tasks are returned. If integer is supplied then only subtasks of a specific task are returned. By default all tasks are returned.
  --done: float@done-completer # Whether the task is done or not. `0` = Not done, `1` = Done. If not omitted then returns both done and not done tasks.
]: nothing -> record<success: bool, data: list<record>, additional_data: record<next_cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "assignee_id" $assignee_id "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "parent_task_id" $parent_task_id "scalar") (serialize-qp "done" $done "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a task
#
# POST /tasks
# operationId: addTask
export def "tasks addTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string # The title of the task
  project_id: float # The ID of a project
  --description: string # The description of the task
  --parent-task-id: float # The ID of a parent task. Can not be ID of a task which is already a subtask.
  --assignee-id: float # The ID of the user assigned to the task. When the `assignee_id` field is updated, the `assignee_ids` field value will be overwritten by the `assignee_id` field value.
  --assignee-ids: list # The IDs of users assigned to the task. When the `assignee_ids` field is updated, the `assignee_id` field value will be set to the first value of the `assignee_ids` field, or `null` if the list is empty.
  --done: any # Whether the task is done or not. 0 = Not done, 1 = Done.
  --due-date: string # The due date of the task. Format: YYYY-MM-DD. (format: date)
]: any -> record<success: bool, data: record, additional_data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tasks")
  let body = {title: $title, project_id: $project_id, description: $description, parent_task_id: $parent_task_id, assignee_id: $assignee_id, assignee_ids: $assignee_ids, done: $done, due_date: $due_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get details of a task
#
# GET /tasks/{id}
# operationId: getTask
export def "tasks get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record, additional_data: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a task
#
# PUT /tasks/{id}
# operationId: updateTask
export def "tasks updateTask" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # The title of the task
  --project-id: float # The ID of the project this task is associated with
  --description: string # The description of the task
  --parent-task-id: float # The ID of a parent task. Can not be ID of a task which is already a subtask.
  --assignee-id: float # The ID of the user assigned to the task. When the `assignee_id` field is updated, the `assignee_ids` field value will be overwritten by the `assignee_id` field value.
  --assignee-ids: list # The IDs of users assigned to the task. When the `assignee_ids` field is updated, the `assignee_id` field value will be set to the first value of the `assignee_ids` field, or `null` if the list is empty.
  --done: any # Whether the task is done or not. 0 = Not done, 1 = Done.
  --due-date: string # The due date of the task. Format: YYYY-MM-DD. (format: date)
]: any -> record<success: bool, data: record, additional_data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($id)")
  let body = {title: $title, project_id: $project_id, description: $description, parent_task_id: $parent_task_id, assignee_id: $assignee_id, assignee_ids: $assignee_ids, done: $done, due_date: $due_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a task
#
# DELETE /tasks/{id}
# operationId: deleteTask
export def "tasks delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<success: bool, data: record<id: int>>, additional_data: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all users
#
# GET /users
# operationId: getUsers
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: table<id: int, name: string, default_currency: string, locale: string, lang: int, email: string, phone: string, activated: bool, last_login: string, created: string, modified: string, has_created_company: bool, access: list, active_flag: bool, timezone_name: string, timezone_offset: string, role_id: int, icon_url: string, is_you: bool, is_deleted: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new user
#
# POST /users
# operationId: addUser
# --access item shape: {app: "global"|"sales"|"campaigns"|"projects"|"account_settings"|"partnership", admin?: bool, permission_set_id?: string}
export def "users addUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email of the user
  --access: list # The access given to the user. Each item in the array represents access to a specific app. Optionally may include either admin flag or permission set ID to specify which access to give within the app. If both are omitted, the default access for the corresponding app will be used. It requires structure as follows: `[{ app: 'sales', permission_set_id: '62cc4d7f-4038-4352-abf3-a8c1c822b631' }, { app: 'global', admin: true }, { app: 'account_settings' }]`  (default: [{app: sales}]) — item shape: {app: "global"|"sales"|"campaigns"|"projects"|"account_settings"|"partnership", admin?: bool, permission_set_id?: string}
  --active-flag: oneof<nothing, bool> # Whether the user is active or not. `false` = Not activated, `true` = Activated (default: true)
]: any -> record<success: bool, data: record<id: int, name: string, default_currency: string, locale: string, lang: int, email: string, phone: string, activated: bool, last_login: string, created: string, modified: string, has_created_company: bool, access: list<record>, active_flag: bool, timezone_name: string, timezone_offset: string, role_id: int, icon_url: string, is_you: bool, is_deleted: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let body = {email: $email, access: $access, active_flag: $active_flag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find users by name
#
# GET /users/find
# operationId: findUsersByName
export def "users-find findUsersByName" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --term: string # The search term to look for
  --search-by-email: float@search-by-email-completer # When enabled, the term will only be matched against email addresses of users. Default: `false`. (default: 0)
]: nothing -> record<success: bool, data: table<id: int, name: string, default_currency: string, locale: string, lang: int, email: string, phone: string, activated: bool, last_login: string, created: string, modified: string, has_created_company: bool, access: list, active_flag: bool, timezone_name: string, timezone_offset: string, role_id: int, icon_url: string, is_you: bool, is_deleted: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "term" $term "scalar") (serialize-qp "search_by_email" $search_by_email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/find" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current user data
#
# GET /users/me
# operationId: getCurrentUser
export def "users-me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: int, name: string, default_currency: string, locale: string, lang: int, email: string, phone: string, activated: bool, last_login: string, created: string, modified: string, has_created_company: bool, access: list<record>, active_flag: bool, timezone_name: string, timezone_offset: string, role_id: int, icon_url: string, is_you: bool, is_deleted: bool, company_id: int, company_name: string, company_domain: string, company_country: string, company_industry: string, language: record<language_code: string, country_code: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get one user
#
# GET /users/{id}
# operationId: getUser
export def "users get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: int, name: string, default_currency: string, locale: string, lang: int, email: string, phone: string, activated: bool, last_login: string, created: string, modified: string, has_created_company: bool, access: list<record>, active_flag: bool, timezone_name: string, timezone_offset: string, role_id: int, icon_url: string, is_you: bool, is_deleted: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user details
#
# PUT /users/{id}
# operationId: updateUser
export def "users updateUser" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active-flag: oneof<nothing, bool> # Whether the user is active or not. `false` = Not activated, `true` = Activated
]: any -> record<success: bool, data: record<id: int, name: string, default_currency: string, locale: string, lang: int, email: string, phone: string, activated: bool, last_login: string, created: string, modified: string, has_created_company: bool, access: list<record>, active_flag: bool, timezone_name: string, timezone_offset: string, role_id: int, icon_url: string, is_you: bool, is_deleted: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)")
  let body = {active_flag: $active_flag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List followers of a user
#
# GET /users/{id}/followers
# operationId: getUserFollowers
export def "users-followers get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/followers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List user permissions
#
# GET /users/{id}/permissions
# operationId: getUserPermissions
export def "users-permissions get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<can_add_custom_fields: bool, can_add_products: bool, can_add_prospects_as_leads: bool, can_bulk_edit_items: bool, can_change_visibility_of_items: bool, can_convert_deals_to_leads: bool, can_create_own_workflow: bool, can_delete_activities: bool, can_delete_custom_fields: bool, can_delete_deals: bool, can_edit_custom_fields: bool, can_edit_deals_closed_date: bool, can_edit_products: bool, can_edit_shared_filters: bool, can_export_data_from_lists: bool, can_follow_other_users: bool, can_merge_deals: bool, can_merge_organizations: bool, can_merge_people: bool, can_modify_labels: bool, can_see_company_wide_statistics: bool, can_see_deals_list_summary: bool, can_see_hidden_items_names: bool, can_see_other_users: bool, can_see_other_users_statistics: bool, can_see_security_dashboard: bool, can_share_filters: bool, can_share_insights: bool, can_use_api: bool, can_use_email_tracking: bool, can_use_import: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List role assignments
#
# GET /users/{id}/roleAssignments
# operationId: getUserRoleAssignments
export def "users-role-assignments get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Pagination start (default: 0)
  --limit: int # Items shown per page
]: nothing -> record<success: bool, data: table<parent_role_id: int, name: string, user_id: int, role_id: int, active_flag: bool, type: string>, additional_data: record<pagination: record<start: int, limit: int, more_items_in_collection: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/roleAssignments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List user role settings
#
# GET /users/{id}/roleSettings
# operationId: getUserRoleSettings
export def "users-role-settings get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<deal_default_visibility: float, lead_default_visibility: float, org_default_visibility: float, person_default_visibility: float, product_default_visibility: float, deal_access_level: float, org_access_level: float, person_access_level: float, product_access_level: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/roleSettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all user connections
#
# GET /userConnections
# operationId: getUserConnections
export def "user-connections get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<google: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/userConnections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List settings of an authorized user
#
# GET /userSettings
# operationId: getUserSettings
export def "user-settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<marketplace_team: bool, list_limit: float, beta_app: bool, prevent_salesphone_callto_override: bool, file_upload_destination: string, callto_link_syntax: string, autofill_deal_expected_close_date: bool, person_duplicate_condition: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/userSettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all Webhooks
#
# GET /webhooks
# operationId: getWebhooks
export def "webhooks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: int, company_id: int, owner_id: int, user_id: int, event_action: string, event_object: string, subscription_url: string, version: string, is_active: record, add_time: string, remove_time: string, type: string, http_auth_user: string, http_auth_password: string, remove_reason: string, last_delivery_time: string, last_http_status: int, admin_id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Webhook
#
# POST /webhooks
# operationId: addWebhook
export def "webhooks addWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  subscription_url: string # A full, valid, publicly accessible URL which determines where to send the notifications. Please note that you cannot use Pipedrive API endpoints as the `subscription_url` and the chosen URL must not redirect to another link.
  event_action: string@event-action-completer # The type of action to receive notifications about. Wildcard will match all supported actions.
  event_object: string@event-object-completer # The type of object to receive notifications about. Wildcard will match all supported objects.
  name: string # The webhook's name
  --user-id: int # The ID of the user that this webhook will be authorized with. You have the option to use a different user's `user_id`. If it is not set, the current user's `user_id` will be used. As each webhook event is checked against a user's permissions, the webhook will only be sent if the user has access to the specified object(s). If you want to receive notifications for all events, please use a top-level admin user’s `user_id`.
  --http-auth-user: string # The HTTP basic auth username of the subscription URL endpoint (if required) (nullable)
  --http-auth-password: string # The HTTP basic auth password of the subscription URL endpoint (if required) (nullable)
  --version: string@version-completer # The webhook's version. NB! Webhooks v2 is the default from March 17th, 2025. See <a href="https://developers.pipedrive.com/changelog/post/breaking-change-webhooks-v2-will-become-the-new-default-version" target="_blank" rel="noopener noreferrer">this Changelog post</a> for more details. (default: 2.0)
]: any -> record<data: record<id: int, company_id: int, owner_id: int, user_id: int, event_action: string, event_object: string, subscription_url: string, version: string, is_active: record, add_time: string, remove_time: string, type: string, http_auth_user: string, http_auth_password: string, remove_reason: string, last_delivery_time: string, last_http_status: int, admin_id: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let body = {subscription_url: $subscription_url, event_action: $event_action, event_object: $event_object, name: $name, user_id: $user_id, http_auth_user: $http_auth_user, http_auth_password: $http_auth_password, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete existing Webhook
#
# DELETE /webhooks/{id}
# operationId: deleteWebhook
export def "webhooks delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
