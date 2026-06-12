# Auto-generated client for Calendar vv1.0
# Source: https://raw.githubusercontent.com/microsoftgraph/msgraph-sdk-powershell/main/openApiDocs/v1.0/Calendar.yml
# Auth: --token flag or $env.CALENDAR_TOKEN

const BASE_URL = "https://graph.microsoft.com/v1.0"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CALENDAR_TOKEN | default "" }
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

def base-url-completer [] { ["https://graph.microsoft.com/v1.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def role-completer [] { ["custom" "delegateWithPrivateEventAccess" "delegateWithoutPrivateEventAccess" "freeBusyRead" "limitedRead" "none" "read" "write"] }
def importance-completer [] { ["high" "low" "normal"] }
def onlineMeetingProvider-completer [] { ["skypeForBusiness" "skypeForConsumer" "teamsForBusiness" "unknown"] }
def sensitivity-completer [] { ["confidential" "normal" "personal" "private"] }
def showAs-completer [] { ["busy" "free" "oof" "tentative" "unknown" "workingElsewhere"] }
def type-completer [] { ["exception" "occurrence" "seriesMaster" "singleInstance"] }
def checkInMethod-completer [] { ["inferred" "manual" "unknownFutureValue" "unspecified" "verified"] }
def bookingType-completer [] { ["reserved" "standard" "unknown"] }
def teamsEnabledState-completer [] { ["disabled" "enabled" "unknown" "unknownFutureValue"] }
def color-completer [] { ["auto" "lightBlue" "lightBrown" "lightGray" "lightGreen" "lightOrange" "lightPink" "lightRed" "lightTeal" "lightYellow" "maxColor"] }
def defaultOnlineMeetingProvider-completer [] { ["skypeForBusiness" "skypeForConsumer" "teamsForBusiness" "unknown"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "groups-calendar GetCalendar" } } | get name | first)
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

# Get calendar from groups
#
# GET /groups/{group-id}/calendar
# operationId: group_GetCalendar
export def "groups-calendar GetCalendar" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: table<id: string, allowedRoles: list, emailAddress: record, isInsideOrganization: bool, isRemovable: bool, role: string>, calendarView: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, events: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/calendar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get calendarPermissions from groups
#
# GET /groups/{group-id}/calendar/calendarPermissions
# operationId: group.calendar_ListCalendarPermission
export def "groups-calendar-calendar-permissions ListCalendarPermission" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/calendar/calendarPermissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to calendarPermissions for groups
#
# POST /groups/{group-id}/calendar/calendarPermissions
# operationId: group.calendar_CreateCalendarPermission
# --emailAddress shape: {address?: string, name?: string}
export def "groups-calendar-calendar-permissions CreateCalendarPermission" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --allowedRoles: list # List of allowed sharing or delegating permission levels for the calendar. The possible values are: none, freeBusyRead, limitedRead, read, write, delegateWithoutPrivateEventAccess, delegateWithPrivateEventAccess, custom.
  --emailAddress: record # shape: {address?: string, name?: string}
  --isInsideOrganization: oneof<nothing, bool> # True if the user in context (recipient or delegate) is inside the same organization as the calendar owner. (nullable)
  --isRemovable: oneof<nothing, bool> # True if the user can be removed from the list of recipients or delegates for the specified calendar, false otherwise. The 'My organization' user determines the permissions other people within your organization have to the given calendar. You can't remove 'My organization' as a share recipient to a calendar. (nullable)
  --role: string@role-completer
]: any -> record<id: string, allowedRoles: list<string>, emailAddress: record<address: string, name: string>, isInsideOrganization: bool, isRemovable: bool, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/calendar/calendarPermissions")
  let body = {id: $id, allowedRoles: $allowedRoles, emailAddress: $emailAddress, isInsideOrganization: $isInsideOrganization, isRemovable: $isRemovable, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get calendarPermissions from groups
#
# GET /groups/{group-id}/calendar/calendarPermissions/{calendarPermission-id}
# operationId: group.calendar_GetCalendarPermission
export def "groups-calendar-calendar-permissions GetCalendarPermission" [
  group_id: string
  calendarPermission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, allowedRoles: list<string>, emailAddress: record<address: string, name: string>, isInsideOrganization: bool, isRemovable: bool, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/calendar/calendarPermissions/($calendarPermission_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property calendarPermissions in groups
#
# PATCH /groups/{group-id}/calendar/calendarPermissions/{calendarPermission-id}
# operationId: group.calendar_UpdateCalendarPermission
# --emailAddress shape: {address?: string, name?: string}
export def "groups-calendar-calendar-permissions UpdateCalendarPermission" [
  group_id: string
  calendarPermission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --allowedRoles: list # List of allowed sharing or delegating permission levels for the calendar. The possible values are: none, freeBusyRead, limitedRead, read, write, delegateWithoutPrivateEventAccess, delegateWithPrivateEventAccess, custom.
  --emailAddress: record # shape: {address?: string, name?: string}
  --isInsideOrganization: oneof<nothing, bool> # True if the user in context (recipient or delegate) is inside the same organization as the calendar owner. (nullable)
  --isRemovable: oneof<nothing, bool> # True if the user can be removed from the list of recipients or delegates for the specified calendar, false otherwise. The 'My organization' user determines the permissions other people within your organization have to the given calendar. You can't remove 'My organization' as a share recipient to a calendar. (nullable)
  --role: string@role-completer
]: any -> record<id: string, allowedRoles: list<string>, emailAddress: record<address: string, name: string>, isInsideOrganization: bool, isRemovable: bool, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/calendar/calendarPermissions/($calendarPermission_id)")
  let body = {id: $id, allowedRoles: $allowedRoles, emailAddress: $emailAddress, isInsideOrganization: $isInsideOrganization, isRemovable: $isRemovable, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property calendarPermissions for groups
#
# DELETE /groups/{group-id}/calendar/calendarPermissions/{calendarPermission-id}
# operationId: group.calendar_DeleteCalendarPermission
export def "groups-calendar-calendar-permissions DeleteCalendarPermission" [
  group_id: string
  calendarPermission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/calendar/calendarPermissions/($calendarPermission_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /groups/{group-id}/calendar/calendarPermissions/$count
# operationId: group.calendar.calendarPermission_GetCount
export def "groups-calendar-calendar-permissions-count GetCount" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/calendar/calendarPermissions/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get calendarView from groups
#
# GET /groups/{group-id}/calendar/calendarView
# operationId: group.calendar_ListCalendarView
export def "groups-calendar-calendar-view ListCalendarView" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T19:00:00-08:00
  --endDateTime: string # The end date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/calendar/calendarView" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function delta
#
# GET /groups/{group-id}/calendar/calendarView/microsoft.graph.delta()
# Docs: https://learn.microsoft.com/graph/api/event-delta?view=graph-rest-1.0 — Find more info here
# operationId: group.calendar.calendarView_delta
export def "groups-calendar-calendar-view-microsoftgraphdelta delta" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --endDateTime: string # The end date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: record, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, _odata_nextLink: string, _odata_deltaLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/calendar/calendarView/microsoft.graph.delta()" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get events from groups
#
# GET /groups/{group-id}/calendar/events
# operationId: group.calendar_ListEvent
export def "groups-calendar-events ListEvent" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to events for groups
#
# POST /groups/{group-id}/calendar/events
# operationId: group.calendar_CreateEvent
# --attendees item shape: {proposedNewTime?: record, status?: record}
# --body shape: {content?: string, contentType?: "text"|"html"}
# --end shape: {dateTime?: string, timeZone?: string}
# --location shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --locations item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --onlineMeeting shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
# --organizer shape: {emailAddress?: record}
# --recurrence shape: {pattern?: record, range?: record}
# --responseStatus shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
# --start shape: {dateTime?: string, timeZone?: string}
# --attachments item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
# --exceptionOccurrences item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --extensions item shape: {id?: string}
# --instances item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --multiValueExtendedProperties item shape: {id?: string, value?: list}
# --singleValueExtendedProperties item shape: {id?: string, value?: string}
export def "groups-calendar-events CreateEvent" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowNewTimeProposals: oneof<nothing, bool> # true if the meeting organizer allows invitees to propose a new time when responding; otherwise, false. Optional. The default is true. (nullable)
  --attendees: list # The collection of attendees for the event. — item shape: {proposedNewTime?: record, status?: record}
  --body-body: record # shape: {content?: string, contentType?: "text"|"html"}
  --bodyPreview: string # The preview of the message associated with the event. It's in text format. (nullable)
  --cancelledOccurrences: list # Contains occurrenceId property values of canceled instances in a recurring series, if the event is the series master. Instances in a recurring series that are canceled are called canceled occurences.Requires $select to retrieve. Only returned in a Get operation that specifies the ID (seriesMasterId property value) of a series master event.
  --end: record # shape: {dateTime?: string, timeZone?: string}
  --hasAttachments: oneof<nothing, bool> # Set to true if the event has attachments. (nullable)
  --hideAttendees: oneof<nothing, bool> # When set to true, each attendee only sees themselves in the meeting request and meeting Tracking list. The default is false. (nullable)
  --iCalUId: string # A unique identifier for an event across calendars. This ID is different for each occurrence in a recurring series. Read-only. (nullable)
  --importance: string@importance-completer
  --isAllDay: oneof<nothing, bool> # Set to true if the event lasts all day. If true, regardless of whether it's a single-day or multi-day event, start, and endtime must be set to midnight and be in the same time zone. (nullable)
  --isCancelled: oneof<nothing, bool> # Set to true if the event has been canceled. (nullable)
  --isDraft: oneof<nothing, bool> # Set to true if the user has updated the meeting in Outlook but hasn't sent the updates to attendees. Set to false if all changes are sent, or if the event is an appointment without any attendees. (nullable)
  --isOnlineMeeting: oneof<nothing, bool> # True if this event has online meeting information (that is, onlineMeeting points to an onlineMeetingInfo resource), false otherwise. Default is false (onlineMeeting is null). Optional.  After you set isOnlineMeeting to true, Microsoft Graph initializes onlineMeeting. Subsequently, Outlook ignores any further changes to isOnlineMeeting, and the meeting remains available online. (nullable)
  --isOrganizer: oneof<nothing, bool> # Set to true if the calendar owner (specified by the owner property of the calendar) is the organizer of the event (specified by the organizer property of the event). It also applies if a delegate organized the event on behalf of the owner. (nullable)
  --isReminderOn: oneof<nothing, bool> # Set to true if an alert is set to remind the user of the event. (nullable)
  --location: record # shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --locations: list # The locations where the event is held or attended from. The location and locations properties always correspond with each other. If you update the location property, any prior locations in the locations collection are removed and replaced by the new location value. — item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --onlineMeeting: record # shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
  --onlineMeetingProvider: string@onlineMeetingProvider-completer
  --onlineMeetingUrl: string # A URL for an online meeting. The property is set only when an organizer specifies in Outlook that an event is an online meeting such as Skype. Read-only.To access the URL to join an online meeting, use joinUrl which is exposed via the onlineMeeting property of the event. The onlineMeetingUrl property will be deprecated in the future. (nullable)
  --organizer: record # shape: {emailAddress?: record}
  --originalEndTimeZone: string # The end time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --originalStart: string # Represents the start time of an event when it's initially created as an occurrence or exception in a recurring series. This property is not returned for events that are single instances. Its date and time information is expressed in ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --originalStartTimeZone: string # The start time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --recurrence: record # shape: {pattern?: record, range?: record}
  --reminderMinutesBeforeStart: float # The number of minutes before the event start time that the reminder alert occurs. (nullable, format: int32)
  --responseRequested: oneof<nothing, bool> # Default is true, which represents the organizer would like an invitee to send a response to the event. (nullable)
  --responseStatus: record # shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
  --sensitivity: string@sensitivity-completer
  --seriesMasterId: string # The ID for the recurring series master item, if this event is part of a recurring series. (nullable)
  --showAs: string@showAs-completer
  --start: record # shape: {dateTime?: string, timeZone?: string}
  --subject: string # The text of the event's subject line. (nullable)
  --transactionId: string # A custom identifier specified by a client app for the server to avoid redundant POST operations in case of client retries to create the same event. It's useful when low network connectivity causes the client to time out before receiving a response from the server for the client's prior create-event request. After you set transactionId when creating an event, you can't change transactionId in a subsequent update. This property is only returned in a response payload if an app has set it. Optional. (nullable)
  --type: string@type-completer
  --webLink: string # The URL to open the event in Outlook on the web.Outlook on the web opens the event in the browser if you are signed in to your mailbox. Otherwise, Outlook on the web prompts you to sign in.This URL can't be accessed from within an iFrame. (nullable)
  --attachments: list # The collection of FileAttachment, ItemAttachment, and referenceAttachment attachments for the event. Navigation property. Read-only. Nullable. — item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
  --calendar: any
  --exceptionOccurrences: list # Contains the id property values of the event instances that are exceptions in a recurring series.Exceptions can differ from other occurrences in a recurring series, such as the subject, start or end times, or attendees. Exceptions don't include canceled occurrences.Requires $select and $expand to retrieve. Only returned in a GET operation that specifies the ID (seriesMasterId property value) of a series master event. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --extensions: list # The collection of open extensions defined for the event. Nullable. — item shape: {id?: string}
  --instances: list # The occurrences of a recurring series, if the event is a series master. This property includes occurrences that are part of the recurrence pattern, and exceptions modified, but doesn't include occurrences canceled from the series. Navigation property. Read-only. Nullable. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --multiValueExtendedProperties: list # The collection of multi-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: list}
  --singleValueExtendedProperties: list # The collection of single-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: string}
]: any -> record<allowNewTimeProposals: bool, attendees: table<proposedNewTime: record, status: record>, body: record<content: string, contentType: string>, bodyPreview: string, cancelledOccurrences: list<string>, end: record<dateTime: string, timeZone: string>, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, locations: table<address: record, coordinates: record, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, onlineMeeting: record<conferenceId: string, joinUrl: string, phones: list<record>, quickDial: string, tollFreeNumbers: list<string>, tollNumber: string>, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record<emailAddress: record<address: string, name: string>>, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record<pattern: record<dayOfMonth: float, daysOfWeek: list, firstDayOfWeek: string, index: string, interval: float, month: float, type: string>, range: record<endDate: string, numberOfOccurrences: float, recurrenceTimeZone: string, startDate: string, type: string>>, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record<response: string, time: string>, sensitivity: string, seriesMasterId: string, showAs: string, start: record<dateTime: string, timeZone: string>, subject: string, transactionId: string, type: string, webLink: string, attachments: table<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float>, calendar: record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: list<record>, calendarView: list<any>, events: list<any>, multiValueExtendedProperties: list<record>, singleValueExtendedProperties: list<record>>, exceptionOccurrences: list<any>, extensions: table<id: string>, instances: list<any>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events")
  let body = {allowNewTimeProposals: $allowNewTimeProposals, attendees: $attendees, body: $body_body, bodyPreview: $bodyPreview, cancelledOccurrences: $cancelledOccurrences, end: $end, hasAttachments: $hasAttachments, hideAttendees: $hideAttendees, iCalUId: $iCalUId, importance: $importance, isAllDay: $isAllDay, isCancelled: $isCancelled, isDraft: $isDraft, isOnlineMeeting: $isOnlineMeeting, isOrganizer: $isOrganizer, isReminderOn: $isReminderOn, location: $location, locations: $locations, onlineMeeting: $onlineMeeting, onlineMeetingProvider: $onlineMeetingProvider, onlineMeetingUrl: $onlineMeetingUrl, organizer: $organizer, originalEndTimeZone: $originalEndTimeZone, originalStart: $originalStart, originalStartTimeZone: $originalStartTimeZone, recurrence: $recurrence, reminderMinutesBeforeStart: $reminderMinutesBeforeStart, responseRequested: $responseRequested, responseStatus: $responseStatus, sensitivity: $sensitivity, seriesMasterId: $seriesMasterId, showAs: $showAs, start: $start, subject: $subject, transactionId: $transactionId, type: $type, webLink: $webLink, attachments: $attachments, calendar: $calendar, exceptionOccurrences: $exceptionOccurrences, extensions: $extensions, instances: $instances, multiValueExtendedProperties: $multiValueExtendedProperties, singleValueExtendedProperties: $singleValueExtendedProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get events from groups
#
# GET /groups/{group-id}/calendar/events/{event-id}
# operationId: group.calendar_GetEvent
export def "groups-calendar-events GetEvent" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<allowNewTimeProposals: bool, attendees: table<proposedNewTime: record, status: record>, body: record<content: string, contentType: string>, bodyPreview: string, cancelledOccurrences: list<string>, end: record<dateTime: string, timeZone: string>, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, locations: table<address: record, coordinates: record, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, onlineMeeting: record<conferenceId: string, joinUrl: string, phones: list<record>, quickDial: string, tollFreeNumbers: list<string>, tollNumber: string>, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record<emailAddress: record<address: string, name: string>>, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record<pattern: record<dayOfMonth: float, daysOfWeek: list, firstDayOfWeek: string, index: string, interval: float, month: float, type: string>, range: record<endDate: string, numberOfOccurrences: float, recurrenceTimeZone: string, startDate: string, type: string>>, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record<response: string, time: string>, sensitivity: string, seriesMasterId: string, showAs: string, start: record<dateTime: string, timeZone: string>, subject: string, transactionId: string, type: string, webLink: string, attachments: table<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float>, calendar: record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: list<record>, calendarView: list<any>, events: list<any>, multiValueExtendedProperties: list<record>, singleValueExtendedProperties: list<record>>, exceptionOccurrences: list<any>, extensions: table<id: string>, instances: list<any>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update event
#
# PATCH /groups/{group-id}/calendar/events/{event-id}
# Docs: https://learn.microsoft.com/graph/api/group-update-event?view=graph-rest-1.0 — Find more info here
# operationId: group.calendar_UpdateEvent
# --attendees item shape: {proposedNewTime?: record, status?: record}
# --body shape: {content?: string, contentType?: "text"|"html"}
# --end shape: {dateTime?: string, timeZone?: string}
# --location shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --locations item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --onlineMeeting shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
# --organizer shape: {emailAddress?: record}
# --recurrence shape: {pattern?: record, range?: record}
# --responseStatus shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
# --start shape: {dateTime?: string, timeZone?: string}
# --attachments item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
# --exceptionOccurrences item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --extensions item shape: {id?: string}
# --instances item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --multiValueExtendedProperties item shape: {id?: string, value?: list}
# --singleValueExtendedProperties item shape: {id?: string, value?: string}
export def "groups-calendar-events UpdateEvent" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowNewTimeProposals: oneof<nothing, bool> # true if the meeting organizer allows invitees to propose a new time when responding; otherwise, false. Optional. The default is true. (nullable)
  --attendees: list # The collection of attendees for the event. — item shape: {proposedNewTime?: record, status?: record}
  --body-body: record # shape: {content?: string, contentType?: "text"|"html"}
  --bodyPreview: string # The preview of the message associated with the event. It's in text format. (nullable)
  --cancelledOccurrences: list # Contains occurrenceId property values of canceled instances in a recurring series, if the event is the series master. Instances in a recurring series that are canceled are called canceled occurences.Requires $select to retrieve. Only returned in a Get operation that specifies the ID (seriesMasterId property value) of a series master event.
  --end: record # shape: {dateTime?: string, timeZone?: string}
  --hasAttachments: oneof<nothing, bool> # Set to true if the event has attachments. (nullable)
  --hideAttendees: oneof<nothing, bool> # When set to true, each attendee only sees themselves in the meeting request and meeting Tracking list. The default is false. (nullable)
  --iCalUId: string # A unique identifier for an event across calendars. This ID is different for each occurrence in a recurring series. Read-only. (nullable)
  --importance: string@importance-completer
  --isAllDay: oneof<nothing, bool> # Set to true if the event lasts all day. If true, regardless of whether it's a single-day or multi-day event, start, and endtime must be set to midnight and be in the same time zone. (nullable)
  --isCancelled: oneof<nothing, bool> # Set to true if the event has been canceled. (nullable)
  --isDraft: oneof<nothing, bool> # Set to true if the user has updated the meeting in Outlook but hasn't sent the updates to attendees. Set to false if all changes are sent, or if the event is an appointment without any attendees. (nullable)
  --isOnlineMeeting: oneof<nothing, bool> # True if this event has online meeting information (that is, onlineMeeting points to an onlineMeetingInfo resource), false otherwise. Default is false (onlineMeeting is null). Optional.  After you set isOnlineMeeting to true, Microsoft Graph initializes onlineMeeting. Subsequently, Outlook ignores any further changes to isOnlineMeeting, and the meeting remains available online. (nullable)
  --isOrganizer: oneof<nothing, bool> # Set to true if the calendar owner (specified by the owner property of the calendar) is the organizer of the event (specified by the organizer property of the event). It also applies if a delegate organized the event on behalf of the owner. (nullable)
  --isReminderOn: oneof<nothing, bool> # Set to true if an alert is set to remind the user of the event. (nullable)
  --location: record # shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --locations: list # The locations where the event is held or attended from. The location and locations properties always correspond with each other. If you update the location property, any prior locations in the locations collection are removed and replaced by the new location value. — item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --onlineMeeting: record # shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
  --onlineMeetingProvider: string@onlineMeetingProvider-completer
  --onlineMeetingUrl: string # A URL for an online meeting. The property is set only when an organizer specifies in Outlook that an event is an online meeting such as Skype. Read-only.To access the URL to join an online meeting, use joinUrl which is exposed via the onlineMeeting property of the event. The onlineMeetingUrl property will be deprecated in the future. (nullable)
  --organizer: record # shape: {emailAddress?: record}
  --originalEndTimeZone: string # The end time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --originalStart: string # Represents the start time of an event when it's initially created as an occurrence or exception in a recurring series. This property is not returned for events that are single instances. Its date and time information is expressed in ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --originalStartTimeZone: string # The start time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --recurrence: record # shape: {pattern?: record, range?: record}
  --reminderMinutesBeforeStart: float # The number of minutes before the event start time that the reminder alert occurs. (nullable, format: int32)
  --responseRequested: oneof<nothing, bool> # Default is true, which represents the organizer would like an invitee to send a response to the event. (nullable)
  --responseStatus: record # shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
  --sensitivity: string@sensitivity-completer
  --seriesMasterId: string # The ID for the recurring series master item, if this event is part of a recurring series. (nullable)
  --showAs: string@showAs-completer
  --start: record # shape: {dateTime?: string, timeZone?: string}
  --subject: string # The text of the event's subject line. (nullable)
  --transactionId: string # A custom identifier specified by a client app for the server to avoid redundant POST operations in case of client retries to create the same event. It's useful when low network connectivity causes the client to time out before receiving a response from the server for the client's prior create-event request. After you set transactionId when creating an event, you can't change transactionId in a subsequent update. This property is only returned in a response payload if an app has set it. Optional. (nullable)
  --type: string@type-completer
  --webLink: string # The URL to open the event in Outlook on the web.Outlook on the web opens the event in the browser if you are signed in to your mailbox. Otherwise, Outlook on the web prompts you to sign in.This URL can't be accessed from within an iFrame. (nullable)
  --attachments: list # The collection of FileAttachment, ItemAttachment, and referenceAttachment attachments for the event. Navigation property. Read-only. Nullable. — item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
  --calendar: any
  --exceptionOccurrences: list # Contains the id property values of the event instances that are exceptions in a recurring series.Exceptions can differ from other occurrences in a recurring series, such as the subject, start or end times, or attendees. Exceptions don't include canceled occurrences.Requires $select and $expand to retrieve. Only returned in a GET operation that specifies the ID (seriesMasterId property value) of a series master event. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --extensions: list # The collection of open extensions defined for the event. Nullable. — item shape: {id?: string}
  --instances: list # The occurrences of a recurring series, if the event is a series master. This property includes occurrences that are part of the recurrence pattern, and exceptions modified, but doesn't include occurrences canceled from the series. Navigation property. Read-only. Nullable. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --multiValueExtendedProperties: list # The collection of multi-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: list}
  --singleValueExtendedProperties: list # The collection of single-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: string}
]: any -> record<allowNewTimeProposals: bool, attendees: table<proposedNewTime: record, status: record>, body: record<content: string, contentType: string>, bodyPreview: string, cancelledOccurrences: list<string>, end: record<dateTime: string, timeZone: string>, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, locations: table<address: record, coordinates: record, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, onlineMeeting: record<conferenceId: string, joinUrl: string, phones: list<record>, quickDial: string, tollFreeNumbers: list<string>, tollNumber: string>, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record<emailAddress: record<address: string, name: string>>, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record<pattern: record<dayOfMonth: float, daysOfWeek: list, firstDayOfWeek: string, index: string, interval: float, month: float, type: string>, range: record<endDate: string, numberOfOccurrences: float, recurrenceTimeZone: string, startDate: string, type: string>>, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record<response: string, time: string>, sensitivity: string, seriesMasterId: string, showAs: string, start: record<dateTime: string, timeZone: string>, subject: string, transactionId: string, type: string, webLink: string, attachments: table<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float>, calendar: record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: list<record>, calendarView: list<any>, events: list<any>, multiValueExtendedProperties: list<record>, singleValueExtendedProperties: list<record>>, exceptionOccurrences: list<any>, extensions: table<id: string>, instances: list<any>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)")
  let body = {allowNewTimeProposals: $allowNewTimeProposals, attendees: $attendees, body: $body_body, bodyPreview: $bodyPreview, cancelledOccurrences: $cancelledOccurrences, end: $end, hasAttachments: $hasAttachments, hideAttendees: $hideAttendees, iCalUId: $iCalUId, importance: $importance, isAllDay: $isAllDay, isCancelled: $isCancelled, isDraft: $isDraft, isOnlineMeeting: $isOnlineMeeting, isOrganizer: $isOrganizer, isReminderOn: $isReminderOn, location: $location, locations: $locations, onlineMeeting: $onlineMeeting, onlineMeetingProvider: $onlineMeetingProvider, onlineMeetingUrl: $onlineMeetingUrl, organizer: $organizer, originalEndTimeZone: $originalEndTimeZone, originalStart: $originalStart, originalStartTimeZone: $originalStartTimeZone, recurrence: $recurrence, reminderMinutesBeforeStart: $reminderMinutesBeforeStart, responseRequested: $responseRequested, responseStatus: $responseStatus, sensitivity: $sensitivity, seriesMasterId: $seriesMasterId, showAs: $showAs, start: $start, subject: $subject, transactionId: $transactionId, type: $type, webLink: $webLink, attachments: $attachments, calendar: $calendar, exceptionOccurrences: $exceptionOccurrences, extensions: $extensions, instances: $instances, multiValueExtendedProperties: $multiValueExtendedProperties, singleValueExtendedProperties: $singleValueExtendedProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property events for groups
#
# DELETE /groups/{group-id}/calendar/events/{event-id}
# operationId: group.calendar_DeleteEvent
export def "groups-calendar-events DeleteEvent" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get attachments from groups
#
# GET /groups/{group-id}/calendar/events/{event-id}/attachments
# operationId: group.calendar.event_ListAttachment
export def "groups-calendar-events-attachments ListAttachment" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/attachments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to attachments for groups
#
# POST /groups/{group-id}/calendar/events/{event-id}/attachments
# operationId: group.calendar.event_CreateAttachment
export def "groups-calendar-events-attachments CreateAttachment" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --contentType: string # The MIME type. (nullable)
  --isInline: oneof<nothing, bool> # true if the attachment is an inline attachment; otherwise, false.
  --lastModifiedDateTime: string # The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --name: string # The attachment's file name. (nullable)
  --size: float # The length of the attachment in bytes. (format: int32)
]: any -> record<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/attachments")
  let body = {id: $id, contentType: $contentType, isInline: $isInline, lastModifiedDateTime: $lastModifiedDateTime, name: $name, size: $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get attachments from groups
#
# GET /groups/{group-id}/calendar/events/{event-id}/attachments/{attachment-id}
# operationId: group.calendar.event_GetAttachment
export def "groups-calendar-events-attachments GetAttachment" [
  group_id: string
  event_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/attachments/($attachment_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete navigation property attachments for groups
#
# DELETE /groups/{group-id}/calendar/events/{event-id}/attachments/{attachment-id}
# operationId: group.calendar.event_DeleteAttachment
export def "groups-calendar-events-attachments DeleteAttachment" [
  group_id: string
  event_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/attachments/($attachment_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /groups/{group-id}/calendar/events/{event-id}/attachments/$count
# operationId: group.calendar.event.attachment_GetCount
export def "groups-calendar-events-attachments-count GetCount" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/attachments/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action createUploadSession
#
# POST /groups/{group-id}/calendar/events/{event-id}/attachments/microsoft.graph.createUploadSession
# Docs: https://learn.microsoft.com/graph/api/attachment-createuploadsession?view=graph-rest-1.0 — Find more info here
# operationId: group.calendar.event.attachment_createUploadSession
# --AttachmentItem shape: {attachmentType?: "file"|"item"|"reference", contentId?: string, contentType?: string, isInline?: bool, name?: string, size?: float}
export def "groups-calendar-events-attachments-microsoftgraphcreate-upload-session createUploadSession" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AttachmentItem: record # shape: {attachmentType?: "file"|"item"|"reference", contentId?: string, contentType?: string, isInline?: bool, name?: string, size?: float}
]: any -> record<expirationDateTime: string, nextExpectedRanges: list<string>, uploadUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/attachments/microsoft.graph.createUploadSession")
  let body = {AttachmentItem: $AttachmentItem} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get calendar from groups
#
# GET /groups/{group-id}/calendar/events/{event-id}/calendar
# operationId: group.calendar.event_GetCalendar
export def "groups-calendar-events-calendar GetCalendar" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: table<id: string, allowedRoles: list, emailAddress: record, isInsideOrganization: bool, isRemovable: bool, role: string>, calendarView: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, events: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/calendar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get extensions from groups
#
# GET /groups/{group-id}/calendar/events/{event-id}/extensions
# operationId: group.calendar.event_ListExtension
export def "groups-calendar-events-extensions ListExtension" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/extensions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to extensions for groups
#
# POST /groups/{group-id}/calendar/events/{event-id}/extensions
# operationId: group.calendar.event_CreateExtension
export def "groups-calendar-events-extensions CreateExtension" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/extensions")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get extensions from groups
#
# GET /groups/{group-id}/calendar/events/{event-id}/extensions/{extension-id}
# operationId: group.calendar.event_GetExtension
export def "groups-calendar-events-extensions GetExtension" [
  group_id: string
  event_id: string
  extension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/extensions/($extension_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property extensions in groups
#
# PATCH /groups/{group-id}/calendar/events/{event-id}/extensions/{extension-id}
# operationId: group.calendar.event_UpdateExtension
export def "groups-calendar-events-extensions UpdateExtension" [
  group_id: string
  event_id: string
  extension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/extensions/($extension_id)")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property extensions for groups
#
# DELETE /groups/{group-id}/calendar/events/{event-id}/extensions/{extension-id}
# operationId: group.calendar.event_DeleteExtension
export def "groups-calendar-events-extensions DeleteExtension" [
  group_id: string
  event_id: string
  extension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/extensions/($extension_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /groups/{group-id}/calendar/events/{event-id}/extensions/$count
# operationId: group.calendar.event.extension_GetCount
export def "groups-calendar-events-extensions-count GetCount" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/extensions/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get instances from groups
#
# GET /groups/{group-id}/calendar/events/{event-id}/instances
# operationId: group.calendar.event_ListInstance
export def "groups-calendar-events-instances ListInstance" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T19:00:00-08:00
  --endDateTime: string # The end date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/instances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function delta
#
# GET /groups/{group-id}/calendar/events/{event-id}/instances/microsoft.graph.delta()
# Docs: https://learn.microsoft.com/graph/api/event-delta?view=graph-rest-1.0 — Find more info here
# operationId: group.calendar.event.instance_delta
export def "groups-calendar-events-instances-microsoftgraphdelta delta" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --endDateTime: string # The end date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: record, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, _odata_nextLink: string, _odata_deltaLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/instances/microsoft.graph.delta()" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action accept
#
# POST /groups/{group-id}/calendar/events/{event-id}/microsoft.graph.accept
# Docs: https://learn.microsoft.com/graph/api/event-accept?view=graph-rest-1.0 — Find more info here
# operationId: group.calendar.event_accept
export def "groups-calendar-events-microsoftgraphaccept accept" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --SendResponse: oneof<nothing, bool> # nullable, default: false
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/microsoft.graph.accept")
  let body = {SendResponse: $SendResponse, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action cancel
#
# POST /groups/{group-id}/calendar/events/{event-id}/microsoft.graph.cancel
# Docs: https://learn.microsoft.com/graph/api/event-cancel?view=graph-rest-1.0 — Find more info here
# operationId: group.calendar.event_cancel
export def "groups-calendar-events-microsoftgraphcancel cancel" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/microsoft.graph.cancel")
  let body = {Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action decline
#
# POST /groups/{group-id}/calendar/events/{event-id}/microsoft.graph.decline
# Docs: https://learn.microsoft.com/graph/api/event-decline?view=graph-rest-1.0 — Find more info here
# operationId: group.calendar.event_decline
# --ProposedNewTime shape: {end?: record, start?: record}
export def "groups-calendar-events-microsoftgraphdecline decline" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ProposedNewTime: record # shape: {end?: record, start?: record}
  --SendResponse: oneof<nothing, bool> # nullable, default: false
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/microsoft.graph.decline")
  let body = {ProposedNewTime: $ProposedNewTime, SendResponse: $SendResponse, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action dismissReminder
#
# POST /groups/{group-id}/calendar/events/{event-id}/microsoft.graph.dismissReminder
# Docs: https://learn.microsoft.com/graph/api/event-dismissreminder?view=graph-rest-1.0 — Find more info here
# operationId: group.calendar.event_dismissReminder
export def "groups-calendar-events-microsoftgraphdismiss-reminder dismissReminder" [
  group_id: string
  event_id: string
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
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/microsoft.graph.dismissReminder")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action forward
#
# POST /groups/{group-id}/calendar/events/{event-id}/microsoft.graph.forward
# Docs: https://learn.microsoft.com/graph/api/event-forward?view=graph-rest-1.0 — Find more info here
# operationId: group.calendar.event_forward
# --ToRecipients item shape: {emailAddress?: record}
export def "groups-calendar-events-microsoftgraphforward forward" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ToRecipients: list # item shape: {emailAddress?: record}
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/microsoft.graph.forward")
  let body = {ToRecipients: $ToRecipients, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action permanentDelete
#
# POST /groups/{group-id}/calendar/events/{event-id}/microsoft.graph.permanentDelete
# operationId: group.calendar.event_permanentDelete
export def "groups-calendar-events-microsoftgraphpermanent-delete permanentDelete" [
  group_id: string
  event_id: string
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
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/microsoft.graph.permanentDelete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action snoozeReminder
#
# POST /groups/{group-id}/calendar/events/{event-id}/microsoft.graph.snoozeReminder
# Docs: https://learn.microsoft.com/graph/api/event-snoozereminder?view=graph-rest-1.0 — Find more info here
# operationId: group.calendar.event_snoozeReminder
# --NewReminderTime shape: {dateTime?: string, timeZone?: string}
export def "groups-calendar-events-microsoftgraphsnooze-reminder snoozeReminder" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --NewReminderTime: record # shape: {dateTime?: string, timeZone?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/microsoft.graph.snoozeReminder")
  let body = {NewReminderTime: $NewReminderTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action tentativelyAccept
#
# POST /groups/{group-id}/calendar/events/{event-id}/microsoft.graph.tentativelyAccept
# Docs: https://learn.microsoft.com/graph/api/event-tentativelyaccept?view=graph-rest-1.0 — Find more info here
# operationId: group.calendar.event_tentativelyAccept
# --ProposedNewTime shape: {end?: record, start?: record}
export def "groups-calendar-events-microsoftgraphtentatively-accept tentativelyAccept" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ProposedNewTime: record # shape: {end?: record, start?: record}
  --SendResponse: oneof<nothing, bool> # nullable, default: false
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/($event_id)/microsoft.graph.tentativelyAccept")
  let body = {ProposedNewTime: $ProposedNewTime, SendResponse: $SendResponse, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the number of the resource
#
# GET /groups/{group-id}/calendar/events/$count
# operationId: group.calendar.event_GetCount
export def "groups-calendar-events-count GetCount" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function delta
#
# GET /groups/{group-id}/calendar/events/microsoft.graph.delta()
# Docs: https://learn.microsoft.com/graph/api/event-delta?view=graph-rest-1.0 — Find more info here
# operationId: group.calendar.event_delta
export def "groups-calendar-events-microsoftgraphdelta delta" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --endDateTime: string # The end date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: record, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, _odata_nextLink: string, _odata_deltaLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/calendar/events/microsoft.graph.delta()" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function allowedCalendarSharingRoles
#
# GET /groups/{group-id}/calendar/microsoft.graph.allowedCalendarSharingRoles(User='{User}')
# operationId: group.calendar_allowedCalendarSharingRole
export def "groups-calendar-microsoftgraphallowed-calendar-sharing-roles-user-user allowedCalendarSharingRole" [
  group_id: string
  User: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
]: nothing -> record<value: list<string>, _odata_nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/calendar/microsoft.graph.allowedCalendarSharingRoles(User='($User)')" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action getSchedule
#
# POST /groups/{group-id}/calendar/microsoft.graph.getSchedule
# Docs: https://learn.microsoft.com/graph/api/calendar-getschedule?view=graph-rest-1.0 — Find more info here
# operationId: group.calendar_getSchedule
# --EndTime shape: {dateTime?: string, timeZone?: string}
# --StartTime shape: {dateTime?: string, timeZone?: string}
export def "groups-calendar-microsoftgraphget-schedule post" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Schedules: list
  --EndTime: record # shape: {dateTime?: string, timeZone?: string}
  --StartTime: record # shape: {dateTime?: string, timeZone?: string}
  --AvailabilityViewInterval: float # nullable, format: int32
]: any -> record<value: table<availabilityView: string, error: record, scheduleId: string, scheduleItems: list, workingHours: record>, _odata_nextLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/calendar/microsoft.graph.getSchedule")
  let body = {Schedules: $Schedules, EndTime: $EndTime, StartTime: $StartTime, AvailabilityViewInterval: $AvailabilityViewInterval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action permanentDelete
#
# POST /groups/{group-id}/calendar/microsoft.graph.permanentDelete
# operationId: group.calendar_permanentDelete
export def "groups-calendar-microsoftgraphpermanent-delete permanentDelete" [
  group_id: string
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
  let full_url = (build-url $base $"/groups/($group_id)/calendar/microsoft.graph.permanentDelete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List group calendarView
#
# GET /groups/{group-id}/calendarView
# Docs: https://learn.microsoft.com/graph/api/group-list-calendarview?view=graph-rest-1.0 — Find more info here
# operationId: group_ListCalendarView
export def "groups-calendar-view ListCalendarView" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T19:00:00-08:00
  --endDateTime: string # The end date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/calendarView" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function delta
#
# GET /groups/{group-id}/calendarView/microsoft.graph.delta()
# Docs: https://learn.microsoft.com/graph/api/event-delta?view=graph-rest-1.0 — Find more info here
# operationId: group.calendarView_delta
export def "groups-calendar-view-microsoftgraphdelta delta" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --endDateTime: string # The end date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: record, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, _odata_nextLink: string, _odata_deltaLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/calendarView/microsoft.graph.delta()" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List events
#
# GET /groups/{group-id}/events
# Docs: https://learn.microsoft.com/graph/api/group-list-events?view=graph-rest-1.0 — Find more info here
# operationId: group_ListEvent
export def "groups-events ListEvent" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create event
#
# POST /groups/{group-id}/events
# Docs: https://learn.microsoft.com/graph/api/group-post-events?view=graph-rest-1.0 — Find more info here
# operationId: group_CreateEvent
# --attendees item shape: {proposedNewTime?: record, status?: record}
# --body shape: {content?: string, contentType?: "text"|"html"}
# --end shape: {dateTime?: string, timeZone?: string}
# --location shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --locations item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --onlineMeeting shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
# --organizer shape: {emailAddress?: record}
# --recurrence shape: {pattern?: record, range?: record}
# --responseStatus shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
# --start shape: {dateTime?: string, timeZone?: string}
# --attachments item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
# --exceptionOccurrences item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --extensions item shape: {id?: string}
# --instances item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --multiValueExtendedProperties item shape: {id?: string, value?: list}
# --singleValueExtendedProperties item shape: {id?: string, value?: string}
export def "groups-events CreateEvent" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowNewTimeProposals: oneof<nothing, bool> # true if the meeting organizer allows invitees to propose a new time when responding; otherwise, false. Optional. The default is true. (nullable)
  --attendees: list # The collection of attendees for the event. — item shape: {proposedNewTime?: record, status?: record}
  --body-body: record # shape: {content?: string, contentType?: "text"|"html"}
  --bodyPreview: string # The preview of the message associated with the event. It's in text format. (nullable)
  --cancelledOccurrences: list # Contains occurrenceId property values of canceled instances in a recurring series, if the event is the series master. Instances in a recurring series that are canceled are called canceled occurences.Requires $select to retrieve. Only returned in a Get operation that specifies the ID (seriesMasterId property value) of a series master event.
  --end: record # shape: {dateTime?: string, timeZone?: string}
  --hasAttachments: oneof<nothing, bool> # Set to true if the event has attachments. (nullable)
  --hideAttendees: oneof<nothing, bool> # When set to true, each attendee only sees themselves in the meeting request and meeting Tracking list. The default is false. (nullable)
  --iCalUId: string # A unique identifier for an event across calendars. This ID is different for each occurrence in a recurring series. Read-only. (nullable)
  --importance: string@importance-completer
  --isAllDay: oneof<nothing, bool> # Set to true if the event lasts all day. If true, regardless of whether it's a single-day or multi-day event, start, and endtime must be set to midnight and be in the same time zone. (nullable)
  --isCancelled: oneof<nothing, bool> # Set to true if the event has been canceled. (nullable)
  --isDraft: oneof<nothing, bool> # Set to true if the user has updated the meeting in Outlook but hasn't sent the updates to attendees. Set to false if all changes are sent, or if the event is an appointment without any attendees. (nullable)
  --isOnlineMeeting: oneof<nothing, bool> # True if this event has online meeting information (that is, onlineMeeting points to an onlineMeetingInfo resource), false otherwise. Default is false (onlineMeeting is null). Optional.  After you set isOnlineMeeting to true, Microsoft Graph initializes onlineMeeting. Subsequently, Outlook ignores any further changes to isOnlineMeeting, and the meeting remains available online. (nullable)
  --isOrganizer: oneof<nothing, bool> # Set to true if the calendar owner (specified by the owner property of the calendar) is the organizer of the event (specified by the organizer property of the event). It also applies if a delegate organized the event on behalf of the owner. (nullable)
  --isReminderOn: oneof<nothing, bool> # Set to true if an alert is set to remind the user of the event. (nullable)
  --location: record # shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --locations: list # The locations where the event is held or attended from. The location and locations properties always correspond with each other. If you update the location property, any prior locations in the locations collection are removed and replaced by the new location value. — item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --onlineMeeting: record # shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
  --onlineMeetingProvider: string@onlineMeetingProvider-completer
  --onlineMeetingUrl: string # A URL for an online meeting. The property is set only when an organizer specifies in Outlook that an event is an online meeting such as Skype. Read-only.To access the URL to join an online meeting, use joinUrl which is exposed via the onlineMeeting property of the event. The onlineMeetingUrl property will be deprecated in the future. (nullable)
  --organizer: record # shape: {emailAddress?: record}
  --originalEndTimeZone: string # The end time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --originalStart: string # Represents the start time of an event when it's initially created as an occurrence or exception in a recurring series. This property is not returned for events that are single instances. Its date and time information is expressed in ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --originalStartTimeZone: string # The start time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --recurrence: record # shape: {pattern?: record, range?: record}
  --reminderMinutesBeforeStart: float # The number of minutes before the event start time that the reminder alert occurs. (nullable, format: int32)
  --responseRequested: oneof<nothing, bool> # Default is true, which represents the organizer would like an invitee to send a response to the event. (nullable)
  --responseStatus: record # shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
  --sensitivity: string@sensitivity-completer
  --seriesMasterId: string # The ID for the recurring series master item, if this event is part of a recurring series. (nullable)
  --showAs: string@showAs-completer
  --start: record # shape: {dateTime?: string, timeZone?: string}
  --subject: string # The text of the event's subject line. (nullable)
  --transactionId: string # A custom identifier specified by a client app for the server to avoid redundant POST operations in case of client retries to create the same event. It's useful when low network connectivity causes the client to time out before receiving a response from the server for the client's prior create-event request. After you set transactionId when creating an event, you can't change transactionId in a subsequent update. This property is only returned in a response payload if an app has set it. Optional. (nullable)
  --type: string@type-completer
  --webLink: string # The URL to open the event in Outlook on the web.Outlook on the web opens the event in the browser if you are signed in to your mailbox. Otherwise, Outlook on the web prompts you to sign in.This URL can't be accessed from within an iFrame. (nullable)
  --attachments: list # The collection of FileAttachment, ItemAttachment, and referenceAttachment attachments for the event. Navigation property. Read-only. Nullable. — item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
  --calendar: any
  --exceptionOccurrences: list # Contains the id property values of the event instances that are exceptions in a recurring series.Exceptions can differ from other occurrences in a recurring series, such as the subject, start or end times, or attendees. Exceptions don't include canceled occurrences.Requires $select and $expand to retrieve. Only returned in a GET operation that specifies the ID (seriesMasterId property value) of a series master event. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --extensions: list # The collection of open extensions defined for the event. Nullable. — item shape: {id?: string}
  --instances: list # The occurrences of a recurring series, if the event is a series master. This property includes occurrences that are part of the recurrence pattern, and exceptions modified, but doesn't include occurrences canceled from the series. Navigation property. Read-only. Nullable. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --multiValueExtendedProperties: list # The collection of multi-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: list}
  --singleValueExtendedProperties: list # The collection of single-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: string}
]: any -> record<allowNewTimeProposals: bool, attendees: table<proposedNewTime: record, status: record>, body: record<content: string, contentType: string>, bodyPreview: string, cancelledOccurrences: list<string>, end: record<dateTime: string, timeZone: string>, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, locations: table<address: record, coordinates: record, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, onlineMeeting: record<conferenceId: string, joinUrl: string, phones: list<record>, quickDial: string, tollFreeNumbers: list<string>, tollNumber: string>, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record<emailAddress: record<address: string, name: string>>, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record<pattern: record<dayOfMonth: float, daysOfWeek: list, firstDayOfWeek: string, index: string, interval: float, month: float, type: string>, range: record<endDate: string, numberOfOccurrences: float, recurrenceTimeZone: string, startDate: string, type: string>>, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record<response: string, time: string>, sensitivity: string, seriesMasterId: string, showAs: string, start: record<dateTime: string, timeZone: string>, subject: string, transactionId: string, type: string, webLink: string, attachments: table<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float>, calendar: record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: list<record>, calendarView: list<any>, events: list<any>, multiValueExtendedProperties: list<record>, singleValueExtendedProperties: list<record>>, exceptionOccurrences: list<any>, extensions: table<id: string>, instances: list<any>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/events")
  let body = {allowNewTimeProposals: $allowNewTimeProposals, attendees: $attendees, body: $body_body, bodyPreview: $bodyPreview, cancelledOccurrences: $cancelledOccurrences, end: $end, hasAttachments: $hasAttachments, hideAttendees: $hideAttendees, iCalUId: $iCalUId, importance: $importance, isAllDay: $isAllDay, isCancelled: $isCancelled, isDraft: $isDraft, isOnlineMeeting: $isOnlineMeeting, isOrganizer: $isOrganizer, isReminderOn: $isReminderOn, location: $location, locations: $locations, onlineMeeting: $onlineMeeting, onlineMeetingProvider: $onlineMeetingProvider, onlineMeetingUrl: $onlineMeetingUrl, organizer: $organizer, originalEndTimeZone: $originalEndTimeZone, originalStart: $originalStart, originalStartTimeZone: $originalStartTimeZone, recurrence: $recurrence, reminderMinutesBeforeStart: $reminderMinutesBeforeStart, responseRequested: $responseRequested, responseStatus: $responseStatus, sensitivity: $sensitivity, seriesMasterId: $seriesMasterId, showAs: $showAs, start: $start, subject: $subject, transactionId: $transactionId, type: $type, webLink: $webLink, attachments: $attachments, calendar: $calendar, exceptionOccurrences: $exceptionOccurrences, extensions: $extensions, instances: $instances, multiValueExtendedProperties: $multiValueExtendedProperties, singleValueExtendedProperties: $singleValueExtendedProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get event
#
# GET /groups/{group-id}/events/{event-id}
# Docs: https://learn.microsoft.com/graph/api/group-get-event?view=graph-rest-1.0 — Find more info here
# operationId: group_GetEvent
export def "groups-events GetEvent" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<allowNewTimeProposals: bool, attendees: table<proposedNewTime: record, status: record>, body: record<content: string, contentType: string>, bodyPreview: string, cancelledOccurrences: list<string>, end: record<dateTime: string, timeZone: string>, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, locations: table<address: record, coordinates: record, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, onlineMeeting: record<conferenceId: string, joinUrl: string, phones: list<record>, quickDial: string, tollFreeNumbers: list<string>, tollNumber: string>, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record<emailAddress: record<address: string, name: string>>, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record<pattern: record<dayOfMonth: float, daysOfWeek: list, firstDayOfWeek: string, index: string, interval: float, month: float, type: string>, range: record<endDate: string, numberOfOccurrences: float, recurrenceTimeZone: string, startDate: string, type: string>>, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record<response: string, time: string>, sensitivity: string, seriesMasterId: string, showAs: string, start: record<dateTime: string, timeZone: string>, subject: string, transactionId: string, type: string, webLink: string, attachments: table<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float>, calendar: record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: list<record>, calendarView: list<any>, events: list<any>, multiValueExtendedProperties: list<record>, singleValueExtendedProperties: list<record>>, exceptionOccurrences: list<any>, extensions: table<id: string>, instances: list<any>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property events in groups
#
# PATCH /groups/{group-id}/events/{event-id}
# operationId: group_UpdateEvent
# --attendees item shape: {proposedNewTime?: record, status?: record}
# --body shape: {content?: string, contentType?: "text"|"html"}
# --end shape: {dateTime?: string, timeZone?: string}
# --location shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --locations item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --onlineMeeting shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
# --organizer shape: {emailAddress?: record}
# --recurrence shape: {pattern?: record, range?: record}
# --responseStatus shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
# --start shape: {dateTime?: string, timeZone?: string}
# --attachments item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
# --exceptionOccurrences item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --extensions item shape: {id?: string}
# --instances item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --multiValueExtendedProperties item shape: {id?: string, value?: list}
# --singleValueExtendedProperties item shape: {id?: string, value?: string}
export def "groups-events UpdateEvent" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowNewTimeProposals: oneof<nothing, bool> # true if the meeting organizer allows invitees to propose a new time when responding; otherwise, false. Optional. The default is true. (nullable)
  --attendees: list # The collection of attendees for the event. — item shape: {proposedNewTime?: record, status?: record}
  --body-body: record # shape: {content?: string, contentType?: "text"|"html"}
  --bodyPreview: string # The preview of the message associated with the event. It's in text format. (nullable)
  --cancelledOccurrences: list # Contains occurrenceId property values of canceled instances in a recurring series, if the event is the series master. Instances in a recurring series that are canceled are called canceled occurences.Requires $select to retrieve. Only returned in a Get operation that specifies the ID (seriesMasterId property value) of a series master event.
  --end: record # shape: {dateTime?: string, timeZone?: string}
  --hasAttachments: oneof<nothing, bool> # Set to true if the event has attachments. (nullable)
  --hideAttendees: oneof<nothing, bool> # When set to true, each attendee only sees themselves in the meeting request and meeting Tracking list. The default is false. (nullable)
  --iCalUId: string # A unique identifier for an event across calendars. This ID is different for each occurrence in a recurring series. Read-only. (nullable)
  --importance: string@importance-completer
  --isAllDay: oneof<nothing, bool> # Set to true if the event lasts all day. If true, regardless of whether it's a single-day or multi-day event, start, and endtime must be set to midnight and be in the same time zone. (nullable)
  --isCancelled: oneof<nothing, bool> # Set to true if the event has been canceled. (nullable)
  --isDraft: oneof<nothing, bool> # Set to true if the user has updated the meeting in Outlook but hasn't sent the updates to attendees. Set to false if all changes are sent, or if the event is an appointment without any attendees. (nullable)
  --isOnlineMeeting: oneof<nothing, bool> # True if this event has online meeting information (that is, onlineMeeting points to an onlineMeetingInfo resource), false otherwise. Default is false (onlineMeeting is null). Optional.  After you set isOnlineMeeting to true, Microsoft Graph initializes onlineMeeting. Subsequently, Outlook ignores any further changes to isOnlineMeeting, and the meeting remains available online. (nullable)
  --isOrganizer: oneof<nothing, bool> # Set to true if the calendar owner (specified by the owner property of the calendar) is the organizer of the event (specified by the organizer property of the event). It also applies if a delegate organized the event on behalf of the owner. (nullable)
  --isReminderOn: oneof<nothing, bool> # Set to true if an alert is set to remind the user of the event. (nullable)
  --location: record # shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --locations: list # The locations where the event is held or attended from. The location and locations properties always correspond with each other. If you update the location property, any prior locations in the locations collection are removed and replaced by the new location value. — item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --onlineMeeting: record # shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
  --onlineMeetingProvider: string@onlineMeetingProvider-completer
  --onlineMeetingUrl: string # A URL for an online meeting. The property is set only when an organizer specifies in Outlook that an event is an online meeting such as Skype. Read-only.To access the URL to join an online meeting, use joinUrl which is exposed via the onlineMeeting property of the event. The onlineMeetingUrl property will be deprecated in the future. (nullable)
  --organizer: record # shape: {emailAddress?: record}
  --originalEndTimeZone: string # The end time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --originalStart: string # Represents the start time of an event when it's initially created as an occurrence or exception in a recurring series. This property is not returned for events that are single instances. Its date and time information is expressed in ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --originalStartTimeZone: string # The start time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --recurrence: record # shape: {pattern?: record, range?: record}
  --reminderMinutesBeforeStart: float # The number of minutes before the event start time that the reminder alert occurs. (nullable, format: int32)
  --responseRequested: oneof<nothing, bool> # Default is true, which represents the organizer would like an invitee to send a response to the event. (nullable)
  --responseStatus: record # shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
  --sensitivity: string@sensitivity-completer
  --seriesMasterId: string # The ID for the recurring series master item, if this event is part of a recurring series. (nullable)
  --showAs: string@showAs-completer
  --start: record # shape: {dateTime?: string, timeZone?: string}
  --subject: string # The text of the event's subject line. (nullable)
  --transactionId: string # A custom identifier specified by a client app for the server to avoid redundant POST operations in case of client retries to create the same event. It's useful when low network connectivity causes the client to time out before receiving a response from the server for the client's prior create-event request. After you set transactionId when creating an event, you can't change transactionId in a subsequent update. This property is only returned in a response payload if an app has set it. Optional. (nullable)
  --type: string@type-completer
  --webLink: string # The URL to open the event in Outlook on the web.Outlook on the web opens the event in the browser if you are signed in to your mailbox. Otherwise, Outlook on the web prompts you to sign in.This URL can't be accessed from within an iFrame. (nullable)
  --attachments: list # The collection of FileAttachment, ItemAttachment, and referenceAttachment attachments for the event. Navigation property. Read-only. Nullable. — item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
  --calendar: any
  --exceptionOccurrences: list # Contains the id property values of the event instances that are exceptions in a recurring series.Exceptions can differ from other occurrences in a recurring series, such as the subject, start or end times, or attendees. Exceptions don't include canceled occurrences.Requires $select and $expand to retrieve. Only returned in a GET operation that specifies the ID (seriesMasterId property value) of a series master event. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --extensions: list # The collection of open extensions defined for the event. Nullable. — item shape: {id?: string}
  --instances: list # The occurrences of a recurring series, if the event is a series master. This property includes occurrences that are part of the recurrence pattern, and exceptions modified, but doesn't include occurrences canceled from the series. Navigation property. Read-only. Nullable. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --multiValueExtendedProperties: list # The collection of multi-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: list}
  --singleValueExtendedProperties: list # The collection of single-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: string}
]: any -> record<allowNewTimeProposals: bool, attendees: table<proposedNewTime: record, status: record>, body: record<content: string, contentType: string>, bodyPreview: string, cancelledOccurrences: list<string>, end: record<dateTime: string, timeZone: string>, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, locations: table<address: record, coordinates: record, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, onlineMeeting: record<conferenceId: string, joinUrl: string, phones: list<record>, quickDial: string, tollFreeNumbers: list<string>, tollNumber: string>, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record<emailAddress: record<address: string, name: string>>, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record<pattern: record<dayOfMonth: float, daysOfWeek: list, firstDayOfWeek: string, index: string, interval: float, month: float, type: string>, range: record<endDate: string, numberOfOccurrences: float, recurrenceTimeZone: string, startDate: string, type: string>>, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record<response: string, time: string>, sensitivity: string, seriesMasterId: string, showAs: string, start: record<dateTime: string, timeZone: string>, subject: string, transactionId: string, type: string, webLink: string, attachments: table<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float>, calendar: record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: list<record>, calendarView: list<any>, events: list<any>, multiValueExtendedProperties: list<record>, singleValueExtendedProperties: list<record>>, exceptionOccurrences: list<any>, extensions: table<id: string>, instances: list<any>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)")
  let body = {allowNewTimeProposals: $allowNewTimeProposals, attendees: $attendees, body: $body_body, bodyPreview: $bodyPreview, cancelledOccurrences: $cancelledOccurrences, end: $end, hasAttachments: $hasAttachments, hideAttendees: $hideAttendees, iCalUId: $iCalUId, importance: $importance, isAllDay: $isAllDay, isCancelled: $isCancelled, isDraft: $isDraft, isOnlineMeeting: $isOnlineMeeting, isOrganizer: $isOrganizer, isReminderOn: $isReminderOn, location: $location, locations: $locations, onlineMeeting: $onlineMeeting, onlineMeetingProvider: $onlineMeetingProvider, onlineMeetingUrl: $onlineMeetingUrl, organizer: $organizer, originalEndTimeZone: $originalEndTimeZone, originalStart: $originalStart, originalStartTimeZone: $originalStartTimeZone, recurrence: $recurrence, reminderMinutesBeforeStart: $reminderMinutesBeforeStart, responseRequested: $responseRequested, responseStatus: $responseStatus, sensitivity: $sensitivity, seriesMasterId: $seriesMasterId, showAs: $showAs, start: $start, subject: $subject, transactionId: $transactionId, type: $type, webLink: $webLink, attachments: $attachments, calendar: $calendar, exceptionOccurrences: $exceptionOccurrences, extensions: $extensions, instances: $instances, multiValueExtendedProperties: $multiValueExtendedProperties, singleValueExtendedProperties: $singleValueExtendedProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete event
#
# DELETE /groups/{group-id}/events/{event-id}
# Docs: https://learn.microsoft.com/graph/api/group-delete-event?view=graph-rest-1.0 — Find more info here
# operationId: group_DeleteEvent
export def "groups-events DeleteEvent" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get attachments from groups
#
# GET /groups/{group-id}/events/{event-id}/attachments
# operationId: group.event_ListAttachment
export def "groups-events-attachments ListAttachment" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/attachments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to attachments for groups
#
# POST /groups/{group-id}/events/{event-id}/attachments
# operationId: group.event_CreateAttachment
export def "groups-events-attachments CreateAttachment" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --contentType: string # The MIME type. (nullable)
  --isInline: oneof<nothing, bool> # true if the attachment is an inline attachment; otherwise, false.
  --lastModifiedDateTime: string # The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --name: string # The attachment's file name. (nullable)
  --size: float # The length of the attachment in bytes. (format: int32)
]: any -> record<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/attachments")
  let body = {id: $id, contentType: $contentType, isInline: $isInline, lastModifiedDateTime: $lastModifiedDateTime, name: $name, size: $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get attachments from groups
#
# GET /groups/{group-id}/events/{event-id}/attachments/{attachment-id}
# operationId: group.event_GetAttachment
export def "groups-events-attachments GetAttachment" [
  group_id: string
  event_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/attachments/($attachment_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete navigation property attachments for groups
#
# DELETE /groups/{group-id}/events/{event-id}/attachments/{attachment-id}
# operationId: group.event_DeleteAttachment
export def "groups-events-attachments DeleteAttachment" [
  group_id: string
  event_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/attachments/($attachment_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /groups/{group-id}/events/{event-id}/attachments/$count
# operationId: group.event.attachment_GetCount
export def "groups-events-attachments-count GetCount" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/attachments/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action createUploadSession
#
# POST /groups/{group-id}/events/{event-id}/attachments/microsoft.graph.createUploadSession
# Docs: https://learn.microsoft.com/graph/api/attachment-createuploadsession?view=graph-rest-1.0 — Find more info here
# operationId: group.event.attachment_createUploadSession
# --AttachmentItem shape: {attachmentType?: "file"|"item"|"reference", contentId?: string, contentType?: string, isInline?: bool, name?: string, size?: float}
export def "groups-events-attachments-microsoftgraphcreate-upload-session createUploadSession" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AttachmentItem: record # shape: {attachmentType?: "file"|"item"|"reference", contentId?: string, contentType?: string, isInline?: bool, name?: string, size?: float}
]: any -> record<expirationDateTime: string, nextExpectedRanges: list<string>, uploadUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/attachments/microsoft.graph.createUploadSession")
  let body = {AttachmentItem: $AttachmentItem} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get calendar from groups
#
# GET /groups/{group-id}/events/{event-id}/calendar
# operationId: group.event_GetCalendar
export def "groups-events-calendar GetCalendar" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: table<id: string, allowedRoles: list, emailAddress: record, isInsideOrganization: bool, isRemovable: bool, role: string>, calendarView: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, events: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/calendar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get open extension
#
# GET /groups/{group-id}/events/{event-id}/extensions
# operationId: group.event_ListExtension
export def "groups-events-extensions ListExtension" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/extensions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create open extension
#
# POST /groups/{group-id}/events/{event-id}/extensions
# Docs: https://learn.microsoft.com/graph/api/opentypeextension-post-opentypeextension?view=graph-rest-1.0 — Find more info here
# operationId: group.event_CreateExtension
export def "groups-events-extensions CreateExtension" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/extensions")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get open extension
#
# GET /groups/{group-id}/events/{event-id}/extensions/{extension-id}
# Docs: https://learn.microsoft.com/graph/api/opentypeextension-get?view=graph-rest-1.0 — Find more info here
# operationId: group.event_GetExtension
export def "groups-events-extensions GetExtension" [
  group_id: string
  event_id: string
  extension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/extensions/($extension_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property extensions in groups
#
# PATCH /groups/{group-id}/events/{event-id}/extensions/{extension-id}
# operationId: group.event_UpdateExtension
export def "groups-events-extensions UpdateExtension" [
  group_id: string
  event_id: string
  extension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/extensions/($extension_id)")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property extensions for groups
#
# DELETE /groups/{group-id}/events/{event-id}/extensions/{extension-id}
# operationId: group.event_DeleteExtension
export def "groups-events-extensions DeleteExtension" [
  group_id: string
  event_id: string
  extension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/extensions/($extension_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /groups/{group-id}/events/{event-id}/extensions/$count
# operationId: group.event.extension_GetCount
export def "groups-events-extensions-count GetCount" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/extensions/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get instances from groups
#
# GET /groups/{group-id}/events/{event-id}/instances
# operationId: group.event_ListInstance
export def "groups-events-instances ListInstance" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T19:00:00-08:00
  --endDateTime: string # The end date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/instances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function delta
#
# GET /groups/{group-id}/events/{event-id}/instances/microsoft.graph.delta()
# Docs: https://learn.microsoft.com/graph/api/event-delta?view=graph-rest-1.0 — Find more info here
# operationId: group.event.instance_delta
export def "groups-events-instances-microsoftgraphdelta delta" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --endDateTime: string # The end date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: record, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, _odata_nextLink: string, _odata_deltaLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/instances/microsoft.graph.delta()" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action accept
#
# POST /groups/{group-id}/events/{event-id}/microsoft.graph.accept
# Docs: https://learn.microsoft.com/graph/api/event-accept?view=graph-rest-1.0 — Find more info here
# operationId: group.event_accept
export def "groups-events-microsoftgraphaccept accept" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --SendResponse: oneof<nothing, bool> # nullable, default: false
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/microsoft.graph.accept")
  let body = {SendResponse: $SendResponse, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action cancel
#
# POST /groups/{group-id}/events/{event-id}/microsoft.graph.cancel
# Docs: https://learn.microsoft.com/graph/api/event-cancel?view=graph-rest-1.0 — Find more info here
# operationId: group.event_cancel
export def "groups-events-microsoftgraphcancel cancel" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/microsoft.graph.cancel")
  let body = {Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action decline
#
# POST /groups/{group-id}/events/{event-id}/microsoft.graph.decline
# Docs: https://learn.microsoft.com/graph/api/event-decline?view=graph-rest-1.0 — Find more info here
# operationId: group.event_decline
# --ProposedNewTime shape: {end?: record, start?: record}
export def "groups-events-microsoftgraphdecline decline" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ProposedNewTime: record # shape: {end?: record, start?: record}
  --SendResponse: oneof<nothing, bool> # nullable, default: false
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/microsoft.graph.decline")
  let body = {ProposedNewTime: $ProposedNewTime, SendResponse: $SendResponse, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action dismissReminder
#
# POST /groups/{group-id}/events/{event-id}/microsoft.graph.dismissReminder
# Docs: https://learn.microsoft.com/graph/api/event-dismissreminder?view=graph-rest-1.0 — Find more info here
# operationId: group.event_dismissReminder
export def "groups-events-microsoftgraphdismiss-reminder dismissReminder" [
  group_id: string
  event_id: string
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
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/microsoft.graph.dismissReminder")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action forward
#
# POST /groups/{group-id}/events/{event-id}/microsoft.graph.forward
# Docs: https://learn.microsoft.com/graph/api/event-forward?view=graph-rest-1.0 — Find more info here
# operationId: group.event_forward
# --ToRecipients item shape: {emailAddress?: record}
export def "groups-events-microsoftgraphforward forward" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ToRecipients: list # item shape: {emailAddress?: record}
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/microsoft.graph.forward")
  let body = {ToRecipients: $ToRecipients, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action permanentDelete
#
# POST /groups/{group-id}/events/{event-id}/microsoft.graph.permanentDelete
# operationId: group.event_permanentDelete
export def "groups-events-microsoftgraphpermanent-delete permanentDelete" [
  group_id: string
  event_id: string
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
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/microsoft.graph.permanentDelete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action snoozeReminder
#
# POST /groups/{group-id}/events/{event-id}/microsoft.graph.snoozeReminder
# Docs: https://learn.microsoft.com/graph/api/event-snoozereminder?view=graph-rest-1.0 — Find more info here
# operationId: group.event_snoozeReminder
# --NewReminderTime shape: {dateTime?: string, timeZone?: string}
export def "groups-events-microsoftgraphsnooze-reminder snoozeReminder" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --NewReminderTime: record # shape: {dateTime?: string, timeZone?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/microsoft.graph.snoozeReminder")
  let body = {NewReminderTime: $NewReminderTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action tentativelyAccept
#
# POST /groups/{group-id}/events/{event-id}/microsoft.graph.tentativelyAccept
# Docs: https://learn.microsoft.com/graph/api/event-tentativelyaccept?view=graph-rest-1.0 — Find more info here
# operationId: group.event_tentativelyAccept
# --ProposedNewTime shape: {end?: record, start?: record}
export def "groups-events-microsoftgraphtentatively-accept tentativelyAccept" [
  group_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ProposedNewTime: record # shape: {end?: record, start?: record}
  --SendResponse: oneof<nothing, bool> # nullable, default: false
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)/events/($event_id)/microsoft.graph.tentativelyAccept")
  let body = {ProposedNewTime: $ProposedNewTime, SendResponse: $SendResponse, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the number of the resource
#
# GET /groups/{group-id}/events/$count
# operationId: group.event_GetCount
export def "groups-events-count GetCount" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/events/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function delta
#
# GET /groups/{group-id}/events/microsoft.graph.delta()
# Docs: https://learn.microsoft.com/graph/api/event-delta?view=graph-rest-1.0 — Find more info here
# operationId: group.event_delta
export def "groups-events-microsoftgraphdelta delta" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --endDateTime: string # The end date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: record, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, _odata_nextLink: string, _odata_deltaLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/events/microsoft.graph.delta()" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create place
#
# POST /places
# Docs: https://learn.microsoft.com/graph/api/place-post?view=graph-rest-1.0 — Find more info here
# operationId: place_CreatePlace
# --address shape: {city?: string, countryOrRegion?: string, postalCode?: string, state?: string, street?: string}
# --geoCoordinates shape: {accuracy?: float, altitude?: float, altitudeAccuracy?: float, latitude?: float, longitude?: float}
# --checkIns item shape: {calendarEventId?: string, checkInMethod?: "unspecified"|"manual"|"inferred"|"verified"|"unknownFutureValue", createdDateTime?: string}
export def "places CreatePlace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --address: record # shape: {city?: string, countryOrRegion?: string, postalCode?: string, state?: string, street?: string}
  --displayName: string # The name that is associated with the place.
  --geoCoordinates: record # shape: {accuracy?: float, altitude?: float, altitudeAccuracy?: float, latitude?: float, longitude?: float}
  --isWheelChairAccessible: oneof<nothing, bool> # Indicates whether the place is wheelchair accessible. (nullable)
  --label: string # User-defined description of the place. (nullable)
  --parentId: string # The ID of a parent place. (nullable)
  --phone: string # The phone number of the place. (nullable)
  --tags: list # Custom tags that are associated with the place for categorization or filtering.
  --checkIns: list # A subresource of a place object that indicates the check-in status of an Outlook calendar event booked at the place. — item shape: {calendarEventId?: string, checkInMethod?: "unspecified"|"manual"|"inferred"|"verified"|"unknownFutureValue", createdDateTime?: string}
]: any -> record<id: string, address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, displayName: string, geoCoordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, isWheelChairAccessible: bool, label: string, parentId: string, phone: string, tags: list<string>, checkIns: table<calendarEventId: string, checkInMethod: string, createdDateTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/places")
  let body = {id: $id, address: $address, displayName: $displayName, geoCoordinates: $geoCoordinates, isWheelChairAccessible: $isWheelChairAccessible, label: $label, parentId: $parentId, phone: $phone, tags: $tags, checkIns: $checkIns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update place
#
# PATCH /places/{place-id}
# Docs: https://learn.microsoft.com/graph/api/place-update?view=graph-rest-1.0 — Find more info here
# operationId: place_UpdatePlace
# --address shape: {city?: string, countryOrRegion?: string, postalCode?: string, state?: string, street?: string}
# --geoCoordinates shape: {accuracy?: float, altitude?: float, altitudeAccuracy?: float, latitude?: float, longitude?: float}
# --checkIns item shape: {calendarEventId?: string, checkInMethod?: "unspecified"|"manual"|"inferred"|"verified"|"unknownFutureValue", createdDateTime?: string}
export def "places UpdatePlace" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --address: record # shape: {city?: string, countryOrRegion?: string, postalCode?: string, state?: string, street?: string}
  --displayName: string # The name that is associated with the place.
  --geoCoordinates: record # shape: {accuracy?: float, altitude?: float, altitudeAccuracy?: float, latitude?: float, longitude?: float}
  --isWheelChairAccessible: oneof<nothing, bool> # Indicates whether the place is wheelchair accessible. (nullable)
  --label: string # User-defined description of the place. (nullable)
  --parentId: string # The ID of a parent place. (nullable)
  --phone: string # The phone number of the place. (nullable)
  --tags: list # Custom tags that are associated with the place for categorization or filtering.
  --checkIns: list # A subresource of a place object that indicates the check-in status of an Outlook calendar event booked at the place. — item shape: {calendarEventId?: string, checkInMethod?: "unspecified"|"manual"|"inferred"|"verified"|"unknownFutureValue", createdDateTime?: string}
]: any -> record<id: string, address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, displayName: string, geoCoordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, isWheelChairAccessible: bool, label: string, parentId: string, phone: string, tags: list<string>, checkIns: table<calendarEventId: string, checkInMethod: string, createdDateTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)")
  let body = {id: $id, address: $address, displayName: $displayName, geoCoordinates: $geoCoordinates, isWheelChairAccessible: $isWheelChairAccessible, label: $label, parentId: $parentId, phone: $phone, tags: $tags, checkIns: $checkIns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete place
#
# DELETE /places/{place-id}
# Docs: https://learn.microsoft.com/graph/api/place-delete?view=graph-rest-1.0 — Find more info here
# operationId: place_DeletePlace
export def "places DeletePlace" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get checkInClaim
#
# GET /places/{place-id}/checkIns
# operationId: place_ListCheckIn
export def "places-check-ins ListCheckIn" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/checkIns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create checkInClaim
#
# POST /places/{place-id}/checkIns
# Docs: https://learn.microsoft.com/graph/api/place-post-checkins?view=graph-rest-1.0 — Find more info here
# operationId: place_CreateCheckIn
export def "places-check-ins CreateCheckIn" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calendarEventId: string # The unique identifier for an Outlook calendar event associated with the checkInClaim object. For more information, see the iCalUId property in event.
  --checkInMethod: string@checkInMethod-completer
  --createdDateTime: string # The date and time when the checkInClaim object was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
]: any -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/checkIns")
  let body = {calendarEventId: $calendarEventId, checkInMethod: $checkInMethod, createdDateTime: $createdDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get checkInClaim
#
# GET /places/{place-id}/checkIns/{checkInClaim-calendarEventId}
# Docs: https://learn.microsoft.com/graph/api/checkinclaim-get?view=graph-rest-1.0 — Find more info here
# operationId: place_GetCheckIn
export def "places-check-ins GetCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/checkIns/($checkInClaim_calendarEventId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property checkIns in places
#
# PATCH /places/{place-id}/checkIns/{checkInClaim-calendarEventId}
# operationId: place_UpdateCheckIn
export def "places-check-ins UpdateCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calendarEventId: string # The unique identifier for an Outlook calendar event associated with the checkInClaim object. For more information, see the iCalUId property in event.
  --checkInMethod: string@checkInMethod-completer
  --createdDateTime: string # The date and time when the checkInClaim object was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
]: any -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/checkIns/($checkInClaim_calendarEventId)")
  let body = {calendarEventId: $calendarEventId, checkInMethod: $checkInMethod, createdDateTime: $createdDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property checkIns for places
#
# DELETE /places/{place-id}/checkIns/{checkInClaim-calendarEventId}
# operationId: place_DeleteCheckIn
export def "places-check-ins DeleteCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/checkIns/($checkInClaim_calendarEventId)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/{place-id}/checkIns/$count
# operationId: place.checkIn_GetCount
export def "places-check-ins-count GetCount" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/checkIns/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List place objects
#
# GET /places/{place-id}/microsoft.graph.building
# Docs: https://learn.microsoft.com/graph/api/place-list?view=graph-rest-1.0 — Find more info here
# operationId: place_GetPlaceAsBuilding
export def "places-microsoftgraphbuilding GetPlaceAsBuilding" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<resourceLinks: table<linkType: string, name: string, value: string>, wifiState: string, map: record<placeId: string, footprints: list<record>, levels: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get checkIns from places
#
# GET /places/{place-id}/microsoft.graph.building/checkIns
# operationId: placeAsBuilding_ListCheckIn
export def "places-microsoftgraphbuilding-check-ins ListCheckIn" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/checkIns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to checkIns for places
#
# POST /places/{place-id}/microsoft.graph.building/checkIns
# operationId: placeAsBuilding_CreateCheckIn
export def "places-microsoftgraphbuilding-check-ins CreateCheckIn" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calendarEventId: string # The unique identifier for an Outlook calendar event associated with the checkInClaim object. For more information, see the iCalUId property in event.
  --checkInMethod: string@checkInMethod-completer
  --createdDateTime: string # The date and time when the checkInClaim object was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
]: any -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/checkIns")
  let body = {calendarEventId: $calendarEventId, checkInMethod: $checkInMethod, createdDateTime: $createdDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get checkIns from places
#
# GET /places/{place-id}/microsoft.graph.building/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsBuilding_GetCheckIn
export def "places-microsoftgraphbuilding-check-ins GetCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/checkIns/($checkInClaim_calendarEventId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property checkIns in places
#
# PATCH /places/{place-id}/microsoft.graph.building/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsBuilding_UpdateCheckIn
export def "places-microsoftgraphbuilding-check-ins UpdateCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calendarEventId: string # The unique identifier for an Outlook calendar event associated with the checkInClaim object. For more information, see the iCalUId property in event.
  --checkInMethod: string@checkInMethod-completer
  --createdDateTime: string # The date and time when the checkInClaim object was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
]: any -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/checkIns/($checkInClaim_calendarEventId)")
  let body = {calendarEventId: $calendarEventId, checkInMethod: $checkInMethod, createdDateTime: $createdDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property checkIns for places
#
# DELETE /places/{place-id}/microsoft.graph.building/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsBuilding_DeleteCheckIn
export def "places-microsoftgraphbuilding-check-ins DeleteCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/checkIns/($checkInClaim_calendarEventId)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/{place-id}/microsoft.graph.building/checkIns/$count
# operationId: placeAsBuilding.checkIn_GetCount
export def "places-microsoftgraphbuilding-check-ins-count GetCount" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/checkIns/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get buildingMap
#
# GET /places/{place-id}/microsoft.graph.building/map
# Docs: https://learn.microsoft.com/graph/api/buildingmap-get?view=graph-rest-1.0 — Find more info here
# operationId: placeAsBuilding_GetMap
export def "places-microsoftgraphbuilding-map GetMap" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<placeId: string, footprints: list<record>, levels: table<placeId: string, fixtures: list, sections: list, units: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property map in places
#
# PATCH /places/{place-id}/microsoft.graph.building/map
# operationId: placeAsBuilding_UpdateMap
# --levels item shape: {placeId?: string, fixtures?: list, sections?: list, units?: list}
export def "places-microsoftgraphbuilding-map UpdateMap" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --placeId: string # Identifier for the building to which this buildingMap belongs. (nullable)
  --footprints: list # Represents the approximate physical extent of a referenced building. It corresponds to footprint.geojson in IMDF format.
  --levels: list # Represents a physical floor structure within a building. It corresponds to level.geojson in IMDF format. — item shape: {placeId?: string, fixtures?: list, sections?: list, units?: list}
]: any -> record<placeId: string, footprints: list<record>, levels: table<placeId: string, fixtures: list, sections: list, units: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map")
  let body = {placeId: $placeId, footprints: $footprints, levels: $levels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete buildingMap
#
# DELETE /places/{place-id}/microsoft.graph.building/map
# Docs: https://learn.microsoft.com/graph/api/buildingmap-delete?view=graph-rest-1.0 — Find more info here
# operationId: placeAsBuilding_DeleteMap
export def "places-microsoftgraphbuilding-map DeleteMap" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List footprints
#
# GET /places/{place-id}/microsoft.graph.building/map/footprints
# Docs: https://learn.microsoft.com/graph/api/buildingmap-list-footprints?view=graph-rest-1.0 — Find more info here
# operationId: placeAsBuilding.map_ListFootprint
export def "places-microsoftgraphbuilding-map-footprints ListFootprint" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/footprints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to footprints for places
#
# POST /places/{place-id}/microsoft.graph.building/map/footprints
# operationId: placeAsBuilding.map_CreateFootprint
export def "places-microsoftgraphbuilding-map-footprints CreateFootprint" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/footprints")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get footprints from places
#
# GET /places/{place-id}/microsoft.graph.building/map/footprints/{footprintMap-id}
# operationId: placeAsBuilding.map_GetFootprint
export def "places-microsoftgraphbuilding-map-footprints GetFootprint" [
  place_id: string
  footprintMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/footprints/($footprintMap_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property footprints in places
#
# PATCH /places/{place-id}/microsoft.graph.building/map/footprints/{footprintMap-id}
# operationId: placeAsBuilding.map_UpdateFootprint
export def "places-microsoftgraphbuilding-map-footprints UpdateFootprint" [
  place_id: string
  footprintMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/footprints/($footprintMap_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property footprints for places
#
# DELETE /places/{place-id}/microsoft.graph.building/map/footprints/{footprintMap-id}
# operationId: placeAsBuilding.map_DeleteFootprint
export def "places-microsoftgraphbuilding-map-footprints DeleteFootprint" [
  place_id: string
  footprintMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/footprints/($footprintMap_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/{place-id}/microsoft.graph.building/map/footprints/$count
# operationId: placeAsBuilding.map.footprint_GetCount
export def "places-microsoftgraphbuilding-map-footprints-count GetCount" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/footprints/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List levels
#
# GET /places/{place-id}/microsoft.graph.building/map/levels
# Docs: https://learn.microsoft.com/graph/api/buildingmap-list-levels?view=graph-rest-1.0 — Find more info here
# operationId: placeAsBuilding.map_ListLevel
export def "places-microsoftgraphbuilding-map-levels ListLevel" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to levels for places
#
# POST /places/{place-id}/microsoft.graph.building/map/levels
# operationId: placeAsBuilding.map_CreateLevel
# --fixtures item shape: {placeId?: string}
# --sections item shape: {placeId?: string}
# --units item shape: {placeId?: string}
export def "places-microsoftgraphbuilding-map-levels CreateLevel" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --placeId: string # Identifier of the floor to which this levelMap belongs. (nullable)
  --fixtures: list # Collection of fixtures (such as furniture or equipment) on this level. Supports upsert. — item shape: {placeId?: string}
  --sections: list # Collection of sections (such as zones or partitions) on this level. Supports upsert. — item shape: {placeId?: string}
  --units: list # Collection of units (such as rooms or offices) on this level. Supports upsert. — item shape: {placeId?: string}
]: any -> record<placeId: string, fixtures: table<placeId: string>, sections: table<placeId: string>, units: table<placeId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels")
  let body = {placeId: $placeId, fixtures: $fixtures, sections: $sections, units: $units} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get levels from places
#
# GET /places/{place-id}/microsoft.graph.building/map/levels/{levelMap-id}
# operationId: placeAsBuilding.map_GetLevel
export def "places-microsoftgraphbuilding-map-levels GetLevel" [
  place_id: string
  levelMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<placeId: string, fixtures: table<placeId: string>, sections: table<placeId: string>, units: table<placeId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels/($levelMap_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property levels in places
#
# PATCH /places/{place-id}/microsoft.graph.building/map/levels/{levelMap-id}
# operationId: placeAsBuilding.map_UpdateLevel
# --fixtures item shape: {placeId?: string}
# --sections item shape: {placeId?: string}
# --units item shape: {placeId?: string}
export def "places-microsoftgraphbuilding-map-levels UpdateLevel" [
  place_id: string
  levelMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --placeId: string # Identifier of the floor to which this levelMap belongs. (nullable)
  --fixtures: list # Collection of fixtures (such as furniture or equipment) on this level. Supports upsert. — item shape: {placeId?: string}
  --sections: list # Collection of sections (such as zones or partitions) on this level. Supports upsert. — item shape: {placeId?: string}
  --units: list # Collection of units (such as rooms or offices) on this level. Supports upsert. — item shape: {placeId?: string}
]: any -> record<placeId: string, fixtures: table<placeId: string>, sections: table<placeId: string>, units: table<placeId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels/($levelMap_id)")
  let body = {placeId: $placeId, fixtures: $fixtures, sections: $sections, units: $units} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property levels for places
#
# DELETE /places/{place-id}/microsoft.graph.building/map/levels/{levelMap-id}
# operationId: placeAsBuilding.map_DeleteLevel
export def "places-microsoftgraphbuilding-map-levels DeleteLevel" [
  place_id: string
  levelMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels/($levelMap_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List fixtures
#
# GET /places/{place-id}/microsoft.graph.building/map/levels/{levelMap-id}/fixtures
# Docs: https://learn.microsoft.com/graph/api/levelmap-list-fixtures?view=graph-rest-1.0 — Find more info here
# operationId: placeAsBuilding.map.level_ListFixture
export def "places-microsoftgraphbuilding-map-levels-fixtures ListFixture" [
  place_id: string
  levelMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels/($levelMap_id)/fixtures" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to fixtures for places
#
# POST /places/{place-id}/microsoft.graph.building/map/levels/{levelMap-id}/fixtures
# operationId: placeAsBuilding.map.level_CreateFixture
export def "places-microsoftgraphbuilding-map-levels-fixtures CreateFixture" [
  place_id: string
  levelMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --placeId: string # Identifier for the floor to which this fixtureMap belongs. (nullable)
]: any -> record<placeId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels/($levelMap_id)/fixtures")
  let body = {placeId: $placeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get fixtures from places
#
# GET /places/{place-id}/microsoft.graph.building/map/levels/{levelMap-id}/fixtures/{fixtureMap-id}
# operationId: placeAsBuilding.map.level_GetFixture
export def "places-microsoftgraphbuilding-map-levels-fixtures GetFixture" [
  place_id: string
  levelMap_id: string
  fixtureMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<placeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels/($levelMap_id)/fixtures/($fixtureMap_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update fixtureMap
#
# PATCH /places/{place-id}/microsoft.graph.building/map/levels/{levelMap-id}/fixtures/{fixtureMap-id}
# Docs: https://learn.microsoft.com/graph/api/fixturemap-update?view=graph-rest-1.0 — Find more info here
# operationId: placeAsBuilding.map.level_UpdateFixture
export def "places-microsoftgraphbuilding-map-levels-fixtures UpdateFixture" [
  place_id: string
  levelMap_id: string
  fixtureMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --placeId: string # Identifier for the floor to which this fixtureMap belongs. (nullable)
]: any -> record<placeId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels/($levelMap_id)/fixtures/($fixtureMap_id)")
  let body = {placeId: $placeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete fixtureMap
#
# DELETE /places/{place-id}/microsoft.graph.building/map/levels/{levelMap-id}/fixtures/{fixtureMap-id}
# Docs: https://learn.microsoft.com/graph/api/fixturemap-delete?view=graph-rest-1.0 — Find more info here
# operationId: placeAsBuilding.map.level_DeleteFixture
export def "places-microsoftgraphbuilding-map-levels-fixtures DeleteFixture" [
  place_id: string
  levelMap_id: string
  fixtureMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels/($levelMap_id)/fixtures/($fixtureMap_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/{place-id}/microsoft.graph.building/map/levels/{levelMap-id}/fixtures/$count
# operationId: placeAsBuilding.map.level.fixture_GetCount
export def "places-microsoftgraphbuilding-map-levels-fixtures-count GetCount" [
  place_id: string
  levelMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels/($levelMap_id)/fixtures/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List sections
#
# GET /places/{place-id}/microsoft.graph.building/map/levels/{levelMap-id}/sections
# Docs: https://learn.microsoft.com/graph/api/levelmap-list-sections?view=graph-rest-1.0 — Find more info here
# operationId: placeAsBuilding.map.level_ListSection
export def "places-microsoftgraphbuilding-map-levels-sections ListSection" [
  place_id: string
  levelMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels/($levelMap_id)/sections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to sections for places
#
# POST /places/{place-id}/microsoft.graph.building/map/levels/{levelMap-id}/sections
# operationId: placeAsBuilding.map.level_CreateSection
export def "places-microsoftgraphbuilding-map-levels-sections CreateSection" [
  place_id: string
  levelMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --placeId: string # Identifier of the section to which this sectionMap belongs. (nullable)
]: any -> record<placeId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels/($levelMap_id)/sections")
  let body = {placeId: $placeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get sections from places
#
# GET /places/{place-id}/microsoft.graph.building/map/levels/{levelMap-id}/sections/{sectionMap-id}
# operationId: placeAsBuilding.map.level_GetSection
export def "places-microsoftgraphbuilding-map-levels-sections GetSection" [
  place_id: string
  levelMap_id: string
  sectionMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<placeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels/($levelMap_id)/sections/($sectionMap_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property sections in places
#
# PATCH /places/{place-id}/microsoft.graph.building/map/levels/{levelMap-id}/sections/{sectionMap-id}
# operationId: placeAsBuilding.map.level_UpdateSection
export def "places-microsoftgraphbuilding-map-levels-sections UpdateSection" [
  place_id: string
  levelMap_id: string
  sectionMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --placeId: string # Identifier of the section to which this sectionMap belongs. (nullable)
]: any -> record<placeId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels/($levelMap_id)/sections/($sectionMap_id)")
  let body = {placeId: $placeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property sections for places
#
# DELETE /places/{place-id}/microsoft.graph.building/map/levels/{levelMap-id}/sections/{sectionMap-id}
# operationId: placeAsBuilding.map.level_DeleteSection
export def "places-microsoftgraphbuilding-map-levels-sections DeleteSection" [
  place_id: string
  levelMap_id: string
  sectionMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels/($levelMap_id)/sections/($sectionMap_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/{place-id}/microsoft.graph.building/map/levels/{levelMap-id}/sections/$count
# operationId: placeAsBuilding.map.level.section_GetCount
export def "places-microsoftgraphbuilding-map-levels-sections-count GetCount" [
  place_id: string
  levelMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels/($levelMap_id)/sections/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List units
#
# GET /places/{place-id}/microsoft.graph.building/map/levels/{levelMap-id}/units
# Docs: https://learn.microsoft.com/graph/api/levelmap-list-units?view=graph-rest-1.0 — Find more info here
# operationId: placeAsBuilding.map.level_ListUnit
export def "places-microsoftgraphbuilding-map-levels-units ListUnit" [
  place_id: string
  levelMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels/($levelMap_id)/units" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to units for places
#
# POST /places/{place-id}/microsoft.graph.building/map/levels/{levelMap-id}/units
# operationId: placeAsBuilding.map.level_CreateUnit
export def "places-microsoftgraphbuilding-map-levels-units CreateUnit" [
  place_id: string
  levelMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --placeId: string # Identifier of the place (such as a room) to which this unitMap belongs. (nullable)
]: any -> record<placeId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels/($levelMap_id)/units")
  let body = {placeId: $placeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get units from places
#
# GET /places/{place-id}/microsoft.graph.building/map/levels/{levelMap-id}/units/{unitMap-id}
# operationId: placeAsBuilding.map.level_GetUnit
export def "places-microsoftgraphbuilding-map-levels-units GetUnit" [
  place_id: string
  levelMap_id: string
  unitMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<placeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels/($levelMap_id)/units/($unitMap_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update unitMap
#
# PATCH /places/{place-id}/microsoft.graph.building/map/levels/{levelMap-id}/units/{unitMap-id}
# Docs: https://learn.microsoft.com/graph/api/unitmap-update?view=graph-rest-1.0 — Find more info here
# operationId: placeAsBuilding.map.level_UpdateUnit
export def "places-microsoftgraphbuilding-map-levels-units UpdateUnit" [
  place_id: string
  levelMap_id: string
  unitMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --placeId: string # Identifier of the place (such as a room) to which this unitMap belongs. (nullable)
]: any -> record<placeId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels/($levelMap_id)/units/($unitMap_id)")
  let body = {placeId: $placeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete unitMap
#
# DELETE /places/{place-id}/microsoft.graph.building/map/levels/{levelMap-id}/units/{unitMap-id}
# Docs: https://learn.microsoft.com/graph/api/unitmap-delete?view=graph-rest-1.0 — Find more info here
# operationId: placeAsBuilding.map.level_DeleteUnit
export def "places-microsoftgraphbuilding-map-levels-units DeleteUnit" [
  place_id: string
  levelMap_id: string
  unitMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels/($levelMap_id)/units/($unitMap_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/{place-id}/microsoft.graph.building/map/levels/{levelMap-id}/units/$count
# operationId: placeAsBuilding.map.level.unit_GetCount
export def "places-microsoftgraphbuilding-map-levels-units-count GetCount" [
  place_id: string
  levelMap_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels/($levelMap_id)/units/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/{place-id}/microsoft.graph.building/map/levels/$count
# operationId: placeAsBuilding.map.level_GetCount
export def "places-microsoftgraphbuilding-map-levels-count GetCount" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.building/map/levels/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function descendants
#
# GET /places/{place-id}/microsoft.graph.descendants()
# operationId: place_descendant
export def "places-microsoftgraphdescendants descendant" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<id: string, address: record, displayName: string, geoCoordinates: record, isWheelChairAccessible: bool, label: string, parentId: string, phone: string, tags: list, checkIns: list>, _odata_nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.descendants()" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List place objects
#
# GET /places/{place-id}/microsoft.graph.desk
# Docs: https://learn.microsoft.com/graph/api/place-list?view=graph-rest-1.0 — Find more info here
# operationId: place_GetPlaceAsDesk
export def "places-microsoftgraphdesk GetPlaceAsDesk" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<displayDeviceName: string, heightAdjustableState: string, mailboxDetails: record<emailAddress: string, externalDirectoryObjectId: string>, mode: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.desk" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get checkIns from places
#
# GET /places/{place-id}/microsoft.graph.desk/checkIns
# operationId: placeAsDesk_ListCheckIn
export def "places-microsoftgraphdesk-check-ins ListCheckIn" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.desk/checkIns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to checkIns for places
#
# POST /places/{place-id}/microsoft.graph.desk/checkIns
# operationId: placeAsDesk_CreateCheckIn
export def "places-microsoftgraphdesk-check-ins CreateCheckIn" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calendarEventId: string # The unique identifier for an Outlook calendar event associated with the checkInClaim object. For more information, see the iCalUId property in event.
  --checkInMethod: string@checkInMethod-completer
  --createdDateTime: string # The date and time when the checkInClaim object was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
]: any -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.desk/checkIns")
  let body = {calendarEventId: $calendarEventId, checkInMethod: $checkInMethod, createdDateTime: $createdDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get checkIns from places
#
# GET /places/{place-id}/microsoft.graph.desk/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsDesk_GetCheckIn
export def "places-microsoftgraphdesk-check-ins GetCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.desk/checkIns/($checkInClaim_calendarEventId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property checkIns in places
#
# PATCH /places/{place-id}/microsoft.graph.desk/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsDesk_UpdateCheckIn
export def "places-microsoftgraphdesk-check-ins UpdateCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calendarEventId: string # The unique identifier for an Outlook calendar event associated with the checkInClaim object. For more information, see the iCalUId property in event.
  --checkInMethod: string@checkInMethod-completer
  --createdDateTime: string # The date and time when the checkInClaim object was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
]: any -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.desk/checkIns/($checkInClaim_calendarEventId)")
  let body = {calendarEventId: $calendarEventId, checkInMethod: $checkInMethod, createdDateTime: $createdDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property checkIns for places
#
# DELETE /places/{place-id}/microsoft.graph.desk/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsDesk_DeleteCheckIn
export def "places-microsoftgraphdesk-check-ins DeleteCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.desk/checkIns/($checkInClaim_calendarEventId)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/{place-id}/microsoft.graph.desk/checkIns/$count
# operationId: placeAsDesk.checkIn_GetCount
export def "places-microsoftgraphdesk-check-ins-count GetCount" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.desk/checkIns/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List place objects
#
# GET /places/{place-id}/microsoft.graph.floor
# Docs: https://learn.microsoft.com/graph/api/place-list?view=graph-rest-1.0 — Find more info here
# operationId: place_GetPlaceAsFloor
export def "places-microsoftgraphfloor GetPlaceAsFloor" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<sortOrder: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.floor" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get checkIns from places
#
# GET /places/{place-id}/microsoft.graph.floor/checkIns
# operationId: placeAsFloor_ListCheckIn
export def "places-microsoftgraphfloor-check-ins ListCheckIn" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.floor/checkIns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to checkIns for places
#
# POST /places/{place-id}/microsoft.graph.floor/checkIns
# operationId: placeAsFloor_CreateCheckIn
export def "places-microsoftgraphfloor-check-ins CreateCheckIn" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calendarEventId: string # The unique identifier for an Outlook calendar event associated with the checkInClaim object. For more information, see the iCalUId property in event.
  --checkInMethod: string@checkInMethod-completer
  --createdDateTime: string # The date and time when the checkInClaim object was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
]: any -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.floor/checkIns")
  let body = {calendarEventId: $calendarEventId, checkInMethod: $checkInMethod, createdDateTime: $createdDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get checkIns from places
#
# GET /places/{place-id}/microsoft.graph.floor/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsFloor_GetCheckIn
export def "places-microsoftgraphfloor-check-ins GetCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.floor/checkIns/($checkInClaim_calendarEventId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property checkIns in places
#
# PATCH /places/{place-id}/microsoft.graph.floor/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsFloor_UpdateCheckIn
export def "places-microsoftgraphfloor-check-ins UpdateCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calendarEventId: string # The unique identifier for an Outlook calendar event associated with the checkInClaim object. For more information, see the iCalUId property in event.
  --checkInMethod: string@checkInMethod-completer
  --createdDateTime: string # The date and time when the checkInClaim object was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
]: any -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.floor/checkIns/($checkInClaim_calendarEventId)")
  let body = {calendarEventId: $calendarEventId, checkInMethod: $checkInMethod, createdDateTime: $createdDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property checkIns for places
#
# DELETE /places/{place-id}/microsoft.graph.floor/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsFloor_DeleteCheckIn
export def "places-microsoftgraphfloor-check-ins DeleteCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.floor/checkIns/($checkInClaim_calendarEventId)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/{place-id}/microsoft.graph.floor/checkIns/$count
# operationId: placeAsFloor.checkIn_GetCount
export def "places-microsoftgraphfloor-check-ins-count GetCount" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.floor/checkIns/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List place objects
#
# GET /places/{place-id}/microsoft.graph.room
# Docs: https://learn.microsoft.com/graph/api/place-list?view=graph-rest-1.0 — Find more info here
# operationId: place_GetPlaceAsRoom
export def "places-microsoftgraphroom GetPlaceAsRoom" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<audioDeviceName: string, bookingType: string, building: string, capacity: float, displayDeviceName: string, emailAddress: string, floorLabel: string, floorNumber: float, nickname: string, placeId: string, teamsEnabledState: string, videoDeviceName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.room" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get checkIns from places
#
# GET /places/{place-id}/microsoft.graph.room/checkIns
# operationId: placeAsRoom_ListCheckIn
export def "places-microsoftgraphroom-check-ins ListCheckIn" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.room/checkIns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to checkIns for places
#
# POST /places/{place-id}/microsoft.graph.room/checkIns
# operationId: placeAsRoom_CreateCheckIn
export def "places-microsoftgraphroom-check-ins CreateCheckIn" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calendarEventId: string # The unique identifier for an Outlook calendar event associated with the checkInClaim object. For more information, see the iCalUId property in event.
  --checkInMethod: string@checkInMethod-completer
  --createdDateTime: string # The date and time when the checkInClaim object was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
]: any -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.room/checkIns")
  let body = {calendarEventId: $calendarEventId, checkInMethod: $checkInMethod, createdDateTime: $createdDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get checkIns from places
#
# GET /places/{place-id}/microsoft.graph.room/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsRoom_GetCheckIn
export def "places-microsoftgraphroom-check-ins GetCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.room/checkIns/($checkInClaim_calendarEventId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property checkIns in places
#
# PATCH /places/{place-id}/microsoft.graph.room/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsRoom_UpdateCheckIn
export def "places-microsoftgraphroom-check-ins UpdateCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calendarEventId: string # The unique identifier for an Outlook calendar event associated with the checkInClaim object. For more information, see the iCalUId property in event.
  --checkInMethod: string@checkInMethod-completer
  --createdDateTime: string # The date and time when the checkInClaim object was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
]: any -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.room/checkIns/($checkInClaim_calendarEventId)")
  let body = {calendarEventId: $calendarEventId, checkInMethod: $checkInMethod, createdDateTime: $createdDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property checkIns for places
#
# DELETE /places/{place-id}/microsoft.graph.room/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsRoom_DeleteCheckIn
export def "places-microsoftgraphroom-check-ins DeleteCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.room/checkIns/($checkInClaim_calendarEventId)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/{place-id}/microsoft.graph.room/checkIns/$count
# operationId: placeAsRoom.checkIn_GetCount
export def "places-microsoftgraphroom-check-ins-count GetCount" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.room/checkIns/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get place
#
# GET /places/{place-id}/microsoft.graph.roomList
# Docs: https://learn.microsoft.com/graph/api/place-get?view=graph-rest-1.0 — Find more info here
# operationId: place_GetPlaceAsRoomList
export def "places-microsoftgraphroom-list GetPlaceAsRoomList" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<emailAddress: string, rooms: table<audioDeviceName: string, bookingType: string, building: string, capacity: float, displayDeviceName: string, emailAddress: string, floorLabel: string, floorNumber: float, nickname: string, placeId: string, teamsEnabledState: string, videoDeviceName: string>, workspaces: table<capacity: float, displayDeviceName: string, emailAddress: string, mode: record, nickname: string, placeId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get checkIns from places
#
# GET /places/{place-id}/microsoft.graph.roomList/checkIns
# operationId: placeAsRoomList_ListCheckIn
export def "places-microsoftgraphroom-list-check-ins ListCheckIn" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/checkIns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to checkIns for places
#
# POST /places/{place-id}/microsoft.graph.roomList/checkIns
# operationId: placeAsRoomList_CreateCheckIn
export def "places-microsoftgraphroom-list-check-ins CreateCheckIn" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calendarEventId: string # The unique identifier for an Outlook calendar event associated with the checkInClaim object. For more information, see the iCalUId property in event.
  --checkInMethod: string@checkInMethod-completer
  --createdDateTime: string # The date and time when the checkInClaim object was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
]: any -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/checkIns")
  let body = {calendarEventId: $calendarEventId, checkInMethod: $checkInMethod, createdDateTime: $createdDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get checkIns from places
#
# GET /places/{place-id}/microsoft.graph.roomList/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsRoomList_GetCheckIn
export def "places-microsoftgraphroom-list-check-ins GetCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/checkIns/($checkInClaim_calendarEventId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property checkIns in places
#
# PATCH /places/{place-id}/microsoft.graph.roomList/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsRoomList_UpdateCheckIn
export def "places-microsoftgraphroom-list-check-ins UpdateCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calendarEventId: string # The unique identifier for an Outlook calendar event associated with the checkInClaim object. For more information, see the iCalUId property in event.
  --checkInMethod: string@checkInMethod-completer
  --createdDateTime: string # The date and time when the checkInClaim object was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
]: any -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/checkIns/($checkInClaim_calendarEventId)")
  let body = {calendarEventId: $calendarEventId, checkInMethod: $checkInMethod, createdDateTime: $createdDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property checkIns for places
#
# DELETE /places/{place-id}/microsoft.graph.roomList/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsRoomList_DeleteCheckIn
export def "places-microsoftgraphroom-list-check-ins DeleteCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/checkIns/($checkInClaim_calendarEventId)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/{place-id}/microsoft.graph.roomList/checkIns/$count
# operationId: placeAsRoomList.checkIn_GetCount
export def "places-microsoftgraphroom-list-check-ins-count GetCount" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/checkIns/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get rooms from places
#
# GET /places/{place-id}/microsoft.graph.roomList/rooms
# operationId: placeAsRoomList_ListRoom
export def "places-microsoftgraphroom-list-rooms ListRoom" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/rooms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to rooms for places
#
# POST /places/{place-id}/microsoft.graph.roomList/rooms
# operationId: placeAsRoomList_CreateRoom
export def "places-microsoftgraphroom-list-rooms CreateRoom" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --audioDeviceName: string # Specifies the name of the audio device in the room. (nullable)
  --bookingType: string@bookingType-completer
  --building: string # Specifies the building name or building number that the room is in. (nullable)
  --capacity: float # Specifies the capacity of the room. (nullable, format: int32)
  --displayDeviceName: string # Specifies the name of the display device in the room. (nullable)
  --emailAddress: string # Email address of the room. (nullable)
  --floorLabel: string # Specifies a descriptive label for the floor, for example, P. (nullable)
  --floorNumber: float # Specifies the floor number that the room is on. (nullable, format: int32)
  --nickname: string # Specifies a nickname for the room, for example, 'conf room'.
  --placeId: string # An alternative immutable unique identifier of the room. Read-only. (nullable)
  --teamsEnabledState: string@teamsEnabledState-completer
  --videoDeviceName: string # Specifies the name of the video device in the room. (nullable)
]: any -> record<audioDeviceName: string, bookingType: string, building: string, capacity: float, displayDeviceName: string, emailAddress: string, floorLabel: string, floorNumber: float, nickname: string, placeId: string, teamsEnabledState: string, videoDeviceName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/rooms")
  let body = {audioDeviceName: $audioDeviceName, bookingType: $bookingType, building: $building, capacity: $capacity, displayDeviceName: $displayDeviceName, emailAddress: $emailAddress, floorLabel: $floorLabel, floorNumber: $floorNumber, nickname: $nickname, placeId: $placeId, teamsEnabledState: $teamsEnabledState, videoDeviceName: $videoDeviceName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get rooms from places
#
# GET /places/{place-id}/microsoft.graph.roomList/rooms/{room-id}
# operationId: placeAsRoomList_GetRoom
export def "places-microsoftgraphroom-list-rooms GetRoom" [
  place_id: string
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<audioDeviceName: string, bookingType: string, building: string, capacity: float, displayDeviceName: string, emailAddress: string, floorLabel: string, floorNumber: float, nickname: string, placeId: string, teamsEnabledState: string, videoDeviceName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/rooms/($room_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property rooms in places
#
# PATCH /places/{place-id}/microsoft.graph.roomList/rooms/{room-id}
# operationId: placeAsRoomList_UpdateRoom
export def "places-microsoftgraphroom-list-rooms UpdateRoom" [
  place_id: string
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --audioDeviceName: string # Specifies the name of the audio device in the room. (nullable)
  --bookingType: string@bookingType-completer
  --building: string # Specifies the building name or building number that the room is in. (nullable)
  --capacity: float # Specifies the capacity of the room. (nullable, format: int32)
  --displayDeviceName: string # Specifies the name of the display device in the room. (nullable)
  --emailAddress: string # Email address of the room. (nullable)
  --floorLabel: string # Specifies a descriptive label for the floor, for example, P. (nullable)
  --floorNumber: float # Specifies the floor number that the room is on. (nullable, format: int32)
  --nickname: string # Specifies a nickname for the room, for example, 'conf room'.
  --placeId: string # An alternative immutable unique identifier of the room. Read-only. (nullable)
  --teamsEnabledState: string@teamsEnabledState-completer
  --videoDeviceName: string # Specifies the name of the video device in the room. (nullable)
]: any -> record<audioDeviceName: string, bookingType: string, building: string, capacity: float, displayDeviceName: string, emailAddress: string, floorLabel: string, floorNumber: float, nickname: string, placeId: string, teamsEnabledState: string, videoDeviceName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/rooms/($room_id)")
  let body = {audioDeviceName: $audioDeviceName, bookingType: $bookingType, building: $building, capacity: $capacity, displayDeviceName: $displayDeviceName, emailAddress: $emailAddress, floorLabel: $floorLabel, floorNumber: $floorNumber, nickname: $nickname, placeId: $placeId, teamsEnabledState: $teamsEnabledState, videoDeviceName: $videoDeviceName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property rooms for places
#
# DELETE /places/{place-id}/microsoft.graph.roomList/rooms/{room-id}
# operationId: placeAsRoomList_DeleteRoom
export def "places-microsoftgraphroom-list-rooms DeleteRoom" [
  place_id: string
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/rooms/($room_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get checkIns from places
#
# GET /places/{place-id}/microsoft.graph.roomList/rooms/{room-id}/checkIns
# operationId: placeAsRoomList.room_ListCheckIn
export def "places-microsoftgraphroom-list-rooms-check-ins ListCheckIn" [
  place_id: string
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/rooms/($room_id)/checkIns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to checkIns for places
#
# POST /places/{place-id}/microsoft.graph.roomList/rooms/{room-id}/checkIns
# operationId: placeAsRoomList.room_CreateCheckIn
export def "places-microsoftgraphroom-list-rooms-check-ins CreateCheckIn" [
  place_id: string
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calendarEventId: string # The unique identifier for an Outlook calendar event associated with the checkInClaim object. For more information, see the iCalUId property in event.
  --checkInMethod: string@checkInMethod-completer
  --createdDateTime: string # The date and time when the checkInClaim object was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
]: any -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/rooms/($room_id)/checkIns")
  let body = {calendarEventId: $calendarEventId, checkInMethod: $checkInMethod, createdDateTime: $createdDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get checkIns from places
#
# GET /places/{place-id}/microsoft.graph.roomList/rooms/{room-id}/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsRoomList.room_GetCheckIn
export def "places-microsoftgraphroom-list-rooms-check-ins GetCheckIn" [
  place_id: string
  room_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/rooms/($room_id)/checkIns/($checkInClaim_calendarEventId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property checkIns in places
#
# PATCH /places/{place-id}/microsoft.graph.roomList/rooms/{room-id}/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsRoomList.room_UpdateCheckIn
export def "places-microsoftgraphroom-list-rooms-check-ins UpdateCheckIn" [
  place_id: string
  room_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calendarEventId: string # The unique identifier for an Outlook calendar event associated with the checkInClaim object. For more information, see the iCalUId property in event.
  --checkInMethod: string@checkInMethod-completer
  --createdDateTime: string # The date and time when the checkInClaim object was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
]: any -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/rooms/($room_id)/checkIns/($checkInClaim_calendarEventId)")
  let body = {calendarEventId: $calendarEventId, checkInMethod: $checkInMethod, createdDateTime: $createdDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property checkIns for places
#
# DELETE /places/{place-id}/microsoft.graph.roomList/rooms/{room-id}/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsRoomList.room_DeleteCheckIn
export def "places-microsoftgraphroom-list-rooms-check-ins DeleteCheckIn" [
  place_id: string
  room_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/rooms/($room_id)/checkIns/($checkInClaim_calendarEventId)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/{place-id}/microsoft.graph.roomList/rooms/{room-id}/checkIns/$count
# operationId: placeAsRoomList.room.checkIn_GetCount
export def "places-microsoftgraphroom-list-rooms-check-ins-count GetCount" [
  place_id: string
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/rooms/($room_id)/checkIns/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/{place-id}/microsoft.graph.roomList/rooms/$count
# operationId: placeAsRoomList.room_GetCount
export def "places-microsoftgraphroom-list-rooms-count GetCount" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/rooms/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get workspaces from places
#
# GET /places/{place-id}/microsoft.graph.roomList/workspaces
# operationId: placeAsRoomList_ListWorkspace
export def "places-microsoftgraphroom-list-workspaces ListWorkspace" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/workspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to workspaces for places
#
# POST /places/{place-id}/microsoft.graph.roomList/workspaces
# operationId: placeAsRoomList_CreateWorkspace
export def "places-microsoftgraphroom-list-workspaces CreateWorkspace" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --capacity: float # The maximum number of individual desks within a workspace. (nullable, format: int32)
  --displayDeviceName: string # The name of the display device (for example, monitor or projector) that is available in the workspace. (nullable)
  --emailAddress: string # The email address that is associated with the workspace. This email address is used for booking. (nullable)
  --mode: record
  --nickname: string # A short, friendly name for the workspace, often used for easier identification or display in the UI.
  --placeId: string # An alternative immutable unique identifier of the workspace. Read-only. (nullable)
]: any -> record<capacity: float, displayDeviceName: string, emailAddress: string, mode: record, nickname: string, placeId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/workspaces")
  let body = {capacity: $capacity, displayDeviceName: $displayDeviceName, emailAddress: $emailAddress, mode: $mode, nickname: $nickname, placeId: $placeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get workspaces from places
#
# GET /places/{place-id}/microsoft.graph.roomList/workspaces/{workspace-id}
# operationId: placeAsRoomList_GetWorkspace
export def "places-microsoftgraphroom-list-workspaces GetWorkspace" [
  place_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<capacity: float, displayDeviceName: string, emailAddress: string, mode: record, nickname: string, placeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/workspaces/($workspace_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property workspaces in places
#
# PATCH /places/{place-id}/microsoft.graph.roomList/workspaces/{workspace-id}
# operationId: placeAsRoomList_UpdateWorkspace
export def "places-microsoftgraphroom-list-workspaces UpdateWorkspace" [
  place_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --capacity: float # The maximum number of individual desks within a workspace. (nullable, format: int32)
  --displayDeviceName: string # The name of the display device (for example, monitor or projector) that is available in the workspace. (nullable)
  --emailAddress: string # The email address that is associated with the workspace. This email address is used for booking. (nullable)
  --mode: record
  --nickname: string # A short, friendly name for the workspace, often used for easier identification or display in the UI.
  --placeId: string # An alternative immutable unique identifier of the workspace. Read-only. (nullable)
]: any -> record<capacity: float, displayDeviceName: string, emailAddress: string, mode: record, nickname: string, placeId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/workspaces/($workspace_id)")
  let body = {capacity: $capacity, displayDeviceName: $displayDeviceName, emailAddress: $emailAddress, mode: $mode, nickname: $nickname, placeId: $placeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property workspaces for places
#
# DELETE /places/{place-id}/microsoft.graph.roomList/workspaces/{workspace-id}
# operationId: placeAsRoomList_DeleteWorkspace
export def "places-microsoftgraphroom-list-workspaces DeleteWorkspace" [
  place_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/workspaces/($workspace_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get checkIns from places
#
# GET /places/{place-id}/microsoft.graph.roomList/workspaces/{workspace-id}/checkIns
# operationId: placeAsRoomList.workspace_ListCheckIn
export def "places-microsoftgraphroom-list-workspaces-check-ins ListCheckIn" [
  place_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/workspaces/($workspace_id)/checkIns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to checkIns for places
#
# POST /places/{place-id}/microsoft.graph.roomList/workspaces/{workspace-id}/checkIns
# operationId: placeAsRoomList.workspace_CreateCheckIn
export def "places-microsoftgraphroom-list-workspaces-check-ins CreateCheckIn" [
  place_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calendarEventId: string # The unique identifier for an Outlook calendar event associated with the checkInClaim object. For more information, see the iCalUId property in event.
  --checkInMethod: string@checkInMethod-completer
  --createdDateTime: string # The date and time when the checkInClaim object was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
]: any -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/workspaces/($workspace_id)/checkIns")
  let body = {calendarEventId: $calendarEventId, checkInMethod: $checkInMethod, createdDateTime: $createdDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get checkIns from places
#
# GET /places/{place-id}/microsoft.graph.roomList/workspaces/{workspace-id}/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsRoomList.workspace_GetCheckIn
export def "places-microsoftgraphroom-list-workspaces-check-ins GetCheckIn" [
  place_id: string
  workspace_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/workspaces/($workspace_id)/checkIns/($checkInClaim_calendarEventId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property checkIns in places
#
# PATCH /places/{place-id}/microsoft.graph.roomList/workspaces/{workspace-id}/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsRoomList.workspace_UpdateCheckIn
export def "places-microsoftgraphroom-list-workspaces-check-ins UpdateCheckIn" [
  place_id: string
  workspace_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calendarEventId: string # The unique identifier for an Outlook calendar event associated with the checkInClaim object. For more information, see the iCalUId property in event.
  --checkInMethod: string@checkInMethod-completer
  --createdDateTime: string # The date and time when the checkInClaim object was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
]: any -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/workspaces/($workspace_id)/checkIns/($checkInClaim_calendarEventId)")
  let body = {calendarEventId: $calendarEventId, checkInMethod: $checkInMethod, createdDateTime: $createdDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property checkIns for places
#
# DELETE /places/{place-id}/microsoft.graph.roomList/workspaces/{workspace-id}/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsRoomList.workspace_DeleteCheckIn
export def "places-microsoftgraphroom-list-workspaces-check-ins DeleteCheckIn" [
  place_id: string
  workspace_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/workspaces/($workspace_id)/checkIns/($checkInClaim_calendarEventId)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/{place-id}/microsoft.graph.roomList/workspaces/{workspace-id}/checkIns/$count
# operationId: placeAsRoomList.workspace.checkIn_GetCount
export def "places-microsoftgraphroom-list-workspaces-check-ins-count GetCount" [
  place_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/workspaces/($workspace_id)/checkIns/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/{place-id}/microsoft.graph.roomList/workspaces/$count
# operationId: placeAsRoomList.workspace_GetCount
export def "places-microsoftgraphroom-list-workspaces-count GetCount" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.roomList/workspaces/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List place objects
#
# GET /places/{place-id}/microsoft.graph.section
# Docs: https://learn.microsoft.com/graph/api/place-list?view=graph-rest-1.0 — Find more info here
# operationId: place_GetPlaceAsSection
export def "places-microsoftgraphsection GetPlaceAsSection" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.section" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get checkIns from places
#
# GET /places/{place-id}/microsoft.graph.section/checkIns
# operationId: placeAsSection_ListCheckIn
export def "places-microsoftgraphsection-check-ins ListCheckIn" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.section/checkIns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to checkIns for places
#
# POST /places/{place-id}/microsoft.graph.section/checkIns
# operationId: placeAsSection_CreateCheckIn
export def "places-microsoftgraphsection-check-ins CreateCheckIn" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calendarEventId: string # The unique identifier for an Outlook calendar event associated with the checkInClaim object. For more information, see the iCalUId property in event.
  --checkInMethod: string@checkInMethod-completer
  --createdDateTime: string # The date and time when the checkInClaim object was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
]: any -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.section/checkIns")
  let body = {calendarEventId: $calendarEventId, checkInMethod: $checkInMethod, createdDateTime: $createdDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get checkIns from places
#
# GET /places/{place-id}/microsoft.graph.section/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsSection_GetCheckIn
export def "places-microsoftgraphsection-check-ins GetCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.section/checkIns/($checkInClaim_calendarEventId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property checkIns in places
#
# PATCH /places/{place-id}/microsoft.graph.section/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsSection_UpdateCheckIn
export def "places-microsoftgraphsection-check-ins UpdateCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calendarEventId: string # The unique identifier for an Outlook calendar event associated with the checkInClaim object. For more information, see the iCalUId property in event.
  --checkInMethod: string@checkInMethod-completer
  --createdDateTime: string # The date and time when the checkInClaim object was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
]: any -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.section/checkIns/($checkInClaim_calendarEventId)")
  let body = {calendarEventId: $calendarEventId, checkInMethod: $checkInMethod, createdDateTime: $createdDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property checkIns for places
#
# DELETE /places/{place-id}/microsoft.graph.section/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsSection_DeleteCheckIn
export def "places-microsoftgraphsection-check-ins DeleteCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.section/checkIns/($checkInClaim_calendarEventId)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/{place-id}/microsoft.graph.section/checkIns/$count
# operationId: placeAsSection.checkIn_GetCount
export def "places-microsoftgraphsection-check-ins-count GetCount" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.section/checkIns/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List place objects
#
# GET /places/{place-id}/microsoft.graph.workspace
# Docs: https://learn.microsoft.com/graph/api/place-list?view=graph-rest-1.0 — Find more info here
# operationId: place_GetPlaceAsWorkspace
export def "places-microsoftgraphworkspace GetPlaceAsWorkspace" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<capacity: float, displayDeviceName: string, emailAddress: string, mode: record, nickname: string, placeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.workspace" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get checkIns from places
#
# GET /places/{place-id}/microsoft.graph.workspace/checkIns
# operationId: placeAsWorkspace_ListCheckIn
export def "places-microsoftgraphworkspace-check-ins ListCheckIn" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.workspace/checkIns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to checkIns for places
#
# POST /places/{place-id}/microsoft.graph.workspace/checkIns
# operationId: placeAsWorkspace_CreateCheckIn
export def "places-microsoftgraphworkspace-check-ins CreateCheckIn" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calendarEventId: string # The unique identifier for an Outlook calendar event associated with the checkInClaim object. For more information, see the iCalUId property in event.
  --checkInMethod: string@checkInMethod-completer
  --createdDateTime: string # The date and time when the checkInClaim object was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
]: any -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.workspace/checkIns")
  let body = {calendarEventId: $calendarEventId, checkInMethod: $checkInMethod, createdDateTime: $createdDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get checkIns from places
#
# GET /places/{place-id}/microsoft.graph.workspace/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsWorkspace_GetCheckIn
export def "places-microsoftgraphworkspace-check-ins GetCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.workspace/checkIns/($checkInClaim_calendarEventId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property checkIns in places
#
# PATCH /places/{place-id}/microsoft.graph.workspace/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsWorkspace_UpdateCheckIn
export def "places-microsoftgraphworkspace-check-ins UpdateCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calendarEventId: string # The unique identifier for an Outlook calendar event associated with the checkInClaim object. For more information, see the iCalUId property in event.
  --checkInMethod: string@checkInMethod-completer
  --createdDateTime: string # The date and time when the checkInClaim object was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
]: any -> record<calendarEventId: string, checkInMethod: string, createdDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.workspace/checkIns/($checkInClaim_calendarEventId)")
  let body = {calendarEventId: $calendarEventId, checkInMethod: $checkInMethod, createdDateTime: $createdDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property checkIns for places
#
# DELETE /places/{place-id}/microsoft.graph.workspace/checkIns/{checkInClaim-calendarEventId}
# operationId: placeAsWorkspace_DeleteCheckIn
export def "places-microsoftgraphworkspace-check-ins DeleteCheckIn" [
  place_id: string
  checkInClaim_calendarEventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.workspace/checkIns/($checkInClaim_calendarEventId)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/{place-id}/microsoft.graph.workspace/checkIns/$count
# operationId: placeAsWorkspace.checkIn_GetCount
export def "places-microsoftgraphworkspace-check-ins-count GetCount" [
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($place_id)/microsoft.graph.workspace/checkIns/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/$count
# operationId: place_GetCount
export def "places-count GetCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/places/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List place objects
#
# GET /places/microsoft.graph.building
# Docs: https://learn.microsoft.com/graph/api/place-list?view=graph-rest-1.0 — Find more info here
# operationId: place_ListPlaceAsBuilding
export def "places-microsoftgraphbuilding ListPlaceAsBuilding" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/places/microsoft.graph.building" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/microsoft.graph.building/$count
# operationId: place_GetCountAsBuilding
export def "places-microsoftgraphbuilding-count GetCountAsBuilding" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/places/microsoft.graph.building/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List place objects
#
# GET /places/microsoft.graph.desk
# Docs: https://learn.microsoft.com/graph/api/place-list?view=graph-rest-1.0 — Find more info here
# operationId: place_ListPlaceAsDesk
export def "places-microsoftgraphdesk ListPlaceAsDesk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/places/microsoft.graph.desk" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/microsoft.graph.desk/$count
# operationId: place_GetCountAsDesk
export def "places-microsoftgraphdesk-count GetCountAsDesk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/places/microsoft.graph.desk/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List place objects
#
# GET /places/microsoft.graph.floor
# Docs: https://learn.microsoft.com/graph/api/place-list?view=graph-rest-1.0 — Find more info here
# operationId: place_ListPlaceAsFloor
export def "places-microsoftgraphfloor ListPlaceAsFloor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/places/microsoft.graph.floor" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/microsoft.graph.floor/$count
# operationId: place_GetCountAsFloor
export def "places-microsoftgraphfloor-count GetCountAsFloor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/places/microsoft.graph.floor/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List place objects
#
# GET /places/microsoft.graph.room
# Docs: https://learn.microsoft.com/graph/api/place-list?view=graph-rest-1.0 — Find more info here
# operationId: place_ListPlaceAsRoom
export def "places-microsoftgraphroom ListPlaceAsRoom" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/places/microsoft.graph.room" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/microsoft.graph.room/$count
# operationId: place_GetCountAsRoom
export def "places-microsoftgraphroom-count GetCountAsRoom" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/places/microsoft.graph.room/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get place
#
# GET /places/microsoft.graph.roomList
# Docs: https://learn.microsoft.com/graph/api/place-get?view=graph-rest-1.0 — Find more info here
# operationId: place_ListPlaceAsRoomList
export def "places-microsoftgraphroom-list ListPlaceAsRoomList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/places/microsoft.graph.roomList" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/microsoft.graph.roomList/$count
# operationId: place_GetCountAsRoomList
export def "places-microsoftgraphroom-list-count GetCountAsRoomList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/places/microsoft.graph.roomList/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List place objects
#
# GET /places/microsoft.graph.section
# Docs: https://learn.microsoft.com/graph/api/place-list?view=graph-rest-1.0 — Find more info here
# operationId: place_ListPlaceAsSection
export def "places-microsoftgraphsection ListPlaceAsSection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/places/microsoft.graph.section" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/microsoft.graph.section/$count
# operationId: place_GetCountAsSection
export def "places-microsoftgraphsection-count GetCountAsSection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/places/microsoft.graph.section/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List place objects
#
# GET /places/microsoft.graph.workspace
# Docs: https://learn.microsoft.com/graph/api/place-list?view=graph-rest-1.0 — Find more info here
# operationId: place_ListPlaceAsWorkspace
export def "places-microsoftgraphworkspace ListPlaceAsWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/places/microsoft.graph.workspace" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /places/microsoft.graph.workspace/$count
# operationId: place_GetCountAsWorkspace
export def "places-microsoftgraphworkspace-count GetCountAsWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/places/microsoft.graph.workspace/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get calendar from users
#
# GET /users/{user-id}/calendar
# operationId: user_GetCalendar
export def "users-calendar GetCalendar" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: table<id: string, allowedRoles: list, emailAddress: record, isInsideOrganization: bool, isRemovable: bool, role: string>, calendarView: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, events: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property calendar in users
#
# PATCH /users/{user-id}/calendar
# operationId: user_UpdateCalendar
# --owner shape: {address?: string, name?: string}
# --calendarPermissions item shape: {id?: string, allowedRoles?: list, emailAddress?: record, isInsideOrganization?: bool, isRemovable?: bool, role?: "none"|"freeBusyRead"|"limitedRead"|"read"|"write"|"delegateWithoutPrivateEventAccess"|"delegateWithPrivateEventAccess"|"custom"}
# --calendarView item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --events item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --multiValueExtendedProperties item shape: {id?: string, value?: list}
# --singleValueExtendedProperties item shape: {id?: string, value?: string}
export def "users-calendar UpdateCalendar" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --allowedOnlineMeetingProviders: list # Represent the online meeting service providers that can be used to create online meetings in this calendar. The possible values are: unknown, skypeForBusiness, skypeForConsumer, teamsForBusiness.
  --canEdit: oneof<nothing, bool> # true if the user can write to the calendar, false otherwise. This property is true for the user who created the calendar. This property is also true for a user who shared a calendar and granted write access. (nullable)
  --canShare: oneof<nothing, bool> # true if the user has permission to share the calendar, false otherwise. Only the user who created the calendar can share it. (nullable)
  --canViewPrivateItems: oneof<nothing, bool> # If true, the user can read calendar items that have been marked private, false otherwise. (nullable)
  --changeKey: string # Identifies the version of the calendar object. Every time the calendar is changed, changeKey changes as well. This allows Exchange to apply changes to the correct version of the object. Read-only. (nullable)
  --color: string@color-completer
  --defaultOnlineMeetingProvider: string@defaultOnlineMeetingProvider-completer
  --hexColor: string # The calendar color, expressed in a hex color code of three hexadecimal values, each ranging from 00 to FF and representing the red, green, or blue components of the color in the RGB color space. If the user has never explicitly set a color for the calendar, this property is empty. Read-only. (nullable)
  --isDefaultCalendar: oneof<nothing, bool> # true if this is the default calendar where new events are created by default, false otherwise. (nullable)
  --isRemovable: oneof<nothing, bool> # Indicates whether this user calendar can be deleted from the user mailbox. (nullable)
  --isTallyingResponses: oneof<nothing, bool> # Indicates whether this user calendar supports tracking of meeting responses. Only meeting invites sent from users' primary calendars support tracking of meeting responses. (nullable)
  --name: string # The calendar name. (nullable)
  --owner: record # shape: {address?: string, name?: string}
  --calendarPermissions: list # The permissions of the users with whom the calendar is shared. — item shape: {id?: string, allowedRoles?: list, emailAddress?: record, isInsideOrganization?: bool, isRemovable?: bool, role?: "none"|"freeBusyRead"|"limitedRead"|"read"|"write"|"delegateWithoutPrivateEventAccess"|"delegateWithPrivateEventAccess"|"custom"}
  --calendarView: list # The calendar view for the calendar. Navigation property. Read-only. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --events: list # The events in the calendar. Navigation property. Read-only. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --multiValueExtendedProperties: list # The collection of multi-value extended properties defined for the calendar. Read-only. Nullable. — item shape: {id?: string, value?: list}
  --singleValueExtendedProperties: list # The collection of single-value extended properties defined for the calendar. Read-only. Nullable. — item shape: {id?: string, value?: string}
]: any -> record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: table<id: string, allowedRoles: list, emailAddress: record, isInsideOrganization: bool, isRemovable: bool, role: string>, calendarView: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, events: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendar")
  let body = {id: $id, allowedOnlineMeetingProviders: $allowedOnlineMeetingProviders, canEdit: $canEdit, canShare: $canShare, canViewPrivateItems: $canViewPrivateItems, changeKey: $changeKey, color: $color, defaultOnlineMeetingProvider: $defaultOnlineMeetingProvider, hexColor: $hexColor, isDefaultCalendar: $isDefaultCalendar, isRemovable: $isRemovable, isTallyingResponses: $isTallyingResponses, name: $name, owner: $owner, calendarPermissions: $calendarPermissions, calendarView: $calendarView, events: $events, multiValueExtendedProperties: $multiValueExtendedProperties, singleValueExtendedProperties: $singleValueExtendedProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List calendarPermissions
#
# GET /users/{user-id}/calendar/calendarPermissions
# Docs: https://learn.microsoft.com/graph/api/calendar-list-calendarpermissions?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar_ListCalendarPermission
export def "users-calendar-calendar-permissions ListCalendarPermission" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendar/calendarPermissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to calendarPermissions for users
#
# POST /users/{user-id}/calendar/calendarPermissions
# operationId: user.calendar_CreateCalendarPermission
# --emailAddress shape: {address?: string, name?: string}
export def "users-calendar-calendar-permissions CreateCalendarPermission" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --allowedRoles: list # List of allowed sharing or delegating permission levels for the calendar. The possible values are: none, freeBusyRead, limitedRead, read, write, delegateWithoutPrivateEventAccess, delegateWithPrivateEventAccess, custom.
  --emailAddress: record # shape: {address?: string, name?: string}
  --isInsideOrganization: oneof<nothing, bool> # True if the user in context (recipient or delegate) is inside the same organization as the calendar owner. (nullable)
  --isRemovable: oneof<nothing, bool> # True if the user can be removed from the list of recipients or delegates for the specified calendar, false otherwise. The 'My organization' user determines the permissions other people within your organization have to the given calendar. You can't remove 'My organization' as a share recipient to a calendar. (nullable)
  --role: string@role-completer
]: any -> record<id: string, allowedRoles: list<string>, emailAddress: record<address: string, name: string>, isInsideOrganization: bool, isRemovable: bool, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendar/calendarPermissions")
  let body = {id: $id, allowedRoles: $allowedRoles, emailAddress: $emailAddress, isInsideOrganization: $isInsideOrganization, isRemovable: $isRemovable, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get calendarPermission
#
# GET /users/{user-id}/calendar/calendarPermissions/{calendarPermission-id}
# Docs: https://learn.microsoft.com/graph/api/calendarpermission-get?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar_GetCalendarPermission
export def "users-calendar-calendar-permissions GetCalendarPermission" [
  user_id: string
  calendarPermission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, allowedRoles: list<string>, emailAddress: record<address: string, name: string>, isInsideOrganization: bool, isRemovable: bool, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendar/calendarPermissions/($calendarPermission_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update calendarPermission
#
# PATCH /users/{user-id}/calendar/calendarPermissions/{calendarPermission-id}
# Docs: https://learn.microsoft.com/graph/api/calendarpermission-update?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar_UpdateCalendarPermission
# --emailAddress shape: {address?: string, name?: string}
export def "users-calendar-calendar-permissions UpdateCalendarPermission" [
  user_id: string
  calendarPermission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --allowedRoles: list # List of allowed sharing or delegating permission levels for the calendar. The possible values are: none, freeBusyRead, limitedRead, read, write, delegateWithoutPrivateEventAccess, delegateWithPrivateEventAccess, custom.
  --emailAddress: record # shape: {address?: string, name?: string}
  --isInsideOrganization: oneof<nothing, bool> # True if the user in context (recipient or delegate) is inside the same organization as the calendar owner. (nullable)
  --isRemovable: oneof<nothing, bool> # True if the user can be removed from the list of recipients or delegates for the specified calendar, false otherwise. The 'My organization' user determines the permissions other people within your organization have to the given calendar. You can't remove 'My organization' as a share recipient to a calendar. (nullable)
  --role: string@role-completer
]: any -> record<id: string, allowedRoles: list<string>, emailAddress: record<address: string, name: string>, isInsideOrganization: bool, isRemovable: bool, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendar/calendarPermissions/($calendarPermission_id)")
  let body = {id: $id, allowedRoles: $allowedRoles, emailAddress: $emailAddress, isInsideOrganization: $isInsideOrganization, isRemovable: $isRemovable, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete calendarPermission
#
# DELETE /users/{user-id}/calendar/calendarPermissions/{calendarPermission-id}
# Docs: https://learn.microsoft.com/graph/api/calendarpermission-delete?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar_DeleteCalendarPermission
export def "users-calendar-calendar-permissions DeleteCalendarPermission" [
  user_id: string
  calendarPermission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendar/calendarPermissions/($calendarPermission_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /users/{user-id}/calendar/calendarPermissions/$count
# operationId: user.calendar.calendarPermission_GetCount
export def "users-calendar-calendar-permissions-count GetCount" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendar/calendarPermissions/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get calendarView from users
#
# GET /users/{user-id}/calendar/calendarView
# operationId: user.calendar_ListCalendarView
export def "users-calendar-calendar-view ListCalendarView" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T19:00:00-08:00
  --endDateTime: string # The end date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendar/calendarView" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function delta
#
# GET /users/{user-id}/calendar/calendarView/microsoft.graph.delta()
# Docs: https://learn.microsoft.com/graph/api/event-delta?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar.calendarView_delta
export def "users-calendar-calendar-view-microsoftgraphdelta delta" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --endDateTime: string # The end date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: record, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, _odata_nextLink: string, _odata_deltaLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendar/calendarView/microsoft.graph.delta()" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get events from users
#
# GET /users/{user-id}/calendar/events
# operationId: user.calendar_ListEvent
export def "users-calendar-events ListEvent" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendar/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to events for users
#
# POST /users/{user-id}/calendar/events
# operationId: user.calendar_CreateEvent
# --attendees item shape: {proposedNewTime?: record, status?: record}
# --body shape: {content?: string, contentType?: "text"|"html"}
# --end shape: {dateTime?: string, timeZone?: string}
# --location shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --locations item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --onlineMeeting shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
# --organizer shape: {emailAddress?: record}
# --recurrence shape: {pattern?: record, range?: record}
# --responseStatus shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
# --start shape: {dateTime?: string, timeZone?: string}
# --attachments item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
# --exceptionOccurrences item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --extensions item shape: {id?: string}
# --instances item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --multiValueExtendedProperties item shape: {id?: string, value?: list}
# --singleValueExtendedProperties item shape: {id?: string, value?: string}
export def "users-calendar-events CreateEvent" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowNewTimeProposals: oneof<nothing, bool> # true if the meeting organizer allows invitees to propose a new time when responding; otherwise, false. Optional. The default is true. (nullable)
  --attendees: list # The collection of attendees for the event. — item shape: {proposedNewTime?: record, status?: record}
  --body-body: record # shape: {content?: string, contentType?: "text"|"html"}
  --bodyPreview: string # The preview of the message associated with the event. It's in text format. (nullable)
  --cancelledOccurrences: list # Contains occurrenceId property values of canceled instances in a recurring series, if the event is the series master. Instances in a recurring series that are canceled are called canceled occurences.Requires $select to retrieve. Only returned in a Get operation that specifies the ID (seriesMasterId property value) of a series master event.
  --end: record # shape: {dateTime?: string, timeZone?: string}
  --hasAttachments: oneof<nothing, bool> # Set to true if the event has attachments. (nullable)
  --hideAttendees: oneof<nothing, bool> # When set to true, each attendee only sees themselves in the meeting request and meeting Tracking list. The default is false. (nullable)
  --iCalUId: string # A unique identifier for an event across calendars. This ID is different for each occurrence in a recurring series. Read-only. (nullable)
  --importance: string@importance-completer
  --isAllDay: oneof<nothing, bool> # Set to true if the event lasts all day. If true, regardless of whether it's a single-day or multi-day event, start, and endtime must be set to midnight and be in the same time zone. (nullable)
  --isCancelled: oneof<nothing, bool> # Set to true if the event has been canceled. (nullable)
  --isDraft: oneof<nothing, bool> # Set to true if the user has updated the meeting in Outlook but hasn't sent the updates to attendees. Set to false if all changes are sent, or if the event is an appointment without any attendees. (nullable)
  --isOnlineMeeting: oneof<nothing, bool> # True if this event has online meeting information (that is, onlineMeeting points to an onlineMeetingInfo resource), false otherwise. Default is false (onlineMeeting is null). Optional.  After you set isOnlineMeeting to true, Microsoft Graph initializes onlineMeeting. Subsequently, Outlook ignores any further changes to isOnlineMeeting, and the meeting remains available online. (nullable)
  --isOrganizer: oneof<nothing, bool> # Set to true if the calendar owner (specified by the owner property of the calendar) is the organizer of the event (specified by the organizer property of the event). It also applies if a delegate organized the event on behalf of the owner. (nullable)
  --isReminderOn: oneof<nothing, bool> # Set to true if an alert is set to remind the user of the event. (nullable)
  --location: record # shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --locations: list # The locations where the event is held or attended from. The location and locations properties always correspond with each other. If you update the location property, any prior locations in the locations collection are removed and replaced by the new location value. — item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --onlineMeeting: record # shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
  --onlineMeetingProvider: string@onlineMeetingProvider-completer
  --onlineMeetingUrl: string # A URL for an online meeting. The property is set only when an organizer specifies in Outlook that an event is an online meeting such as Skype. Read-only.To access the URL to join an online meeting, use joinUrl which is exposed via the onlineMeeting property of the event. The onlineMeetingUrl property will be deprecated in the future. (nullable)
  --organizer: record # shape: {emailAddress?: record}
  --originalEndTimeZone: string # The end time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --originalStart: string # Represents the start time of an event when it's initially created as an occurrence or exception in a recurring series. This property is not returned for events that are single instances. Its date and time information is expressed in ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --originalStartTimeZone: string # The start time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --recurrence: record # shape: {pattern?: record, range?: record}
  --reminderMinutesBeforeStart: float # The number of minutes before the event start time that the reminder alert occurs. (nullable, format: int32)
  --responseRequested: oneof<nothing, bool> # Default is true, which represents the organizer would like an invitee to send a response to the event. (nullable)
  --responseStatus: record # shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
  --sensitivity: string@sensitivity-completer
  --seriesMasterId: string # The ID for the recurring series master item, if this event is part of a recurring series. (nullable)
  --showAs: string@showAs-completer
  --start: record # shape: {dateTime?: string, timeZone?: string}
  --subject: string # The text of the event's subject line. (nullable)
  --transactionId: string # A custom identifier specified by a client app for the server to avoid redundant POST operations in case of client retries to create the same event. It's useful when low network connectivity causes the client to time out before receiving a response from the server for the client's prior create-event request. After you set transactionId when creating an event, you can't change transactionId in a subsequent update. This property is only returned in a response payload if an app has set it. Optional. (nullable)
  --type: string@type-completer
  --webLink: string # The URL to open the event in Outlook on the web.Outlook on the web opens the event in the browser if you are signed in to your mailbox. Otherwise, Outlook on the web prompts you to sign in.This URL can't be accessed from within an iFrame. (nullable)
  --attachments: list # The collection of FileAttachment, ItemAttachment, and referenceAttachment attachments for the event. Navigation property. Read-only. Nullable. — item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
  --calendar: any
  --exceptionOccurrences: list # Contains the id property values of the event instances that are exceptions in a recurring series.Exceptions can differ from other occurrences in a recurring series, such as the subject, start or end times, or attendees. Exceptions don't include canceled occurrences.Requires $select and $expand to retrieve. Only returned in a GET operation that specifies the ID (seriesMasterId property value) of a series master event. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --extensions: list # The collection of open extensions defined for the event. Nullable. — item shape: {id?: string}
  --instances: list # The occurrences of a recurring series, if the event is a series master. This property includes occurrences that are part of the recurrence pattern, and exceptions modified, but doesn't include occurrences canceled from the series. Navigation property. Read-only. Nullable. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --multiValueExtendedProperties: list # The collection of multi-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: list}
  --singleValueExtendedProperties: list # The collection of single-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: string}
]: any -> record<allowNewTimeProposals: bool, attendees: table<proposedNewTime: record, status: record>, body: record<content: string, contentType: string>, bodyPreview: string, cancelledOccurrences: list<string>, end: record<dateTime: string, timeZone: string>, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, locations: table<address: record, coordinates: record, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, onlineMeeting: record<conferenceId: string, joinUrl: string, phones: list<record>, quickDial: string, tollFreeNumbers: list<string>, tollNumber: string>, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record<emailAddress: record<address: string, name: string>>, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record<pattern: record<dayOfMonth: float, daysOfWeek: list, firstDayOfWeek: string, index: string, interval: float, month: float, type: string>, range: record<endDate: string, numberOfOccurrences: float, recurrenceTimeZone: string, startDate: string, type: string>>, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record<response: string, time: string>, sensitivity: string, seriesMasterId: string, showAs: string, start: record<dateTime: string, timeZone: string>, subject: string, transactionId: string, type: string, webLink: string, attachments: table<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float>, calendar: record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: list<record>, calendarView: list<any>, events: list<any>, multiValueExtendedProperties: list<record>, singleValueExtendedProperties: list<record>>, exceptionOccurrences: list<any>, extensions: table<id: string>, instances: list<any>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendar/events")
  let body = {allowNewTimeProposals: $allowNewTimeProposals, attendees: $attendees, body: $body_body, bodyPreview: $bodyPreview, cancelledOccurrences: $cancelledOccurrences, end: $end, hasAttachments: $hasAttachments, hideAttendees: $hideAttendees, iCalUId: $iCalUId, importance: $importance, isAllDay: $isAllDay, isCancelled: $isCancelled, isDraft: $isDraft, isOnlineMeeting: $isOnlineMeeting, isOrganizer: $isOrganizer, isReminderOn: $isReminderOn, location: $location, locations: $locations, onlineMeeting: $onlineMeeting, onlineMeetingProvider: $onlineMeetingProvider, onlineMeetingUrl: $onlineMeetingUrl, organizer: $organizer, originalEndTimeZone: $originalEndTimeZone, originalStart: $originalStart, originalStartTimeZone: $originalStartTimeZone, recurrence: $recurrence, reminderMinutesBeforeStart: $reminderMinutesBeforeStart, responseRequested: $responseRequested, responseStatus: $responseStatus, sensitivity: $sensitivity, seriesMasterId: $seriesMasterId, showAs: $showAs, start: $start, subject: $subject, transactionId: $transactionId, type: $type, webLink: $webLink, attachments: $attachments, calendar: $calendar, exceptionOccurrences: $exceptionOccurrences, extensions: $extensions, instances: $instances, multiValueExtendedProperties: $multiValueExtendedProperties, singleValueExtendedProperties: $singleValueExtendedProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get events from users
#
# GET /users/{user-id}/calendar/events/{event-id}
# operationId: user.calendar_GetEvent
export def "users-calendar-events GetEvent" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<allowNewTimeProposals: bool, attendees: table<proposedNewTime: record, status: record>, body: record<content: string, contentType: string>, bodyPreview: string, cancelledOccurrences: list<string>, end: record<dateTime: string, timeZone: string>, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, locations: table<address: record, coordinates: record, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, onlineMeeting: record<conferenceId: string, joinUrl: string, phones: list<record>, quickDial: string, tollFreeNumbers: list<string>, tollNumber: string>, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record<emailAddress: record<address: string, name: string>>, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record<pattern: record<dayOfMonth: float, daysOfWeek: list, firstDayOfWeek: string, index: string, interval: float, month: float, type: string>, range: record<endDate: string, numberOfOccurrences: float, recurrenceTimeZone: string, startDate: string, type: string>>, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record<response: string, time: string>, sensitivity: string, seriesMasterId: string, showAs: string, start: record<dateTime: string, timeZone: string>, subject: string, transactionId: string, type: string, webLink: string, attachments: table<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float>, calendar: record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: list<record>, calendarView: list<any>, events: list<any>, multiValueExtendedProperties: list<record>, singleValueExtendedProperties: list<record>>, exceptionOccurrences: list<any>, extensions: table<id: string>, instances: list<any>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property events in users
#
# PATCH /users/{user-id}/calendar/events/{event-id}
# operationId: user.calendar_UpdateEvent
# --attendees item shape: {proposedNewTime?: record, status?: record}
# --body shape: {content?: string, contentType?: "text"|"html"}
# --end shape: {dateTime?: string, timeZone?: string}
# --location shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --locations item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --onlineMeeting shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
# --organizer shape: {emailAddress?: record}
# --recurrence shape: {pattern?: record, range?: record}
# --responseStatus shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
# --start shape: {dateTime?: string, timeZone?: string}
# --attachments item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
# --exceptionOccurrences item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --extensions item shape: {id?: string}
# --instances item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --multiValueExtendedProperties item shape: {id?: string, value?: list}
# --singleValueExtendedProperties item shape: {id?: string, value?: string}
export def "users-calendar-events UpdateEvent" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowNewTimeProposals: oneof<nothing, bool> # true if the meeting organizer allows invitees to propose a new time when responding; otherwise, false. Optional. The default is true. (nullable)
  --attendees: list # The collection of attendees for the event. — item shape: {proposedNewTime?: record, status?: record}
  --body-body: record # shape: {content?: string, contentType?: "text"|"html"}
  --bodyPreview: string # The preview of the message associated with the event. It's in text format. (nullable)
  --cancelledOccurrences: list # Contains occurrenceId property values of canceled instances in a recurring series, if the event is the series master. Instances in a recurring series that are canceled are called canceled occurences.Requires $select to retrieve. Only returned in a Get operation that specifies the ID (seriesMasterId property value) of a series master event.
  --end: record # shape: {dateTime?: string, timeZone?: string}
  --hasAttachments: oneof<nothing, bool> # Set to true if the event has attachments. (nullable)
  --hideAttendees: oneof<nothing, bool> # When set to true, each attendee only sees themselves in the meeting request and meeting Tracking list. The default is false. (nullable)
  --iCalUId: string # A unique identifier for an event across calendars. This ID is different for each occurrence in a recurring series. Read-only. (nullable)
  --importance: string@importance-completer
  --isAllDay: oneof<nothing, bool> # Set to true if the event lasts all day. If true, regardless of whether it's a single-day or multi-day event, start, and endtime must be set to midnight and be in the same time zone. (nullable)
  --isCancelled: oneof<nothing, bool> # Set to true if the event has been canceled. (nullable)
  --isDraft: oneof<nothing, bool> # Set to true if the user has updated the meeting in Outlook but hasn't sent the updates to attendees. Set to false if all changes are sent, or if the event is an appointment without any attendees. (nullable)
  --isOnlineMeeting: oneof<nothing, bool> # True if this event has online meeting information (that is, onlineMeeting points to an onlineMeetingInfo resource), false otherwise. Default is false (onlineMeeting is null). Optional.  After you set isOnlineMeeting to true, Microsoft Graph initializes onlineMeeting. Subsequently, Outlook ignores any further changes to isOnlineMeeting, and the meeting remains available online. (nullable)
  --isOrganizer: oneof<nothing, bool> # Set to true if the calendar owner (specified by the owner property of the calendar) is the organizer of the event (specified by the organizer property of the event). It also applies if a delegate organized the event on behalf of the owner. (nullable)
  --isReminderOn: oneof<nothing, bool> # Set to true if an alert is set to remind the user of the event. (nullable)
  --location: record # shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --locations: list # The locations where the event is held or attended from. The location and locations properties always correspond with each other. If you update the location property, any prior locations in the locations collection are removed and replaced by the new location value. — item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --onlineMeeting: record # shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
  --onlineMeetingProvider: string@onlineMeetingProvider-completer
  --onlineMeetingUrl: string # A URL for an online meeting. The property is set only when an organizer specifies in Outlook that an event is an online meeting such as Skype. Read-only.To access the URL to join an online meeting, use joinUrl which is exposed via the onlineMeeting property of the event. The onlineMeetingUrl property will be deprecated in the future. (nullable)
  --organizer: record # shape: {emailAddress?: record}
  --originalEndTimeZone: string # The end time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --originalStart: string # Represents the start time of an event when it's initially created as an occurrence or exception in a recurring series. This property is not returned for events that are single instances. Its date and time information is expressed in ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --originalStartTimeZone: string # The start time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --recurrence: record # shape: {pattern?: record, range?: record}
  --reminderMinutesBeforeStart: float # The number of minutes before the event start time that the reminder alert occurs. (nullable, format: int32)
  --responseRequested: oneof<nothing, bool> # Default is true, which represents the organizer would like an invitee to send a response to the event. (nullable)
  --responseStatus: record # shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
  --sensitivity: string@sensitivity-completer
  --seriesMasterId: string # The ID for the recurring series master item, if this event is part of a recurring series. (nullable)
  --showAs: string@showAs-completer
  --start: record # shape: {dateTime?: string, timeZone?: string}
  --subject: string # The text of the event's subject line. (nullable)
  --transactionId: string # A custom identifier specified by a client app for the server to avoid redundant POST operations in case of client retries to create the same event. It's useful when low network connectivity causes the client to time out before receiving a response from the server for the client's prior create-event request. After you set transactionId when creating an event, you can't change transactionId in a subsequent update. This property is only returned in a response payload if an app has set it. Optional. (nullable)
  --type: string@type-completer
  --webLink: string # The URL to open the event in Outlook on the web.Outlook on the web opens the event in the browser if you are signed in to your mailbox. Otherwise, Outlook on the web prompts you to sign in.This URL can't be accessed from within an iFrame. (nullable)
  --attachments: list # The collection of FileAttachment, ItemAttachment, and referenceAttachment attachments for the event. Navigation property. Read-only. Nullable. — item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
  --calendar: any
  --exceptionOccurrences: list # Contains the id property values of the event instances that are exceptions in a recurring series.Exceptions can differ from other occurrences in a recurring series, such as the subject, start or end times, or attendees. Exceptions don't include canceled occurrences.Requires $select and $expand to retrieve. Only returned in a GET operation that specifies the ID (seriesMasterId property value) of a series master event. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --extensions: list # The collection of open extensions defined for the event. Nullable. — item shape: {id?: string}
  --instances: list # The occurrences of a recurring series, if the event is a series master. This property includes occurrences that are part of the recurrence pattern, and exceptions modified, but doesn't include occurrences canceled from the series. Navigation property. Read-only. Nullable. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --multiValueExtendedProperties: list # The collection of multi-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: list}
  --singleValueExtendedProperties: list # The collection of single-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: string}
]: any -> record<allowNewTimeProposals: bool, attendees: table<proposedNewTime: record, status: record>, body: record<content: string, contentType: string>, bodyPreview: string, cancelledOccurrences: list<string>, end: record<dateTime: string, timeZone: string>, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, locations: table<address: record, coordinates: record, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, onlineMeeting: record<conferenceId: string, joinUrl: string, phones: list<record>, quickDial: string, tollFreeNumbers: list<string>, tollNumber: string>, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record<emailAddress: record<address: string, name: string>>, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record<pattern: record<dayOfMonth: float, daysOfWeek: list, firstDayOfWeek: string, index: string, interval: float, month: float, type: string>, range: record<endDate: string, numberOfOccurrences: float, recurrenceTimeZone: string, startDate: string, type: string>>, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record<response: string, time: string>, sensitivity: string, seriesMasterId: string, showAs: string, start: record<dateTime: string, timeZone: string>, subject: string, transactionId: string, type: string, webLink: string, attachments: table<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float>, calendar: record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: list<record>, calendarView: list<any>, events: list<any>, multiValueExtendedProperties: list<record>, singleValueExtendedProperties: list<record>>, exceptionOccurrences: list<any>, extensions: table<id: string>, instances: list<any>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)")
  let body = {allowNewTimeProposals: $allowNewTimeProposals, attendees: $attendees, body: $body_body, bodyPreview: $bodyPreview, cancelledOccurrences: $cancelledOccurrences, end: $end, hasAttachments: $hasAttachments, hideAttendees: $hideAttendees, iCalUId: $iCalUId, importance: $importance, isAllDay: $isAllDay, isCancelled: $isCancelled, isDraft: $isDraft, isOnlineMeeting: $isOnlineMeeting, isOrganizer: $isOrganizer, isReminderOn: $isReminderOn, location: $location, locations: $locations, onlineMeeting: $onlineMeeting, onlineMeetingProvider: $onlineMeetingProvider, onlineMeetingUrl: $onlineMeetingUrl, organizer: $organizer, originalEndTimeZone: $originalEndTimeZone, originalStart: $originalStart, originalStartTimeZone: $originalStartTimeZone, recurrence: $recurrence, reminderMinutesBeforeStart: $reminderMinutesBeforeStart, responseRequested: $responseRequested, responseStatus: $responseStatus, sensitivity: $sensitivity, seriesMasterId: $seriesMasterId, showAs: $showAs, start: $start, subject: $subject, transactionId: $transactionId, type: $type, webLink: $webLink, attachments: $attachments, calendar: $calendar, exceptionOccurrences: $exceptionOccurrences, extensions: $extensions, instances: $instances, multiValueExtendedProperties: $multiValueExtendedProperties, singleValueExtendedProperties: $singleValueExtendedProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property events for users
#
# DELETE /users/{user-id}/calendar/events/{event-id}
# operationId: user.calendar_DeleteEvent
export def "users-calendar-events DeleteEvent" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get attachments from users
#
# GET /users/{user-id}/calendar/events/{event-id}/attachments
# operationId: user.calendar.event_ListAttachment
export def "users-calendar-events-attachments ListAttachment" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/attachments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to attachments for users
#
# POST /users/{user-id}/calendar/events/{event-id}/attachments
# operationId: user.calendar.event_CreateAttachment
export def "users-calendar-events-attachments CreateAttachment" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --contentType: string # The MIME type. (nullable)
  --isInline: oneof<nothing, bool> # true if the attachment is an inline attachment; otherwise, false.
  --lastModifiedDateTime: string # The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --name: string # The attachment's file name. (nullable)
  --size: float # The length of the attachment in bytes. (format: int32)
]: any -> record<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/attachments")
  let body = {id: $id, contentType: $contentType, isInline: $isInline, lastModifiedDateTime: $lastModifiedDateTime, name: $name, size: $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get attachments from users
#
# GET /users/{user-id}/calendar/events/{event-id}/attachments/{attachment-id}
# operationId: user.calendar.event_GetAttachment
export def "users-calendar-events-attachments GetAttachment" [
  user_id: string
  event_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/attachments/($attachment_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete navigation property attachments for users
#
# DELETE /users/{user-id}/calendar/events/{event-id}/attachments/{attachment-id}
# operationId: user.calendar.event_DeleteAttachment
export def "users-calendar-events-attachments DeleteAttachment" [
  user_id: string
  event_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/attachments/($attachment_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /users/{user-id}/calendar/events/{event-id}/attachments/$count
# operationId: user.calendar.event.attachment_GetCount
export def "users-calendar-events-attachments-count GetCount" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/attachments/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action createUploadSession
#
# POST /users/{user-id}/calendar/events/{event-id}/attachments/microsoft.graph.createUploadSession
# Docs: https://learn.microsoft.com/graph/api/attachment-createuploadsession?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar.event.attachment_createUploadSession
# --AttachmentItem shape: {attachmentType?: "file"|"item"|"reference", contentId?: string, contentType?: string, isInline?: bool, name?: string, size?: float}
export def "users-calendar-events-attachments-microsoftgraphcreate-upload-session createUploadSession" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AttachmentItem: record # shape: {attachmentType?: "file"|"item"|"reference", contentId?: string, contentType?: string, isInline?: bool, name?: string, size?: float}
]: any -> record<expirationDateTime: string, nextExpectedRanges: list<string>, uploadUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/attachments/microsoft.graph.createUploadSession")
  let body = {AttachmentItem: $AttachmentItem} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get calendar from users
#
# GET /users/{user-id}/calendar/events/{event-id}/calendar
# operationId: user.calendar.event_GetCalendar
export def "users-calendar-events-calendar GetCalendar" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: table<id: string, allowedRoles: list, emailAddress: record, isInsideOrganization: bool, isRemovable: bool, role: string>, calendarView: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, events: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/calendar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get extensions from users
#
# GET /users/{user-id}/calendar/events/{event-id}/extensions
# operationId: user.calendar.event_ListExtension
export def "users-calendar-events-extensions ListExtension" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/extensions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to extensions for users
#
# POST /users/{user-id}/calendar/events/{event-id}/extensions
# operationId: user.calendar.event_CreateExtension
export def "users-calendar-events-extensions CreateExtension" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/extensions")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get extensions from users
#
# GET /users/{user-id}/calendar/events/{event-id}/extensions/{extension-id}
# operationId: user.calendar.event_GetExtension
export def "users-calendar-events-extensions GetExtension" [
  user_id: string
  event_id: string
  extension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/extensions/($extension_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property extensions in users
#
# PATCH /users/{user-id}/calendar/events/{event-id}/extensions/{extension-id}
# operationId: user.calendar.event_UpdateExtension
export def "users-calendar-events-extensions UpdateExtension" [
  user_id: string
  event_id: string
  extension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/extensions/($extension_id)")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property extensions for users
#
# DELETE /users/{user-id}/calendar/events/{event-id}/extensions/{extension-id}
# operationId: user.calendar.event_DeleteExtension
export def "users-calendar-events-extensions DeleteExtension" [
  user_id: string
  event_id: string
  extension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/extensions/($extension_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /users/{user-id}/calendar/events/{event-id}/extensions/$count
# operationId: user.calendar.event.extension_GetCount
export def "users-calendar-events-extensions-count GetCount" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/extensions/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get instances from users
#
# GET /users/{user-id}/calendar/events/{event-id}/instances
# operationId: user.calendar.event_ListInstance
export def "users-calendar-events-instances ListInstance" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T19:00:00-08:00
  --endDateTime: string # The end date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/instances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function delta
#
# GET /users/{user-id}/calendar/events/{event-id}/instances/microsoft.graph.delta()
# Docs: https://learn.microsoft.com/graph/api/event-delta?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar.event.instance_delta
export def "users-calendar-events-instances-microsoftgraphdelta delta" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --endDateTime: string # The end date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: record, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, _odata_nextLink: string, _odata_deltaLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/instances/microsoft.graph.delta()" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action accept
#
# POST /users/{user-id}/calendar/events/{event-id}/microsoft.graph.accept
# Docs: https://learn.microsoft.com/graph/api/event-accept?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar.event_accept
export def "users-calendar-events-microsoftgraphaccept accept" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --SendResponse: oneof<nothing, bool> # nullable, default: false
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/microsoft.graph.accept")
  let body = {SendResponse: $SendResponse, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action cancel
#
# POST /users/{user-id}/calendar/events/{event-id}/microsoft.graph.cancel
# Docs: https://learn.microsoft.com/graph/api/event-cancel?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar.event_cancel
export def "users-calendar-events-microsoftgraphcancel cancel" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/microsoft.graph.cancel")
  let body = {Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action decline
#
# POST /users/{user-id}/calendar/events/{event-id}/microsoft.graph.decline
# Docs: https://learn.microsoft.com/graph/api/event-decline?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar.event_decline
# --ProposedNewTime shape: {end?: record, start?: record}
export def "users-calendar-events-microsoftgraphdecline decline" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ProposedNewTime: record # shape: {end?: record, start?: record}
  --SendResponse: oneof<nothing, bool> # nullable, default: false
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/microsoft.graph.decline")
  let body = {ProposedNewTime: $ProposedNewTime, SendResponse: $SendResponse, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action dismissReminder
#
# POST /users/{user-id}/calendar/events/{event-id}/microsoft.graph.dismissReminder
# Docs: https://learn.microsoft.com/graph/api/event-dismissreminder?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar.event_dismissReminder
export def "users-calendar-events-microsoftgraphdismiss-reminder dismissReminder" [
  user_id: string
  event_id: string
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
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/microsoft.graph.dismissReminder")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action forward
#
# POST /users/{user-id}/calendar/events/{event-id}/microsoft.graph.forward
# Docs: https://learn.microsoft.com/graph/api/event-forward?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar.event_forward
# --ToRecipients item shape: {emailAddress?: record}
export def "users-calendar-events-microsoftgraphforward forward" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ToRecipients: list # item shape: {emailAddress?: record}
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/microsoft.graph.forward")
  let body = {ToRecipients: $ToRecipients, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action permanentDelete
#
# POST /users/{user-id}/calendar/events/{event-id}/microsoft.graph.permanentDelete
# operationId: user.calendar.event_permanentDelete
export def "users-calendar-events-microsoftgraphpermanent-delete permanentDelete" [
  user_id: string
  event_id: string
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
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/microsoft.graph.permanentDelete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action snoozeReminder
#
# POST /users/{user-id}/calendar/events/{event-id}/microsoft.graph.snoozeReminder
# Docs: https://learn.microsoft.com/graph/api/event-snoozereminder?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar.event_snoozeReminder
# --NewReminderTime shape: {dateTime?: string, timeZone?: string}
export def "users-calendar-events-microsoftgraphsnooze-reminder snoozeReminder" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --NewReminderTime: record # shape: {dateTime?: string, timeZone?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/microsoft.graph.snoozeReminder")
  let body = {NewReminderTime: $NewReminderTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action tentativelyAccept
#
# POST /users/{user-id}/calendar/events/{event-id}/microsoft.graph.tentativelyAccept
# Docs: https://learn.microsoft.com/graph/api/event-tentativelyaccept?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar.event_tentativelyAccept
# --ProposedNewTime shape: {end?: record, start?: record}
export def "users-calendar-events-microsoftgraphtentatively-accept tentativelyAccept" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ProposedNewTime: record # shape: {end?: record, start?: record}
  --SendResponse: oneof<nothing, bool> # nullable, default: false
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/($event_id)/microsoft.graph.tentativelyAccept")
  let body = {ProposedNewTime: $ProposedNewTime, SendResponse: $SendResponse, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the number of the resource
#
# GET /users/{user-id}/calendar/events/$count
# operationId: user.calendar.event_GetCount
export def "users-calendar-events-count GetCount" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function delta
#
# GET /users/{user-id}/calendar/events/microsoft.graph.delta()
# Docs: https://learn.microsoft.com/graph/api/event-delta?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar.event_delta
export def "users-calendar-events-microsoftgraphdelta delta" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --endDateTime: string # The end date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: record, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, _odata_nextLink: string, _odata_deltaLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendar/events/microsoft.graph.delta()" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function allowedCalendarSharingRoles
#
# GET /users/{user-id}/calendar/microsoft.graph.allowedCalendarSharingRoles(User='{User}')
# operationId: user.calendar_allowedCalendarSharingRole
export def "users-calendar-microsoftgraphallowed-calendar-sharing-roles-user-user allowedCalendarSharingRole" [
  user_id: string
  User: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
]: nothing -> record<value: list<string>, _odata_nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendar/microsoft.graph.allowedCalendarSharingRoles(User='($User)')" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action getSchedule
#
# POST /users/{user-id}/calendar/microsoft.graph.getSchedule
# Docs: https://learn.microsoft.com/graph/api/calendar-getschedule?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar_getSchedule
# --EndTime shape: {dateTime?: string, timeZone?: string}
# --StartTime shape: {dateTime?: string, timeZone?: string}
export def "users-calendar-microsoftgraphget-schedule post" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Schedules: list
  --EndTime: record # shape: {dateTime?: string, timeZone?: string}
  --StartTime: record # shape: {dateTime?: string, timeZone?: string}
  --AvailabilityViewInterval: float # nullable, format: int32
]: any -> record<value: table<availabilityView: string, error: record, scheduleId: string, scheduleItems: list, workingHours: record>, _odata_nextLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendar/microsoft.graph.getSchedule")
  let body = {Schedules: $Schedules, EndTime: $EndTime, StartTime: $StartTime, AvailabilityViewInterval: $AvailabilityViewInterval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action permanentDelete
#
# POST /users/{user-id}/calendar/microsoft.graph.permanentDelete
# operationId: user.calendar_permanentDelete
export def "users-calendar-microsoftgraphpermanent-delete permanentDelete" [
  user_id: string
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
  let full_url = (build-url $base $"/users/($user_id)/calendar/microsoft.graph.permanentDelete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get calendarGroups from users
#
# GET /users/{user-id}/calendarGroups
# operationId: user_ListCalendarGroup
export def "users-calendar-groups ListCalendarGroup" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to calendarGroups for users
#
# POST /users/{user-id}/calendarGroups
# operationId: user_CreateCalendarGroup
# --calendars item shape: {id?: string, allowedOnlineMeetingProviders?: list, canEdit?: bool, canShare?: bool, canViewPrivateItems?: bool, changeKey?: string, color?: "auto"|"lightBlue"|"lightGreen"|"lightOrange"|"lightGray"|"lightYellow"|"lightTeal"|"lightPink"|"lightBrown"|"lightRed"|"maxColor", defaultOnlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", hexColor?: string, isDefaultCalendar?: bool, isRemovable?: bool, isTallyingResponses?: bool, name?: string, owner?: record, calendarPermissions?: list, calendarView?: list, events?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
export def "users-calendar-groups CreateCalendarGroup" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --changeKey: string # Identifies the version of the calendar group. Every time the calendar group is changed, ChangeKey changes as well. This allows Exchange to apply changes to the correct version of the object. Read-only. (nullable)
  --classId: string # The class identifier. Read-only. (nullable, format: uuid)
  --name: string # The group name. (nullable)
  --calendars: list # The calendars in the calendar group. Navigation property. Read-only. Nullable. — item shape: {id?: string, allowedOnlineMeetingProviders?: list, canEdit?: bool, canShare?: bool, canViewPrivateItems?: bool, changeKey?: string, color?: "auto"|"lightBlue"|"lightGreen"|"lightOrange"|"lightGray"|"lightYellow"|"lightTeal"|"lightPink"|"lightBrown"|"lightRed"|"maxColor", defaultOnlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", hexColor?: string, isDefaultCalendar?: bool, isRemovable?: bool, isTallyingResponses?: bool, name?: string, owner?: record, calendarPermissions?: list, calendarView?: list, events?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
]: any -> record<id: string, changeKey: string, classId: string, name: string, calendars: table<id: string, allowedOnlineMeetingProviders: list, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record, calendarPermissions: list, calendarView: list, events: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups")
  let body = {id: $id, changeKey: $changeKey, classId: $classId, name: $name, calendars: $calendars} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get calendarGroups from users
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}
# operationId: user_GetCalendarGroup
export def "users-calendar-groups GetCalendarGroup" [
  user_id: string
  calendarGroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, changeKey: string, classId: string, name: string, calendars: table<id: string, allowedOnlineMeetingProviders: list, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record, calendarPermissions: list, calendarView: list, events: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property calendarGroups in users
#
# PATCH /users/{user-id}/calendarGroups/{calendarGroup-id}
# operationId: user_UpdateCalendarGroup
# --calendars item shape: {id?: string, allowedOnlineMeetingProviders?: list, canEdit?: bool, canShare?: bool, canViewPrivateItems?: bool, changeKey?: string, color?: "auto"|"lightBlue"|"lightGreen"|"lightOrange"|"lightGray"|"lightYellow"|"lightTeal"|"lightPink"|"lightBrown"|"lightRed"|"maxColor", defaultOnlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", hexColor?: string, isDefaultCalendar?: bool, isRemovable?: bool, isTallyingResponses?: bool, name?: string, owner?: record, calendarPermissions?: list, calendarView?: list, events?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
export def "users-calendar-groups UpdateCalendarGroup" [
  user_id: string
  calendarGroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --changeKey: string # Identifies the version of the calendar group. Every time the calendar group is changed, ChangeKey changes as well. This allows Exchange to apply changes to the correct version of the object. Read-only. (nullable)
  --classId: string # The class identifier. Read-only. (nullable, format: uuid)
  --name: string # The group name. (nullable)
  --calendars: list # The calendars in the calendar group. Navigation property. Read-only. Nullable. — item shape: {id?: string, allowedOnlineMeetingProviders?: list, canEdit?: bool, canShare?: bool, canViewPrivateItems?: bool, changeKey?: string, color?: "auto"|"lightBlue"|"lightGreen"|"lightOrange"|"lightGray"|"lightYellow"|"lightTeal"|"lightPink"|"lightBrown"|"lightRed"|"maxColor", defaultOnlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", hexColor?: string, isDefaultCalendar?: bool, isRemovable?: bool, isTallyingResponses?: bool, name?: string, owner?: record, calendarPermissions?: list, calendarView?: list, events?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
]: any -> record<id: string, changeKey: string, classId: string, name: string, calendars: table<id: string, allowedOnlineMeetingProviders: list, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record, calendarPermissions: list, calendarView: list, events: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)")
  let body = {id: $id, changeKey: $changeKey, classId: $classId, name: $name, calendars: $calendars} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property calendarGroups for users
#
# DELETE /users/{user-id}/calendarGroups/{calendarGroup-id}
# operationId: user_DeleteCalendarGroup
export def "users-calendar-groups DeleteCalendarGroup" [
  user_id: string
  calendarGroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get calendars from users
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars
# operationId: user.calendarGroup_ListCalendar
export def "users-calendar-groups-calendars ListCalendar" [
  user_id: string
  calendarGroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to calendars for users
#
# POST /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars
# operationId: user.calendarGroup_CreateCalendar
# --owner shape: {address?: string, name?: string}
# --calendarPermissions item shape: {id?: string, allowedRoles?: list, emailAddress?: record, isInsideOrganization?: bool, isRemovable?: bool, role?: "none"|"freeBusyRead"|"limitedRead"|"read"|"write"|"delegateWithoutPrivateEventAccess"|"delegateWithPrivateEventAccess"|"custom"}
# --calendarView item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --events item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --multiValueExtendedProperties item shape: {id?: string, value?: list}
# --singleValueExtendedProperties item shape: {id?: string, value?: string}
export def "users-calendar-groups-calendars CreateCalendar" [
  user_id: string
  calendarGroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --allowedOnlineMeetingProviders: list # Represent the online meeting service providers that can be used to create online meetings in this calendar. The possible values are: unknown, skypeForBusiness, skypeForConsumer, teamsForBusiness.
  --canEdit: oneof<nothing, bool> # true if the user can write to the calendar, false otherwise. This property is true for the user who created the calendar. This property is also true for a user who shared a calendar and granted write access. (nullable)
  --canShare: oneof<nothing, bool> # true if the user has permission to share the calendar, false otherwise. Only the user who created the calendar can share it. (nullable)
  --canViewPrivateItems: oneof<nothing, bool> # If true, the user can read calendar items that have been marked private, false otherwise. (nullable)
  --changeKey: string # Identifies the version of the calendar object. Every time the calendar is changed, changeKey changes as well. This allows Exchange to apply changes to the correct version of the object. Read-only. (nullable)
  --color: string@color-completer
  --defaultOnlineMeetingProvider: string@defaultOnlineMeetingProvider-completer
  --hexColor: string # The calendar color, expressed in a hex color code of three hexadecimal values, each ranging from 00 to FF and representing the red, green, or blue components of the color in the RGB color space. If the user has never explicitly set a color for the calendar, this property is empty. Read-only. (nullable)
  --isDefaultCalendar: oneof<nothing, bool> # true if this is the default calendar where new events are created by default, false otherwise. (nullable)
  --isRemovable: oneof<nothing, bool> # Indicates whether this user calendar can be deleted from the user mailbox. (nullable)
  --isTallyingResponses: oneof<nothing, bool> # Indicates whether this user calendar supports tracking of meeting responses. Only meeting invites sent from users' primary calendars support tracking of meeting responses. (nullable)
  --name: string # The calendar name. (nullable)
  --owner: record # shape: {address?: string, name?: string}
  --calendarPermissions: list # The permissions of the users with whom the calendar is shared. — item shape: {id?: string, allowedRoles?: list, emailAddress?: record, isInsideOrganization?: bool, isRemovable?: bool, role?: "none"|"freeBusyRead"|"limitedRead"|"read"|"write"|"delegateWithoutPrivateEventAccess"|"delegateWithPrivateEventAccess"|"custom"}
  --calendarView: list # The calendar view for the calendar. Navigation property. Read-only. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --events: list # The events in the calendar. Navigation property. Read-only. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --multiValueExtendedProperties: list # The collection of multi-value extended properties defined for the calendar. Read-only. Nullable. — item shape: {id?: string, value?: list}
  --singleValueExtendedProperties: list # The collection of single-value extended properties defined for the calendar. Read-only. Nullable. — item shape: {id?: string, value?: string}
]: any -> record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: table<id: string, allowedRoles: list, emailAddress: record, isInsideOrganization: bool, isRemovable: bool, role: string>, calendarView: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, events: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars")
  let body = {id: $id, allowedOnlineMeetingProviders: $allowedOnlineMeetingProviders, canEdit: $canEdit, canShare: $canShare, canViewPrivateItems: $canViewPrivateItems, changeKey: $changeKey, color: $color, defaultOnlineMeetingProvider: $defaultOnlineMeetingProvider, hexColor: $hexColor, isDefaultCalendar: $isDefaultCalendar, isRemovable: $isRemovable, isTallyingResponses: $isTallyingResponses, name: $name, owner: $owner, calendarPermissions: $calendarPermissions, calendarView: $calendarView, events: $events, multiValueExtendedProperties: $multiValueExtendedProperties, singleValueExtendedProperties: $singleValueExtendedProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get calendars from users
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}
# operationId: user.calendarGroup_GetCalendar
export def "users-calendar-groups-calendars GetCalendar" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: table<id: string, allowedRoles: list, emailAddress: record, isInsideOrganization: bool, isRemovable: bool, role: string>, calendarView: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, events: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property calendars in users
#
# PATCH /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}
# operationId: user.calendarGroup_UpdateCalendar
# --owner shape: {address?: string, name?: string}
# --calendarPermissions item shape: {id?: string, allowedRoles?: list, emailAddress?: record, isInsideOrganization?: bool, isRemovable?: bool, role?: "none"|"freeBusyRead"|"limitedRead"|"read"|"write"|"delegateWithoutPrivateEventAccess"|"delegateWithPrivateEventAccess"|"custom"}
# --calendarView item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --events item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --multiValueExtendedProperties item shape: {id?: string, value?: list}
# --singleValueExtendedProperties item shape: {id?: string, value?: string}
export def "users-calendar-groups-calendars UpdateCalendar" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --allowedOnlineMeetingProviders: list # Represent the online meeting service providers that can be used to create online meetings in this calendar. The possible values are: unknown, skypeForBusiness, skypeForConsumer, teamsForBusiness.
  --canEdit: oneof<nothing, bool> # true if the user can write to the calendar, false otherwise. This property is true for the user who created the calendar. This property is also true for a user who shared a calendar and granted write access. (nullable)
  --canShare: oneof<nothing, bool> # true if the user has permission to share the calendar, false otherwise. Only the user who created the calendar can share it. (nullable)
  --canViewPrivateItems: oneof<nothing, bool> # If true, the user can read calendar items that have been marked private, false otherwise. (nullable)
  --changeKey: string # Identifies the version of the calendar object. Every time the calendar is changed, changeKey changes as well. This allows Exchange to apply changes to the correct version of the object. Read-only. (nullable)
  --color: string@color-completer
  --defaultOnlineMeetingProvider: string@defaultOnlineMeetingProvider-completer
  --hexColor: string # The calendar color, expressed in a hex color code of three hexadecimal values, each ranging from 00 to FF and representing the red, green, or blue components of the color in the RGB color space. If the user has never explicitly set a color for the calendar, this property is empty. Read-only. (nullable)
  --isDefaultCalendar: oneof<nothing, bool> # true if this is the default calendar where new events are created by default, false otherwise. (nullable)
  --isRemovable: oneof<nothing, bool> # Indicates whether this user calendar can be deleted from the user mailbox. (nullable)
  --isTallyingResponses: oneof<nothing, bool> # Indicates whether this user calendar supports tracking of meeting responses. Only meeting invites sent from users' primary calendars support tracking of meeting responses. (nullable)
  --name: string # The calendar name. (nullable)
  --owner: record # shape: {address?: string, name?: string}
  --calendarPermissions: list # The permissions of the users with whom the calendar is shared. — item shape: {id?: string, allowedRoles?: list, emailAddress?: record, isInsideOrganization?: bool, isRemovable?: bool, role?: "none"|"freeBusyRead"|"limitedRead"|"read"|"write"|"delegateWithoutPrivateEventAccess"|"delegateWithPrivateEventAccess"|"custom"}
  --calendarView: list # The calendar view for the calendar. Navigation property. Read-only. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --events: list # The events in the calendar. Navigation property. Read-only. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --multiValueExtendedProperties: list # The collection of multi-value extended properties defined for the calendar. Read-only. Nullable. — item shape: {id?: string, value?: list}
  --singleValueExtendedProperties: list # The collection of single-value extended properties defined for the calendar. Read-only. Nullable. — item shape: {id?: string, value?: string}
]: any -> record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: table<id: string, allowedRoles: list, emailAddress: record, isInsideOrganization: bool, isRemovable: bool, role: string>, calendarView: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, events: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)")
  let body = {id: $id, allowedOnlineMeetingProviders: $allowedOnlineMeetingProviders, canEdit: $canEdit, canShare: $canShare, canViewPrivateItems: $canViewPrivateItems, changeKey: $changeKey, color: $color, defaultOnlineMeetingProvider: $defaultOnlineMeetingProvider, hexColor: $hexColor, isDefaultCalendar: $isDefaultCalendar, isRemovable: $isRemovable, isTallyingResponses: $isTallyingResponses, name: $name, owner: $owner, calendarPermissions: $calendarPermissions, calendarView: $calendarView, events: $events, multiValueExtendedProperties: $multiValueExtendedProperties, singleValueExtendedProperties: $singleValueExtendedProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property calendars for users
#
# DELETE /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}
# operationId: user.calendarGroup_DeleteCalendar
export def "users-calendar-groups-calendars DeleteCalendar" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get calendarPermissions from users
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/calendarPermissions
# operationId: user.calendarGroup.calendar_ListCalendarPermission
export def "users-calendar-groups-calendars-calendar-permissions ListCalendarPermission" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/calendarPermissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to calendarPermissions for users
#
# POST /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/calendarPermissions
# operationId: user.calendarGroup.calendar_CreateCalendarPermission
# --emailAddress shape: {address?: string, name?: string}
export def "users-calendar-groups-calendars-calendar-permissions CreateCalendarPermission" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --allowedRoles: list # List of allowed sharing or delegating permission levels for the calendar. The possible values are: none, freeBusyRead, limitedRead, read, write, delegateWithoutPrivateEventAccess, delegateWithPrivateEventAccess, custom.
  --emailAddress: record # shape: {address?: string, name?: string}
  --isInsideOrganization: oneof<nothing, bool> # True if the user in context (recipient or delegate) is inside the same organization as the calendar owner. (nullable)
  --isRemovable: oneof<nothing, bool> # True if the user can be removed from the list of recipients or delegates for the specified calendar, false otherwise. The 'My organization' user determines the permissions other people within your organization have to the given calendar. You can't remove 'My organization' as a share recipient to a calendar. (nullable)
  --role: string@role-completer
]: any -> record<id: string, allowedRoles: list<string>, emailAddress: record<address: string, name: string>, isInsideOrganization: bool, isRemovable: bool, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/calendarPermissions")
  let body = {id: $id, allowedRoles: $allowedRoles, emailAddress: $emailAddress, isInsideOrganization: $isInsideOrganization, isRemovable: $isRemovable, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get calendarPermissions from users
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/calendarPermissions/{calendarPermission-id}
# operationId: user.calendarGroup.calendar_GetCalendarPermission
export def "users-calendar-groups-calendars-calendar-permissions GetCalendarPermission" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  calendarPermission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, allowedRoles: list<string>, emailAddress: record<address: string, name: string>, isInsideOrganization: bool, isRemovable: bool, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/calendarPermissions/($calendarPermission_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property calendarPermissions in users
#
# PATCH /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/calendarPermissions/{calendarPermission-id}
# operationId: user.calendarGroup.calendar_UpdateCalendarPermission
# --emailAddress shape: {address?: string, name?: string}
export def "users-calendar-groups-calendars-calendar-permissions UpdateCalendarPermission" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  calendarPermission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --allowedRoles: list # List of allowed sharing or delegating permission levels for the calendar. The possible values are: none, freeBusyRead, limitedRead, read, write, delegateWithoutPrivateEventAccess, delegateWithPrivateEventAccess, custom.
  --emailAddress: record # shape: {address?: string, name?: string}
  --isInsideOrganization: oneof<nothing, bool> # True if the user in context (recipient or delegate) is inside the same organization as the calendar owner. (nullable)
  --isRemovable: oneof<nothing, bool> # True if the user can be removed from the list of recipients or delegates for the specified calendar, false otherwise. The 'My organization' user determines the permissions other people within your organization have to the given calendar. You can't remove 'My organization' as a share recipient to a calendar. (nullable)
  --role: string@role-completer
]: any -> record<id: string, allowedRoles: list<string>, emailAddress: record<address: string, name: string>, isInsideOrganization: bool, isRemovable: bool, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/calendarPermissions/($calendarPermission_id)")
  let body = {id: $id, allowedRoles: $allowedRoles, emailAddress: $emailAddress, isInsideOrganization: $isInsideOrganization, isRemovable: $isRemovable, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property calendarPermissions for users
#
# DELETE /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/calendarPermissions/{calendarPermission-id}
# operationId: user.calendarGroup.calendar_DeleteCalendarPermission
export def "users-calendar-groups-calendars-calendar-permissions DeleteCalendarPermission" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  calendarPermission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/calendarPermissions/($calendarPermission_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/calendarPermissions/$count
# operationId: user.calendarGroup.calendar.calendarPermission_GetCount
export def "users-calendar-groups-calendars-calendar-permissions-count GetCount" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/calendarPermissions/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get calendarView from users
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/calendarView
# operationId: user.calendarGroup.calendar_ListCalendarView
export def "users-calendar-groups-calendars-calendar-view ListCalendarView" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T19:00:00-08:00
  --endDateTime: string # The end date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/calendarView" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function delta
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/calendarView/microsoft.graph.delta()
# Docs: https://learn.microsoft.com/graph/api/event-delta?view=graph-rest-1.0 — Find more info here
# operationId: user.calendarGroup.calendar.calendarView_delta
export def "users-calendar-groups-calendars-calendar-view-microsoftgraphdelta delta" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --endDateTime: string # The end date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: record, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, _odata_nextLink: string, _odata_deltaLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/calendarView/microsoft.graph.delta()" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get events from users
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events
# operationId: user.calendarGroup.calendar_ListEvent
export def "users-calendar-groups-calendars-events ListEvent" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to events for users
#
# POST /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events
# operationId: user.calendarGroup.calendar_CreateEvent
# --attendees item shape: {proposedNewTime?: record, status?: record}
# --body shape: {content?: string, contentType?: "text"|"html"}
# --end shape: {dateTime?: string, timeZone?: string}
# --location shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --locations item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --onlineMeeting shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
# --organizer shape: {emailAddress?: record}
# --recurrence shape: {pattern?: record, range?: record}
# --responseStatus shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
# --start shape: {dateTime?: string, timeZone?: string}
# --attachments item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
# --exceptionOccurrences item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --extensions item shape: {id?: string}
# --instances item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --multiValueExtendedProperties item shape: {id?: string, value?: list}
# --singleValueExtendedProperties item shape: {id?: string, value?: string}
export def "users-calendar-groups-calendars-events CreateEvent" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowNewTimeProposals: oneof<nothing, bool> # true if the meeting organizer allows invitees to propose a new time when responding; otherwise, false. Optional. The default is true. (nullable)
  --attendees: list # The collection of attendees for the event. — item shape: {proposedNewTime?: record, status?: record}
  --body-body: record # shape: {content?: string, contentType?: "text"|"html"}
  --bodyPreview: string # The preview of the message associated with the event. It's in text format. (nullable)
  --cancelledOccurrences: list # Contains occurrenceId property values of canceled instances in a recurring series, if the event is the series master. Instances in a recurring series that are canceled are called canceled occurences.Requires $select to retrieve. Only returned in a Get operation that specifies the ID (seriesMasterId property value) of a series master event.
  --end: record # shape: {dateTime?: string, timeZone?: string}
  --hasAttachments: oneof<nothing, bool> # Set to true if the event has attachments. (nullable)
  --hideAttendees: oneof<nothing, bool> # When set to true, each attendee only sees themselves in the meeting request and meeting Tracking list. The default is false. (nullable)
  --iCalUId: string # A unique identifier for an event across calendars. This ID is different for each occurrence in a recurring series. Read-only. (nullable)
  --importance: string@importance-completer
  --isAllDay: oneof<nothing, bool> # Set to true if the event lasts all day. If true, regardless of whether it's a single-day or multi-day event, start, and endtime must be set to midnight and be in the same time zone. (nullable)
  --isCancelled: oneof<nothing, bool> # Set to true if the event has been canceled. (nullable)
  --isDraft: oneof<nothing, bool> # Set to true if the user has updated the meeting in Outlook but hasn't sent the updates to attendees. Set to false if all changes are sent, or if the event is an appointment without any attendees. (nullable)
  --isOnlineMeeting: oneof<nothing, bool> # True if this event has online meeting information (that is, onlineMeeting points to an onlineMeetingInfo resource), false otherwise. Default is false (onlineMeeting is null). Optional.  After you set isOnlineMeeting to true, Microsoft Graph initializes onlineMeeting. Subsequently, Outlook ignores any further changes to isOnlineMeeting, and the meeting remains available online. (nullable)
  --isOrganizer: oneof<nothing, bool> # Set to true if the calendar owner (specified by the owner property of the calendar) is the organizer of the event (specified by the organizer property of the event). It also applies if a delegate organized the event on behalf of the owner. (nullable)
  --isReminderOn: oneof<nothing, bool> # Set to true if an alert is set to remind the user of the event. (nullable)
  --location: record # shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --locations: list # The locations where the event is held or attended from. The location and locations properties always correspond with each other. If you update the location property, any prior locations in the locations collection are removed and replaced by the new location value. — item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --onlineMeeting: record # shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
  --onlineMeetingProvider: string@onlineMeetingProvider-completer
  --onlineMeetingUrl: string # A URL for an online meeting. The property is set only when an organizer specifies in Outlook that an event is an online meeting such as Skype. Read-only.To access the URL to join an online meeting, use joinUrl which is exposed via the onlineMeeting property of the event. The onlineMeetingUrl property will be deprecated in the future. (nullable)
  --organizer: record # shape: {emailAddress?: record}
  --originalEndTimeZone: string # The end time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --originalStart: string # Represents the start time of an event when it's initially created as an occurrence or exception in a recurring series. This property is not returned for events that are single instances. Its date and time information is expressed in ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --originalStartTimeZone: string # The start time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --recurrence: record # shape: {pattern?: record, range?: record}
  --reminderMinutesBeforeStart: float # The number of minutes before the event start time that the reminder alert occurs. (nullable, format: int32)
  --responseRequested: oneof<nothing, bool> # Default is true, which represents the organizer would like an invitee to send a response to the event. (nullable)
  --responseStatus: record # shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
  --sensitivity: string@sensitivity-completer
  --seriesMasterId: string # The ID for the recurring series master item, if this event is part of a recurring series. (nullable)
  --showAs: string@showAs-completer
  --start: record # shape: {dateTime?: string, timeZone?: string}
  --subject: string # The text of the event's subject line. (nullable)
  --transactionId: string # A custom identifier specified by a client app for the server to avoid redundant POST operations in case of client retries to create the same event. It's useful when low network connectivity causes the client to time out before receiving a response from the server for the client's prior create-event request. After you set transactionId when creating an event, you can't change transactionId in a subsequent update. This property is only returned in a response payload if an app has set it. Optional. (nullable)
  --type: string@type-completer
  --webLink: string # The URL to open the event in Outlook on the web.Outlook on the web opens the event in the browser if you are signed in to your mailbox. Otherwise, Outlook on the web prompts you to sign in.This URL can't be accessed from within an iFrame. (nullable)
  --attachments: list # The collection of FileAttachment, ItemAttachment, and referenceAttachment attachments for the event. Navigation property. Read-only. Nullable. — item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
  --calendar: any
  --exceptionOccurrences: list # Contains the id property values of the event instances that are exceptions in a recurring series.Exceptions can differ from other occurrences in a recurring series, such as the subject, start or end times, or attendees. Exceptions don't include canceled occurrences.Requires $select and $expand to retrieve. Only returned in a GET operation that specifies the ID (seriesMasterId property value) of a series master event. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --extensions: list # The collection of open extensions defined for the event. Nullable. — item shape: {id?: string}
  --instances: list # The occurrences of a recurring series, if the event is a series master. This property includes occurrences that are part of the recurrence pattern, and exceptions modified, but doesn't include occurrences canceled from the series. Navigation property. Read-only. Nullable. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --multiValueExtendedProperties: list # The collection of multi-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: list}
  --singleValueExtendedProperties: list # The collection of single-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: string}
]: any -> record<allowNewTimeProposals: bool, attendees: table<proposedNewTime: record, status: record>, body: record<content: string, contentType: string>, bodyPreview: string, cancelledOccurrences: list<string>, end: record<dateTime: string, timeZone: string>, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, locations: table<address: record, coordinates: record, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, onlineMeeting: record<conferenceId: string, joinUrl: string, phones: list<record>, quickDial: string, tollFreeNumbers: list<string>, tollNumber: string>, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record<emailAddress: record<address: string, name: string>>, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record<pattern: record<dayOfMonth: float, daysOfWeek: list, firstDayOfWeek: string, index: string, interval: float, month: float, type: string>, range: record<endDate: string, numberOfOccurrences: float, recurrenceTimeZone: string, startDate: string, type: string>>, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record<response: string, time: string>, sensitivity: string, seriesMasterId: string, showAs: string, start: record<dateTime: string, timeZone: string>, subject: string, transactionId: string, type: string, webLink: string, attachments: table<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float>, calendar: record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: list<record>, calendarView: list<any>, events: list<any>, multiValueExtendedProperties: list<record>, singleValueExtendedProperties: list<record>>, exceptionOccurrences: list<any>, extensions: table<id: string>, instances: list<any>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events")
  let body = {allowNewTimeProposals: $allowNewTimeProposals, attendees: $attendees, body: $body_body, bodyPreview: $bodyPreview, cancelledOccurrences: $cancelledOccurrences, end: $end, hasAttachments: $hasAttachments, hideAttendees: $hideAttendees, iCalUId: $iCalUId, importance: $importance, isAllDay: $isAllDay, isCancelled: $isCancelled, isDraft: $isDraft, isOnlineMeeting: $isOnlineMeeting, isOrganizer: $isOrganizer, isReminderOn: $isReminderOn, location: $location, locations: $locations, onlineMeeting: $onlineMeeting, onlineMeetingProvider: $onlineMeetingProvider, onlineMeetingUrl: $onlineMeetingUrl, organizer: $organizer, originalEndTimeZone: $originalEndTimeZone, originalStart: $originalStart, originalStartTimeZone: $originalStartTimeZone, recurrence: $recurrence, reminderMinutesBeforeStart: $reminderMinutesBeforeStart, responseRequested: $responseRequested, responseStatus: $responseStatus, sensitivity: $sensitivity, seriesMasterId: $seriesMasterId, showAs: $showAs, start: $start, subject: $subject, transactionId: $transactionId, type: $type, webLink: $webLink, attachments: $attachments, calendar: $calendar, exceptionOccurrences: $exceptionOccurrences, extensions: $extensions, instances: $instances, multiValueExtendedProperties: $multiValueExtendedProperties, singleValueExtendedProperties: $singleValueExtendedProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get events from users
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}
# operationId: user.calendarGroup.calendar_GetEvent
export def "users-calendar-groups-calendars-events GetEvent" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<allowNewTimeProposals: bool, attendees: table<proposedNewTime: record, status: record>, body: record<content: string, contentType: string>, bodyPreview: string, cancelledOccurrences: list<string>, end: record<dateTime: string, timeZone: string>, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, locations: table<address: record, coordinates: record, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, onlineMeeting: record<conferenceId: string, joinUrl: string, phones: list<record>, quickDial: string, tollFreeNumbers: list<string>, tollNumber: string>, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record<emailAddress: record<address: string, name: string>>, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record<pattern: record<dayOfMonth: float, daysOfWeek: list, firstDayOfWeek: string, index: string, interval: float, month: float, type: string>, range: record<endDate: string, numberOfOccurrences: float, recurrenceTimeZone: string, startDate: string, type: string>>, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record<response: string, time: string>, sensitivity: string, seriesMasterId: string, showAs: string, start: record<dateTime: string, timeZone: string>, subject: string, transactionId: string, type: string, webLink: string, attachments: table<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float>, calendar: record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: list<record>, calendarView: list<any>, events: list<any>, multiValueExtendedProperties: list<record>, singleValueExtendedProperties: list<record>>, exceptionOccurrences: list<any>, extensions: table<id: string>, instances: list<any>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property events in users
#
# PATCH /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}
# operationId: user.calendarGroup.calendar_UpdateEvent
# --attendees item shape: {proposedNewTime?: record, status?: record}
# --body shape: {content?: string, contentType?: "text"|"html"}
# --end shape: {dateTime?: string, timeZone?: string}
# --location shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --locations item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --onlineMeeting shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
# --organizer shape: {emailAddress?: record}
# --recurrence shape: {pattern?: record, range?: record}
# --responseStatus shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
# --start shape: {dateTime?: string, timeZone?: string}
# --attachments item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
# --exceptionOccurrences item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --extensions item shape: {id?: string}
# --instances item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --multiValueExtendedProperties item shape: {id?: string, value?: list}
# --singleValueExtendedProperties item shape: {id?: string, value?: string}
export def "users-calendar-groups-calendars-events UpdateEvent" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowNewTimeProposals: oneof<nothing, bool> # true if the meeting organizer allows invitees to propose a new time when responding; otherwise, false. Optional. The default is true. (nullable)
  --attendees: list # The collection of attendees for the event. — item shape: {proposedNewTime?: record, status?: record}
  --body-body: record # shape: {content?: string, contentType?: "text"|"html"}
  --bodyPreview: string # The preview of the message associated with the event. It's in text format. (nullable)
  --cancelledOccurrences: list # Contains occurrenceId property values of canceled instances in a recurring series, if the event is the series master. Instances in a recurring series that are canceled are called canceled occurences.Requires $select to retrieve. Only returned in a Get operation that specifies the ID (seriesMasterId property value) of a series master event.
  --end: record # shape: {dateTime?: string, timeZone?: string}
  --hasAttachments: oneof<nothing, bool> # Set to true if the event has attachments. (nullable)
  --hideAttendees: oneof<nothing, bool> # When set to true, each attendee only sees themselves in the meeting request and meeting Tracking list. The default is false. (nullable)
  --iCalUId: string # A unique identifier for an event across calendars. This ID is different for each occurrence in a recurring series. Read-only. (nullable)
  --importance: string@importance-completer
  --isAllDay: oneof<nothing, bool> # Set to true if the event lasts all day. If true, regardless of whether it's a single-day or multi-day event, start, and endtime must be set to midnight and be in the same time zone. (nullable)
  --isCancelled: oneof<nothing, bool> # Set to true if the event has been canceled. (nullable)
  --isDraft: oneof<nothing, bool> # Set to true if the user has updated the meeting in Outlook but hasn't sent the updates to attendees. Set to false if all changes are sent, or if the event is an appointment without any attendees. (nullable)
  --isOnlineMeeting: oneof<nothing, bool> # True if this event has online meeting information (that is, onlineMeeting points to an onlineMeetingInfo resource), false otherwise. Default is false (onlineMeeting is null). Optional.  After you set isOnlineMeeting to true, Microsoft Graph initializes onlineMeeting. Subsequently, Outlook ignores any further changes to isOnlineMeeting, and the meeting remains available online. (nullable)
  --isOrganizer: oneof<nothing, bool> # Set to true if the calendar owner (specified by the owner property of the calendar) is the organizer of the event (specified by the organizer property of the event). It also applies if a delegate organized the event on behalf of the owner. (nullable)
  --isReminderOn: oneof<nothing, bool> # Set to true if an alert is set to remind the user of the event. (nullable)
  --location: record # shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --locations: list # The locations where the event is held or attended from. The location and locations properties always correspond with each other. If you update the location property, any prior locations in the locations collection are removed and replaced by the new location value. — item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --onlineMeeting: record # shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
  --onlineMeetingProvider: string@onlineMeetingProvider-completer
  --onlineMeetingUrl: string # A URL for an online meeting. The property is set only when an organizer specifies in Outlook that an event is an online meeting such as Skype. Read-only.To access the URL to join an online meeting, use joinUrl which is exposed via the onlineMeeting property of the event. The onlineMeetingUrl property will be deprecated in the future. (nullable)
  --organizer: record # shape: {emailAddress?: record}
  --originalEndTimeZone: string # The end time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --originalStart: string # Represents the start time of an event when it's initially created as an occurrence or exception in a recurring series. This property is not returned for events that are single instances. Its date and time information is expressed in ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --originalStartTimeZone: string # The start time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --recurrence: record # shape: {pattern?: record, range?: record}
  --reminderMinutesBeforeStart: float # The number of minutes before the event start time that the reminder alert occurs. (nullable, format: int32)
  --responseRequested: oneof<nothing, bool> # Default is true, which represents the organizer would like an invitee to send a response to the event. (nullable)
  --responseStatus: record # shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
  --sensitivity: string@sensitivity-completer
  --seriesMasterId: string # The ID for the recurring series master item, if this event is part of a recurring series. (nullable)
  --showAs: string@showAs-completer
  --start: record # shape: {dateTime?: string, timeZone?: string}
  --subject: string # The text of the event's subject line. (nullable)
  --transactionId: string # A custom identifier specified by a client app for the server to avoid redundant POST operations in case of client retries to create the same event. It's useful when low network connectivity causes the client to time out before receiving a response from the server for the client's prior create-event request. After you set transactionId when creating an event, you can't change transactionId in a subsequent update. This property is only returned in a response payload if an app has set it. Optional. (nullable)
  --type: string@type-completer
  --webLink: string # The URL to open the event in Outlook on the web.Outlook on the web opens the event in the browser if you are signed in to your mailbox. Otherwise, Outlook on the web prompts you to sign in.This URL can't be accessed from within an iFrame. (nullable)
  --attachments: list # The collection of FileAttachment, ItemAttachment, and referenceAttachment attachments for the event. Navigation property. Read-only. Nullable. — item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
  --calendar: any
  --exceptionOccurrences: list # Contains the id property values of the event instances that are exceptions in a recurring series.Exceptions can differ from other occurrences in a recurring series, such as the subject, start or end times, or attendees. Exceptions don't include canceled occurrences.Requires $select and $expand to retrieve. Only returned in a GET operation that specifies the ID (seriesMasterId property value) of a series master event. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --extensions: list # The collection of open extensions defined for the event. Nullable. — item shape: {id?: string}
  --instances: list # The occurrences of a recurring series, if the event is a series master. This property includes occurrences that are part of the recurrence pattern, and exceptions modified, but doesn't include occurrences canceled from the series. Navigation property. Read-only. Nullable. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --multiValueExtendedProperties: list # The collection of multi-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: list}
  --singleValueExtendedProperties: list # The collection of single-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: string}
]: any -> record<allowNewTimeProposals: bool, attendees: table<proposedNewTime: record, status: record>, body: record<content: string, contentType: string>, bodyPreview: string, cancelledOccurrences: list<string>, end: record<dateTime: string, timeZone: string>, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, locations: table<address: record, coordinates: record, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, onlineMeeting: record<conferenceId: string, joinUrl: string, phones: list<record>, quickDial: string, tollFreeNumbers: list<string>, tollNumber: string>, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record<emailAddress: record<address: string, name: string>>, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record<pattern: record<dayOfMonth: float, daysOfWeek: list, firstDayOfWeek: string, index: string, interval: float, month: float, type: string>, range: record<endDate: string, numberOfOccurrences: float, recurrenceTimeZone: string, startDate: string, type: string>>, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record<response: string, time: string>, sensitivity: string, seriesMasterId: string, showAs: string, start: record<dateTime: string, timeZone: string>, subject: string, transactionId: string, type: string, webLink: string, attachments: table<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float>, calendar: record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: list<record>, calendarView: list<any>, events: list<any>, multiValueExtendedProperties: list<record>, singleValueExtendedProperties: list<record>>, exceptionOccurrences: list<any>, extensions: table<id: string>, instances: list<any>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)")
  let body = {allowNewTimeProposals: $allowNewTimeProposals, attendees: $attendees, body: $body_body, bodyPreview: $bodyPreview, cancelledOccurrences: $cancelledOccurrences, end: $end, hasAttachments: $hasAttachments, hideAttendees: $hideAttendees, iCalUId: $iCalUId, importance: $importance, isAllDay: $isAllDay, isCancelled: $isCancelled, isDraft: $isDraft, isOnlineMeeting: $isOnlineMeeting, isOrganizer: $isOrganizer, isReminderOn: $isReminderOn, location: $location, locations: $locations, onlineMeeting: $onlineMeeting, onlineMeetingProvider: $onlineMeetingProvider, onlineMeetingUrl: $onlineMeetingUrl, organizer: $organizer, originalEndTimeZone: $originalEndTimeZone, originalStart: $originalStart, originalStartTimeZone: $originalStartTimeZone, recurrence: $recurrence, reminderMinutesBeforeStart: $reminderMinutesBeforeStart, responseRequested: $responseRequested, responseStatus: $responseStatus, sensitivity: $sensitivity, seriesMasterId: $seriesMasterId, showAs: $showAs, start: $start, subject: $subject, transactionId: $transactionId, type: $type, webLink: $webLink, attachments: $attachments, calendar: $calendar, exceptionOccurrences: $exceptionOccurrences, extensions: $extensions, instances: $instances, multiValueExtendedProperties: $multiValueExtendedProperties, singleValueExtendedProperties: $singleValueExtendedProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property events for users
#
# DELETE /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}
# operationId: user.calendarGroup.calendar_DeleteEvent
export def "users-calendar-groups-calendars-events DeleteEvent" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get attachments from users
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/attachments
# operationId: user.calendarGroup.calendar.event_ListAttachment
export def "users-calendar-groups-calendars-events-attachments ListAttachment" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/attachments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to attachments for users
#
# POST /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/attachments
# operationId: user.calendarGroup.calendar.event_CreateAttachment
export def "users-calendar-groups-calendars-events-attachments CreateAttachment" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --contentType: string # The MIME type. (nullable)
  --isInline: oneof<nothing, bool> # true if the attachment is an inline attachment; otherwise, false.
  --lastModifiedDateTime: string # The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --name: string # The attachment's file name. (nullable)
  --size: float # The length of the attachment in bytes. (format: int32)
]: any -> record<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/attachments")
  let body = {id: $id, contentType: $contentType, isInline: $isInline, lastModifiedDateTime: $lastModifiedDateTime, name: $name, size: $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get attachments from users
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/attachments/{attachment-id}
# operationId: user.calendarGroup.calendar.event_GetAttachment
export def "users-calendar-groups-calendars-events-attachments GetAttachment" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/attachments/($attachment_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete navigation property attachments for users
#
# DELETE /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/attachments/{attachment-id}
# operationId: user.calendarGroup.calendar.event_DeleteAttachment
export def "users-calendar-groups-calendars-events-attachments DeleteAttachment" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/attachments/($attachment_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/attachments/$count
# operationId: user.calendarGroup.calendar.event.attachment_GetCount
export def "users-calendar-groups-calendars-events-attachments-count GetCount" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/attachments/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action createUploadSession
#
# POST /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/attachments/microsoft.graph.createUploadSession
# Docs: https://learn.microsoft.com/graph/api/attachment-createuploadsession?view=graph-rest-1.0 — Find more info here
# operationId: user.calendarGroup.calendar.event.attachment_createUploadSession
# --AttachmentItem shape: {attachmentType?: "file"|"item"|"reference", contentId?: string, contentType?: string, isInline?: bool, name?: string, size?: float}
export def "users-calendar-groups-calendars-events-attachments-microsoftgraphcreate-upload-session createUploadSession" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AttachmentItem: record # shape: {attachmentType?: "file"|"item"|"reference", contentId?: string, contentType?: string, isInline?: bool, name?: string, size?: float}
]: any -> record<expirationDateTime: string, nextExpectedRanges: list<string>, uploadUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/attachments/microsoft.graph.createUploadSession")
  let body = {AttachmentItem: $AttachmentItem} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get calendar from users
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/calendar
# operationId: user.calendarGroup.calendar.event_GetCalendar
export def "users-calendar-groups-calendars-events-calendar GetCalendar" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: table<id: string, allowedRoles: list, emailAddress: record, isInsideOrganization: bool, isRemovable: bool, role: string>, calendarView: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, events: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/calendar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get extensions from users
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/extensions
# operationId: user.calendarGroup.calendar.event_ListExtension
export def "users-calendar-groups-calendars-events-extensions ListExtension" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/extensions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to extensions for users
#
# POST /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/extensions
# operationId: user.calendarGroup.calendar.event_CreateExtension
export def "users-calendar-groups-calendars-events-extensions CreateExtension" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/extensions")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get extensions from users
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/extensions/{extension-id}
# operationId: user.calendarGroup.calendar.event_GetExtension
export def "users-calendar-groups-calendars-events-extensions GetExtension" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  extension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/extensions/($extension_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property extensions in users
#
# PATCH /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/extensions/{extension-id}
# operationId: user.calendarGroup.calendar.event_UpdateExtension
export def "users-calendar-groups-calendars-events-extensions UpdateExtension" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  extension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/extensions/($extension_id)")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property extensions for users
#
# DELETE /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/extensions/{extension-id}
# operationId: user.calendarGroup.calendar.event_DeleteExtension
export def "users-calendar-groups-calendars-events-extensions DeleteExtension" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  extension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/extensions/($extension_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/extensions/$count
# operationId: user.calendarGroup.calendar.event.extension_GetCount
export def "users-calendar-groups-calendars-events-extensions-count GetCount" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/extensions/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get instances from users
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/instances
# operationId: user.calendarGroup.calendar.event_ListInstance
export def "users-calendar-groups-calendars-events-instances ListInstance" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T19:00:00-08:00
  --endDateTime: string # The end date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/instances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function delta
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/instances/microsoft.graph.delta()
# Docs: https://learn.microsoft.com/graph/api/event-delta?view=graph-rest-1.0 — Find more info here
# operationId: user.calendarGroup.calendar.event.instance_delta
export def "users-calendar-groups-calendars-events-instances-microsoftgraphdelta delta" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --endDateTime: string # The end date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: record, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, _odata_nextLink: string, _odata_deltaLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/instances/microsoft.graph.delta()" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action accept
#
# POST /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/microsoft.graph.accept
# Docs: https://learn.microsoft.com/graph/api/event-accept?view=graph-rest-1.0 — Find more info here
# operationId: user.calendarGroup.calendar.event_accept
export def "users-calendar-groups-calendars-events-microsoftgraphaccept accept" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --SendResponse: oneof<nothing, bool> # nullable, default: false
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/microsoft.graph.accept")
  let body = {SendResponse: $SendResponse, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action cancel
#
# POST /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/microsoft.graph.cancel
# Docs: https://learn.microsoft.com/graph/api/event-cancel?view=graph-rest-1.0 — Find more info here
# operationId: user.calendarGroup.calendar.event_cancel
export def "users-calendar-groups-calendars-events-microsoftgraphcancel cancel" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/microsoft.graph.cancel")
  let body = {Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action decline
#
# POST /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/microsoft.graph.decline
# Docs: https://learn.microsoft.com/graph/api/event-decline?view=graph-rest-1.0 — Find more info here
# operationId: user.calendarGroup.calendar.event_decline
# --ProposedNewTime shape: {end?: record, start?: record}
export def "users-calendar-groups-calendars-events-microsoftgraphdecline decline" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ProposedNewTime: record # shape: {end?: record, start?: record}
  --SendResponse: oneof<nothing, bool> # nullable, default: false
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/microsoft.graph.decline")
  let body = {ProposedNewTime: $ProposedNewTime, SendResponse: $SendResponse, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action dismissReminder
#
# POST /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/microsoft.graph.dismissReminder
# Docs: https://learn.microsoft.com/graph/api/event-dismissreminder?view=graph-rest-1.0 — Find more info here
# operationId: user.calendarGroup.calendar.event_dismissReminder
export def "users-calendar-groups-calendars-events-microsoftgraphdismiss-reminder dismissReminder" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
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
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/microsoft.graph.dismissReminder")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action forward
#
# POST /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/microsoft.graph.forward
# Docs: https://learn.microsoft.com/graph/api/event-forward?view=graph-rest-1.0 — Find more info here
# operationId: user.calendarGroup.calendar.event_forward
# --ToRecipients item shape: {emailAddress?: record}
export def "users-calendar-groups-calendars-events-microsoftgraphforward forward" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ToRecipients: list # item shape: {emailAddress?: record}
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/microsoft.graph.forward")
  let body = {ToRecipients: $ToRecipients, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action permanentDelete
#
# POST /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/microsoft.graph.permanentDelete
# operationId: user.calendarGroup.calendar.event_permanentDelete
export def "users-calendar-groups-calendars-events-microsoftgraphpermanent-delete permanentDelete" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
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
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/microsoft.graph.permanentDelete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action snoozeReminder
#
# POST /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/microsoft.graph.snoozeReminder
# Docs: https://learn.microsoft.com/graph/api/event-snoozereminder?view=graph-rest-1.0 — Find more info here
# operationId: user.calendarGroup.calendar.event_snoozeReminder
# --NewReminderTime shape: {dateTime?: string, timeZone?: string}
export def "users-calendar-groups-calendars-events-microsoftgraphsnooze-reminder snoozeReminder" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --NewReminderTime: record # shape: {dateTime?: string, timeZone?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/microsoft.graph.snoozeReminder")
  let body = {NewReminderTime: $NewReminderTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action tentativelyAccept
#
# POST /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/{event-id}/microsoft.graph.tentativelyAccept
# Docs: https://learn.microsoft.com/graph/api/event-tentativelyaccept?view=graph-rest-1.0 — Find more info here
# operationId: user.calendarGroup.calendar.event_tentativelyAccept
# --ProposedNewTime shape: {end?: record, start?: record}
export def "users-calendar-groups-calendars-events-microsoftgraphtentatively-accept tentativelyAccept" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ProposedNewTime: record # shape: {end?: record, start?: record}
  --SendResponse: oneof<nothing, bool> # nullable, default: false
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/($event_id)/microsoft.graph.tentativelyAccept")
  let body = {ProposedNewTime: $ProposedNewTime, SendResponse: $SendResponse, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the number of the resource
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/$count
# operationId: user.calendarGroup.calendar.event_GetCount
export def "users-calendar-groups-calendars-events-count GetCount" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function delta
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/events/microsoft.graph.delta()
# Docs: https://learn.microsoft.com/graph/api/event-delta?view=graph-rest-1.0 — Find more info here
# operationId: user.calendarGroup.calendar.event_delta
export def "users-calendar-groups-calendars-events-microsoftgraphdelta delta" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --endDateTime: string # The end date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: record, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, _odata_nextLink: string, _odata_deltaLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/events/microsoft.graph.delta()" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function allowedCalendarSharingRoles
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/microsoft.graph.allowedCalendarSharingRoles(User='{User}')
# operationId: user.calendarGroup.calendar_allowedCalendarSharingRole
export def "users-calendar-groups-calendars-microsoftgraphallowed-calendar-sharing-roles-user-user allowedCalendarSharingRole" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  User: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
]: nothing -> record<value: list<string>, _odata_nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/microsoft.graph.allowedCalendarSharingRoles(User='($User)')" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action getSchedule
#
# POST /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/microsoft.graph.getSchedule
# Docs: https://learn.microsoft.com/graph/api/calendar-getschedule?view=graph-rest-1.0 — Find more info here
# operationId: user.calendarGroup.calendar_getSchedule
# --EndTime shape: {dateTime?: string, timeZone?: string}
# --StartTime shape: {dateTime?: string, timeZone?: string}
export def "users-calendar-groups-calendars-microsoftgraphget-schedule post" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Schedules: list
  --EndTime: record # shape: {dateTime?: string, timeZone?: string}
  --StartTime: record # shape: {dateTime?: string, timeZone?: string}
  --AvailabilityViewInterval: float # nullable, format: int32
]: any -> record<value: table<availabilityView: string, error: record, scheduleId: string, scheduleItems: list, workingHours: record>, _odata_nextLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/microsoft.graph.getSchedule")
  let body = {Schedules: $Schedules, EndTime: $EndTime, StartTime: $StartTime, AvailabilityViewInterval: $AvailabilityViewInterval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action permanentDelete
#
# POST /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/{calendar-id}/microsoft.graph.permanentDelete
# operationId: user.calendarGroup.calendar_permanentDelete
export def "users-calendar-groups-calendars-microsoftgraphpermanent-delete permanentDelete" [
  user_id: string
  calendarGroup_id: string
  calendar_id: string
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
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/($calendar_id)/microsoft.graph.permanentDelete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /users/{user-id}/calendarGroups/{calendarGroup-id}/calendars/$count
# operationId: user.calendarGroup.calendar_GetCount
export def "users-calendar-groups-calendars-count GetCount" [
  user_id: string
  calendarGroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/($calendarGroup_id)/calendars/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /users/{user-id}/calendarGroups/$count
# operationId: user.calendarGroup_GetCount
export def "users-calendar-groups-count GetCount" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarGroups/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get calendars from users
#
# GET /users/{user-id}/calendars
# operationId: user_ListCalendar
export def "users-calendars ListCalendar" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendars" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to calendars for users
#
# POST /users/{user-id}/calendars
# operationId: user_CreateCalendar
# --owner shape: {address?: string, name?: string}
# --calendarPermissions item shape: {id?: string, allowedRoles?: list, emailAddress?: record, isInsideOrganization?: bool, isRemovable?: bool, role?: "none"|"freeBusyRead"|"limitedRead"|"read"|"write"|"delegateWithoutPrivateEventAccess"|"delegateWithPrivateEventAccess"|"custom"}
# --calendarView item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --events item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --multiValueExtendedProperties item shape: {id?: string, value?: list}
# --singleValueExtendedProperties item shape: {id?: string, value?: string}
export def "users-calendars CreateCalendar" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --allowedOnlineMeetingProviders: list # Represent the online meeting service providers that can be used to create online meetings in this calendar. The possible values are: unknown, skypeForBusiness, skypeForConsumer, teamsForBusiness.
  --canEdit: oneof<nothing, bool> # true if the user can write to the calendar, false otherwise. This property is true for the user who created the calendar. This property is also true for a user who shared a calendar and granted write access. (nullable)
  --canShare: oneof<nothing, bool> # true if the user has permission to share the calendar, false otherwise. Only the user who created the calendar can share it. (nullable)
  --canViewPrivateItems: oneof<nothing, bool> # If true, the user can read calendar items that have been marked private, false otherwise. (nullable)
  --changeKey: string # Identifies the version of the calendar object. Every time the calendar is changed, changeKey changes as well. This allows Exchange to apply changes to the correct version of the object. Read-only. (nullable)
  --color: string@color-completer
  --defaultOnlineMeetingProvider: string@defaultOnlineMeetingProvider-completer
  --hexColor: string # The calendar color, expressed in a hex color code of three hexadecimal values, each ranging from 00 to FF and representing the red, green, or blue components of the color in the RGB color space. If the user has never explicitly set a color for the calendar, this property is empty. Read-only. (nullable)
  --isDefaultCalendar: oneof<nothing, bool> # true if this is the default calendar where new events are created by default, false otherwise. (nullable)
  --isRemovable: oneof<nothing, bool> # Indicates whether this user calendar can be deleted from the user mailbox. (nullable)
  --isTallyingResponses: oneof<nothing, bool> # Indicates whether this user calendar supports tracking of meeting responses. Only meeting invites sent from users' primary calendars support tracking of meeting responses. (nullable)
  --name: string # The calendar name. (nullable)
  --owner: record # shape: {address?: string, name?: string}
  --calendarPermissions: list # The permissions of the users with whom the calendar is shared. — item shape: {id?: string, allowedRoles?: list, emailAddress?: record, isInsideOrganization?: bool, isRemovable?: bool, role?: "none"|"freeBusyRead"|"limitedRead"|"read"|"write"|"delegateWithoutPrivateEventAccess"|"delegateWithPrivateEventAccess"|"custom"}
  --calendarView: list # The calendar view for the calendar. Navigation property. Read-only. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --events: list # The events in the calendar. Navigation property. Read-only. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --multiValueExtendedProperties: list # The collection of multi-value extended properties defined for the calendar. Read-only. Nullable. — item shape: {id?: string, value?: list}
  --singleValueExtendedProperties: list # The collection of single-value extended properties defined for the calendar. Read-only. Nullable. — item shape: {id?: string, value?: string}
]: any -> record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: table<id: string, allowedRoles: list, emailAddress: record, isInsideOrganization: bool, isRemovable: bool, role: string>, calendarView: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, events: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendars")
  let body = {id: $id, allowedOnlineMeetingProviders: $allowedOnlineMeetingProviders, canEdit: $canEdit, canShare: $canShare, canViewPrivateItems: $canViewPrivateItems, changeKey: $changeKey, color: $color, defaultOnlineMeetingProvider: $defaultOnlineMeetingProvider, hexColor: $hexColor, isDefaultCalendar: $isDefaultCalendar, isRemovable: $isRemovable, isTallyingResponses: $isTallyingResponses, name: $name, owner: $owner, calendarPermissions: $calendarPermissions, calendarView: $calendarView, events: $events, multiValueExtendedProperties: $multiValueExtendedProperties, singleValueExtendedProperties: $singleValueExtendedProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get calendars from users
#
# GET /users/{user-id}/calendars/{calendar-id}
# operationId: user_GetCalendar
export def "users-calendars GetCalendar" [
  user_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: table<id: string, allowedRoles: list, emailAddress: record, isInsideOrganization: bool, isRemovable: bool, role: string>, calendarView: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, events: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property calendars in users
#
# PATCH /users/{user-id}/calendars/{calendar-id}
# operationId: user_UpdateCalendar
# --owner shape: {address?: string, name?: string}
# --calendarPermissions item shape: {id?: string, allowedRoles?: list, emailAddress?: record, isInsideOrganization?: bool, isRemovable?: bool, role?: "none"|"freeBusyRead"|"limitedRead"|"read"|"write"|"delegateWithoutPrivateEventAccess"|"delegateWithPrivateEventAccess"|"custom"}
# --calendarView item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --events item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --multiValueExtendedProperties item shape: {id?: string, value?: list}
# --singleValueExtendedProperties item shape: {id?: string, value?: string}
export def "users-calendars UpdateCalendar" [
  user_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --allowedOnlineMeetingProviders: list # Represent the online meeting service providers that can be used to create online meetings in this calendar. The possible values are: unknown, skypeForBusiness, skypeForConsumer, teamsForBusiness.
  --canEdit: oneof<nothing, bool> # true if the user can write to the calendar, false otherwise. This property is true for the user who created the calendar. This property is also true for a user who shared a calendar and granted write access. (nullable)
  --canShare: oneof<nothing, bool> # true if the user has permission to share the calendar, false otherwise. Only the user who created the calendar can share it. (nullable)
  --canViewPrivateItems: oneof<nothing, bool> # If true, the user can read calendar items that have been marked private, false otherwise. (nullable)
  --changeKey: string # Identifies the version of the calendar object. Every time the calendar is changed, changeKey changes as well. This allows Exchange to apply changes to the correct version of the object. Read-only. (nullable)
  --color: string@color-completer
  --defaultOnlineMeetingProvider: string@defaultOnlineMeetingProvider-completer
  --hexColor: string # The calendar color, expressed in a hex color code of three hexadecimal values, each ranging from 00 to FF and representing the red, green, or blue components of the color in the RGB color space. If the user has never explicitly set a color for the calendar, this property is empty. Read-only. (nullable)
  --isDefaultCalendar: oneof<nothing, bool> # true if this is the default calendar where new events are created by default, false otherwise. (nullable)
  --isRemovable: oneof<nothing, bool> # Indicates whether this user calendar can be deleted from the user mailbox. (nullable)
  --isTallyingResponses: oneof<nothing, bool> # Indicates whether this user calendar supports tracking of meeting responses. Only meeting invites sent from users' primary calendars support tracking of meeting responses. (nullable)
  --name: string # The calendar name. (nullable)
  --owner: record # shape: {address?: string, name?: string}
  --calendarPermissions: list # The permissions of the users with whom the calendar is shared. — item shape: {id?: string, allowedRoles?: list, emailAddress?: record, isInsideOrganization?: bool, isRemovable?: bool, role?: "none"|"freeBusyRead"|"limitedRead"|"read"|"write"|"delegateWithoutPrivateEventAccess"|"delegateWithPrivateEventAccess"|"custom"}
  --calendarView: list # The calendar view for the calendar. Navigation property. Read-only. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --events: list # The events in the calendar. Navigation property. Read-only. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --multiValueExtendedProperties: list # The collection of multi-value extended properties defined for the calendar. Read-only. Nullable. — item shape: {id?: string, value?: list}
  --singleValueExtendedProperties: list # The collection of single-value extended properties defined for the calendar. Read-only. Nullable. — item shape: {id?: string, value?: string}
]: any -> record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: table<id: string, allowedRoles: list, emailAddress: record, isInsideOrganization: bool, isRemovable: bool, role: string>, calendarView: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, events: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)")
  let body = {id: $id, allowedOnlineMeetingProviders: $allowedOnlineMeetingProviders, canEdit: $canEdit, canShare: $canShare, canViewPrivateItems: $canViewPrivateItems, changeKey: $changeKey, color: $color, defaultOnlineMeetingProvider: $defaultOnlineMeetingProvider, hexColor: $hexColor, isDefaultCalendar: $isDefaultCalendar, isRemovable: $isRemovable, isTallyingResponses: $isTallyingResponses, name: $name, owner: $owner, calendarPermissions: $calendarPermissions, calendarView: $calendarView, events: $events, multiValueExtendedProperties: $multiValueExtendedProperties, singleValueExtendedProperties: $singleValueExtendedProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property calendars for users
#
# DELETE /users/{user-id}/calendars/{calendar-id}
# operationId: user_DeleteCalendar
export def "users-calendars DeleteCalendar" [
  user_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get calendarPermissions from users
#
# GET /users/{user-id}/calendars/{calendar-id}/calendarPermissions
# operationId: user.calendar_ListCalendarPermission
export def "users-calendars-calendar-permissions ListCalendarPermission" [
  user_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/calendarPermissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to calendarPermissions for users
#
# POST /users/{user-id}/calendars/{calendar-id}/calendarPermissions
# operationId: user.calendar_CreateCalendarPermission
# --emailAddress shape: {address?: string, name?: string}
export def "users-calendars-calendar-permissions CreateCalendarPermission" [
  user_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --allowedRoles: list # List of allowed sharing or delegating permission levels for the calendar. The possible values are: none, freeBusyRead, limitedRead, read, write, delegateWithoutPrivateEventAccess, delegateWithPrivateEventAccess, custom.
  --emailAddress: record # shape: {address?: string, name?: string}
  --isInsideOrganization: oneof<nothing, bool> # True if the user in context (recipient or delegate) is inside the same organization as the calendar owner. (nullable)
  --isRemovable: oneof<nothing, bool> # True if the user can be removed from the list of recipients or delegates for the specified calendar, false otherwise. The 'My organization' user determines the permissions other people within your organization have to the given calendar. You can't remove 'My organization' as a share recipient to a calendar. (nullable)
  --role: string@role-completer
]: any -> record<id: string, allowedRoles: list<string>, emailAddress: record<address: string, name: string>, isInsideOrganization: bool, isRemovable: bool, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/calendarPermissions")
  let body = {id: $id, allowedRoles: $allowedRoles, emailAddress: $emailAddress, isInsideOrganization: $isInsideOrganization, isRemovable: $isRemovable, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get calendarPermissions from users
#
# GET /users/{user-id}/calendars/{calendar-id}/calendarPermissions/{calendarPermission-id}
# operationId: user.calendar_GetCalendarPermission
export def "users-calendars-calendar-permissions GetCalendarPermission" [
  user_id: string
  calendar_id: string
  calendarPermission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, allowedRoles: list<string>, emailAddress: record<address: string, name: string>, isInsideOrganization: bool, isRemovable: bool, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/calendarPermissions/($calendarPermission_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property calendarPermissions in users
#
# PATCH /users/{user-id}/calendars/{calendar-id}/calendarPermissions/{calendarPermission-id}
# operationId: user.calendar_UpdateCalendarPermission
# --emailAddress shape: {address?: string, name?: string}
export def "users-calendars-calendar-permissions UpdateCalendarPermission" [
  user_id: string
  calendar_id: string
  calendarPermission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --allowedRoles: list # List of allowed sharing or delegating permission levels for the calendar. The possible values are: none, freeBusyRead, limitedRead, read, write, delegateWithoutPrivateEventAccess, delegateWithPrivateEventAccess, custom.
  --emailAddress: record # shape: {address?: string, name?: string}
  --isInsideOrganization: oneof<nothing, bool> # True if the user in context (recipient or delegate) is inside the same organization as the calendar owner. (nullable)
  --isRemovable: oneof<nothing, bool> # True if the user can be removed from the list of recipients or delegates for the specified calendar, false otherwise. The 'My organization' user determines the permissions other people within your organization have to the given calendar. You can't remove 'My organization' as a share recipient to a calendar. (nullable)
  --role: string@role-completer
]: any -> record<id: string, allowedRoles: list<string>, emailAddress: record<address: string, name: string>, isInsideOrganization: bool, isRemovable: bool, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/calendarPermissions/($calendarPermission_id)")
  let body = {id: $id, allowedRoles: $allowedRoles, emailAddress: $emailAddress, isInsideOrganization: $isInsideOrganization, isRemovable: $isRemovable, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property calendarPermissions for users
#
# DELETE /users/{user-id}/calendars/{calendar-id}/calendarPermissions/{calendarPermission-id}
# operationId: user.calendar_DeleteCalendarPermission
export def "users-calendars-calendar-permissions DeleteCalendarPermission" [
  user_id: string
  calendar_id: string
  calendarPermission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/calendarPermissions/($calendarPermission_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /users/{user-id}/calendars/{calendar-id}/calendarPermissions/$count
# operationId: user.calendar.calendarPermission_GetCount
export def "users-calendars-calendar-permissions-count GetCount" [
  user_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/calendarPermissions/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get calendarView from users
#
# GET /users/{user-id}/calendars/{calendar-id}/calendarView
# operationId: user.calendar_ListCalendarView
export def "users-calendars-calendar-view ListCalendarView" [
  user_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T19:00:00-08:00
  --endDateTime: string # The end date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/calendarView" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function delta
#
# GET /users/{user-id}/calendars/{calendar-id}/calendarView/microsoft.graph.delta()
# Docs: https://learn.microsoft.com/graph/api/event-delta?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar.calendarView_delta
export def "users-calendars-calendar-view-microsoftgraphdelta delta" [
  user_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --endDateTime: string # The end date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: record, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, _odata_nextLink: string, _odata_deltaLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/calendarView/microsoft.graph.delta()" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get events from users
#
# GET /users/{user-id}/calendars/{calendar-id}/events
# operationId: user.calendar_ListEvent
export def "users-calendars-events ListEvent" [
  user_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to events for users
#
# POST /users/{user-id}/calendars/{calendar-id}/events
# operationId: user.calendar_CreateEvent
# --attendees item shape: {proposedNewTime?: record, status?: record}
# --body shape: {content?: string, contentType?: "text"|"html"}
# --end shape: {dateTime?: string, timeZone?: string}
# --location shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --locations item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --onlineMeeting shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
# --organizer shape: {emailAddress?: record}
# --recurrence shape: {pattern?: record, range?: record}
# --responseStatus shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
# --start shape: {dateTime?: string, timeZone?: string}
# --attachments item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
# --exceptionOccurrences item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --extensions item shape: {id?: string}
# --instances item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --multiValueExtendedProperties item shape: {id?: string, value?: list}
# --singleValueExtendedProperties item shape: {id?: string, value?: string}
export def "users-calendars-events CreateEvent" [
  user_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowNewTimeProposals: oneof<nothing, bool> # true if the meeting organizer allows invitees to propose a new time when responding; otherwise, false. Optional. The default is true. (nullable)
  --attendees: list # The collection of attendees for the event. — item shape: {proposedNewTime?: record, status?: record}
  --body-body: record # shape: {content?: string, contentType?: "text"|"html"}
  --bodyPreview: string # The preview of the message associated with the event. It's in text format. (nullable)
  --cancelledOccurrences: list # Contains occurrenceId property values of canceled instances in a recurring series, if the event is the series master. Instances in a recurring series that are canceled are called canceled occurences.Requires $select to retrieve. Only returned in a Get operation that specifies the ID (seriesMasterId property value) of a series master event.
  --end: record # shape: {dateTime?: string, timeZone?: string}
  --hasAttachments: oneof<nothing, bool> # Set to true if the event has attachments. (nullable)
  --hideAttendees: oneof<nothing, bool> # When set to true, each attendee only sees themselves in the meeting request and meeting Tracking list. The default is false. (nullable)
  --iCalUId: string # A unique identifier for an event across calendars. This ID is different for each occurrence in a recurring series. Read-only. (nullable)
  --importance: string@importance-completer
  --isAllDay: oneof<nothing, bool> # Set to true if the event lasts all day. If true, regardless of whether it's a single-day or multi-day event, start, and endtime must be set to midnight and be in the same time zone. (nullable)
  --isCancelled: oneof<nothing, bool> # Set to true if the event has been canceled. (nullable)
  --isDraft: oneof<nothing, bool> # Set to true if the user has updated the meeting in Outlook but hasn't sent the updates to attendees. Set to false if all changes are sent, or if the event is an appointment without any attendees. (nullable)
  --isOnlineMeeting: oneof<nothing, bool> # True if this event has online meeting information (that is, onlineMeeting points to an onlineMeetingInfo resource), false otherwise. Default is false (onlineMeeting is null). Optional.  After you set isOnlineMeeting to true, Microsoft Graph initializes onlineMeeting. Subsequently, Outlook ignores any further changes to isOnlineMeeting, and the meeting remains available online. (nullable)
  --isOrganizer: oneof<nothing, bool> # Set to true if the calendar owner (specified by the owner property of the calendar) is the organizer of the event (specified by the organizer property of the event). It also applies if a delegate organized the event on behalf of the owner. (nullable)
  --isReminderOn: oneof<nothing, bool> # Set to true if an alert is set to remind the user of the event. (nullable)
  --location: record # shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --locations: list # The locations where the event is held or attended from. The location and locations properties always correspond with each other. If you update the location property, any prior locations in the locations collection are removed and replaced by the new location value. — item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --onlineMeeting: record # shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
  --onlineMeetingProvider: string@onlineMeetingProvider-completer
  --onlineMeetingUrl: string # A URL for an online meeting. The property is set only when an organizer specifies in Outlook that an event is an online meeting such as Skype. Read-only.To access the URL to join an online meeting, use joinUrl which is exposed via the onlineMeeting property of the event. The onlineMeetingUrl property will be deprecated in the future. (nullable)
  --organizer: record # shape: {emailAddress?: record}
  --originalEndTimeZone: string # The end time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --originalStart: string # Represents the start time of an event when it's initially created as an occurrence or exception in a recurring series. This property is not returned for events that are single instances. Its date and time information is expressed in ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --originalStartTimeZone: string # The start time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --recurrence: record # shape: {pattern?: record, range?: record}
  --reminderMinutesBeforeStart: float # The number of minutes before the event start time that the reminder alert occurs. (nullable, format: int32)
  --responseRequested: oneof<nothing, bool> # Default is true, which represents the organizer would like an invitee to send a response to the event. (nullable)
  --responseStatus: record # shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
  --sensitivity: string@sensitivity-completer
  --seriesMasterId: string # The ID for the recurring series master item, if this event is part of a recurring series. (nullable)
  --showAs: string@showAs-completer
  --start: record # shape: {dateTime?: string, timeZone?: string}
  --subject: string # The text of the event's subject line. (nullable)
  --transactionId: string # A custom identifier specified by a client app for the server to avoid redundant POST operations in case of client retries to create the same event. It's useful when low network connectivity causes the client to time out before receiving a response from the server for the client's prior create-event request. After you set transactionId when creating an event, you can't change transactionId in a subsequent update. This property is only returned in a response payload if an app has set it. Optional. (nullable)
  --type: string@type-completer
  --webLink: string # The URL to open the event in Outlook on the web.Outlook on the web opens the event in the browser if you are signed in to your mailbox. Otherwise, Outlook on the web prompts you to sign in.This URL can't be accessed from within an iFrame. (nullable)
  --attachments: list # The collection of FileAttachment, ItemAttachment, and referenceAttachment attachments for the event. Navigation property. Read-only. Nullable. — item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
  --calendar: any
  --exceptionOccurrences: list # Contains the id property values of the event instances that are exceptions in a recurring series.Exceptions can differ from other occurrences in a recurring series, such as the subject, start or end times, or attendees. Exceptions don't include canceled occurrences.Requires $select and $expand to retrieve. Only returned in a GET operation that specifies the ID (seriesMasterId property value) of a series master event. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --extensions: list # The collection of open extensions defined for the event. Nullable. — item shape: {id?: string}
  --instances: list # The occurrences of a recurring series, if the event is a series master. This property includes occurrences that are part of the recurrence pattern, and exceptions modified, but doesn't include occurrences canceled from the series. Navigation property. Read-only. Nullable. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --multiValueExtendedProperties: list # The collection of multi-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: list}
  --singleValueExtendedProperties: list # The collection of single-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: string}
]: any -> record<allowNewTimeProposals: bool, attendees: table<proposedNewTime: record, status: record>, body: record<content: string, contentType: string>, bodyPreview: string, cancelledOccurrences: list<string>, end: record<dateTime: string, timeZone: string>, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, locations: table<address: record, coordinates: record, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, onlineMeeting: record<conferenceId: string, joinUrl: string, phones: list<record>, quickDial: string, tollFreeNumbers: list<string>, tollNumber: string>, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record<emailAddress: record<address: string, name: string>>, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record<pattern: record<dayOfMonth: float, daysOfWeek: list, firstDayOfWeek: string, index: string, interval: float, month: float, type: string>, range: record<endDate: string, numberOfOccurrences: float, recurrenceTimeZone: string, startDate: string, type: string>>, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record<response: string, time: string>, sensitivity: string, seriesMasterId: string, showAs: string, start: record<dateTime: string, timeZone: string>, subject: string, transactionId: string, type: string, webLink: string, attachments: table<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float>, calendar: record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: list<record>, calendarView: list<any>, events: list<any>, multiValueExtendedProperties: list<record>, singleValueExtendedProperties: list<record>>, exceptionOccurrences: list<any>, extensions: table<id: string>, instances: list<any>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events")
  let body = {allowNewTimeProposals: $allowNewTimeProposals, attendees: $attendees, body: $body_body, bodyPreview: $bodyPreview, cancelledOccurrences: $cancelledOccurrences, end: $end, hasAttachments: $hasAttachments, hideAttendees: $hideAttendees, iCalUId: $iCalUId, importance: $importance, isAllDay: $isAllDay, isCancelled: $isCancelled, isDraft: $isDraft, isOnlineMeeting: $isOnlineMeeting, isOrganizer: $isOrganizer, isReminderOn: $isReminderOn, location: $location, locations: $locations, onlineMeeting: $onlineMeeting, onlineMeetingProvider: $onlineMeetingProvider, onlineMeetingUrl: $onlineMeetingUrl, organizer: $organizer, originalEndTimeZone: $originalEndTimeZone, originalStart: $originalStart, originalStartTimeZone: $originalStartTimeZone, recurrence: $recurrence, reminderMinutesBeforeStart: $reminderMinutesBeforeStart, responseRequested: $responseRequested, responseStatus: $responseStatus, sensitivity: $sensitivity, seriesMasterId: $seriesMasterId, showAs: $showAs, start: $start, subject: $subject, transactionId: $transactionId, type: $type, webLink: $webLink, attachments: $attachments, calendar: $calendar, exceptionOccurrences: $exceptionOccurrences, extensions: $extensions, instances: $instances, multiValueExtendedProperties: $multiValueExtendedProperties, singleValueExtendedProperties: $singleValueExtendedProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get events from users
#
# GET /users/{user-id}/calendars/{calendar-id}/events/{event-id}
# operationId: user.calendar_GetEvent
export def "users-calendars-events GetEvent" [
  user_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<allowNewTimeProposals: bool, attendees: table<proposedNewTime: record, status: record>, body: record<content: string, contentType: string>, bodyPreview: string, cancelledOccurrences: list<string>, end: record<dateTime: string, timeZone: string>, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, locations: table<address: record, coordinates: record, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, onlineMeeting: record<conferenceId: string, joinUrl: string, phones: list<record>, quickDial: string, tollFreeNumbers: list<string>, tollNumber: string>, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record<emailAddress: record<address: string, name: string>>, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record<pattern: record<dayOfMonth: float, daysOfWeek: list, firstDayOfWeek: string, index: string, interval: float, month: float, type: string>, range: record<endDate: string, numberOfOccurrences: float, recurrenceTimeZone: string, startDate: string, type: string>>, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record<response: string, time: string>, sensitivity: string, seriesMasterId: string, showAs: string, start: record<dateTime: string, timeZone: string>, subject: string, transactionId: string, type: string, webLink: string, attachments: table<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float>, calendar: record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: list<record>, calendarView: list<any>, events: list<any>, multiValueExtendedProperties: list<record>, singleValueExtendedProperties: list<record>>, exceptionOccurrences: list<any>, extensions: table<id: string>, instances: list<any>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property events in users
#
# PATCH /users/{user-id}/calendars/{calendar-id}/events/{event-id}
# operationId: user.calendar_UpdateEvent
# --attendees item shape: {proposedNewTime?: record, status?: record}
# --body shape: {content?: string, contentType?: "text"|"html"}
# --end shape: {dateTime?: string, timeZone?: string}
# --location shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --locations item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --onlineMeeting shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
# --organizer shape: {emailAddress?: record}
# --recurrence shape: {pattern?: record, range?: record}
# --responseStatus shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
# --start shape: {dateTime?: string, timeZone?: string}
# --attachments item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
# --exceptionOccurrences item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --extensions item shape: {id?: string}
# --instances item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --multiValueExtendedProperties item shape: {id?: string, value?: list}
# --singleValueExtendedProperties item shape: {id?: string, value?: string}
export def "users-calendars-events UpdateEvent" [
  user_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowNewTimeProposals: oneof<nothing, bool> # true if the meeting organizer allows invitees to propose a new time when responding; otherwise, false. Optional. The default is true. (nullable)
  --attendees: list # The collection of attendees for the event. — item shape: {proposedNewTime?: record, status?: record}
  --body-body: record # shape: {content?: string, contentType?: "text"|"html"}
  --bodyPreview: string # The preview of the message associated with the event. It's in text format. (nullable)
  --cancelledOccurrences: list # Contains occurrenceId property values of canceled instances in a recurring series, if the event is the series master. Instances in a recurring series that are canceled are called canceled occurences.Requires $select to retrieve. Only returned in a Get operation that specifies the ID (seriesMasterId property value) of a series master event.
  --end: record # shape: {dateTime?: string, timeZone?: string}
  --hasAttachments: oneof<nothing, bool> # Set to true if the event has attachments. (nullable)
  --hideAttendees: oneof<nothing, bool> # When set to true, each attendee only sees themselves in the meeting request and meeting Tracking list. The default is false. (nullable)
  --iCalUId: string # A unique identifier for an event across calendars. This ID is different for each occurrence in a recurring series. Read-only. (nullable)
  --importance: string@importance-completer
  --isAllDay: oneof<nothing, bool> # Set to true if the event lasts all day. If true, regardless of whether it's a single-day or multi-day event, start, and endtime must be set to midnight and be in the same time zone. (nullable)
  --isCancelled: oneof<nothing, bool> # Set to true if the event has been canceled. (nullable)
  --isDraft: oneof<nothing, bool> # Set to true if the user has updated the meeting in Outlook but hasn't sent the updates to attendees. Set to false if all changes are sent, or if the event is an appointment without any attendees. (nullable)
  --isOnlineMeeting: oneof<nothing, bool> # True if this event has online meeting information (that is, onlineMeeting points to an onlineMeetingInfo resource), false otherwise. Default is false (onlineMeeting is null). Optional.  After you set isOnlineMeeting to true, Microsoft Graph initializes onlineMeeting. Subsequently, Outlook ignores any further changes to isOnlineMeeting, and the meeting remains available online. (nullable)
  --isOrganizer: oneof<nothing, bool> # Set to true if the calendar owner (specified by the owner property of the calendar) is the organizer of the event (specified by the organizer property of the event). It also applies if a delegate organized the event on behalf of the owner. (nullable)
  --isReminderOn: oneof<nothing, bool> # Set to true if an alert is set to remind the user of the event. (nullable)
  --location: record # shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --locations: list # The locations where the event is held or attended from. The location and locations properties always correspond with each other. If you update the location property, any prior locations in the locations collection are removed and replaced by the new location value. — item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --onlineMeeting: record # shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
  --onlineMeetingProvider: string@onlineMeetingProvider-completer
  --onlineMeetingUrl: string # A URL for an online meeting. The property is set only when an organizer specifies in Outlook that an event is an online meeting such as Skype. Read-only.To access the URL to join an online meeting, use joinUrl which is exposed via the onlineMeeting property of the event. The onlineMeetingUrl property will be deprecated in the future. (nullable)
  --organizer: record # shape: {emailAddress?: record}
  --originalEndTimeZone: string # The end time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --originalStart: string # Represents the start time of an event when it's initially created as an occurrence or exception in a recurring series. This property is not returned for events that are single instances. Its date and time information is expressed in ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --originalStartTimeZone: string # The start time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --recurrence: record # shape: {pattern?: record, range?: record}
  --reminderMinutesBeforeStart: float # The number of minutes before the event start time that the reminder alert occurs. (nullable, format: int32)
  --responseRequested: oneof<nothing, bool> # Default is true, which represents the organizer would like an invitee to send a response to the event. (nullable)
  --responseStatus: record # shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
  --sensitivity: string@sensitivity-completer
  --seriesMasterId: string # The ID for the recurring series master item, if this event is part of a recurring series. (nullable)
  --showAs: string@showAs-completer
  --start: record # shape: {dateTime?: string, timeZone?: string}
  --subject: string # The text of the event's subject line. (nullable)
  --transactionId: string # A custom identifier specified by a client app for the server to avoid redundant POST operations in case of client retries to create the same event. It's useful when low network connectivity causes the client to time out before receiving a response from the server for the client's prior create-event request. After you set transactionId when creating an event, you can't change transactionId in a subsequent update. This property is only returned in a response payload if an app has set it. Optional. (nullable)
  --type: string@type-completer
  --webLink: string # The URL to open the event in Outlook on the web.Outlook on the web opens the event in the browser if you are signed in to your mailbox. Otherwise, Outlook on the web prompts you to sign in.This URL can't be accessed from within an iFrame. (nullable)
  --attachments: list # The collection of FileAttachment, ItemAttachment, and referenceAttachment attachments for the event. Navigation property. Read-only. Nullable. — item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
  --calendar: any
  --exceptionOccurrences: list # Contains the id property values of the event instances that are exceptions in a recurring series.Exceptions can differ from other occurrences in a recurring series, such as the subject, start or end times, or attendees. Exceptions don't include canceled occurrences.Requires $select and $expand to retrieve. Only returned in a GET operation that specifies the ID (seriesMasterId property value) of a series master event. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --extensions: list # The collection of open extensions defined for the event. Nullable. — item shape: {id?: string}
  --instances: list # The occurrences of a recurring series, if the event is a series master. This property includes occurrences that are part of the recurrence pattern, and exceptions modified, but doesn't include occurrences canceled from the series. Navigation property. Read-only. Nullable. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --multiValueExtendedProperties: list # The collection of multi-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: list}
  --singleValueExtendedProperties: list # The collection of single-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: string}
]: any -> record<allowNewTimeProposals: bool, attendees: table<proposedNewTime: record, status: record>, body: record<content: string, contentType: string>, bodyPreview: string, cancelledOccurrences: list<string>, end: record<dateTime: string, timeZone: string>, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, locations: table<address: record, coordinates: record, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, onlineMeeting: record<conferenceId: string, joinUrl: string, phones: list<record>, quickDial: string, tollFreeNumbers: list<string>, tollNumber: string>, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record<emailAddress: record<address: string, name: string>>, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record<pattern: record<dayOfMonth: float, daysOfWeek: list, firstDayOfWeek: string, index: string, interval: float, month: float, type: string>, range: record<endDate: string, numberOfOccurrences: float, recurrenceTimeZone: string, startDate: string, type: string>>, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record<response: string, time: string>, sensitivity: string, seriesMasterId: string, showAs: string, start: record<dateTime: string, timeZone: string>, subject: string, transactionId: string, type: string, webLink: string, attachments: table<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float>, calendar: record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: list<record>, calendarView: list<any>, events: list<any>, multiValueExtendedProperties: list<record>, singleValueExtendedProperties: list<record>>, exceptionOccurrences: list<any>, extensions: table<id: string>, instances: list<any>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)")
  let body = {allowNewTimeProposals: $allowNewTimeProposals, attendees: $attendees, body: $body_body, bodyPreview: $bodyPreview, cancelledOccurrences: $cancelledOccurrences, end: $end, hasAttachments: $hasAttachments, hideAttendees: $hideAttendees, iCalUId: $iCalUId, importance: $importance, isAllDay: $isAllDay, isCancelled: $isCancelled, isDraft: $isDraft, isOnlineMeeting: $isOnlineMeeting, isOrganizer: $isOrganizer, isReminderOn: $isReminderOn, location: $location, locations: $locations, onlineMeeting: $onlineMeeting, onlineMeetingProvider: $onlineMeetingProvider, onlineMeetingUrl: $onlineMeetingUrl, organizer: $organizer, originalEndTimeZone: $originalEndTimeZone, originalStart: $originalStart, originalStartTimeZone: $originalStartTimeZone, recurrence: $recurrence, reminderMinutesBeforeStart: $reminderMinutesBeforeStart, responseRequested: $responseRequested, responseStatus: $responseStatus, sensitivity: $sensitivity, seriesMasterId: $seriesMasterId, showAs: $showAs, start: $start, subject: $subject, transactionId: $transactionId, type: $type, webLink: $webLink, attachments: $attachments, calendar: $calendar, exceptionOccurrences: $exceptionOccurrences, extensions: $extensions, instances: $instances, multiValueExtendedProperties: $multiValueExtendedProperties, singleValueExtendedProperties: $singleValueExtendedProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property events for users
#
# DELETE /users/{user-id}/calendars/{calendar-id}/events/{event-id}
# operationId: user.calendar_DeleteEvent
export def "users-calendars-events DeleteEvent" [
  user_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get attachments from users
#
# GET /users/{user-id}/calendars/{calendar-id}/events/{event-id}/attachments
# operationId: user.calendar.event_ListAttachment
export def "users-calendars-events-attachments ListAttachment" [
  user_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/attachments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to attachments for users
#
# POST /users/{user-id}/calendars/{calendar-id}/events/{event-id}/attachments
# operationId: user.calendar.event_CreateAttachment
export def "users-calendars-events-attachments CreateAttachment" [
  user_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --contentType: string # The MIME type. (nullable)
  --isInline: oneof<nothing, bool> # true if the attachment is an inline attachment; otherwise, false.
  --lastModifiedDateTime: string # The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --name: string # The attachment's file name. (nullable)
  --size: float # The length of the attachment in bytes. (format: int32)
]: any -> record<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/attachments")
  let body = {id: $id, contentType: $contentType, isInline: $isInline, lastModifiedDateTime: $lastModifiedDateTime, name: $name, size: $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get attachments from users
#
# GET /users/{user-id}/calendars/{calendar-id}/events/{event-id}/attachments/{attachment-id}
# operationId: user.calendar.event_GetAttachment
export def "users-calendars-events-attachments GetAttachment" [
  user_id: string
  calendar_id: string
  event_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/attachments/($attachment_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete navigation property attachments for users
#
# DELETE /users/{user-id}/calendars/{calendar-id}/events/{event-id}/attachments/{attachment-id}
# operationId: user.calendar.event_DeleteAttachment
export def "users-calendars-events-attachments DeleteAttachment" [
  user_id: string
  calendar_id: string
  event_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/attachments/($attachment_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /users/{user-id}/calendars/{calendar-id}/events/{event-id}/attachments/$count
# operationId: user.calendar.event.attachment_GetCount
export def "users-calendars-events-attachments-count GetCount" [
  user_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/attachments/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action createUploadSession
#
# POST /users/{user-id}/calendars/{calendar-id}/events/{event-id}/attachments/microsoft.graph.createUploadSession
# Docs: https://learn.microsoft.com/graph/api/attachment-createuploadsession?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar.event.attachment_createUploadSession
# --AttachmentItem shape: {attachmentType?: "file"|"item"|"reference", contentId?: string, contentType?: string, isInline?: bool, name?: string, size?: float}
export def "users-calendars-events-attachments-microsoftgraphcreate-upload-session createUploadSession" [
  user_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AttachmentItem: record # shape: {attachmentType?: "file"|"item"|"reference", contentId?: string, contentType?: string, isInline?: bool, name?: string, size?: float}
]: any -> record<expirationDateTime: string, nextExpectedRanges: list<string>, uploadUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/attachments/microsoft.graph.createUploadSession")
  let body = {AttachmentItem: $AttachmentItem} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get calendar from users
#
# GET /users/{user-id}/calendars/{calendar-id}/events/{event-id}/calendar
# operationId: user.calendar.event_GetCalendar
export def "users-calendars-events-calendar GetCalendar" [
  user_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: table<id: string, allowedRoles: list, emailAddress: record, isInsideOrganization: bool, isRemovable: bool, role: string>, calendarView: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, events: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/calendar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get extensions from users
#
# GET /users/{user-id}/calendars/{calendar-id}/events/{event-id}/extensions
# operationId: user.calendar.event_ListExtension
export def "users-calendars-events-extensions ListExtension" [
  user_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/extensions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to extensions for users
#
# POST /users/{user-id}/calendars/{calendar-id}/events/{event-id}/extensions
# operationId: user.calendar.event_CreateExtension
export def "users-calendars-events-extensions CreateExtension" [
  user_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/extensions")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get extensions from users
#
# GET /users/{user-id}/calendars/{calendar-id}/events/{event-id}/extensions/{extension-id}
# operationId: user.calendar.event_GetExtension
export def "users-calendars-events-extensions GetExtension" [
  user_id: string
  calendar_id: string
  event_id: string
  extension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/extensions/($extension_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property extensions in users
#
# PATCH /users/{user-id}/calendars/{calendar-id}/events/{event-id}/extensions/{extension-id}
# operationId: user.calendar.event_UpdateExtension
export def "users-calendars-events-extensions UpdateExtension" [
  user_id: string
  calendar_id: string
  event_id: string
  extension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/extensions/($extension_id)")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property extensions for users
#
# DELETE /users/{user-id}/calendars/{calendar-id}/events/{event-id}/extensions/{extension-id}
# operationId: user.calendar.event_DeleteExtension
export def "users-calendars-events-extensions DeleteExtension" [
  user_id: string
  calendar_id: string
  event_id: string
  extension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/extensions/($extension_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /users/{user-id}/calendars/{calendar-id}/events/{event-id}/extensions/$count
# operationId: user.calendar.event.extension_GetCount
export def "users-calendars-events-extensions-count GetCount" [
  user_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/extensions/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get instances from users
#
# GET /users/{user-id}/calendars/{calendar-id}/events/{event-id}/instances
# operationId: user.calendar.event_ListInstance
export def "users-calendars-events-instances ListInstance" [
  user_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T19:00:00-08:00
  --endDateTime: string # The end date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/instances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function delta
#
# GET /users/{user-id}/calendars/{calendar-id}/events/{event-id}/instances/microsoft.graph.delta()
# Docs: https://learn.microsoft.com/graph/api/event-delta?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar.event.instance_delta
export def "users-calendars-events-instances-microsoftgraphdelta delta" [
  user_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --endDateTime: string # The end date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: record, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, _odata_nextLink: string, _odata_deltaLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/instances/microsoft.graph.delta()" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action accept
#
# POST /users/{user-id}/calendars/{calendar-id}/events/{event-id}/microsoft.graph.accept
# Docs: https://learn.microsoft.com/graph/api/event-accept?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar.event_accept
export def "users-calendars-events-microsoftgraphaccept accept" [
  user_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --SendResponse: oneof<nothing, bool> # nullable, default: false
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/microsoft.graph.accept")
  let body = {SendResponse: $SendResponse, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action cancel
#
# POST /users/{user-id}/calendars/{calendar-id}/events/{event-id}/microsoft.graph.cancel
# Docs: https://learn.microsoft.com/graph/api/event-cancel?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar.event_cancel
export def "users-calendars-events-microsoftgraphcancel cancel" [
  user_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/microsoft.graph.cancel")
  let body = {Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action decline
#
# POST /users/{user-id}/calendars/{calendar-id}/events/{event-id}/microsoft.graph.decline
# Docs: https://learn.microsoft.com/graph/api/event-decline?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar.event_decline
# --ProposedNewTime shape: {end?: record, start?: record}
export def "users-calendars-events-microsoftgraphdecline decline" [
  user_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ProposedNewTime: record # shape: {end?: record, start?: record}
  --SendResponse: oneof<nothing, bool> # nullable, default: false
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/microsoft.graph.decline")
  let body = {ProposedNewTime: $ProposedNewTime, SendResponse: $SendResponse, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action dismissReminder
#
# POST /users/{user-id}/calendars/{calendar-id}/events/{event-id}/microsoft.graph.dismissReminder
# Docs: https://learn.microsoft.com/graph/api/event-dismissreminder?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar.event_dismissReminder
export def "users-calendars-events-microsoftgraphdismiss-reminder dismissReminder" [
  user_id: string
  calendar_id: string
  event_id: string
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
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/microsoft.graph.dismissReminder")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action forward
#
# POST /users/{user-id}/calendars/{calendar-id}/events/{event-id}/microsoft.graph.forward
# Docs: https://learn.microsoft.com/graph/api/event-forward?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar.event_forward
# --ToRecipients item shape: {emailAddress?: record}
export def "users-calendars-events-microsoftgraphforward forward" [
  user_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ToRecipients: list # item shape: {emailAddress?: record}
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/microsoft.graph.forward")
  let body = {ToRecipients: $ToRecipients, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action permanentDelete
#
# POST /users/{user-id}/calendars/{calendar-id}/events/{event-id}/microsoft.graph.permanentDelete
# operationId: user.calendar.event_permanentDelete
export def "users-calendars-events-microsoftgraphpermanent-delete permanentDelete" [
  user_id: string
  calendar_id: string
  event_id: string
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
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/microsoft.graph.permanentDelete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action snoozeReminder
#
# POST /users/{user-id}/calendars/{calendar-id}/events/{event-id}/microsoft.graph.snoozeReminder
# Docs: https://learn.microsoft.com/graph/api/event-snoozereminder?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar.event_snoozeReminder
# --NewReminderTime shape: {dateTime?: string, timeZone?: string}
export def "users-calendars-events-microsoftgraphsnooze-reminder snoozeReminder" [
  user_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --NewReminderTime: record # shape: {dateTime?: string, timeZone?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/microsoft.graph.snoozeReminder")
  let body = {NewReminderTime: $NewReminderTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action tentativelyAccept
#
# POST /users/{user-id}/calendars/{calendar-id}/events/{event-id}/microsoft.graph.tentativelyAccept
# Docs: https://learn.microsoft.com/graph/api/event-tentativelyaccept?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar.event_tentativelyAccept
# --ProposedNewTime shape: {end?: record, start?: record}
export def "users-calendars-events-microsoftgraphtentatively-accept tentativelyAccept" [
  user_id: string
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ProposedNewTime: record # shape: {end?: record, start?: record}
  --SendResponse: oneof<nothing, bool> # nullable, default: false
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/($event_id)/microsoft.graph.tentativelyAccept")
  let body = {ProposedNewTime: $ProposedNewTime, SendResponse: $SendResponse, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the number of the resource
#
# GET /users/{user-id}/calendars/{calendar-id}/events/$count
# operationId: user.calendar.event_GetCount
export def "users-calendars-events-count GetCount" [
  user_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function delta
#
# GET /users/{user-id}/calendars/{calendar-id}/events/microsoft.graph.delta()
# Docs: https://learn.microsoft.com/graph/api/event-delta?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar.event_delta
export def "users-calendars-events-microsoftgraphdelta delta" [
  user_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --endDateTime: string # The end date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: record, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, _odata_nextLink: string, _odata_deltaLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/events/microsoft.graph.delta()" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function allowedCalendarSharingRoles
#
# GET /users/{user-id}/calendars/{calendar-id}/microsoft.graph.allowedCalendarSharingRoles(User='{User}')
# operationId: user.calendar_allowedCalendarSharingRole
export def "users-calendars-microsoftgraphallowed-calendar-sharing-roles-user-user allowedCalendarSharingRole" [
  user_id: string
  calendar_id: string
  User: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
]: nothing -> record<value: list<string>, _odata_nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/microsoft.graph.allowedCalendarSharingRoles(User='($User)')" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action getSchedule
#
# POST /users/{user-id}/calendars/{calendar-id}/microsoft.graph.getSchedule
# Docs: https://learn.microsoft.com/graph/api/calendar-getschedule?view=graph-rest-1.0 — Find more info here
# operationId: user.calendar_getSchedule
# --EndTime shape: {dateTime?: string, timeZone?: string}
# --StartTime shape: {dateTime?: string, timeZone?: string}
export def "users-calendars-microsoftgraphget-schedule post" [
  user_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Schedules: list
  --EndTime: record # shape: {dateTime?: string, timeZone?: string}
  --StartTime: record # shape: {dateTime?: string, timeZone?: string}
  --AvailabilityViewInterval: float # nullable, format: int32
]: any -> record<value: table<availabilityView: string, error: record, scheduleId: string, scheduleItems: list, workingHours: record>, _odata_nextLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/microsoft.graph.getSchedule")
  let body = {Schedules: $Schedules, EndTime: $EndTime, StartTime: $StartTime, AvailabilityViewInterval: $AvailabilityViewInterval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action permanentDelete
#
# POST /users/{user-id}/calendars/{calendar-id}/microsoft.graph.permanentDelete
# operationId: user.calendar_permanentDelete
export def "users-calendars-microsoftgraphpermanent-delete permanentDelete" [
  user_id: string
  calendar_id: string
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
  let full_url = (build-url $base $"/users/($user_id)/calendars/($calendar_id)/microsoft.graph.permanentDelete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /users/{user-id}/calendars/$count
# operationId: user.calendar_GetCount
export def "users-calendars-count GetCount" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendars/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get calendarView from users
#
# GET /users/{user-id}/calendarView
# operationId: user_ListCalendarView
export def "users-calendar-view ListCalendarView" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T19:00:00-08:00
  --endDateTime: string # The end date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarView" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function delta
#
# GET /users/{user-id}/calendarView/microsoft.graph.delta()
# Docs: https://learn.microsoft.com/graph/api/event-delta?view=graph-rest-1.0 — Find more info here
# operationId: user.calendarView_delta
export def "users-calendar-view-microsoftgraphdelta delta" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --endDateTime: string # The end date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: record, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, _odata_nextLink: string, _odata_deltaLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/calendarView/microsoft.graph.delta()" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get events from users
#
# GET /users/{user-id}/events
# operationId: user_ListEvent
export def "users-events ListEvent" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to events for users
#
# POST /users/{user-id}/events
# operationId: user_CreateEvent
# --attendees item shape: {proposedNewTime?: record, status?: record}
# --body shape: {content?: string, contentType?: "text"|"html"}
# --end shape: {dateTime?: string, timeZone?: string}
# --location shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --locations item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --onlineMeeting shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
# --organizer shape: {emailAddress?: record}
# --recurrence shape: {pattern?: record, range?: record}
# --responseStatus shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
# --start shape: {dateTime?: string, timeZone?: string}
# --attachments item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
# --exceptionOccurrences item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --extensions item shape: {id?: string}
# --instances item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --multiValueExtendedProperties item shape: {id?: string, value?: list}
# --singleValueExtendedProperties item shape: {id?: string, value?: string}
export def "users-events CreateEvent" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowNewTimeProposals: oneof<nothing, bool> # true if the meeting organizer allows invitees to propose a new time when responding; otherwise, false. Optional. The default is true. (nullable)
  --attendees: list # The collection of attendees for the event. — item shape: {proposedNewTime?: record, status?: record}
  --body-body: record # shape: {content?: string, contentType?: "text"|"html"}
  --bodyPreview: string # The preview of the message associated with the event. It's in text format. (nullable)
  --cancelledOccurrences: list # Contains occurrenceId property values of canceled instances in a recurring series, if the event is the series master. Instances in a recurring series that are canceled are called canceled occurences.Requires $select to retrieve. Only returned in a Get operation that specifies the ID (seriesMasterId property value) of a series master event.
  --end: record # shape: {dateTime?: string, timeZone?: string}
  --hasAttachments: oneof<nothing, bool> # Set to true if the event has attachments. (nullable)
  --hideAttendees: oneof<nothing, bool> # When set to true, each attendee only sees themselves in the meeting request and meeting Tracking list. The default is false. (nullable)
  --iCalUId: string # A unique identifier for an event across calendars. This ID is different for each occurrence in a recurring series. Read-only. (nullable)
  --importance: string@importance-completer
  --isAllDay: oneof<nothing, bool> # Set to true if the event lasts all day. If true, regardless of whether it's a single-day or multi-day event, start, and endtime must be set to midnight and be in the same time zone. (nullable)
  --isCancelled: oneof<nothing, bool> # Set to true if the event has been canceled. (nullable)
  --isDraft: oneof<nothing, bool> # Set to true if the user has updated the meeting in Outlook but hasn't sent the updates to attendees. Set to false if all changes are sent, or if the event is an appointment without any attendees. (nullable)
  --isOnlineMeeting: oneof<nothing, bool> # True if this event has online meeting information (that is, onlineMeeting points to an onlineMeetingInfo resource), false otherwise. Default is false (onlineMeeting is null). Optional.  After you set isOnlineMeeting to true, Microsoft Graph initializes onlineMeeting. Subsequently, Outlook ignores any further changes to isOnlineMeeting, and the meeting remains available online. (nullable)
  --isOrganizer: oneof<nothing, bool> # Set to true if the calendar owner (specified by the owner property of the calendar) is the organizer of the event (specified by the organizer property of the event). It also applies if a delegate organized the event on behalf of the owner. (nullable)
  --isReminderOn: oneof<nothing, bool> # Set to true if an alert is set to remind the user of the event. (nullable)
  --location: record # shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --locations: list # The locations where the event is held or attended from. The location and locations properties always correspond with each other. If you update the location property, any prior locations in the locations collection are removed and replaced by the new location value. — item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --onlineMeeting: record # shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
  --onlineMeetingProvider: string@onlineMeetingProvider-completer
  --onlineMeetingUrl: string # A URL for an online meeting. The property is set only when an organizer specifies in Outlook that an event is an online meeting such as Skype. Read-only.To access the URL to join an online meeting, use joinUrl which is exposed via the onlineMeeting property of the event. The onlineMeetingUrl property will be deprecated in the future. (nullable)
  --organizer: record # shape: {emailAddress?: record}
  --originalEndTimeZone: string # The end time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --originalStart: string # Represents the start time of an event when it's initially created as an occurrence or exception in a recurring series. This property is not returned for events that are single instances. Its date and time information is expressed in ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --originalStartTimeZone: string # The start time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --recurrence: record # shape: {pattern?: record, range?: record}
  --reminderMinutesBeforeStart: float # The number of minutes before the event start time that the reminder alert occurs. (nullable, format: int32)
  --responseRequested: oneof<nothing, bool> # Default is true, which represents the organizer would like an invitee to send a response to the event. (nullable)
  --responseStatus: record # shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
  --sensitivity: string@sensitivity-completer
  --seriesMasterId: string # The ID for the recurring series master item, if this event is part of a recurring series. (nullable)
  --showAs: string@showAs-completer
  --start: record # shape: {dateTime?: string, timeZone?: string}
  --subject: string # The text of the event's subject line. (nullable)
  --transactionId: string # A custom identifier specified by a client app for the server to avoid redundant POST operations in case of client retries to create the same event. It's useful when low network connectivity causes the client to time out before receiving a response from the server for the client's prior create-event request. After you set transactionId when creating an event, you can't change transactionId in a subsequent update. This property is only returned in a response payload if an app has set it. Optional. (nullable)
  --type: string@type-completer
  --webLink: string # The URL to open the event in Outlook on the web.Outlook on the web opens the event in the browser if you are signed in to your mailbox. Otherwise, Outlook on the web prompts you to sign in.This URL can't be accessed from within an iFrame. (nullable)
  --attachments: list # The collection of FileAttachment, ItemAttachment, and referenceAttachment attachments for the event. Navigation property. Read-only. Nullable. — item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
  --calendar: any
  --exceptionOccurrences: list # Contains the id property values of the event instances that are exceptions in a recurring series.Exceptions can differ from other occurrences in a recurring series, such as the subject, start or end times, or attendees. Exceptions don't include canceled occurrences.Requires $select and $expand to retrieve. Only returned in a GET operation that specifies the ID (seriesMasterId property value) of a series master event. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --extensions: list # The collection of open extensions defined for the event. Nullable. — item shape: {id?: string}
  --instances: list # The occurrences of a recurring series, if the event is a series master. This property includes occurrences that are part of the recurrence pattern, and exceptions modified, but doesn't include occurrences canceled from the series. Navigation property. Read-only. Nullable. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --multiValueExtendedProperties: list # The collection of multi-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: list}
  --singleValueExtendedProperties: list # The collection of single-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: string}
]: any -> record<allowNewTimeProposals: bool, attendees: table<proposedNewTime: record, status: record>, body: record<content: string, contentType: string>, bodyPreview: string, cancelledOccurrences: list<string>, end: record<dateTime: string, timeZone: string>, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, locations: table<address: record, coordinates: record, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, onlineMeeting: record<conferenceId: string, joinUrl: string, phones: list<record>, quickDial: string, tollFreeNumbers: list<string>, tollNumber: string>, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record<emailAddress: record<address: string, name: string>>, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record<pattern: record<dayOfMonth: float, daysOfWeek: list, firstDayOfWeek: string, index: string, interval: float, month: float, type: string>, range: record<endDate: string, numberOfOccurrences: float, recurrenceTimeZone: string, startDate: string, type: string>>, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record<response: string, time: string>, sensitivity: string, seriesMasterId: string, showAs: string, start: record<dateTime: string, timeZone: string>, subject: string, transactionId: string, type: string, webLink: string, attachments: table<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float>, calendar: record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: list<record>, calendarView: list<any>, events: list<any>, multiValueExtendedProperties: list<record>, singleValueExtendedProperties: list<record>>, exceptionOccurrences: list<any>, extensions: table<id: string>, instances: list<any>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/events")
  let body = {allowNewTimeProposals: $allowNewTimeProposals, attendees: $attendees, body: $body_body, bodyPreview: $bodyPreview, cancelledOccurrences: $cancelledOccurrences, end: $end, hasAttachments: $hasAttachments, hideAttendees: $hideAttendees, iCalUId: $iCalUId, importance: $importance, isAllDay: $isAllDay, isCancelled: $isCancelled, isDraft: $isDraft, isOnlineMeeting: $isOnlineMeeting, isOrganizer: $isOrganizer, isReminderOn: $isReminderOn, location: $location, locations: $locations, onlineMeeting: $onlineMeeting, onlineMeetingProvider: $onlineMeetingProvider, onlineMeetingUrl: $onlineMeetingUrl, organizer: $organizer, originalEndTimeZone: $originalEndTimeZone, originalStart: $originalStart, originalStartTimeZone: $originalStartTimeZone, recurrence: $recurrence, reminderMinutesBeforeStart: $reminderMinutesBeforeStart, responseRequested: $responseRequested, responseStatus: $responseStatus, sensitivity: $sensitivity, seriesMasterId: $seriesMasterId, showAs: $showAs, start: $start, subject: $subject, transactionId: $transactionId, type: $type, webLink: $webLink, attachments: $attachments, calendar: $calendar, exceptionOccurrences: $exceptionOccurrences, extensions: $extensions, instances: $instances, multiValueExtendedProperties: $multiValueExtendedProperties, singleValueExtendedProperties: $singleValueExtendedProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get events from users
#
# GET /users/{user-id}/events/{event-id}
# operationId: user_GetEvent
export def "users-events GetEvent" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<allowNewTimeProposals: bool, attendees: table<proposedNewTime: record, status: record>, body: record<content: string, contentType: string>, bodyPreview: string, cancelledOccurrences: list<string>, end: record<dateTime: string, timeZone: string>, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, locations: table<address: record, coordinates: record, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, onlineMeeting: record<conferenceId: string, joinUrl: string, phones: list<record>, quickDial: string, tollFreeNumbers: list<string>, tollNumber: string>, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record<emailAddress: record<address: string, name: string>>, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record<pattern: record<dayOfMonth: float, daysOfWeek: list, firstDayOfWeek: string, index: string, interval: float, month: float, type: string>, range: record<endDate: string, numberOfOccurrences: float, recurrenceTimeZone: string, startDate: string, type: string>>, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record<response: string, time: string>, sensitivity: string, seriesMasterId: string, showAs: string, start: record<dateTime: string, timeZone: string>, subject: string, transactionId: string, type: string, webLink: string, attachments: table<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float>, calendar: record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: list<record>, calendarView: list<any>, events: list<any>, multiValueExtendedProperties: list<record>, singleValueExtendedProperties: list<record>>, exceptionOccurrences: list<any>, extensions: table<id: string>, instances: list<any>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property events in users
#
# PATCH /users/{user-id}/events/{event-id}
# operationId: user_UpdateEvent
# --attendees item shape: {proposedNewTime?: record, status?: record}
# --body shape: {content?: string, contentType?: "text"|"html"}
# --end shape: {dateTime?: string, timeZone?: string}
# --location shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --locations item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --onlineMeeting shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
# --organizer shape: {emailAddress?: record}
# --recurrence shape: {pattern?: record, range?: record}
# --responseStatus shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
# --start shape: {dateTime?: string, timeZone?: string}
# --attachments item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
# --exceptionOccurrences item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --extensions item shape: {id?: string}
# --instances item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
# --multiValueExtendedProperties item shape: {id?: string, value?: list}
# --singleValueExtendedProperties item shape: {id?: string, value?: string}
export def "users-events UpdateEvent" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowNewTimeProposals: oneof<nothing, bool> # true if the meeting organizer allows invitees to propose a new time when responding; otherwise, false. Optional. The default is true. (nullable)
  --attendees: list # The collection of attendees for the event. — item shape: {proposedNewTime?: record, status?: record}
  --body-body: record # shape: {content?: string, contentType?: "text"|"html"}
  --bodyPreview: string # The preview of the message associated with the event. It's in text format. (nullable)
  --cancelledOccurrences: list # Contains occurrenceId property values of canceled instances in a recurring series, if the event is the series master. Instances in a recurring series that are canceled are called canceled occurences.Requires $select to retrieve. Only returned in a Get operation that specifies the ID (seriesMasterId property value) of a series master event.
  --end: record # shape: {dateTime?: string, timeZone?: string}
  --hasAttachments: oneof<nothing, bool> # Set to true if the event has attachments. (nullable)
  --hideAttendees: oneof<nothing, bool> # When set to true, each attendee only sees themselves in the meeting request and meeting Tracking list. The default is false. (nullable)
  --iCalUId: string # A unique identifier for an event across calendars. This ID is different for each occurrence in a recurring series. Read-only. (nullable)
  --importance: string@importance-completer
  --isAllDay: oneof<nothing, bool> # Set to true if the event lasts all day. If true, regardless of whether it's a single-day or multi-day event, start, and endtime must be set to midnight and be in the same time zone. (nullable)
  --isCancelled: oneof<nothing, bool> # Set to true if the event has been canceled. (nullable)
  --isDraft: oneof<nothing, bool> # Set to true if the user has updated the meeting in Outlook but hasn't sent the updates to attendees. Set to false if all changes are sent, or if the event is an appointment without any attendees. (nullable)
  --isOnlineMeeting: oneof<nothing, bool> # True if this event has online meeting information (that is, onlineMeeting points to an onlineMeetingInfo resource), false otherwise. Default is false (onlineMeeting is null). Optional.  After you set isOnlineMeeting to true, Microsoft Graph initializes onlineMeeting. Subsequently, Outlook ignores any further changes to isOnlineMeeting, and the meeting remains available online. (nullable)
  --isOrganizer: oneof<nothing, bool> # Set to true if the calendar owner (specified by the owner property of the calendar) is the organizer of the event (specified by the organizer property of the event). It also applies if a delegate organized the event on behalf of the owner. (nullable)
  --isReminderOn: oneof<nothing, bool> # Set to true if an alert is set to remind the user of the event. (nullable)
  --location: record # shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --locations: list # The locations where the event is held or attended from. The location and locations properties always correspond with each other. If you update the location property, any prior locations in the locations collection are removed and replaced by the new location value. — item shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --onlineMeeting: record # shape: {conferenceId?: string, joinUrl?: string, phones?: list, quickDial?: string, tollFreeNumbers?: list, tollNumber?: string}
  --onlineMeetingProvider: string@onlineMeetingProvider-completer
  --onlineMeetingUrl: string # A URL for an online meeting. The property is set only when an organizer specifies in Outlook that an event is an online meeting such as Skype. Read-only.To access the URL to join an online meeting, use joinUrl which is exposed via the onlineMeeting property of the event. The onlineMeetingUrl property will be deprecated in the future. (nullable)
  --organizer: record # shape: {emailAddress?: record}
  --originalEndTimeZone: string # The end time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --originalStart: string # Represents the start time of an event when it's initially created as an occurrence or exception in a recurring series. This property is not returned for events that are single instances. Its date and time information is expressed in ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --originalStartTimeZone: string # The start time zone that was set when the event was created. A value of tzone://Microsoft/Custom indicates that a legacy custom time zone was set in desktop Outlook. (nullable)
  --recurrence: record # shape: {pattern?: record, range?: record}
  --reminderMinutesBeforeStart: float # The number of minutes before the event start time that the reminder alert occurs. (nullable, format: int32)
  --responseRequested: oneof<nothing, bool> # Default is true, which represents the organizer would like an invitee to send a response to the event. (nullable)
  --responseStatus: record # shape: {response?: "none"|"organizer"|"tentativelyAccepted"|"accepted"|"declined"|"notResponded", time?: string}
  --sensitivity: string@sensitivity-completer
  --seriesMasterId: string # The ID for the recurring series master item, if this event is part of a recurring series. (nullable)
  --showAs: string@showAs-completer
  --start: record # shape: {dateTime?: string, timeZone?: string}
  --subject: string # The text of the event's subject line. (nullable)
  --transactionId: string # A custom identifier specified by a client app for the server to avoid redundant POST operations in case of client retries to create the same event. It's useful when low network connectivity causes the client to time out before receiving a response from the server for the client's prior create-event request. After you set transactionId when creating an event, you can't change transactionId in a subsequent update. This property is only returned in a response payload if an app has set it. Optional. (nullable)
  --type: string@type-completer
  --webLink: string # The URL to open the event in Outlook on the web.Outlook on the web opens the event in the browser if you are signed in to your mailbox. Otherwise, Outlook on the web prompts you to sign in.This URL can't be accessed from within an iFrame. (nullable)
  --attachments: list # The collection of FileAttachment, ItemAttachment, and referenceAttachment attachments for the event. Navigation property. Read-only. Nullable. — item shape: {id?: string, contentType?: string, isInline?: bool, lastModifiedDateTime?: string, name?: string, size?: float}
  --calendar: any
  --exceptionOccurrences: list # Contains the id property values of the event instances that are exceptions in a recurring series.Exceptions can differ from other occurrences in a recurring series, such as the subject, start or end times, or attendees. Exceptions don't include canceled occurrences.Requires $select and $expand to retrieve. Only returned in a GET operation that specifies the ID (seriesMasterId property value) of a series master event. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --extensions: list # The collection of open extensions defined for the event. Nullable. — item shape: {id?: string}
  --instances: list # The occurrences of a recurring series, if the event is a series master. This property includes occurrences that are part of the recurrence pattern, and exceptions modified, but doesn't include occurrences canceled from the series. Navigation property. Read-only. Nullable. — item shape: {allowNewTimeProposals?: bool, attendees?: list, body?: record, bodyPreview?: string, cancelledOccurrences?: list, end?: record, hasAttachments?: bool, hideAttendees?: bool, iCalUId?: string, importance?: "low"|"normal"|"high", isAllDay?: bool, isCancelled?: bool, isDraft?: bool, isOnlineMeeting?: bool, isOrganizer?: bool, isReminderOn?: bool, location?: record, locations?: list, onlineMeeting?: record, onlineMeetingProvider?: "unknown"|"skypeForBusiness"|"skypeForConsumer"|"teamsForBusiness", onlineMeetingUrl?: string, organizer?: record, originalEndTimeZone?: string, originalStart?: string, originalStartTimeZone?: string, recurrence?: record, reminderMinutesBeforeStart?: float, responseRequested?: bool, responseStatus?: record, sensitivity?: "normal"|"personal"|"private"|"confidential", seriesMasterId?: string, showAs?: "unknown"|"free"|"tentative"|"busy"|"oof"|"workingElsewhere", start?: record, subject?: string, transactionId?: string, type?: "singleInstance"|"occurrence"|"exception"|"seriesMaster", webLink?: string, attachments?: list, calendar?: any, exceptionOccurrences?: list, extensions?: list, instances?: list, multiValueExtendedProperties?: list, singleValueExtendedProperties?: list}
  --multiValueExtendedProperties: list # The collection of multi-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: list}
  --singleValueExtendedProperties: list # The collection of single-value extended properties defined for the event. Read-only. Nullable. — item shape: {id?: string, value?: string}
]: any -> record<allowNewTimeProposals: bool, attendees: table<proposedNewTime: record, status: record>, body: record<content: string, contentType: string>, bodyPreview: string, cancelledOccurrences: list<string>, end: record<dateTime: string, timeZone: string>, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, locations: table<address: record, coordinates: record, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, onlineMeeting: record<conferenceId: string, joinUrl: string, phones: list<record>, quickDial: string, tollFreeNumbers: list<string>, tollNumber: string>, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record<emailAddress: record<address: string, name: string>>, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record<pattern: record<dayOfMonth: float, daysOfWeek: list, firstDayOfWeek: string, index: string, interval: float, month: float, type: string>, range: record<endDate: string, numberOfOccurrences: float, recurrenceTimeZone: string, startDate: string, type: string>>, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record<response: string, time: string>, sensitivity: string, seriesMasterId: string, showAs: string, start: record<dateTime: string, timeZone: string>, subject: string, transactionId: string, type: string, webLink: string, attachments: table<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float>, calendar: record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: list<record>, calendarView: list<any>, events: list<any>, multiValueExtendedProperties: list<record>, singleValueExtendedProperties: list<record>>, exceptionOccurrences: list<any>, extensions: table<id: string>, instances: list<any>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)")
  let body = {allowNewTimeProposals: $allowNewTimeProposals, attendees: $attendees, body: $body_body, bodyPreview: $bodyPreview, cancelledOccurrences: $cancelledOccurrences, end: $end, hasAttachments: $hasAttachments, hideAttendees: $hideAttendees, iCalUId: $iCalUId, importance: $importance, isAllDay: $isAllDay, isCancelled: $isCancelled, isDraft: $isDraft, isOnlineMeeting: $isOnlineMeeting, isOrganizer: $isOrganizer, isReminderOn: $isReminderOn, location: $location, locations: $locations, onlineMeeting: $onlineMeeting, onlineMeetingProvider: $onlineMeetingProvider, onlineMeetingUrl: $onlineMeetingUrl, organizer: $organizer, originalEndTimeZone: $originalEndTimeZone, originalStart: $originalStart, originalStartTimeZone: $originalStartTimeZone, recurrence: $recurrence, reminderMinutesBeforeStart: $reminderMinutesBeforeStart, responseRequested: $responseRequested, responseStatus: $responseStatus, sensitivity: $sensitivity, seriesMasterId: $seriesMasterId, showAs: $showAs, start: $start, subject: $subject, transactionId: $transactionId, type: $type, webLink: $webLink, attachments: $attachments, calendar: $calendar, exceptionOccurrences: $exceptionOccurrences, extensions: $extensions, instances: $instances, multiValueExtendedProperties: $multiValueExtendedProperties, singleValueExtendedProperties: $singleValueExtendedProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property events for users
#
# DELETE /users/{user-id}/events/{event-id}
# operationId: user_DeleteEvent
export def "users-events DeleteEvent" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get attachments from users
#
# GET /users/{user-id}/events/{event-id}/attachments
# operationId: user.event_ListAttachment
export def "users-events-attachments ListAttachment" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/attachments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to attachments for users
#
# POST /users/{user-id}/events/{event-id}/attachments
# operationId: user.event_CreateAttachment
export def "users-events-attachments CreateAttachment" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
  --contentType: string # The MIME type. (nullable)
  --isInline: oneof<nothing, bool> # true if the attachment is an inline attachment; otherwise, false.
  --lastModifiedDateTime: string # The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z (nullable, format: date-time)
  --name: string # The attachment's file name. (nullable)
  --size: float # The length of the attachment in bytes. (format: int32)
]: any -> record<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/attachments")
  let body = {id: $id, contentType: $contentType, isInline: $isInline, lastModifiedDateTime: $lastModifiedDateTime, name: $name, size: $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get attachments from users
#
# GET /users/{user-id}/events/{event-id}/attachments/{attachment-id}
# operationId: user.event_GetAttachment
export def "users-events-attachments GetAttachment" [
  user_id: string
  event_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, contentType: string, isInline: bool, lastModifiedDateTime: string, name: string, size: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/attachments/($attachment_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete navigation property attachments for users
#
# DELETE /users/{user-id}/events/{event-id}/attachments/{attachment-id}
# operationId: user.event_DeleteAttachment
export def "users-events-attachments DeleteAttachment" [
  user_id: string
  event_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/attachments/($attachment_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /users/{user-id}/events/{event-id}/attachments/$count
# operationId: user.event.attachment_GetCount
export def "users-events-attachments-count GetCount" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/attachments/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action createUploadSession
#
# POST /users/{user-id}/events/{event-id}/attachments/microsoft.graph.createUploadSession
# Docs: https://learn.microsoft.com/graph/api/attachment-createuploadsession?view=graph-rest-1.0 — Find more info here
# operationId: user.event.attachment_createUploadSession
# --AttachmentItem shape: {attachmentType?: "file"|"item"|"reference", contentId?: string, contentType?: string, isInline?: bool, name?: string, size?: float}
export def "users-events-attachments-microsoftgraphcreate-upload-session createUploadSession" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AttachmentItem: record # shape: {attachmentType?: "file"|"item"|"reference", contentId?: string, contentType?: string, isInline?: bool, name?: string, size?: float}
]: any -> record<expirationDateTime: string, nextExpectedRanges: list<string>, uploadUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/attachments/microsoft.graph.createUploadSession")
  let body = {AttachmentItem: $AttachmentItem} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get calendar from users
#
# GET /users/{user-id}/events/{event-id}/calendar
# operationId: user.event_GetCalendar
export def "users-events-calendar GetCalendar" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, allowedOnlineMeetingProviders: list<string>, canEdit: bool, canShare: bool, canViewPrivateItems: bool, changeKey: string, color: string, defaultOnlineMeetingProvider: string, hexColor: string, isDefaultCalendar: bool, isRemovable: bool, isTallyingResponses: bool, name: string, owner: record<address: string, name: string>, calendarPermissions: table<id: string, allowedRoles: list, emailAddress: record, isInsideOrganization: bool, isRemovable: bool, role: string>, calendarView: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, events: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: any, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, multiValueExtendedProperties: table<id: string, value: list>, singleValueExtendedProperties: table<id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/calendar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get extensions from users
#
# GET /users/{user-id}/events/{event-id}/extensions
# operationId: user.event_ListExtension
export def "users-events-extensions ListExtension" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/extensions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new navigation property to extensions for users
#
# POST /users/{user-id}/events/{event-id}/extensions
# operationId: user.event_CreateExtension
export def "users-events-extensions CreateExtension" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/extensions")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get extensions from users
#
# GET /users/{user-id}/events/{event-id}/extensions/{extension-id}
# operationId: user.event_GetExtension
export def "users-events-extensions GetExtension" [
  user_id: string
  event_id: string
  extension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/extensions/($extension_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the navigation property extensions in users
#
# PATCH /users/{user-id}/events/{event-id}/extensions/{extension-id}
# operationId: user.event_UpdateExtension
export def "users-events-extensions UpdateExtension" [
  user_id: string
  event_id: string
  extension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The unique identifier for an entity. Read-only.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/extensions/($extension_id)")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete navigation property extensions for users
#
# DELETE /users/{user-id}/events/{event-id}/extensions/{extension-id}
# operationId: user.event_DeleteExtension
export def "users-events-extensions DeleteExtension" [
  user_id: string
  event_id: string
  extension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/extensions/($extension_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /users/{user-id}/events/{event-id}/extensions/$count
# operationId: user.event.extension_GetCount
export def "users-events-extensions-count GetCount" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/extensions/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get instances from users
#
# GET /users/{user-id}/events/{event-id}/instances
# operationId: user.event_ListInstance
export def "users-events-instances ListInstance" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T19:00:00-08:00
  --endDateTime: string # The end date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/instances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function delta
#
# GET /users/{user-id}/events/{event-id}/instances/microsoft.graph.delta()
# Docs: https://learn.microsoft.com/graph/api/event-delta?view=graph-rest-1.0 — Find more info here
# operationId: user.event.instance_delta
export def "users-events-instances-microsoftgraphdelta delta" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --endDateTime: string # The end date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: record, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, _odata_nextLink: string, _odata_deltaLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/instances/microsoft.graph.delta()" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action accept
#
# POST /users/{user-id}/events/{event-id}/microsoft.graph.accept
# Docs: https://learn.microsoft.com/graph/api/event-accept?view=graph-rest-1.0 — Find more info here
# operationId: user.event_accept
export def "users-events-microsoftgraphaccept accept" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --SendResponse: oneof<nothing, bool> # nullable, default: false
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/microsoft.graph.accept")
  let body = {SendResponse: $SendResponse, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action cancel
#
# POST /users/{user-id}/events/{event-id}/microsoft.graph.cancel
# Docs: https://learn.microsoft.com/graph/api/event-cancel?view=graph-rest-1.0 — Find more info here
# operationId: user.event_cancel
export def "users-events-microsoftgraphcancel cancel" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/microsoft.graph.cancel")
  let body = {Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action decline
#
# POST /users/{user-id}/events/{event-id}/microsoft.graph.decline
# Docs: https://learn.microsoft.com/graph/api/event-decline?view=graph-rest-1.0 — Find more info here
# operationId: user.event_decline
# --ProposedNewTime shape: {end?: record, start?: record}
export def "users-events-microsoftgraphdecline decline" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ProposedNewTime: record # shape: {end?: record, start?: record}
  --SendResponse: oneof<nothing, bool> # nullable, default: false
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/microsoft.graph.decline")
  let body = {ProposedNewTime: $ProposedNewTime, SendResponse: $SendResponse, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action dismissReminder
#
# POST /users/{user-id}/events/{event-id}/microsoft.graph.dismissReminder
# Docs: https://learn.microsoft.com/graph/api/event-dismissreminder?view=graph-rest-1.0 — Find more info here
# operationId: user.event_dismissReminder
export def "users-events-microsoftgraphdismiss-reminder dismissReminder" [
  user_id: string
  event_id: string
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
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/microsoft.graph.dismissReminder")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action forward
#
# POST /users/{user-id}/events/{event-id}/microsoft.graph.forward
# Docs: https://learn.microsoft.com/graph/api/event-forward?view=graph-rest-1.0 — Find more info here
# operationId: user.event_forward
# --ToRecipients item shape: {emailAddress?: record}
export def "users-events-microsoftgraphforward forward" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ToRecipients: list # item shape: {emailAddress?: record}
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/microsoft.graph.forward")
  let body = {ToRecipients: $ToRecipients, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action permanentDelete
#
# POST /users/{user-id}/events/{event-id}/microsoft.graph.permanentDelete
# operationId: user.event_permanentDelete
export def "users-events-microsoftgraphpermanent-delete permanentDelete" [
  user_id: string
  event_id: string
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
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/microsoft.graph.permanentDelete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke action snoozeReminder
#
# POST /users/{user-id}/events/{event-id}/microsoft.graph.snoozeReminder
# Docs: https://learn.microsoft.com/graph/api/event-snoozereminder?view=graph-rest-1.0 — Find more info here
# operationId: user.event_snoozeReminder
# --NewReminderTime shape: {dateTime?: string, timeZone?: string}
export def "users-events-microsoftgraphsnooze-reminder snoozeReminder" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --NewReminderTime: record # shape: {dateTime?: string, timeZone?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/microsoft.graph.snoozeReminder")
  let body = {NewReminderTime: $NewReminderTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invoke action tentativelyAccept
#
# POST /users/{user-id}/events/{event-id}/microsoft.graph.tentativelyAccept
# Docs: https://learn.microsoft.com/graph/api/event-tentativelyaccept?view=graph-rest-1.0 — Find more info here
# operationId: user.event_tentativelyAccept
# --ProposedNewTime shape: {end?: record, start?: record}
export def "users-events-microsoftgraphtentatively-accept tentativelyAccept" [
  user_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ProposedNewTime: record # shape: {end?: record, start?: record}
  --SendResponse: oneof<nothing, bool> # nullable, default: false
  --Comment: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/events/($event_id)/microsoft.graph.tentativelyAccept")
  let body = {ProposedNewTime: $ProposedNewTime, SendResponse: $SendResponse, Comment: $Comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the number of the resource
#
# GET /users/{user-id}/events/$count
# operationId: user.event_GetCount
export def "users-events-count GetCount" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/events/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke function delta
#
# GET /users/{user-id}/events/microsoft.graph.delta()
# Docs: https://learn.microsoft.com/graph/api/event-delta?view=graph-rest-1.0 — Find more info here
# operationId: user.event_delta
export def "users-events-microsoftgraphdelta delta" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDateTime: string # The start date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --endDateTime: string # The end date and time of the time range in the function, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: oneof<nothing, bool> # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<allowNewTimeProposals: bool, attendees: list, body: record, bodyPreview: string, cancelledOccurrences: list, end: record, hasAttachments: bool, hideAttendees: bool, iCalUId: string, importance: string, isAllDay: bool, isCancelled: bool, isDraft: bool, isOnlineMeeting: bool, isOrganizer: bool, isReminderOn: bool, location: record, locations: list, onlineMeeting: record, onlineMeetingProvider: string, onlineMeetingUrl: string, organizer: record, originalEndTimeZone: string, originalStart: string, originalStartTimeZone: string, recurrence: record, reminderMinutesBeforeStart: float, responseRequested: bool, responseStatus: record, sensitivity: string, seriesMasterId: string, showAs: string, start: record, subject: string, transactionId: string, type: string, webLink: string, attachments: list, calendar: record, exceptionOccurrences: list, extensions: list, instances: list, multiValueExtendedProperties: list, singleValueExtendedProperties: list>, _odata_nextLink: string, _odata_deltaLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/events/microsoft.graph.delta()" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
