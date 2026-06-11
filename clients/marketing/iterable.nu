# Auto-generated client for Iterable API v1.8
# Source: https://api.iterable.com/api-docs
# Auth: --token flag or $env.ITERABLE_API_TOKEN

const BASE_URL = "https://api.iterable.com"
const DEFAULT_AUTH = "api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ITERABLE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "api-key" => { {headers: {Api-Key: $token_val}, query: ""} }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.iterable.com"] }
def auth-scheme-completer [] { ["api-key"] }

# Completers for enum parameters
def sendMode-completer [] { ["ProjectTimeZone" "RecipientTimeZone"] }
def state-completer [] { ["draft" "finished" "ready" "running" "winner_found"] }
def dataTypeName-completer [] { ["customEvent" "emailBounce" "emailClick" "emailComplaint" "emailOpen" "emailSend" "emailSendSkip" "emailSubscribe" "emailUnSubscribe" "embeddedClick" "embeddedImpression" "embeddedReceived" "embeddedSend" "embeddedSendSkip" "embeddedSession" "hostedUnsubscribeClick" "inAppClick" "inAppClose" "inAppDelete" "inAppDelivery" "inAppOpen" "inAppRecall" "inAppSend" "inAppSendSkip" "inboxMessageImpression" "inboxSession" "journeyExit" "purchase" "pushBounce" "pushOpen" "pushSend" "pushSendSkip" "pushUninstall" "smsBounce" "smsClick" "smsReceived" "smsSend" "smsSendSkip" "smsUsageInfo" "unknownSession" "user" "webPushClick" "webPushSend" "webPushSendSkip" "whatsAppBounce" "whatsAppClick" "whatsAppReceived" "whatsAppSeen" "whatsAppSend" "whatsAppSendSkip" "whatsAppUsageInfo"] }
def range-completer [] { ["All" "BeforeToday" "Today" "Yesterday"] }
def outputFormat-completer [] { ["application/x-json-stream" "text/csv"] }
def platform-completer [] { ["Android" "OTT" "Web" "iOS"] }
def templateType-completer [] { ["Base" "Blast" "Triggered" "Workflow"] }
def messageMedium-completer [] { ["Email" "InApp" "Push" "SMS"] }
def interruptionLevel-completer [] { ["active" "critical" "passive" "time-sensitive"] }
def authType-completer [] { ["Basic" "NoAuth" "OAuth2"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "auth-jwts-invalidate Invalidate-JWT" } } | get name | first)
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

# Invalidate all JWTs issued for a user
#
# POST /api/auth/jwts/invalidate
# operationId: Invalidate JWT
export def "auth-jwts-invalidate Invalidate-JWT" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # An email address that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --issuedBefore: int # Timestamp to invalidate JWTs before as epoch time in milliseconds. Defaults to the current time. (format: int32)
  --userId: string # A user ID that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/auth/jwts/invalidate")
  let body = {email: $email, issuedBefore: $issuedBefore, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List campaign metadata
#
# GET /api/campaigns
# operationId: campaigns
export def "campaigns campaigns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number (starting at 1). (format: int32, e.g. 1)
  --pageSize: int # Number of results to return per page (defaults to 20, maximum of 1000). (format: int32, e.g. 25)
  --qp-sort: string # Field to sort campaigns by, with optional direction prefix. Use - for descending, + or no prefix for ascending. Campaigns can be sorted by id, name, createdAt, updatedAt, or startAt. Examples: -createdAt, +name, id (default: id, e.g. id)
  --campaignState: list # Filter campaigns by state. Can be specified multiple times to filter by multiple states. Valid states: Draft, Ready, Scheduled, Running, Finished, Starting, Aborted, Recurring, Archived. Example: ?campaignState=Ready&campaignState=Running
]: nothing -> record<campaigns: table<campaignState: string, createdAt: int, createdByUserId: string, endedAt: int, id: float, labelIds: list, labels: list, listIds: list, messageMedium: string, name: string, recurringCampaignId: float, sendSize: float, startAt: int, suppressionListIds: list, templateId: float, type: string, updatedAt: int, updatedByUserId: string, workflowId: float>, nextPageUrl: string, previousPageUrl: string, totalCampaignsCount: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "campaignState" $campaignState "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/campaigns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Abort a campaign
#
# POST /api/campaigns/abort
# operationId: abort campaign
export def "campaigns-abort abort-campaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  campaignId: float
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/campaigns/abort")
  let body = {campaignId: $campaignId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Activate a triggered campaign
#
# POST /api/campaigns/activateTriggered
# operationId: activate triggered campaign
export def "campaigns-activate-triggered activate-triggered-campaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  campaignId: float
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/campaigns/activateTriggered")
  let body = {campaignId: $campaignId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive campaigns
#
# POST /api/campaigns/archive
# operationId: archive campaigns
export def "campaigns-archive archive-campaigns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  campaignIds: list # Campaign IDs to archive
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/campaigns/archive")
  let body = {campaignIds: $campaignIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel a scheduled or recurring campaign
#
# POST /api/campaigns/cancel
# operationId: cancel campaign
export def "campaigns-cancel cancel-campaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  campaignId: float
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/campaigns/cancel")
  let body = {campaignId: $campaignId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a campaign
#
# POST /api/campaigns/create
# operationId: create campaign
export def "campaigns-create create-campaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaignDataFields: record # A JSON object containing campaign-level data fields that are available as merge parameters (for example, <code>{{field}}</code>) during message rendering. These fields are available in templates, data feed URLs, and all other contexts where merge parameters are supported. Campaign-level fields are overridden by user and event data fields of the same name.
  --dataFields: record # A JSON object containing data to be statically rendered into the base template at creation time using double square brackets (for example, <code>[[field]]</code>). These values replace the placeholders in the base template and are baked into the campaign template, and cannot be changed later. Supported by email campaigns only.
  --defaultTimeZone: string # For a scheduled blast campaign, when <code>sendMode</code> is <code>RecipientTimeZone</code>, <code>defaultTimeZone</code> specifies the time zone to use when sending to recipients without a known time zone. IANA format (for example, <code>America/Los_Angeles</code>). For more details, see our <a href="https://support.iterable.com/hc/articles/204780579#post-api-campaigns-create">API Overview</a>.
  --labelIds: list # An optional array of label IDs to associate with the new campaign. Labels must exist in the project. Maximum 50 labels allowed.
  listIds: list # To create a blast campaign, set <code>listIds</code> to a non-empty array of list IDs to which the campaign should be sent. To create a triggered campaign, omit <code>listIds</code> from the request body.
  name: string # The name to use in Iterable for the new campaign.
  --scheduleSend: string@bool-completer # Whether to immediately schedule the blast campaign for sending. Defaults to <code>true</code>. Set to <code>false</code> to create the campaign without scheduling it (the campaign can be scheduled later using <code>POST /api/campaigns/{campaignId}/schedule</code>). Only applies to blast campaigns. (e.g. false)
  --sendAt: string # A scheduled send time for a new blast campaign, up to 21 days in the future. Format: <code>YYYY-MM-DD HH:MM:SS</code> (UTC). For more details, see our <a href="https://support.iterable.com/hc/articles/204780579#post-api-campaigns-create">API Overview</a>.
  --sendMode: string@sendMode-completer # When creating a blast campaign, set <code>sendMode</code> to <code>RecipientTimeZone</code> to have Iterable send the campaign to each recipient at a given local time in their own time zone — the same local time associated with <code>sendAt</code> (UTC) in <code>startTimeZone</code>. Or set <code>sendMode</code> to <code>ProjectTimeZone</code> (default value) to have Iterable send the campaign to all recipients at the UTC time specified by <code>sendAt</code>, regardless of local time zone. For more details, see our <a href="https://support.iterable.com/hc/articles/204780579#post-api-campaigns-create">API Overview</a>.
  --startTimeZone: string # For a scheduled blast campaign, when <code>sendMode</code> is <code>RecipientTimeZone</code>, Iterable sends the campaign at the same local time in all recipient time zones — starting with <code>startTimeZone</code>. Recipients in time zones to the east of <code>startTimeZone</code> receive the campaign simultaneously with recipients in <code>startTimeZone</code>, and recipients in time zones to the west of <code>startTimeZone</code> receive the campaign when the same local time arrives in their own time zone. IANA format (for example, <code>America/New_York</code>). For more details, see our <a href="https://support.iterable.com/hc/articles/204780579#post-api-campaigns-create">API Overview</a>.
  --suppressionListIds: list # An array of suppression list IDs to associate with a new blast campaign.
  templateId: float # The ID of a template to associate with the new campaign. The new campaign receives a copy of this template.
]: any -> record<campaignId: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/campaigns/create")
  let body = {campaignDataFields: $campaignDataFields, dataFields: $dataFields, defaultTimeZone: $defaultTimeZone, labelIds: $labelIds, listIds: $listIds, name: $name, scheduleSend: $scheduleSend, sendAt: $sendAt, sendMode: $sendMode, startTimeZone: $startTimeZone, suppressionListIds: $suppressionListIds, templateId: $templateId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deactivate a triggered campaign
#
# POST /api/campaigns/deactivateTriggered
# operationId: Deactivate triggered campaign
export def "campaigns-deactivate-triggered Deactivate-triggered-campaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  campaignId: float
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/campaigns/deactivateTriggered")
  let body = {campaignId: $campaignId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get metrics for campaigns
#
# GET /api/campaigns/metrics
# operationId: metrics
export def "campaigns-metrics metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaignId: list # Campaign(s) to export
  --startDateTime: string # Export starting from (>=).  Accepted formats include YYYY-MM-DD and other ISO 8601 formats. (format: date-time, default: 2018-06-25, allows empty value)
  --endDateTime: string # Export ending at (<).  Accepted formats include YYYY-MM-DD and other ISO 8601 formats. (format: date-time, default: 2018-07-25, allows empty value)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "campaignId" $campaignId "multi") (serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/campaigns/metrics" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get child campaigns of a recurring campaign
#
# GET /api/campaigns/recurring/{id}/childCampaigns
# operationId: child campaigns
export def "campaigns-recurring-child-campaigns child-campaigns" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number (starting at 1). (format: int32, e.g. 1)
  --pageSize: int # Number of results to return per page (defaults to 20, maximum of 1000). (format: int32, e.g. 25)
  --qp-sort: string # Field to sort campaigns by, with optional direction prefix. Use - for descending, + or no prefix for ascending. Campaigns can be sorted by id, name, createdAt, updatedAt, or startAt. Examples: -createdAt, +name, id (default: id, e.g. id)
  --campaignState: list # Filter campaigns by state. Can be specified multiple times to filter by multiple states. Valid states: Draft, Ready, Scheduled, Running, Finished, Starting, Aborted, Recurring, Archived. Example: ?campaignState=Ready&campaignState=Running
]: nothing -> record<campaigns: table<campaignState: string, createdAt: int, createdByUserId: string, endedAt: int, id: float, labelIds: list, labels: list, listIds: list, messageMedium: string, name: string, recurringCampaignId: float, sendSize: float, startAt: int, suppressionListIds: list, templateId: float, type: string, updatedAt: int, updatedByUserId: string, workflowId: float>, nextPageUrl: string, previousPageUrl: string, totalCampaignsCount: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "campaignState" $campaignState "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/campaigns/recurring/($id)/childCampaigns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger a campaign
#
# POST /api/campaigns/trigger
# operationId: trigger campaign
export def "campaigns-trigger trigger-campaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowRepeatMarketingSends: string@bool-completer # Allow repeat marketing sends? Defaults to true.
  campaignId: int # format: int64
  --dataFields: record # Fields to merge into handlebars context
  listIds: list # A non-empty array of list IDs to send to
  --suppressionListIds: list # Lists to suppress
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/campaigns/trigger")
  let body = {allowRepeatMarketingSends: $allowRepeatMarketingSends, campaignId: $campaignId, dataFields: $dataFields, listIds: $listIds, suppressionListIds: $suppressionListIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Schedule existing campaign to be sent
#
# POST /api/campaigns/{campaignId}/schedule
# operationId: schedule campaign
# --recipientTimeZone shape: {defaultTimeZone: string, startTimeZone: string}
export def "campaigns-schedule schedule-campaign" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recipientTimeZone: record # shape: {defaultTimeZone: string, startTimeZone: string}
  sendAt: string # When to send up to 7 days in the future. ISO-8601 date time format (e.g. 2007-12-03T10:15:30.00Z)
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/campaigns/($campaignId)/schedule")
  let body = {recipientTimeZone: $recipientTimeZone, sendAt: $sendAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send existing campaign now
#
# POST /api/campaigns/{campaignId}/send
# operationId: send campaign
export def "campaigns-send send-campaign" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, msg: string, params: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/campaigns/($campaignId)/send")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a campaign
#
# GET /api/campaigns/{id}
# operationId: getCampaign
export def "campaigns get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<campaignState: string, createdAt: int, createdByUserId: string, endedAt: int, id: float, labelIds: list<int>, labels: list<string>, listIds: list<int>, messageMedium: string, name: string, recurringCampaignId: float, sendSize: float, startAt: int, suppressionListIds: list<int>, templateId: float, type: string, updatedAt: int, updatedByUserId: string, workflowId: float> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/campaigns/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get catalog names
#
# GET /api/catalogs
# operationId: listCatalogs
export def "catalogs listCatalogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number to list (starting at 1). (format: int32, e.g. 1)
  --pageSize: int # Number of results to display per page (defaults to 10). (format: int32, e.g. 10)
]: nothing -> record<catalogNames: table<name: string>, nextPageUrl: string, previousPageUrl: string, totalCatalogsCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalogs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a catalog
#
# DELETE /api/catalogs/{catalogName}
# operationId: deleteCatalog
export def "catalogs delete" [
  catalogName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, msg: string, params: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalogs/($catalogName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a catalog
#
# POST /api/catalogs/{catalogName}
# operationId: createCatalog
export def "catalogs createCatalog" [
  catalogName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, msg: string, params: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalogs/($catalogName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get field mappings for a catalog
#
# GET /api/catalogs/{catalogName}/fieldMappings
# operationId: getFieldMappings
export def "catalogs-field-mappings get" [
  catalogName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<definedMappings: record, undefinedFields: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalogs/($catalogName)/fieldMappings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set a catalog's field mappings (data types)
#
# PUT /api/catalogs/{catalogName}/fieldMappings
# operationId: updateFieldTypes
# --mappingsUpdates item shape: {children?: list, fieldName: string, fieldType: string}
export def "catalogs-field-mappings updateFieldTypes" [
  catalogName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  mappingsUpdates: list # mappingsUpdates — item shape: {children?: list, fieldName: string, fieldType: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalogs/($catalogName)/fieldMappings")
  let body = {mappingsUpdates: $mappingsUpdates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk delete catalog items
#
# DELETE /api/catalogs/{catalogName}/items
# operationId: bulkDeleteCatalogItems
export def "catalogs-items bulkDeleteCatalogItems" [
  catalogName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  itemIds: list
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalogs/($catalogName)/items")
  let body = {itemIds: $itemIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the catalog items for a catalog
#
# GET /api/catalogs/{catalogName}/items
# operationId: listCatalogItems
export def "catalogs-items listCatalogItems" [
  catalogName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number to list (starting at 1). (format: int32, e.g. 1)
  --pageSize: int # Number of results to display per page (defaults to 10). (format: int32, e.g. 10)
  --orderBy: string # Field by which results should be ordered. To also use the sortAscending parameter, this field must have a defined type. (e.g. myField)
  --sortAscending: string@bool-completer # Sort results by ascending (Defaults to false). (e.g. false)
]: nothing -> record<catalogItemsWithProperties: table<catalogName: string, itemId: string, lastModified: string, size: int, value: record>, nextPageUrl: string, previousPageUrl: string, totalItemsCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "sortAscending" $sortAscending "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalogs/($catalogName)/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk create catalog items
#
# POST /api/catalogs/{catalogName}/items
# operationId: bulkUpdateCatalogItems
export def "catalogs-items bulkUpdateCatalogItems" [
  catalogName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  documents: record # Json map of id to values. Max number of pairs in list is 1000. Max size of each json value is is 30kb.
  --replaceUploadedFieldsOnly: string@bool-completer # Whether to replace only the upload fields within each document, not each entire document
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalogs/($catalogName)/items")
  let body = {documents: $documents, replaceUploadedFieldsOnly: $replaceUploadedFieldsOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a catalog item
#
# DELETE /api/catalogs/{catalogName}/items/{itemId}
# operationId: deleteCatalogItem
export def "catalogs-items delete" [
  catalogName: string
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, msg: string, params: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalogs/($catalogName)/items/($itemId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific catalog item
#
# GET /api/catalogs/{catalogName}/items/{itemId}
# operationId: getCatalogItem
export def "catalogs-items get" [
  catalogName: string
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<catalogName: string, itemId: string, lastModified: string, size: int, value: record<underlying: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalogs/($catalogName)/items/($itemId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update a catalog item
#
# PATCH /api/catalogs/{catalogName}/items/{itemId}
# operationId: partialUpdateCatalogItem
export def "catalogs-items partialUpdateCatalogItem" [
  catalogName: string
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  update: record # JSON representation of the catalog item fields to update.  Max size is is 30kb.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalogs/($catalogName)/items/($itemId)")
  let body = {update: $update} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create or replace a catalog item
#
# PUT /api/catalogs/{catalogName}/items/{itemId}
# operationId: indexCatalogItem
export def "catalogs-items indexCatalogItem" [
  catalogName: string
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  value: record # JSON representation of the catalog item. Max size is is 30kb.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalogs/($catalogName)/items/($itemId)")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get channels
#
# GET /api/channels
# operationId: channels
export def "channels channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<channels: table<channelType: string, id: int, messageMedium: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/channels")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Track a purchase
#
# POST /api/commerce/trackPurchase
# operationId: trackPurchase
# --items item shape: {categories?: list, dataFields?: record, description?: string, id: string, imageUrl?: string, name: string, price: float, quantity: int, sku?: string, url?: string}
# --user shape: {createNewFields?: bool, dataFields?: record, email?: string, mergeNestedObjects?: bool, preferUserId?: bool, userId?: string}
export def "commerce-track-purchase trackPurchase" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaignId: int # format: int32
  --createdAt: int # Time event happened. Set to the time event was received if unspecified. Expects a Unix timestamp. (format: int64)
  --dataFields: record # Additional fields to be tracked.
  --id: string # Optional purchase id. If a purchase exists with that id, the purchase will be updated. If none is specified, a new id will automatically be generated and returned. Note that this ID cannot be longer than 512 bytes.
  items: list # item shape: {categories?: list, dataFields?: record, description?: string, id: string, imageUrl?: string, name: string, price: float, quantity: int, sku?: string, url?: string}
  --templateId: int # Used in AB testing attribution (format: int32)
  total: float # Total order dollar amount (format: double)
  user: record # shape: {createNewFields?: bool, dataFields?: record, email?: string, mergeNestedObjects?: bool, preferUserId?: bool, userId?: string}
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/commerce/trackPurchase")
  let body = {campaignId: $campaignId, createdAt: $createdAt, dataFields: $dataFields, id: $id, items: $items, templateId: $templateId, total: $total, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a user's shopping cart items
#
# POST /api/commerce/updateCart
# operationId: updateCart
# --items item shape: {categories?: list, dataFields?: record, description?: string, id: string, imageUrl?: string, name: string, price: float, quantity: int, sku?: string, url?: string}
# --user shape: {createNewFields?: bool, dataFields?: record, email?: string, mergeNestedObjects?: bool, preferUserId?: bool, userId?: string}
export def "commerce-update-cart updateCart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  items: list # item shape: {categories?: list, dataFields?: record, description?: string, id: string, imageUrl?: string, name: string, price: float, quantity: int, sku?: string, url?: string}
  user: record # shape: {createNewFields?: bool, dataFields?: record, email?: string, mergeNestedObjects?: bool, preferUserId?: bool, userId?: string}
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/commerce/updateCart")
  let body = {items: $items, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel an email to a user
#
# POST /api/email/cancel
# operationId: cancel
export def "email-cancel cancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaignId: float # The ID of the campaign associated with the scheduled message you'd like to cancel. If you provide a <code>campaignId</code>, you must also provide an <code>email</code> or <code>userId</code>, depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --email: string # An email address that identifies a user profile in Iterable. If you provide a <code>campaignId</code>, you must also provide an <code>email</code> or a <code>userId</code>, depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --scheduledMessageId: float
  --userId: string # A user ID that identifies a user profile in Iterable. If you provide a <code>campaignId</code>, you must also provide an <code>email</code> or a <code>userId</code>, depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/email/cancel")
  let body = {campaignId: $campaignId, email: $email, scheduledMessageId: $scheduledMessageId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send an email to an email address
#
# POST /api/email/target
# operationId: target
export def "email-target target" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowRepeatMarketingSends: string@bool-completer # Allow repeat marketing sends? Defaults to true.
  campaignId: int # Campaign ID (format: int64)
  --dataFields: record # Fields to merge into email template
  --metadata: record # Metadata to pass back via webhooks. Not used for rendering
  --recipientEmail: string # An email address that identifies a user profile in Iterable. Provide a <code>recipientEmail</code> or a <code>recipientUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --recipientUserId: string # A user ID that identifies a user profile in Iterable. Provide a <code>recipientEmail</code> or a <code>recipientUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --sendAt: string # Schedule the message for up to 365 days in the future. If set in the past, email is sent immediately. Format is <code>YYYY-MM-DD HH:MM:SS</code> in UTC
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/email/target")
  let body = {allowRepeatMarketingSends: $allowRepeatMarketingSends, campaignId: $campaignId, dataFields: $dataFields, metadata: $metadata, recipientEmail: $recipientEmail, recipientUserId: $recipientUserId, sendAt: $sendAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# View a previously sent email
#
# GET /api/email/viewInBrowser
# operationId: viewInBrowser
export def "email-view-in-browser viewInBrowser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # user's email
  --userId: string # user's userId
  --messageId: string # id of sent message
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "messageId" $messageId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/email/viewInBrowser" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Track an embedded message click
#
# POST /api/embedded-messaging/events/click
# operationId: embedded-track-click
# --deviceInfo shape: {appPackageName: string, deviceId: string, platform: "iOS"|"Android"|"Web"}
export def "embedded-messaging-events-click embedded-track-click" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --buttonIdentifier: string # ID of the button that was clicked (button IDs are defined in Iterable, as part of the template / campaign).
  --createdAt: int # The time of the click's occurrence (Unix timestamp). If unspecified, gets set to the time Iterable received the event. (format: int64)
  --deviceInfo: record # shape: {appPackageName: string, deviceId: string, platform: "iOS"|"Android"|"Web"}
  --email: string # An email address that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  messageId: string # ID of the message on which the click occurred.
  --targetUrl: string # URL associated with the click.
  --userId: string # A user ID that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/embedded-messaging/events/click")
  let body = {buttonIdentifier: $buttonIdentifier, createdAt: $createdAt, deviceInfo: $deviceInfo, email: $email, messageId: $messageId, targetUrl: $targetUrl, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Track an embedded message received event
#
# POST /api/embedded-messaging/events/received
# operationId: embedded-track-received
# --deviceInfo shape: {appPackageName: string, deviceId: string, platform: "iOS"|"Android"|"Web"}
export def "embedded-messaging-events-received embedded-track-received" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdAt: int # The time of the event's occurrence (Unix timestamp). If unspecified, gets set to the time Iterable received the event. (format: int64)
  --deviceInfo: record # shape: {appPackageName: string, deviceId: string, platform: "iOS"|"Android"|"Web"}
  --email: string # An email address that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  messageId: string # ID of the message that was retrieved by a device.
  --userId: string # A user ID that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/embedded-messaging/events/received")
  let body = {createdAt: $createdAt, deviceInfo: $deviceInfo, email: $email, messageId: $messageId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Track an embedded message session and related impressions
#
# POST /api/embedded-messaging/events/session
# operationId: embedded-track-impression
# --deviceInfo shape: {appPackageName: string, deviceId: string, platform: "iOS"|"Android"|"Web"}
# --impressions item shape: {displayCount?: int, displayDuration?: float, messageId?: string, placementId?: int}
# --session shape: {end?: int, id?: string, start?: int}
export def "embedded-messaging-events-session embedded-track-impression" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdAt: int # The time of the event's occurrence (Unix timestamp). If unspecified, gets set to the time Iterable received the event. (format: int64)
  --deviceInfo: record # shape: {appPackageName: string, deviceId: string, platform: "iOS"|"Android"|"Web"}
  --email: string # An email address that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --impressions: list # Impressions associated with the session. — item shape: {displayCount?: int, displayDuration?: float, messageId?: string, placementId?: int}
  --session: record # shape: {end?: int, id?: string, start?: int}
  --userId: string # A user ID that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/embedded-messaging/events/session")
  let body = {createdAt: $createdAt, deviceInfo: $deviceInfo, email: $email, impressions: $impressions, session: $session, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a user's embedded messages
#
# GET /api/embedded-messaging/messages
# operationId: messages
export def "embedded-messaging-messages messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # User identifier. Provide an email or a userId, but not both.
  --userId: string # User identifier. Provide a userId or an email, but not both.
  --platform: string # The platform of the app for which to retrieve embedded messages: iOS, Android, or Web (case-sensitive).
  --sdkVersion: string # Iterable SDK version (e.g., 6.5.0). (default: None)
  --packageName: string # The package name of the app for which to retrieve embedded messages. (default: None)
  --placementIds: list # Placements to include in the response, even if they don't have embedded messages for the user. When no placementIds are specified, the response includes all embedded messages for which the user is eligible.
  --currentMessageIds: list # IDs of embedded messages already retrieved by the device making the request. If the user is no longer eligible for a specified message, that message will be omitted from the API response. Otherwise, it will be present, but without an elements field.
]: nothing -> record<placements: table<embeddedMessages: list, placementId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "platform" $platform "scalar") (serialize-qp "sdkVersion" $sdkVersion "scalar") (serialize-qp "packageName" $packageName "scalar") (serialize-qp "placementIds" $placementIds "multi") (serialize-qp "currentMessageIds" $currentMessageIds "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/embedded-messaging/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user events by userId
#
# GET /api/events/byUserId/{userId}
# operationId: User events by userId
export def "events-by-user-id User-events-by-userId" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of events to retrieve.  (Max is 200) (format: int32, default: 30)
]: nothing -> record<events: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/events/byUserId/($userId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Consume or delete an in-app message
#
# POST /api/events/inAppConsume
# operationId: inAppConsume
# --deviceInfo shape: {appPackageName: string, deviceId: string, platform: "iOS"|"Android"|"Web"}
# --messageContext shape: {location?: string, saveToInbox?: bool, silentInbox?: bool}
export def "events-in-app-consume inAppConsume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdAt: int # Time event happened. Set to the time event was received if unspecified. Expects a Unix timestamp. (format: int64)
  --deleteAction: string # How the message was deleted (for example, <code>inbox-swipe</code>, <code>delete-action</code>, or a custom value).
  --deviceInfo: record # shape: {appPackageName: string, deviceId: string, platform: "iOS"|"Android"|"Web"}
  --email: string # An email address that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --messageContext: record # shape: {location?: string, saveToInbox?: bool, silentInbox?: bool}
  messageId: string # The ID of the message associated with the event
  --userId: string # A user ID that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/events/inAppConsume")
  let body = {createdAt: $createdAt, deleteAction: $deleteAction, deviceInfo: $deviceInfo, email: $email, messageContext: $messageContext, messageId: $messageId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Track an event
#
# POST /api/events/track
# operationId: track
export def "events-track track" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaignId: int # Campaign tied to conversion (format: int64)
  --createNewFields: string@bool-completer # Whether new fields should be ingested and added to the schema. Defaults to project's setting to allow or drop unrecognized fields. (e.g. false)
  --createdAt: int # Time event happened. Set to the time event was received if unspecified. Expects a unix timestamp. (format: int64)
  --dataFields: record # Additional data associated with event (i.e. item amount, item quantity). For events of the same name, identically named data fields must be of the same type.
  --email: string # An email address that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  eventName: string # Name of event
  --id: string # Optional event id. If an event exists with that id, the event will be updated. If none is specified, a new id will automatically be generated and returned. Note that this ID cannot be longer than 512 bytes.
  --templateId: int # Template id (format: int64)
  --userId: string # A user ID that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/events/track")
  let body = {campaignId: $campaignId, createNewFields: $createNewFields, createdAt: $createdAt, dataFields: $dataFields, email: $email, eventName: $eventName, id: $id, templateId: $templateId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk track events
#
# POST /api/events/trackBulk
# operationId: trackBulk
# --events item shape: {campaignId?: int, createNewFields?: bool, createdAt?: int, dataFields?: record, email?: string, eventName: string, id?: string, templateId?: int, userId?: string}
export def "events-track-bulk trackBulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  events: list # item shape: {campaignId?: int, createNewFields?: bool, createdAt?: int, dataFields?: record, email?: string, eventName: string, id?: string, templateId?: int, userId?: string}
]: any -> record<createdFields: list<string>, disallowedEventNames: list<string>, failCount: int, failedUpdates: record<forgottenEmails: list<string>, forgottenUserIds: list<string>, invalidEmails: list<string>, invalidUserIds: list<string>, notFoundEmails: list<string>, notFoundUserIds: list<string>>, filteredOutFields: list<string>, invalidEmails: list<string>, invalidUserIds: list<string>, successCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/events/trackBulk")
  let body = {events: $events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Track an in-app message click
#
# POST /api/events/trackInAppClick
# operationId: trackInAppClick
# --deviceInfo shape: {appPackageName: string, deviceId: string, platform: "iOS"|"Android"|"Web"}
# --messageContext shape: {location?: string, saveToInbox?: bool, silentInbox?: bool}
export def "events-track-in-app-click trackInAppClick" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clickedUrl: string # The URL of the clicked link/button
  --createdAt: int # Time event happened. Set to the time event was received if unspecified. Expects a Unix timestamp. (format: int64)
  --deviceInfo: record # shape: {appPackageName: string, deviceId: string, platform: "iOS"|"Android"|"Web"}
  --email: string # An email address that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --messageContext: record # shape: {location?: string, saveToInbox?: bool, silentInbox?: bool}
  messageId: string # The ID of the message associated with the event
  --userId: string # A user ID that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/events/trackInAppClick")
  let body = {clickedUrl: $clickedUrl, createdAt: $createdAt, deviceInfo: $deviceInfo, email: $email, messageContext: $messageContext, messageId: $messageId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Track the closing of an in-app message
#
# POST /api/events/trackInAppClose
# operationId: trackInAppClose
# --deviceInfo shape: {appPackageName: string, deviceId: string, platform: "iOS"|"Android"|"Web"}
# --messageContext shape: {location?: string, saveToInbox?: bool, silentInbox?: bool}
export def "events-track-in-app-close trackInAppClose" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clickedUrl: string # url used to close the in-app
  --closeAction: string # The type of action that initiated the close (for example, <code>link</code>, <code>back</code>, or a custom value).
  --createdAt: int # Time event happened. Set to the time event was received if unspecified. Expects a Unix timestamp. (format: int64)
  --deviceInfo: record # shape: {appPackageName: string, deviceId: string, platform: "iOS"|"Android"|"Web"}
  --email: string # An email address that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --inboxSessionId: string # Inbox SessionId
  --messageContext: record # shape: {location?: string, saveToInbox?: bool, silentInbox?: bool}
  messageId: string # The ID of the message associated with the event
  --userId: string # A user ID that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/events/trackInAppClose")
  let body = {clickedUrl: $clickedUrl, closeAction: $closeAction, createdAt: $createdAt, deviceInfo: $deviceInfo, email: $email, inboxSessionId: $inboxSessionId, messageContext: $messageContext, messageId: $messageId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Track the delivery of an in-app message
#
# POST /api/events/trackInAppDelivery
# operationId: trackInAppDelivery
# --deviceInfo shape: {appPackageName: string, deviceId: string, platform: "iOS"|"Android"|"Web"}
# --messageContext shape: {saveToInbox?: bool, silentInbox?: bool}
export def "events-track-in-app-delivery trackInAppDelivery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdAt: int # Time event happened. Set to the time event was received if unspecified. Expects a Unix timestamp. (format: int64)
  --deviceInfo: record # shape: {appPackageName: string, deviceId: string, platform: "iOS"|"Android"|"Web"}
  --email: string # An email address that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --messageContext: record # shape: {saveToInbox?: bool, silentInbox?: bool}
  messageId: string # The ID of the message associated with the event
  --userId: string # A user ID that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/events/trackInAppDelivery")
  let body = {createdAt: $createdAt, deviceInfo: $deviceInfo, email: $email, messageContext: $messageContext, messageId: $messageId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Track an in-app message open
#
# POST /api/events/trackInAppOpen
# operationId: trackInAppOpen
# --deviceInfo shape: {appPackageName: string, deviceId: string, platform: "iOS"|"Android"|"Web"}
# --messageContext shape: {location?: string, saveToInbox?: bool, silentInbox?: bool}
export def "events-track-in-app-open trackInAppOpen" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdAt: int # Time event happened. Set to the time event was received if unspecified. Expects a Unix timestamp. (format: int64)
  --deviceInfo: record # shape: {appPackageName: string, deviceId: string, platform: "iOS"|"Android"|"Web"}
  --email: string # An email address that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --messageContext: record # shape: {location?: string, saveToInbox?: bool, silentInbox?: bool}
  messageId: string # The ID of the message associated with the event
  --userId: string # A user ID that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/events/trackInAppOpen")
  let body = {createdAt: $createdAt, deviceInfo: $deviceInfo, email: $email, messageContext: $messageContext, messageId: $messageId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Track a mobile push open
#
# POST /api/events/trackPushOpen
# operationId: trackPushOpen
export def "events-track-push-open trackPushOpen" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  campaignId: int # Campaign tied to open (format: int64)
  --createdAt: int # Timestamp of the open event. If unspecified, set to the time event was received  Expects a unix timestamp. (format: int64)
  --dataFields: record # Additional data associated with event
  --email: string # An email address that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  messageId: string # Iterable-generated Message ID
  --templateId: int # Used in AB testing attribution (format: int64)
  --userId: string # A user ID that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/events/trackPushOpen")
  let body = {campaignId: $campaignId, createdAt: $createdAt, dataFields: $dataFields, email: $email, messageId: $messageId, templateId: $templateId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Track a web push click
#
# POST /api/events/trackWebPushClick
# operationId: trackWebPushClick
export def "events-track-web-push-click trackWebPushClick" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaignId: int # format: int64
  --createdAt: int # Time event happened. Set to the time event was received if unspecified. Expects a Unix timestamp. (format: int64)
  --email: string # An email address that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  messageId: string
  --templateId: int # format: int64
  --userId: string # A user ID that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/events/trackWebPushClick")
  let body = {campaignId: $campaignId, createdAt: $createdAt, email: $email, messageId: $messageId, templateId: $templateId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get user events
#
# GET /api/events/{email}
# operationId: User events
export def "events User-events" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of events to retrieve.  (Max is 200) (format: int32, default: 30)
]: nothing -> record<events: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/events/($email)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get metrics for experiments
#
# GET /api/experiments/metrics
# operationId: metrics
export def "experiments-metrics metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --experimentId: list # Experiment to export. Specify multiple experimentId query parameters to export multiple experiments.
  --campaignId: list # Campaign whose experiments you want to export. Specify multiple campaignId query parameters to export multiple campaigns.
  --startDateTime: string # export starting from (>=) (format: date-time, default: 2018-06-25)
  --endDateTime: string # export ending at (<=) (format: date-time, default: 2018-07-25)
]: nothing -> record<headers: string, rows: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "experimentId" $experimentId "multi") (serialize-qp "campaignId" $campaignId "multi") (serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/experiments/metrics" $qp)
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List experiments
#
# GET /api/experiments
# operationId: list
export def "experiments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaignId: int # Filter by campaign ID (format: int64)
  --state: string@state-completer # Filter by experiment state. Valid values: draft, ready, running, finished, winner_found
  --startDateTime: string # Filter by start date (>=) (format: date-time)
  --endDateTime: string # Filter by end date (<=) (format: date-time)
  --limit: int # Maximum number of results to return (default: 20, max: 100) (format: int32, default: 20)
  --offset: int # Number of results to skip (default: 0) (format: int32, default: 0)
]: nothing -> record<experiments: table<author: string, channelType: string, finishDate: string, id: int, name: string, startDate: string, status: string>, pagination: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "campaignId" $campaignId "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/experiments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get experiment
#
# GET /api/experiments/{experimentId}
# operationId: get
export def "experiments get" [
  experimentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<allocationMode: string, channelType: string, constraints: record<suppressionListIds: list<int>, targetSegment: string>, creationDate: string, experimentType: string, finishDate: string, id: int, meta: record<campaignId: int, conversionMetrics: list<string>, name: string, orgId: int, projectId: int>, sizing: record<holdoutPercentage: float, perVariantPercentage: float, testGroupPercentage: float, winnerGroupPercentage: float, testDurationMinutes: int, sendsPerVariant: int>, startDate: string, status: string, variants: table<currentPercentage: float, id: int, isControl: bool, isWinner: bool, name: string, value: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/experiments/($experimentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get experiment variants
#
# GET /api/experiments/{experimentId}/variants
# operationId: variants
export def "experiments-variants variants" [
  experimentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<experimentId: int, variants: table<content: record, currentPercentage: float, name: string, value: record, variantId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/experiments/($experimentId)/variants")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export data to CSV
#
# GET /api/export/data.csv
# operationId: exportDataCsv
export def "export-datacsv exportDataCsv" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataTypeName: string@dataTypeName-completer # Data type name.
  --range: string@range-completer # date range, uses UTC time (default: Today)
  --delimiter: string # CSV file delimiter (default: ,)
  --startDateTime: string # Export starting from (>=) (yyyy-MM-dd HH:mm:ss [ZZ])
  --endDateTime: string # Export ending at (<) (yyyy-MM-dd HH:mm:ss [ZZ])
  --omitFields: string # Fields to omit (comma separated)
  --onlyFields: list # Only export these fields (comma separated)
  --campaignId: int # Only export data from this campaign (format: int64)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataTypeName" $dataTypeName "scalar") (serialize-qp "range" $range "scalar") (serialize-qp "delimiter" $delimiter "scalar") (serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "omitFields" $omitFields "scalar") (serialize-qp "onlyFields" $onlyFields "multi") (serialize-qp "campaignId" $campaignId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/export/data.csv" $qp)
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export data to JSON
#
# GET /api/export/data.json
# operationId: exportDataJson
export def "export-datajson exportDataJson" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataTypeName: string@dataTypeName-completer # Data type name.
  --range: string@range-completer # date range, uses UTC time (default: Today)
  --startDateTime: string # Export starting from (>=) (yyyy-MM-dd HH:mm:ss [ZZ])
  --endDateTime: string # Export ending at (<) (yyyy-MM-dd HH:mm:ss [ZZ])
  --omitFields: string # Fields to omit (comma separated)
  --onlyFields: list # Only export these fields (comma separated)
  --campaignId: int # Only export data from this campaign (format: int64)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataTypeName" $dataTypeName "scalar") (serialize-qp "range" $range "scalar") (serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "omitFields" $omitFields "scalar") (serialize-qp "onlyFields" $onlyFields "multi") (serialize-qp "campaignId" $campaignId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/export/data.json" $qp)
  let accept_val = "application/x-json-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get export jobs
#
# GET /api/export/jobs
# operationId: getExportJobs
export def "export-jobs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --jobState: string # Filter results to only include jobs in the specified state
]: nothing -> record<jobs: table<bytesExported: int, dataTypeName: record, endTime: string, id: int, jobState: record, scheduledStartTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jobState" $jobState "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/export/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start export
#
# POST /api/export/start
# operationId: startExport
export def "export-start startExport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaignId: int # Only export data from this campaign (format: int64)
  dataTypeName: string@dataTypeName-completer # Data type name.
  --delimiter: string # CSV file delimiter (e.g. ,)
  --endDateTime: string # Export events occurring or users updated before date and time exclusive (yyyy-MM-dd HH:mm:ss [ZZ])
  --omitFields: string # Fields to omit from the export (comma separated)
  --onlyFields: string # Only include these fields in the export (comma separated)
  outputFormat: string@outputFormat-completer # Output format
  --startDateTime: string # Export events occurring or users updated after date and time inclusive (yyyy-MM-dd HH:mm:ss [ZZ])
]: any -> record<jobId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/export/start")
  let body = {campaignId: $campaignId, dataTypeName: $dataTypeName, delimiter: $delimiter, endDateTime: $endDateTime, omitFields: $omitFields, onlyFields: $onlyFields, outputFormat: $outputFormat, startDateTime: $startDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export user events
#
# GET /api/export/userEvents
# operationId: exportUserEvents
export def "export-user-events exportUserEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Export by user's email
  --userId: string # Export by user's ID
  --includeCustomEvents: string@bool-completer # Include Custom Events (default: false)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "includeCustomEvents" $includeCustomEvents "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/export/userEvents" $qp)
  let accept_val = "application/x-json-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel export
#
# DELETE /api/export/{jobId}
# operationId: cancelExport
export def "export cancelExport" [
  jobId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/export/($jobId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get export files
#
# GET /api/export/{jobId}/files
# operationId: getExportFiles
export def "export-files get" [
  jobId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startAfter: string # Skip file names up to and including this value. Use for paginating over the files in the export. (default: None, e.g. file-1679086247925.csv)
]: nothing -> record<exportTruncated: bool, files: table<file: string, url: string>, jobId: int, jobState: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startAfter" $startAfter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/export/($jobId)/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a scheduled in-app message
#
# POST /api/inApp/cancel
# operationId: cancel
export def "in-app-cancel cancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaignId: float # The ID of the campaign associated with the scheduled message you'd like to cancel. If you provide a <code>campaignId</code>, you must also provide an <code>email</code> or <code>userId</code>, depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --email: string # An email address that identifies a user profile in Iterable. If you provide a <code>campaignId</code>, you must also provide an <code>email</code> or a <code>userId</code>, depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --scheduledMessageId: float
  --userId: string # A user ID that identifies a user profile in Iterable. If you provide a <code>campaignId</code>, you must also provide an <code>email</code> or a <code>userId</code>, depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/inApp/cancel")
  let body = {campaignId: $campaignId, email: $email, scheduledMessageId: $scheduledMessageId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a user's in-app messages
#
# GET /api/inApp/getMessages
# operationId: getMessages
export def "in-app-get-messages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # The email address of the user for which to fetch in-app messages. Specify either an email or a userId.
  --userId: string # The userId of the user for which to fetch in-app messages. Specify either an email or a userId.
  --count: int # The number of in-app messages to fetch. (format: int32)
  --platform: string@platform-completer # The platform of the app for which to retrieve selective in-app messages: iOS, Android, Web, or OTT (case-sensitive). (default: None)
  --SDKVersion: string # Iterable SDK version (e.g., 6.2.17) (default: None)
  --packageName: string # The package name of the app for which to retrieve selective in-app messages. (default: None)
]: nothing -> record<inAppMessages: table<campaignId: float, content: record, createdAt: string, customPayload: record, expiresAt: string, inboxMetadata: record, jsonOnly: bool, messageId: string, messageType: record, ottPayload: record, priorityLevel: float, read: bool, saveToInbox: bool, trigger: record, typeOfContent: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "platform" $platform "scalar") (serialize-qp "SDKVersion" $SDKVersion "scalar") (serialize-qp "packageName" $packageName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/inApp/getMessages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user's most relevant in-app message
#
# GET /api/inApp/getPriorityMessage
# operationId: getPriorityMessage
export def "in-app-get-priority-message get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # The email address of the user for which to fetch in-app messages. Specify either an email or a userId.
  --userId: string # The userId of the user for which to fetch in-app messages. Specify either an email or a userId.
  --platform: string@platform-completer # The platform of the app for which to retrieve selective in-app messages: iOS, Android, Web, or OTT (case-sensitive). (default: None)
  --SDKVersion: string # Iterable SDK version (e.g., 6.2.17) (default: None)
  --packageName: string # The package name of the app for which to retrieve selective in-app messages. (default: None)
]: nothing -> record<inAppMessages: table<campaignId: float, content: record, createdAt: string, customPayload: record, expiresAt: string, inboxMetadata: record, jsonOnly: bool, messageId: string, messageType: record, ottPayload: record, priorityLevel: float, read: bool, saveToInbox: bool, trigger: record, typeOfContent: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "platform" $platform "scalar") (serialize-qp "SDKVersion" $SDKVersion "scalar") (serialize-qp "packageName" $packageName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/inApp/getPriorityMessage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send an in-app notification to a user
#
# POST /api/inApp/target
# operationId: target
export def "in-app-target target" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowRepeatMarketingSends: string@bool-completer # Allow repeat marketing sends? Defaults to true.
  campaignId: int # Campaign ID (format: int64)
  --dataFields: record # Fields to merge into email template
  --recipientEmail: string # An email address that identifies a user profile in Iterable. Provide a <code>recipientEmail</code> or a <code>recipientUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --recipientUserId: string # A user ID that identifies a user profile in Iterable. Provide a <code>recipientEmail</code> or a <code>recipientUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --sendAt: string # Schedule the message for up to 365 days in the future. If set in the past, message is sent immediately. Format is YYYY-MM-DD HH:MM:SS in UTC
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/inApp/target")
  let body = {allowRepeatMarketingSends: $allowRepeatMarketingSends, campaignId: $campaignId, dataFields: $dataFields, recipientEmail: $recipientEmail, recipientUserId: $recipientUserId, sendAt: $sendAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a user's web in-app messages
#
# GET /api/inApp/web/getMessages
# operationId: getMessages
export def "in-app-web-get-messages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # The email address of the user for which to fetch in-app messages. Specify either an email or a userId.
  --userId: string # The userId of the user for which to fetch in-app messages. Specify either an email or a userId.
  --count: int # The number of web in-app messages to fetch. (format: int32)
  --SDKVersion: string # Iterable SDK version (e.g., 6.2.17) (default: None)
  --packageName: string # The package name of the app for which to retrieve selective web in-app messages. (default: None)
]: nothing -> record<inAppMessages: table<campaignId: float, content: record, createdAt: string, customPayload: record, expiresAt: string, inboxMetadata: record, jsonOnly: bool, messageId: string, messageType: record, ottPayload: record, priorityLevel: float, read: bool, saveToInbox: bool, trigger: record, typeOfContent: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "SDKVersion" $SDKVersion "scalar") (serialize-qp "packageName" $packageName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/inApp/web/getMessages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get journeys (workflows)
#
# GET /api/journeys
# operationId: getJourneys
export def "journeys get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number (starting at 1). (format: int32, e.g. 1)
  --pageSize: int # Number of results to return per page (defaults to 10, maximum of 50). (format: int32, e.g. 25)
  --qp-sort: string # Sort field with optional direction prefix. Use - for descending, + or no prefix for ascending. Examples: -createdAt, +name, id (default: id, e.g. id)
  --state: list # Without this parameter, the endpoint returns all non-archived journeys. With state set to Archived, the endpoint only returns archived journeys. (e.g. Archived)
]: nothing -> record<journeys: table<createdAt: int, creatorUserId: string, description: string, draft: record, enabled: bool, id: float, isArchived: bool, journeyType: string, lifetimeLimit: int, name: string, simultaneousLimit: int, startTileId: int, triggerEventNames: list, updatedAt: int>, nextPageUrl: string, previousPageUrl: string, totalJourneysCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "state" $state "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/journeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get lists
#
# GET /api/lists
# operationId: getLists
export def "lists get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<lists: table<createdAt: int, description: string, id: int, isGlobalSuppressionEnabled: bool, listType: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/lists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a static list
#
# POST /api/lists
# operationId: create
export def "lists create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string
  name: string
]: any -> record<listId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/lists")
  let body = {description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get users in a list
#
# GET /api/lists/getUsers
# operationId: getUsers
export def "lists-get-users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --listId: int # list id (format: int64)
  --preferUserId: string@bool-completer # If true, will return the userId instead of email if both exists in a user profile for a hybrid project. (default: false)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listId" $listId "scalar") (serialize-qp "preferUserId" $preferUserId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/lists/getUsers" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Preview users in a list
#
# GET /api/lists/previewUsers
# operationId: getUsersPreview
export def "lists-preview-users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --listId: int # list id (format: int64)
  --preferUserId: string@bool-completer # If true, will return the userId instead of email if both exists in a user profile for a hybrid project. (default: false)
  --size: int # Number of users the response will return, up to 5000. Defaults to 1000. (format: int32)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listId" $listId "scalar") (serialize-qp "preferUserId" $preferUserId "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/lists/previewUsers" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add subscribers to list
#
# POST /api/lists/subscribe
# operationId: subscribe
# --subscribers item shape: {dataFields?: record, email?: string, mergeNestedObjects?: bool, preferUserId?: bool, userId?: string}
export def "lists-subscribe subscribe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  listId: int # format: int64
  subscribers: list # item shape: {dataFields?: record, email?: string, mergeNestedObjects?: bool, preferUserId?: bool, userId?: string}
  --updateExistingUsersOnly: string@bool-completer # Whether to skip operation when the request includes a <code>userId</code> or <code>email</code> that doesn't yet exist in the Iterable project. When <code>true</code>, Iterable ignores requests with unknown userIds and email addresses. When <code>false</code>, Iterable creates new users. Defaults to <code>false</code>. Only respected in API calls for <a href="https://support.iterable.com/hc/articles/29156459027348">userID-based and hybrid projects</a>. (e.g. false)
]: any -> record<createdFields: list<string>, failCount: int, failedUpdates: record<conflictEmails: list<string>, conflictUserIds: list<string>, forgottenEmails: list<string>, forgottenUserIds: list<string>, invalidDataEmails: list<string>, invalidDataUserIds: list<string>, invalidEmails: list<string>, invalidUserIds: list<string>, notFoundEmails: list<string>, notFoundUserIds: list<string>>, filteredOutFields: list<string>, invalidEmails: list<string>, invalidUserIds: list<string>, successCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/lists/subscribe")
  let body = {listId: $listId, subscribers: $subscribers, updateExistingUsersOnly: $updateExistingUsersOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove users from a list
#
# POST /api/lists/unsubscribe
# operationId: unsubscribe
# --subscribers item shape: {email?: string, userId?: string}
export def "lists-unsubscribe unsubscribe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaignId: int # attribute unsubscribe to a campaign (format: int64)
  --channelUnsubscribe: string@bool-completer # Unsubscribe email from list's associated channel - essentially a global unsubscribe. (default: false)
  listId: int # format: int64
  subscribers: list # item shape: {email?: string, userId?: string}
]: any -> record<createdFields: list<string>, failCount: int, failedUpdates: record<conflictEmails: list<string>, conflictUserIds: list<string>, forgottenEmails: list<string>, forgottenUserIds: list<string>, invalidDataEmails: list<string>, invalidDataUserIds: list<string>, invalidEmails: list<string>, invalidUserIds: list<string>, notFoundEmails: list<string>, notFoundUserIds: list<string>>, filteredOutFields: list<string>, invalidEmails: list<string>, invalidUserIds: list<string>, successCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/lists/unsubscribe")
  let body = {campaignId: $campaignId, channelUnsubscribe: $channelUnsubscribe, listId: $listId, subscribers: $subscribers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a list
#
# DELETE /api/lists/{listId}
# operationId: delete
export def "lists delete" [
  listId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, msg: string, params: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/lists/($listId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get count of users in list
#
# GET /api/lists/{listId}/size
# operationId: getListCount
export def "lists-size get" [
  listId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/lists/($listId)/size")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List message types
#
# GET /api/messageTypes
# operationId: messageTypes
export def "message-types messageTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<messageTypes: table<channelId: int, createdAt: int, frequencyCap: record, id: int, name: string, rateLimitPerMinute: int, subscriptionPolicy: string, updatedAt: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/messageTypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List available tables
#
# GET /api/metadata
# operationId: list tables
export def "metadata list-tables" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<results: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a table
#
# DELETE /api/metadata/{table}
# operationId: delete
export def "metadata delete-by-table" [
  table: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, msg: string, params: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/metadata/($table)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List keys in a table
#
# GET /api/metadata/{table}
# operationId: list
export def "metadata list" [
  table: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nextMarker: string # next result set id; returned by previous search if more hits exist (default: None)
]: nothing -> record<nextMarker: string, results: table<key: string, lastModified: int, size: int, table: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextMarker" $nextMarker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/metadata/($table)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a single metadata key/value
#
# DELETE /api/metadata/{table}/{key}
# operationId: delete
export def "metadata delete-by-table-key" [
  table: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, msg: string, params: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/metadata/($table)/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the metadata value of a single key
#
# GET /api/metadata/{table}/{key}
# operationId: get
export def "metadata get" [
  table: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, lastModified: int, size: int, table: string, value: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/metadata/($table)/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or replace metadata
#
# PUT /api/metadata/{table}/{key}
# operationId: put
export def "metadata put" [
  table: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  value: record # The JSON metadata value.  Max size is is 30kb.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/metadata/($table)/($key)")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel a push notification to a user
#
# POST /api/push/cancel
# operationId: cancel
export def "push-cancel cancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaignId: float # The ID of the campaign associated with the scheduled message you'd like to cancel. If you provide a <code>campaignId</code>, you must also provide an <code>email</code> or <code>userId</code>, depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --email: string # An email address that identifies a user profile in Iterable. If you provide a <code>campaignId</code>, you must also provide an <code>email</code> or a <code>userId</code>, depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --scheduledMessageId: float
  --userId: string # A user ID that identifies a user profile in Iterable. If you provide a <code>campaignId</code>, you must also provide an <code>email</code> or a <code>userId</code>, depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/push/cancel")
  let body = {campaignId: $campaignId, email: $email, scheduledMessageId: $scheduledMessageId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send push notification to user
#
# POST /api/push/target
# operationId: target
export def "push-target target" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowRepeatMarketingSends: string@bool-completer # Allow repeat marketing sends? Defaults to true.
  campaignId: int # Campaign ID (format: int64)
  --dataFields: record # JSON object containing fields to merge into template
  --metadata: record # Metadata to pass back via system webhooks. Not used for rendering
  --recipientEmail: string # An email address that identifies a user profile in Iterable. Provide a <code>recipientEmail</code> or a <code>recipientUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --recipientUserId: string # A user ID that identifies a user profile in Iterable. Provide a <code>recipientEmail</code> or a <code>recipientUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --sendAt: string # Schedule the message for up to 365 days in the future. If set in the past, message is sent immediately. Format is YYYY-MM-DD HH:MM:SS in UTC
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/push/target")
  let body = {allowRepeatMarketingSends: $allowRepeatMarketingSends, campaignId: $campaignId, dataFields: $dataFields, metadata: $metadata, recipientEmail: $recipientEmail, recipientUserId: $recipientUserId, sendAt: $sendAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel an SMS to a user
#
# POST /api/sms/cancel
# operationId: cancel
export def "sms-cancel cancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaignId: float # The ID of the campaign associated with the scheduled message you'd like to cancel. If you provide a <code>campaignId</code>, you must also provide an <code>email</code> or <code>userId</code>, depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --email: string # An email address that identifies a user profile in Iterable. If you provide a <code>campaignId</code>, you must also provide an <code>email</code> or a <code>userId</code>, depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --scheduledMessageId: float
  --userId: string # A user ID that identifies a user profile in Iterable. If you provide a <code>campaignId</code>, you must also provide an <code>email</code> or a <code>userId</code>, depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/sms/cancel")
  let body = {campaignId: $campaignId, email: $email, scheduledMessageId: $scheduledMessageId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send SMS notification to user
#
# POST /api/sms/target
# operationId: target
export def "sms-target target" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowRepeatMarketingSends: string@bool-completer # Allow repeat marketing sends? Defaults to true.
  campaignId: int # Campaign ID (format: int64)
  --dataFields: record # Fields to merge into template
  --recipientEmail: string # An email address that identifies a user profile in Iterable. Provide a <code>recipientEmail</code> or a <code>recipientUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --recipientUserId: string # A user ID that identifies a user profile in Iterable. Provide a <code>recipientEmail</code> or a <code>recipientUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --sendAt: string # Schedule the message for up to 365 days in the future. If set in the past, message is sent immediately. Format is YYYY-MM-DD HH:MM:SS in UTC
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/sms/target")
  let body = {allowRepeatMarketingSends: $allowRepeatMarketingSends, campaignId: $campaignId, dataFields: $dataFields, recipientEmail: $recipientEmail, recipientUserId: $recipientUserId, sendAt: $sendAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all snippets
#
# GET /api/snippets
# operationId: getSnippets
export def "snippets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<snippets: table<content: string, createdAt: string, createdBy: string, description: string, id: record, name: string, projectId: int, updatedAt: string, updatedBy: string, variables: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/snippets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a snippet
#
# POST /api/snippets
# operationId: createSnippet
export def "snippets createSnippet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string # Content of the snippet. Handlebars must be valid. Disallowed content: script tags with JS sources or non-JSON content, inline JS event handlers (e.g., <code>onload=&quot;...&quot;</code>), and <code>javascript:</code> in <code>href</code> or <code>src</code> attributes (anchors and iframes).
  --createdByUserId: string # User ID (email) of the creator. If not provided, defaults to the project creator.
  --description: string # Description of the snippet.
  name: string # Name of the snippet. Must be unique within the project, up to 100 characters (a-z, A-Z, 0-9, hyphens (-), underscores (_), and spaces). Cannot be changed after snippet is created.
  --body-variables: list # A list of variable names used in the content with a Handlebars expression such as <code>{{#if (eq myVariable "someValue")}}</code>. Variable names are case-sensitive and should be simple identifiers (letters, numbers, underscores). To learn more about using variables in Snippets, see <a href=\"https://support.iterable.com/hc/articles/4414796078868\">Customizing Snippets with Variables</a>.
]: any -> record<snippetId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/snippets")
  let body = {content: $content, createdByUserId: $createdByUserId, description: $description, name: $name, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a snippet
#
# DELETE /api/snippets/{identifier}
# operationId: deleteSnippet
export def "snippets delete" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<snippetId: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/snippets/($identifier)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get snippet by ID or name
#
# GET /api/snippets/{identifier}
# operationId: getSnippet
export def "snippets get" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<snippet: record<content: string, createdAt: string, createdBy: string, description: string, id: record, name: string, projectId: int, updatedAt: string, updatedBy: string, variables: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/snippets/($identifier)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update a snippet
#
# PUT /api/snippets/{identifier}
# operationId: updateSnippet
export def "snippets updateSnippet" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string # Content of the snippet. Handlebars must be valid. Disallowed content: script tags with JS sources or non-JSON content, inline JS event handlers (e.g., <code>onload=&quot;...&quot;</code>), and <code>javascript:</code> in <code>href</code> or <code>src</code> attributes (anchors and iframes).
  --createdByUserId: string # User ID (email) of the updater. If not provided, defaults to the project creator.
  --description: string # Description of the snippet.
  --body-variables: list # List of variable names used in the content with a Handlebars expression such as {{myField}}. Variable names are case-sensitive and should be simple identifiers (letters, numbers, underscores). To learn more about using Handlebars in Snippets, see <a href=\"https://support.iterable.com/hc/articles/4414796078868\">Customizing Snippets with Variables</a>.
]: any -> record<snippetId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/snippets/($identifier)")
  let body = {content: $content, createdByUserId: $createdByUserId, description: $description, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Trigger a double opt-in subscription flow
#
# POST /api/subscriptions/subscribeToDoubleOptIn
# operationId: subscribeSingleUserToDoubleOptIn
export def "subscriptions-subscribe-to-double-opt-in subscribeSingleUserToDoubleOptIn" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --brandName: string # To provide context, every double opt-in confirmation message includes a brand name. The value to use for this brand name is determined by (in priority order): the <code>brandName</code> included in the request body (if specified), the default brand name associated with the specified message types (if those message types all have the same default brand name), or a comma-separated, de-duplicated list of default brand names associated with the specified message types (if those message types have different default brand names).
  --email: string # An email address that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  messageTypeIds: list # List of SMS, double opt-in message type IDs to which the user should be subscribed.
  --phoneNumber: string # The <code>phoneNumber</code> to set on the specified user's profile.
  --userId: string # A user ID that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/subscriptions/subscribeToDoubleOptIn")
  let body = {brandName: $brandName, email: $email, messageTypeIds: $messageTypeIds, phoneNumber: $phoneNumber, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk subscription action on a list of users
#
# PUT /api/subscriptions/{subscriptionGroup}/{subscriptionGroupId}
# operationId: Bulk subscription action
export def "subscriptions Bulk-subscription-action" [
  subscriptionGroup: string
  subscriptionGroupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --action: string # subscribe or unsubscribe (default: subscribe)
  --users: list # Users to subscribe/unsubscribe, identified by <code>email</code>.
  --usersByUserId: list # Users to subscribe/unsubscribe, identified by <code>userId</code>.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/subscriptions/($subscriptionGroup)/($subscriptionGroupId)" $qp)
  let body = {users: $users, usersByUserId: $usersByUserId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unsubscribe a single user by userId
#
# DELETE /api/subscriptions/{subscriptionGroup}/{subscriptionGroupId}/byUserId/{userId}
# operationId: unsubscribeSingleUserByUserId
export def "subscriptions-by-user-id unsubscribeSingleUserByUserId" [
  subscriptionGroup: string
  subscriptionGroupId: int
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, msg: string, params: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/subscriptions/($subscriptionGroup)/($subscriptionGroupId)/byUserId/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscribe a single user by their userId
#
# PATCH /api/subscriptions/{subscriptionGroup}/{subscriptionGroupId}/byUserId/{userId}
# operationId: subscribeSingleUserByUserId
export def "subscriptions-by-user-id subscribeSingleUserByUserId" [
  subscriptionGroup: string
  subscriptionGroupId: int
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, msg: string, params: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/subscriptions/($subscriptionGroup)/($subscriptionGroupId)/byUserId/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unsubscribe a single user
#
# DELETE /api/subscriptions/{subscriptionGroup}/{subscriptionGroupId}/user/{userEmail}
# operationId: unsubscribeSingleUser
export def "subscriptions-user unsubscribeSingleUser" [
  subscriptionGroup: string
  subscriptionGroupId: int
  userEmail: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, msg: string, params: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/subscriptions/($subscriptionGroup)/($subscriptionGroupId)/user/($userEmail)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscribe a single user
#
# PATCH /api/subscriptions/{subscriptionGroup}/{subscriptionGroupId}/user/{userEmail}
# operationId: subscribeSingleUser
export def "subscriptions-user subscribeSingleUser" [
  subscriptionGroup: string
  subscriptionGroupId: int
  userEmail: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, msg: string, params: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/subscriptions/($subscriptionGroup)/($subscriptionGroupId)/user/($userEmail)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project templates
#
# GET /api/templates
# operationId: getTemplates
export def "templates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --templateType: string@templateType-completer # Only retrieve templates associated with this template type (default: None)
  --messageMedium: string@messageMedium-completer # Only retrieve templates associated with this message medium (default: None)
  --startDateTime: string # Get templates created at or after this date time (yyyy-MM-dd HH:mm:ss [ZZ]) (format: date-time)
  --endDateTime: string # Get templates created before this date time (yyyy-MM-dd HH:mm:ss [ZZ]) (format: date-time)
  --page: int # Page number (starting at 1). (format: int32, default: 1, e.g. 1)
  --pageSize: int # Number of results to return per page (defaults to 20, maximum of 1000). (format: int32, default: 20, e.g. 25)
  --qp-sort: string # Field to sort templates by, with optional direction prefix. Use - for descending, + or no prefix for ascending. Templates can be sorted by id, name, createdAt, or updatedAt. Examples: -createdAt, +name, id (default: id, e.g. id)
]: nothing -> record<nextPageUrl: string, previousPageUrl: string, templates: table<campaignId: int, clientTemplateId: string, createdAt: string, creatorUserId: string, messageTypeId: int, name: string, templateId: int, updatedAt: string>, totalTemplatesCount: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "templateType" $templateType "scalar") (serialize-qp "messageMedium" $messageMedium "scalar") (serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk delete templates
#
# POST /api/templates/bulkDelete
# operationId: bulk delete templates
export def "templates-bulk-delete bulk-delete-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ids: list # IDs of templates to be deleted.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/templates/bulkDelete")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an email template by templateId
#
# GET /api/templates/email/get
# operationId: getEmailTemplate
export def "templates-email-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --templateId: int # Template ID (format: int64)
  --locale: string # Locale of content to get
]: nothing -> record<bccEmails: list<string>, cacheDataFeed: record, campaignDataFields: record, ccEmails: list<string>, clientTemplateId: string, creatorUserId: string, dataFeedId: float, dataFeedIds: list<float>, fromEmail: string, fromName: string, googleAnalyticsCampaignName: string, html: string, isDefaultLocale: bool, linkParams: table<key: string, value: string>, locale: string, mergeDataFeedContext: record, messageTypeId: float, metadata: record<campaignId: int, clientTemplateId: string, createdAt: string, creatorUserId: string, messageTypeId: int, name: string, templateId: int, updatedAt: string>, name: string, plainText: string, preheaderText: string, replyToEmail: string, subject: string, templateId: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "templateId" $templateId "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/templates/email/get" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Preview email template with custom data
#
# POST /api/templates/email/preview
# operationId: previewEmailTemplate
export def "templates-email-preview previewEmailTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --templateId: int # Template ID (format: int64)
  --locale: string # Locale of content to get (default: None)
  --dataFeed: record # Data feed content for template rendering. Provide key-value pairs for any data feed fields that your template references. Note: Data feed fields are accessible as <code>[[fieldName]]</code> when template's <code>mergeDataFeedContext=false</code>, or as <code>{{fieldName}}</code> when <code>mergeDataFeedContext=true</code>. The <code>mergeDataFeedContext</code> setting is configured when creating/updating templates. If <code>fetchDataFeeds</code> is true, this will be merged with (or overridden by) the fetched data feed data.
  --dataFields: record # Data fields for template rendering. Provide key-value pairs for any user profile, event, or custom fields that your template references. Note: Fields are accessible as <code>{{fieldName}}</code> in templates.
  --fetchDataFeeds: string@bool-completer # Whether to fetch and use actual data feeds configured in the template. If true, the data feeds associated with the template will be fetched and used for rendering. Data from <code>dataFields</code> will be used to render dynamic URLs in the data feed configuration. If <code>dataFeed</code> is also provided, it will be merged with (or override) the fetched data feed data. Defaults to false.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "templateId" $templateId "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/templates/email/preview" $qp)
  let body = {dataFeed: $dataFeed, dataFields: $dataFields, fetchDataFeeds: $fetchDataFeeds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send a proof of an email template
#
# POST /api/templates/email/proof
# operationId: emailProof
export def "templates-email-proof emailProof" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataFields: record # Fields to merge into template for proof
  --locale: string # Locale for the proof message. If provided, must be a valid locale for the project. If not provided, falls back to the user's locale, then to the project's default locale.
  --recipientEmail: string # An email address that identifies a user profile in Iterable. Provide a <code>recipientEmail</code> or a <code>recipientUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --recipientUserId: string # A user ID that identifies a user profile in Iterable. Provide a <code>recipientEmail</code> or a <code>recipientUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  templateId: int # Template ID to send proof for (format: int64)
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/templates/email/proof")
  let body = {dataFields: $dataFields, locale: $locale, recipientEmail: $recipientEmail, recipientUserId: $recipientUserId, templateId: $templateId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update email template
#
# POST /api/templates/email/update
# operationId: updateEmailTemplate
# --linkParams item shape: {key: string, value: string}
# --metadata shape: {campaignId?: int, clientTemplateId?: string, createdAt: string, creatorUserId: string, messageTypeId: int, name: string, templateId: int, updatedAt: string}
export def "templates-email-update updateEmailTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bccEmails: list # BCC emails
  --cacheDataFeed: record # Cache data feed lookups for 1 hour
  --campaignDataFields: record # Campaign-level data fields available as {{field}} merge parameters during message rendering. These fields are overridden by user and event data fields of the same name.
  --ccEmails: list # CC emails
  --clientTemplateId: string # Client template ID. Used as a secondary key to reference the template
  --creatorUserId: string # Creator User Id
  --dataFeedId: float # [Deprecated - use dataFeedIds instead] Id for data feed used in template rendering
  --dataFeedIds: list # Ids for data feeds used in template rendering
  --fromEmail: string # From email (must be an authorized sender)
  --fromName: string # From name
  --googleAnalyticsCampaignName: string # Google analytics utm_campaign value
  --html: string # HTML contents
  --isDefaultLocale: string@bool-completer # Ask your Iterable CSM to enroll you in the beta for this feature.  Identifies if the locale associated with the response is the template’s default. If empty or flexible default locales are not enabled for the project, the project’s default locale is assigned.
  --linkParams: list # Parameters to append to each URL in html contents — item shape: {key: string, value: string}
  --locale: string # The locale for the content in this request. Leave empty for default locale. Iterable will automatically send the content with locale that matches a 'locale' field in the user profile.
  --mergeDataFeedContext: record # Merge data feed contents into user context, so fields be referenced by {{field}} instead of [[field]]
  --messageTypeId: float # Message Type Id
  --metadata: record # shape: {campaignId?: int, clientTemplateId?: string, createdAt: string, creatorUserId: string, messageTypeId: int, name: string, templateId: int, updatedAt: string}
  --name: string # Name of the template
  --plainText: string # Plain text contents
  --preheaderText: string # Preheader text
  --replyToEmail: string # Reply to email
  --subject: string # Subject
  templateId: int # Email Template ID (format: int64)
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/templates/email/update")
  let body = {bccEmails: $bccEmails, cacheDataFeed: $cacheDataFeed, campaignDataFields: $campaignDataFields, ccEmails: $ccEmails, clientTemplateId: $clientTemplateId, creatorUserId: $creatorUserId, dataFeedId: $dataFeedId, dataFeedIds: $dataFeedIds, fromEmail: $fromEmail, fromName: $fromName, googleAnalyticsCampaignName: $googleAnalyticsCampaignName, html: $html, isDefaultLocale: $isDefaultLocale, linkParams: $linkParams, locale: $locale, mergeDataFeedContext: $mergeDataFeedContext, messageTypeId: $messageTypeId, metadata: $metadata, name: $name, plainText: $plainText, preheaderText: $preheaderText, replyToEmail: $replyToEmail, subject: $subject, templateId: $templateId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create email template
#
# POST /api/templates/email/upsert
# operationId: upsertEmailTemplate
# --linkParams item shape: {key: string, value: string}
export def "templates-email-upsert upsertEmailTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bccEmails: list # BCC emails
  --cacheDataFeed: record # Cache data feed lookups for 1 hour
  --campaignDataFields: record # Campaign-level data fields available as {{field}} merge parameters during message rendering. These fields are overridden by user and event data fields of the same name.
  --ccEmails: list # CC emails
  clientTemplateId: string # ID used by the client to identify a template. If multiple templates exist with the ID, all will be updated
  --creatorUserId: string # Specify a specific creator user id (email). The email must be an existing member of the project. Defaults to the organization creator.
  --dataFeedId: int # [Deprecated - use dataFeedIds instead] Id for data feed used in template rendering (format: int32)
  --dataFeedIds: list # Ids for data feeds used in template rendering
  --fromEmail: string # From email (must be an authorized sender)
  --fromName: string # From name
  --googleAnalyticsCampaignName: string # Google analytics utm_campaign value
  --html: string # HTML contents
  --isDefaultLocale: string@bool-completer # Ask your Iterable CSM to enroll you in the beta for this feature.  Sets the locale associated with the request content as the template’s default. If empty or flexible default locales are not enabled for the project, the project’s default locale is assigned.
  --linkParams: list # Parameters to append to each URL in html contents — item shape: {key: string, value: string}
  --locale: string # The locale for the content in this request. Iterable will automatically pick the content with locale that matches a 'locale' field in the user profile.
  --mergeDataFeedContext: string@bool-completer # Merge data feed contents into user context, so fields be referenced by {{field}} instead of [[field]]
  --messageTypeId: int # Message Type Id (format: int32)
  --name: string # Name of the template
  --plainText: string # Plain text contents
  --preheaderText: string # Preheader text
  --replyToEmail: string # Reply to email
  --subject: string # Subject
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/templates/email/upsert")
  let body = {bccEmails: $bccEmails, cacheDataFeed: $cacheDataFeed, campaignDataFields: $campaignDataFields, ccEmails: $ccEmails, clientTemplateId: $clientTemplateId, creatorUserId: $creatorUserId, dataFeedId: $dataFeedId, dataFeedIds: $dataFeedIds, fromEmail: $fromEmail, fromName: $fromName, googleAnalyticsCampaignName: $googleAnalyticsCampaignName, html: $html, isDefaultLocale: $isDefaultLocale, linkParams: $linkParams, locale: $locale, mergeDataFeedContext: $mergeDataFeedContext, messageTypeId: $messageTypeId, name: $name, plainText: $plainText, preheaderText: $preheaderText, replyToEmail: $replyToEmail, subject: $subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an embedded message template
#
# GET /api/templates/embedded/get
# operationId: getEmbeddedTemplate
export def "templates-embedded-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --templateId: int # Template ID (format: int64)
  --locale: string # Locale of content to get
]: nothing -> record<body: string, campaignDataFields: record, campaignId: int, clientTemplateId: string, elements: record<buttons: list<record>, defaultAction: record<data: string, type: string>, mediaUrl: string, mediaUrlCaption: string, text: list<record>>, isDefaultLocale: bool, locale: string, messageTypeId: int, name: string, payload: record, placementId: record, templateId: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "templateId" $templateId "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/templates/embedded/get" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update embedded message template
#
# POST /api/templates/embedded/update
# operationId: updateEmbeddedTemplate
# --elements shape: {buttons?: list, defaultAction?: record, mediaUrl?: string, mediaUrlCaption?: string, text?: list}
export def "templates-embedded-update updateEmbeddedTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-body: string # Body text of the embedded message
  --campaignDataFields: record # Campaign-level data fields available as {{field}} merge parameters during message rendering. These fields are overridden by user and event data fields of the same name.
  --campaignId: int # Campaign ID (format: int32)
  --clientTemplateId: string # Client template ID. Used as a secondary key to reference the template
  --elements: record # shape: {buttons?: list, defaultAction?: record, mediaUrl?: string, mediaUrlCaption?: string, text?: list}
  --isDefaultLocale: string@bool-completer # Ask your Iterable CSM to enroll you in the beta for this feature.  Identifies if the locale associated with the response is the template's default. If empty or flexible default locales are not enabled for the project, the project's default locale is assigned.
  --locale: string # The locale for the content in this request. Leave empty for default locale. Iterable automatically sends the content with a locale that matches a user profile's <code>locale</code> field.
  --messageTypeId: int # Message type ID (format: int32)
  --name: string # Name of the template
  --payload: record # Payload
  --placementId: record # Placement ID that this template is associated with
  templateId: int # Embedded message template ID (format: int64)
  --title: string # Title of the embedded message
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/templates/embedded/update")
  let body = {body: $body_body, campaignDataFields: $campaignDataFields, campaignId: $campaignId, clientTemplateId: $clientTemplateId, elements: $elements, isDefaultLocale: $isDefaultLocale, locale: $locale, messageTypeId: $messageTypeId, name: $name, payload: $payload, placementId: $placementId, templateId: $templateId, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an embedded message template
#
# POST /api/templates/embedded/upsert
# operationId: upsertEmbeddedTemplate
# --elements shape: {buttons?: list, defaultAction?: record, mediaUrl?: string, mediaUrlCaption?: string, text?: list}
# --payload shape: {underlying: record}
export def "templates-embedded-upsert upsertEmbeddedTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-body: string # Body text of the embedded message
  --campaignDataFields: record # Campaign-level data fields available as {{field}} merge parameters during message rendering. These fields are overridden by user and event data fields of the same name.
  clientTemplateId: string # ID used by the client to identify a template. If multiple templates exist with the ID, all will be updated
  --creatorUserId: string # Specify a specific creator user ID (email). The email must be an existing member of the project. Defaults to the organization creator.
  --elements: record # shape: {buttons?: list, defaultAction?: record, mediaUrl?: string, mediaUrlCaption?: string, text?: list}
  --isDefaultLocale: string@bool-completer # Ask your Iterable CSM to enroll you in the beta for this feature.  Sets the locale associated with the request content as the template's default. If empty or flexible default locales are not enabled for the project, the project's default locale is assigned.
  --locale: string # The locale for the content in this request. Leave empty for default locale. Iterable will automatically send the content with locale that matches a 'locale' field in the user profile.
  --messageTypeId: int # Message type ID (format: int32)
  --name: string # Name of the template
  --payload: record # shape: {underlying: record}
  --placementId: record # Placement ID that this template is associated with
  --title: string # Title of the embedded message
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/templates/embedded/upsert")
  let body = {body: $body_body, campaignDataFields: $campaignDataFields, clientTemplateId: $clientTemplateId, creatorUserId: $creatorUserId, elements: $elements, isDefaultLocale: $isDefaultLocale, locale: $locale, messageTypeId: $messageTypeId, name: $name, payload: $payload, placementId: $placementId, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an email template by clientTemplateId
#
# GET /api/templates/getByClientTemplateId
# operationId: getByClientTemplateId
export def "templates-get-by-client-template-id get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clientTemplateId: string # Client Template Id
]: nothing -> record<templates: table<campaignId: int, locales: list, templateId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientTemplateId" $clientTemplateId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/templates/getByClientTemplateId" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an in-app template
#
# GET /api/templates/inapp/get
# operationId: getInAppTemplate
export def "templates-inapp-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --templateId: int # Template ID (format: int64)
  --locale: string # Locale of content to get
]: nothing -> record<campaignDataFields: record, campaignId: int, clientTemplateId: string, expirationDateTime: string, expirationDuration: string, html: string, inAppDisplaySettings: record<bgColor: record<alpha: float, hex: string>, bottom: record, left: record, right: record, shouldAnimate: bool, top: record>, inboxMetadata: record<icon: string, subtitle: string, title: string>, isDefaultLocale: bool, locale: string, messageTypeId: int, name: string, payload: record, templateId: int, webInAppDisplaySettings: record<position: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "templateId" $templateId "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/templates/inapp/get" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Preview in-app template with custom data
#
# POST /api/templates/inapp/preview
# operationId: previewInAppTemplate
export def "templates-inapp-preview previewInAppTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --templateId: int # Template ID (format: int64)
  --locale: string # Locale of content to get (default: None)
  --dataFeed: record # Data feed content for template rendering. Provide key-value pairs for any data feed fields that your template references. Note: Data feed fields are accessible as <code>[[fieldName]]</code> when template's <code>mergeDataFeedContext=false</code>, or as <code>{{fieldName}}</code> when <code>mergeDataFeedContext=true</code>. The <code>mergeDataFeedContext</code> setting is configured when creating/updating templates. If <code>fetchDataFeeds</code> is true, this will be merged with (or overridden by) the fetched data feed data.
  --dataFields: record # Data fields for template rendering. Provide key-value pairs for any user profile, event, or custom fields that your template references. Note: Fields are accessible as <code>{{fieldName}}</code> in templates.
  --fetchDataFeeds: string@bool-completer # Whether to fetch and use actual data feeds configured in the template. If true, the data feeds associated with the template will be fetched and used for rendering. Data from <code>dataFields</code> will be used to render dynamic URLs in the data feed configuration. If <code>dataFeed</code> is also provided, it will be merged with (or override) the fetched data feed data. Defaults to false.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "templateId" $templateId "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/templates/inapp/preview" $qp)
  let body = {dataFeed: $dataFeed, dataFields: $dataFields, fetchDataFeeds: $fetchDataFeeds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send a proof of an in-app template
#
# POST /api/templates/inapp/proof
# operationId: inappProof
export def "templates-inapp-proof inappProof" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataFields: record # Fields to merge into template for proof
  --locale: string # Locale for the proof message. If provided, must be a valid locale for the project. If not provided, falls back to the user's locale, then to the project's default locale.
  --recipientEmail: string # An email address that identifies a user profile in Iterable. Provide a <code>recipientEmail</code> or a <code>recipientUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --recipientUserId: string # A user ID that identifies a user profile in Iterable. Provide a <code>recipientEmail</code> or a <code>recipientUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  templateId: int # Template ID to send proof for (format: int64)
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/templates/inapp/proof")
  let body = {dataFields: $dataFields, locale: $locale, recipientEmail: $recipientEmail, recipientUserId: $recipientUserId, templateId: $templateId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update in-app template
#
# POST /api/templates/inapp/update
# operationId: updateInAppTemplate
# --inAppDisplaySettings shape: {bgColor?: record, bottom?: record, left?: record, right?: record, shouldAnimate?: bool, top?: record}
# --inboxMetadata shape: {icon?: string, subtitle?: string, title?: string}
# --webInAppDisplaySettings shape: {position?: record}
export def "templates-inapp-update updateInAppTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaignDataFields: record # Campaign-level data fields available as {{field}} merge parameters during message rendering. These fields are overridden by user and event data fields of the same name.
  --campaignId: int # Campaign ID (format: int32)
  --clientTemplateId: string # Client template ID. Used as a secondary key to reference the template
  --expirationDateTime: string # The in-app message's absolute expiration time. If set to a time before the campaign sends, contacts will never see the message. Format is <code>YYYY-MM-DD HH:MM:SS</code> (UTC timestamp, time zones not allowed). Default expiration is 90 days after send time. For more information, read <a href="https://support.iterable.com/hc/articles/360044425951">Creating In-App Templates</a>. (format: date-time)
  --expirationDuration: string # The in-app message's expiration time, relative to its send time. Should be an expression such as <code>now+90d</code>. Default expiration is 90 days after send time. For more information, read <a href="https://support.iterable.com/hc/articles/360044425951">Creating In-App Templates</a>.
  --html: string # Html of the in-app notification
  --inAppDisplaySettings: record # shape: {bgColor?: record, bottom?: record, left?: record, right?: record, shouldAnimate?: bool, top?: record}
  --inboxMetadata: record # shape: {icon?: string, subtitle?: string, title?: string}
  --isDefaultLocale: string@bool-completer # Ask your Iterable CSM to enroll you in the beta for this feature.  Identifies if the locale associated with the response is the template's default. If empty or flexible default locales are not enabled for the project, the project's default locale is assigned.
  --locale: string # The locale for the content in this request. Leave empty for default locale. Iterable automatically sends the content with a locale that matches a user profile's <code>locale</code> field.
  --messageTypeId: int # Message Type Id (format: int32)
  --name: string # Name of the template
  --payload: record # Payload
  templateId: int # In-app template ID (format: int64)
  --webInAppDisplaySettings: record # shape: {position?: record}
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/templates/inapp/update")
  let body = {campaignDataFields: $campaignDataFields, campaignId: $campaignId, clientTemplateId: $clientTemplateId, expirationDateTime: $expirationDateTime, expirationDuration: $expirationDuration, html: $html, inAppDisplaySettings: $inAppDisplaySettings, inboxMetadata: $inboxMetadata, isDefaultLocale: $isDefaultLocale, locale: $locale, messageTypeId: $messageTypeId, name: $name, payload: $payload, templateId: $templateId, webInAppDisplaySettings: $webInAppDisplaySettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an in-app template
#
# POST /api/templates/inapp/upsert
# operationId: upsertInAppTemplate
# --inAppDisplaySettings shape: {bgColor?: record, bottom?: record, left?: record, right?: record, shouldAnimate?: bool, top?: record}
# --inboxMetadata shape: {icon?: string, subtitle?: string, title?: string}
# --payload shape: {underlying: record}
# --webInAppDisplaySettings shape: {position?: record}
export def "templates-inapp-upsert upsertInAppTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaignDataFields: record # Campaign-level data fields available as {{field}} merge parameters during message rendering. These fields are overridden by user and event data fields of the same name.
  clientTemplateId: string # ID used by the client to identify a template. If multiple templates exist with the ID, all will be updated
  --creatorUserId: string # Specify a specific creator user id (email). The email must be an existing member of the project. Defaults to the organization creator.
  --expirationDateTime: string # Absolute expiration of message (format: date-time)
  --expirationDuration: string # Relative expiration of message
  --html: string # Html of the in-app notification
  --inAppDisplaySettings: record # shape: {bgColor?: record, bottom?: record, left?: record, right?: record, shouldAnimate?: bool, top?: record}
  --inboxMetadata: record # shape: {icon?: string, subtitle?: string, title?: string}
  --isDefaultLocale: string@bool-completer # Ask your Iterable CSM to enroll you in the beta for this feature.  Sets the locale associated with the request content as the template’s default. If empty or flexible default locales are not enabled for the project, the project’s default locale is assigned.
  --locale: string # The locale for the content in this request. Leave empty for default locale. Iterable will automatically send the content with locale that matches a 'locale' field in the user profile.
  --messageTypeId: int # Message Type Id (format: int32)
  --name: string # Name of the template
  --payload: record # shape: {underlying: record}
  --webInAppDisplaySettings: record # shape: {position?: record}
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/templates/inapp/upsert")
  let body = {campaignDataFields: $campaignDataFields, clientTemplateId: $clientTemplateId, creatorUserId: $creatorUserId, expirationDateTime: $expirationDateTime, expirationDuration: $expirationDuration, html: $html, inAppDisplaySettings: $inAppDisplaySettings, inboxMetadata: $inboxMetadata, isDefaultLocale: $isDefaultLocale, locale: $locale, messageTypeId: $messageTypeId, name: $name, payload: $payload, webInAppDisplaySettings: $webInAppDisplaySettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a push template
#
# GET /api/templates/push/get
# operationId: getPushTemplate
export def "templates-push-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --templateId: int # Template ID (format: int64)
  --locale: string # Locale of content to get
]: nothing -> record<badge: string, buttons: table<action: record, actionIcon: record, buttonType: string, identifier: string, inputPlaceholder: string, inputTitle: string, openApp: bool, requiresUnlock: bool, title: string>, cacheDataFeed: bool, campaignDataFields: record, campaignId: record, clientTemplateId: string, createdAt: string, dataFeedIds: list<float>, deeplink: record<android: string, ios: string>, interruptionLevel: string, isDefaultLocale: bool, isSilentPush: bool, locale: string, mergeDataFeedContext: bool, message: string, messageTypeId: int, name: string, payload: record, relevanceScore: float, richMedia: record<android: string, ios: string>, sound: string, templateId: int, title: string, updatedAt: string, wake: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "templateId" $templateId "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/templates/push/get" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send a proof of a push template
#
# POST /api/templates/push/proof
# operationId: pushProof
export def "templates-push-proof pushProof" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataFields: record # Fields to merge into template for proof
  --locale: string # Locale for the proof message. If provided, must be a valid locale for the project. If not provided, falls back to the user's locale, then to the project's default locale.
  --recipientEmail: string # An email address that identifies a user profile in Iterable. Provide a <code>recipientEmail</code> or a <code>recipientUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --recipientUserId: string # A user ID that identifies a user profile in Iterable. Provide a <code>recipientEmail</code> or a <code>recipientUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  templateId: int # Template ID to send proof for (format: int64)
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/templates/push/proof")
  let body = {dataFields: $dataFields, locale: $locale, recipientEmail: $recipientEmail, recipientUserId: $recipientUserId, templateId: $templateId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update push template
#
# POST /api/templates/push/update
# operationId: updatePushTemplate
# --buttons item shape: {action?: record, actionIcon?: record, buttonType?: "default"|"destructive"|"textInput", identifier: string, inputPlaceholder?: string, inputTitle?: string, openApp: bool, requiresUnlock?: bool, title: string}
# --deeplink shape: {android?: string, ios?: string}
# --richMedia shape: {android?: string, ios?: string}
export def "templates-push-update updatePushTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --badge: string # Badge to set for push notification
  --buttons: list # Array of buttons that appear to respond to the push. Max of 3. — item shape: {action?: record, actionIcon?: record, buttonType?: "default"|"destructive"|"textInput", identifier: string, inputPlaceholder?: string, inputTitle?: string, openApp: bool, requiresUnlock?: bool, title: string}
  --cacheDataFeed: string@bool-completer # Cache data feed lookups for 1 hour
  --campaignDataFields: record # Campaign-level data fields available as {{field}} merge parameters during message rendering. These fields are overridden by user and event data fields of the same name.
  --campaignId: record # Campaign ID
  --clientTemplateId: string # Client template ID. Used as a secondary key to reference the template
  --createdAt: string # Date created [Read only] (format: date-time)
  --dataFeedIds: list # Ids for data feeds used in template rendering
  --deeplink: record # shape: {android?: string, ios?: string}
  --interruptionLevel: string@interruptionLevel-completer # An interruption level helps iOS determine when to alert a user about the arrival of a push notification
  --isDefaultLocale: string@bool-completer # Ask your Iterable CSM to enroll you in the beta for this feature.  Identifies if the locale associated with the response is the template's default. If empty or flexible default locales are not enabled for the project, the project's default locale is assigned.
  --isSilentPush: string@bool-completer # Whether or not this is a silent push notification template
  --locale: string # The locale for the content in this request. Leave empty for default locale. Iterable will automatically send the content with locale that matches a 'locale' field in the user profile.
  --mergeDataFeedContext: string@bool-completer # Merge data feed contents into user context, so fields can be referenced by {{field}} instead of [[field]]
  --message: string # Push message
  --messageTypeId: int # Message Type Id (format: int32)
  --name: string # Name of the template
  --payload: record # Payload to send with push notification
  --relevanceScore: float # Relevance score for iOS notifications on iOS 15+. Number is clamped between 0 and 1.0 (format: double)
  --richMedia: record # shape: {android?: string, ios?: string}
  --sound: string # Sound
  templateId: int # Push template ID (format: int64)
  --title: string # Push message title
  --updatedAt: string # Date last updated [Read only] (format: date-time)
  --wake: string@bool-completer # Set the content-available flag on iOS notifications, which will wake the app in the background
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/templates/push/update")
  let body = {badge: $badge, buttons: $buttons, cacheDataFeed: $cacheDataFeed, campaignDataFields: $campaignDataFields, campaignId: $campaignId, clientTemplateId: $clientTemplateId, createdAt: $createdAt, dataFeedIds: $dataFeedIds, deeplink: $deeplink, interruptionLevel: $interruptionLevel, isDefaultLocale: $isDefaultLocale, isSilentPush: $isSilentPush, locale: $locale, mergeDataFeedContext: $mergeDataFeedContext, message: $message, messageTypeId: $messageTypeId, name: $name, payload: $payload, relevanceScore: $relevanceScore, richMedia: $richMedia, sound: $sound, templateId: $templateId, title: $title, updatedAt: $updatedAt, wake: $wake} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a push template
#
# POST /api/templates/push/upsert
# operationId: upsertPushTemplate
# --buttons item shape: {action?: record, actionIcon?: record, buttonType?: "default"|"destructive"|"textInput", identifier: string, inputPlaceholder?: string, inputTitle?: string, openApp: bool, requiresUnlock?: bool, title: string}
# --deeplink shape: {android?: string, ios?: string}
# --payload shape: {underlying: record}
# --richMedia shape: {android?: string, ios?: string}
export def "templates-push-upsert upsertPushTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --badge: string # Badge to set for push notification
  --buttons: list # Array of buttons that appear to respond to the push. Max of 3. — item shape: {action?: record, actionIcon?: record, buttonType?: "default"|"destructive"|"textInput", identifier: string, inputPlaceholder?: string, inputTitle?: string, openApp: bool, requiresUnlock?: bool, title: string}
  --cacheDataFeed: string@bool-completer # Cache data feed lookups for 1 hour
  --campaignDataFields: record # Campaign-level data fields available as {{field}} merge parameters during message rendering. These fields are overridden by user and event data fields of the same name.
  clientTemplateId: string # ID used by the client to identify a template. If multiple templates exist with the ID, all will be updated
  --creatorUserId: string # Specify a specific creator user id (email). The email must be an existing member of the project. Defaults to the organization creator.
  --dataFeedIds: list # Ids for data feeds used in template rendering
  --deeplink: record # shape: {android?: string, ios?: string}
  --interruptionLevel: string@interruptionLevel-completer # An interruption level helps iOS determine when to alert a user about the arrival of a push notification
  --isDefaultLocale: string@bool-completer # Ask your Iterable CSM to enroll you in the beta for this feature.  Sets the locale associated with the request content as the template’s default. If empty or flexible default locales are not enabled for the project, the project’s default locale is assigned.
  --isSilentPush: string@bool-completer # Whether or not this is a silent push notification template
  --locale: string # The locale for the content in this request. Leave empty for default locale.Iterable will automatically send the content with locale that matches a 'locale' field in the user profile.
  --mergeDataFeedContext: string@bool-completer # Merge data feed contents into user context, so fields can be referenced by {{field}} instead of [[field]]
  --message: string # Push message
  --messageTypeId: int # Message Type Id (format: int32)
  --name: string # Name of the template
  --payload: record # shape: {underlying: record}
  --relevanceScore: float # Relevance score for iOS notifications on iOS 15+. Number is clamped between 0 and 1.0 (format: double)
  --richMedia: record # shape: {android?: string, ios?: string}
  --sound: string # Sound
  --title: string # Push message title
  --wake: string@bool-completer # Set the content-available flag on iOS notifications, which will wake the app in the background
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/templates/push/upsert")
  let body = {badge: $badge, buttons: $buttons, cacheDataFeed: $cacheDataFeed, campaignDataFields: $campaignDataFields, clientTemplateId: $clientTemplateId, creatorUserId: $creatorUserId, dataFeedIds: $dataFeedIds, deeplink: $deeplink, interruptionLevel: $interruptionLevel, isDefaultLocale: $isDefaultLocale, isSilentPush: $isSilentPush, locale: $locale, mergeDataFeedContext: $mergeDataFeedContext, message: $message, messageTypeId: $messageTypeId, name: $name, payload: $payload, relevanceScore: $relevanceScore, richMedia: $richMedia, sound: $sound, title: $title, wake: $wake} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an SMS template
#
# GET /api/templates/sms/get
# operationId: getSMSTemplate
export def "templates-sms-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --templateId: int # Template ID (format: int64)
  --locale: string # Locale of content to get
]: nothing -> record<campaignDataFields: record, campaignId: record, clientTemplateId: string, createdAt: string, googleAnalyticsCampaignName: string, imageUrl: string, isDefaultLocale: bool, linkParams: table<key: string, value: string>, locale: string, message: string, messageTypeId: int, name: string, templateId: int, trackingDomain: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "templateId" $templateId "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/templates/sms/get" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send a proof of an SMS template
#
# POST /api/templates/sms/proof
# operationId: smsProof
export def "templates-sms-proof smsProof" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataFields: record # Fields to merge into template for proof
  --locale: string # Locale for the proof message. If provided, must be a valid locale for the project. If not provided, falls back to the user's locale, then to the project's default locale.
  --recipientEmail: string # An email address that identifies a user profile in Iterable. Provide a <code>recipientEmail</code> or a <code>recipientUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --recipientUserId: string # A user ID that identifies a user profile in Iterable. Provide a <code>recipientEmail</code> or a <code>recipientUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  templateId: int # Template ID to send proof for (format: int64)
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/templates/sms/proof")
  let body = {dataFields: $dataFields, locale: $locale, recipientEmail: $recipientEmail, recipientUserId: $recipientUserId, templateId: $templateId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update SMS template
#
# POST /api/templates/sms/update
# operationId: updateSMSTemplate
# --linkParams item shape: {key: string, value: string}
export def "templates-sms-update updateSMSTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaignDataFields: record # Campaign-level data fields available as {{field}} merge parameters during message rendering. These fields are overridden by user and event data fields of the same name.
  --campaignId: record # Campaign ID
  --clientTemplateId: string # Client template ID. Used as a secondary key to reference the template
  --createdAt: string # Date created [Read only] (format: date-time)
  --googleAnalyticsCampaignName: string # Google analytics utm_campaign value
  --imageUrl: string # Image Url
  --isDefaultLocale: string@bool-completer # Ask your Iterable CSM to enroll you in the beta for this feature.  Identifies if the locale associated with the response is the template's default. If empty or flexible default locales are not enabled for the project, the project's default locale is assigned.
  --linkParams: list # Parameters to append to each URL in contents — item shape: {key: string, value: string}
  --locale: string # The locale for the content in this request. Leave empty for default locale. Iterable will automatically send the content with locale that matches a 'locale' field in the user profile.
  --message: string # SMS message
  --messageTypeId: int # Message Type Id (format: int32)
  --name: string # Name of the template
  templateId: int # SMS template ID (format: int64)
  --trackingDomain: string # Tracking Domain
  --updatedAt: string # Date last updated [Read only] (format: date-time)
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/templates/sms/update")
  let body = {campaignDataFields: $campaignDataFields, campaignId: $campaignId, clientTemplateId: $clientTemplateId, createdAt: $createdAt, googleAnalyticsCampaignName: $googleAnalyticsCampaignName, imageUrl: $imageUrl, isDefaultLocale: $isDefaultLocale, linkParams: $linkParams, locale: $locale, message: $message, messageTypeId: $messageTypeId, name: $name, templateId: $templateId, trackingDomain: $trackingDomain, updatedAt: $updatedAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an SMS template
#
# POST /api/templates/sms/upsert
# operationId: upsertSMSTemplate
# --linkParams item shape: {key: string, value: string}
export def "templates-sms-upsert upsertSMSTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaignDataFields: record # Campaign-level data fields available as {{field}} merge parameters during message rendering. These fields are overridden by user and event data fields of the same name.
  clientTemplateId: string # ID used by the client to identify a template. If multiple templates exist with the ID, all will be updated
  --creatorUserId: string # Specify a specific creator user id (email). The email must be an existing member of the project. Defaults to the organization creator.
  --googleAnalyticsCampaignName: string # Google analytics utm_campaign value
  --imageUrl: string # Image Url
  --isDefaultLocale: string@bool-completer # Ask your Iterable CSM to enroll you in the beta for this feature.  Sets the locale associated with the request content as the template’s default. If empty or flexible default locales are not enabled for the project, the project’s default locale is assigned.
  --linkParams: list # Parameters to append to each URL in html contents — item shape: {key: string, value: string}
  --locale: string # The locale for the content in this request. Leave empty for default locale. Iterable will automatically send the content with locale that matches a 'locale' field in the user profile.
  --message: string # SMS message
  --messageTypeId: int # Message Type Id (format: int32)
  --name: string # Name of the template
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/templates/sms/upsert")
  let body = {campaignDataFields: $campaignDataFields, clientTemplateId: $clientTemplateId, creatorUserId: $creatorUserId, googleAnalyticsCampaignName: $googleAnalyticsCampaignName, imageUrl: $imageUrl, isDefaultLocale: $isDefaultLocale, linkParams: $linkParams, locale: $locale, message: $message, messageTypeId: $messageTypeId, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk update user data
#
# POST /api/users/bulkUpdate
# operationId: bulkUpdateUser
# --users item shape: {dataFields?: record, email?: string, mergeNestedObjects?: bool, preferUserId?: bool, userId?: string}
export def "users-bulk-update bulkUpdateUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createNewFields: string@bool-completer # Whether new fields should be ingested and added to the schema. Defaults to project's setting to allow or drop unrecognized fields. Added fields will be included in the response's <code>createdFields</code>. Dropped fields will be included in <code>filteredOutFields</code> and not added to user profiles. (e.g. false)
  users: list # item shape: {dataFields?: record, email?: string, mergeNestedObjects?: bool, preferUserId?: bool, userId?: string}
]: any -> record<createdFields: list<string>, failCount: int, failedUpdates: record<conflictEmails: list<string>, conflictUserIds: list<string>, forgottenEmails: list<string>, forgottenUserIds: list<string>, invalidDataEmails: list<string>, invalidDataUserIds: list<string>, invalidEmails: list<string>, invalidUserIds: list<string>, notFoundEmails: list<string>, notFoundUserIds: list<string>>, filteredOutFields: list<string>, invalidEmails: list<string>, invalidUserIds: list<string>, successCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/users/bulkUpdate")
  let body = {createNewFields: $createNewFields, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk update user subscriptions
#
# POST /api/users/bulkUpdateSubscriptions
# operationId: bulkUpdateSubscriptions
# --updateSubscriptionsRequests item shape: {campaignId?: int, email?: string, emailListIds?: list, subscribedMessageTypeIds?: list, templateId?: int, unsubscribedChannelIds?: list, unsubscribedMessageTypeIds?: list, userId?: string, validateChannelAlignment?: bool}
export def "users-bulk-update-subscriptions bulkUpdateSubscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  updateSubscriptionsRequests: list # List of UpdateSubscriptionsRequests to process — item shape: {campaignId?: int, email?: string, emailListIds?: list, subscribedMessageTypeIds?: list, templateId?: int, unsubscribedChannelIds?: list, unsubscribedMessageTypeIds?: list, userId?: string, validateChannelAlignment?: bool}
]: any -> record<failCount: int, invalidEmails: list<string>, invalidUserIds: list<string>, successCount: int, validEmailFailures: list<string>, validUserIdFailures: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/users/bulkUpdateSubscriptions")
  let body = {updateSubscriptionsRequests: $updateSubscriptionsRequests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a user by userId (query parameter)
#
# GET /api/users/byUserId
# operationId: getUserById
export def "users-by-user-id list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userId: string
]: nothing -> record<user: record<dataFields: record, email: string, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/users/byUserId" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete user by userId
#
# DELETE /api/users/byUserId/{userId}
# operationId: delete
export def "users-by-user-id delete" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, msg: string, params: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/byUserId/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user by userId (path parameter)
#
# GET /api/users/byUserId/{userId}
# operationId: getUserById
export def "users-by-user-id get" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<user: record<dataFields: record, email: string, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/byUserId/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable pushes to a mobile device
#
# POST /api/users/disableDevice
# operationId: disableDevice
export def "users-disable-device disableDevice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Specific email this device belongs to disable. Will disable device under all users with this device by default.
  --body-token: string # The device token
  --userId: string # Specific userId this device belongs to disable. Will disable device under all users with this device by default.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/users/disableDevice")
  let body = {email: $email, token: $body_token, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Forget a user in compliance with GDPR
#
# POST /api/users/forget
# operationId: forget
export def "users-forget forget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # An email address that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --userId: string # A user ID that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/users/forget")
  let body = {email: $email, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get hashed forgotten users in compliance with GDPR
#
# GET /api/users/forgotten
# operationId: exportProjectForgottenUsers
export def "users-forgotten exportProjectForgottenUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<hashedEmails: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/users/forgotten")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hashed forgotten userIds in compliance with GDPR
#
# GET /api/users/forgottenUserIds
# operationId: exportProjectForgottenUserIds
export def "users-forgotten-user-ids exportProjectForgottenUserIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<hashedUserIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/users/forgottenUserIds")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user by email (query parameter)
#
# GET /api/users/getByEmail
# operationId: getUser
export def "users-get-by-email get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string
]: nothing -> record<user: record<dataFields: record, email: string, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/users/getByEmail" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all user fields
#
# GET /api/users/getFields
# operationId: getUserFields
export def "users-get-fields get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fields: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/users/getFields")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get messages sent to a user
#
# GET /api/users/getSentMessages
# operationId: getSentMessages
export def "users-get-sent-messages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # user's email, either email or userId must be specified
  --userId: string # user's userId, either email or userId must be specified
  --limit: int # max number of messages to return (default: 10, max limit: 1000) (format: int32, default: 10)
  --campaignIds: list # only include messages from these campaigns
  --startDateTime: string # start date time (yyyy-MM-dd HH:mm:ss ZZ) (format: date-time)
  --endDateTime: string # end date time (yyyy-MM-dd HH:mm:ss ZZ) (format: date-time)
  --excludeBlastCampaigns: string@bool-completer # exclude results coming from blast campaigns (ignored if campaignId is set) (default: false)
  --messageMedium: string@messageMedium-completer # only include messages of this type
]: nothing -> record<messages: table<campaignId: int, createdAt: string, messageId: string, templateId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "campaignIds" $campaignIds "multi") (serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "excludeBlastCampaigns" $excludeBlastCampaigns "scalar") (serialize-qp "messageMedium" $messageMedium "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/users/getSentMessages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merge users
#
# POST /api/users/merge
# operationId: mergeUsers
# --arrayMerge item shape: {dedupeBy?: string, field?: string}
export def "users-merge mergeUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --arrayMerge: list # An array of objects, each of which specifies an array field whose contents should be merged during the user merge operation. The objects in this <code>arrayMerge</code> array should only reference custom arrays, not Iterable-managed arrays such as <code>devices</code>. — item shape: {dedupeBy?: string, field?: string}
  --destinationEmail: string # An email address that identifies a user profile in Iterable. Provide a <code>destinationEmail</code> or a <code>destinationUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --destinationUserId: string # A user ID that identifies a user profile in Iterable. Provide a <code>destinationEmail</code> or a <code>destinationUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --sourceEmail: string # An email address that identifies a user profile in Iterable. Provide a <code>sourceEmail</code> or a <code>sourceUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --sourceUserId: string # A user ID that identifies a user profile in Iterable. Provide a <code>sourceEmail</code> or a <code>sourceUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/users/merge")
  let body = {arrayMerge: $arrayMerge, destinationEmail: $destinationEmail, destinationUserId: $destinationUserId, sourceEmail: $sourceEmail, sourceUserId: $sourceUserId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Register a browser token for web push
#
# POST /api/users/registerBrowserToken
# operationId: registerBrowserToken
export def "users-register-browser-token registerBrowserToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  browserToken: string # This is provided by Firebase Messaging javascript API.
  --email: string # An email address that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --userId: string # A user ID that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/users/registerBrowserToken")
  let body = {browserToken: $browserToken, email: $email, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Register a device token for push
#
# POST /api/users/registerDeviceToken
# operationId: registerDeviceToken
# --device shape: {applicationName: string, dataFields?: record, platform: "APNS"|"APNS_SANDBOX"|"GCM", token: string}
export def "users-register-device-token registerDeviceToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  device: record # shape: {applicationName: string, dataFields?: record, platform: "APNS"|"APNS_SANDBOX"|"GCM", token: string}
  --email: string # An email address that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --preferUserId: string@bool-completer # Whether or not a new user should be created if the request includes a <code>userId</code> that doesn't yet exist in the Iterable project. Defaults to <code>false</code>. Only respected in API calls for <a href="https://support.iterable.com/hc/articles/29156459027348">email-based projects</a>. (e.g. false)
  --userId: string # A user ID that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/users/registerDeviceToken")
  let body = {device: $device, email: $email, preferUserId: $preferUserId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unforget a user in compliance with GDPR
#
# POST /api/users/unforget
# operationId: unforget
export def "users-unforget unforget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # An email address that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --userId: string # A user ID that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/users/unforget")
  let body = {email: $email, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update user data
#
# POST /api/users/update
# operationId: updateUser
export def "users-update updateUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createNewFields: string@bool-completer # Whether new fields should be ingested and added to the schema. Defaults to project's setting to allow or drop unrecognized fields. (e.g. false)
  --dataFields: record # Data to store on the user profile identified by <code>userId</code> or <code>email</code>.
  --email: string # An email address that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --mergeNestedObjects: string@bool-completer # Merge top-level objects instead of overwriting them. Defaults to <code>false</code>. For example, if a user profile has data <code>{"mySettings":{"mobile":true}}</code> and the request has data <code>{"mySettings":{"email":true}}</code>, merging results in <code>{"mySettings":{"mobile":true,"email":true}}</code>. (e.g. false)
  --preferUserId: string@bool-completer # Whether or not a new user should be created if the request includes a <code>userId</code> that doesn't yet exist in the Iterable project. Defaults to <code>false</code>. Only respected in API calls for <a href="https://support.iterable.com/hc/articles/29156459027348">email-based projects</a>. (e.g. false)
  --userId: string # A user ID that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/users/update")
  let body = {createNewFields: $createNewFields, dataFields: $dataFields, email: $email, mergeNestedObjects: $mergeNestedObjects, preferUserId: $preferUserId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update user email
#
# POST /api/users/updateEmail
# operationId: updateEmail
export def "users-update-email updateEmail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --currentEmail: string # An email address that identifies a user profile in Iterable. Provide a <code>currentEmail</code> or a <code>currentUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --currentUserId: string # A user ID that identifies a user profile in Iterable. Provide a <code>currentEmail</code> or a <code>currentUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  newEmail: string # The new email address to assign to the specified user.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/users/updateEmail")
  let body = {currentEmail: $currentEmail, currentUserId: $currentUserId, newEmail: $newEmail} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update user subscriptions
#
# POST /api/users/updateSubscriptions
# operationId: updateSubscriptions
export def "users-update-subscriptions updateSubscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaignId: int # Campaign to attribute unsubscribes (format: int64)
  --email: string # An email address that identifies a user profile in Iterable. For each user in your request, provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --emailListIds: list # Lists that a user is subscribed to
  --subscribedMessageTypeIds: list # Individual message type IDs to subscribe (does not impact channel subscriptions). To set a value for this field, first have your CSM enable the opt-in message types feature. Otherwise, attempting to set this field causes an error.
  --templateId: int # Template to attribute unsubscribes (format: int64)
  --unsubscribedChannelIds: list # Email channel ids to unsubscribe from
  --unsubscribedMessageTypeIds: list # Individual message type IDs to unsubscribe (does not impact channel subscriptions).
  --userId: string # A user ID that identifies a user profile in Iterable. For each user in your request, provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --validateChannelAlignment: string@bool-completer # Defaults to <code>true</code> (validation enabled). When <code>false</code>, allows subscribing users to message types that belong to unsubscribed channels. By default, Iterable validates that subscribed message types belong to subscribed channels. Setting this to <code>false</code> bypasses this validation, allowing you to save message type preferences even when the parent channel is unsubscribed. Users won't receive messages from these types while the channel remains unsubscribed, but their preferences are preserved for when the channel becomes subscribed.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/users/updateSubscriptions")
  let body = {campaignId: $campaignId, email: $email, emailListIds: $emailListIds, subscribedMessageTypeIds: $subscribedMessageTypeIds, templateId: $templateId, unsubscribedChannelIds: $unsubscribedChannelIds, unsubscribedMessageTypeIds: $unsubscribedMessageTypeIds, userId: $userId, validateChannelAlignment: $validateChannelAlignment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a user by email
#
# DELETE /api/users/{email}
# operationId: delete
export def "users delete" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, msg: string, params: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/($email)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user by email (path parameter)
#
# GET /api/users/{email}
# operationId: getUser
export def "users get" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<user: record<dataFields: record, email: string, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/($email)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Begin SMS Verification
#
# POST /api/verify/sms/begin
# operationId: beginSmsVerification
export def "verify-sms-begin beginSmsVerification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  phoneNumber: string
  verificationProfileId: int # format: int64
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/verify/sms/begin")
  let body = {phoneNumber: $phoneNumber, verificationProfileId: $verificationProfileId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check SMS Verification Code
#
# POST /api/verify/sms/check
# operationId: checkSmsVerification
export def "verify-sms-check checkSmsVerification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  code: string
  phoneNumber: string
  verificationProfileId: int # format: int64
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/verify/sms/check")
  let body = {code: $code, phoneNumber: $phoneNumber, verificationProfileId: $verificationProfileId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel a web push notification to a user
#
# POST /api/webPush/cancel
# operationId: cancel
export def "web-push-cancel cancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaignId: float # The ID of the campaign associated with the scheduled message you'd like to cancel. If you provide a <code>campaignId</code>, you must also provide an <code>email</code> or <code>userId</code>, depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --email: string # An email address that identifies a user profile in Iterable. If you provide a <code>campaignId</code>, you must also provide an <code>email</code> or a <code>userId</code>, depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --scheduledMessageId: float
  --userId: string # A user ID that identifies a user profile in Iterable. If you provide a <code>campaignId</code>, you must also provide an <code>email</code> or a <code>userId</code>, depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/webPush/cancel")
  let body = {campaignId: $campaignId, email: $email, scheduledMessageId: $scheduledMessageId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send web push notification to user
#
# POST /api/webPush/target
# operationId: target
export def "web-push-target target" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowRepeatMarketingSends: string@bool-completer # Allow repeat marketing sends? Defaults to true.
  campaignId: int # format: int64
  --dataFields: record # Fields to merge into template
  --recipientEmail: string # An email address that identifies a user profile in Iterable. Provide a <code>recipientEmail</code> or a <code>recipientUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --recipientUserId: string # A user ID that identifies a user profile in Iterable. Provide a <code>recipientEmail</code> or a <code>recipientUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --sendAt: string # Schedule the message for up to 365 days in the future. If set in the past, message is sent immediately. Format is YYYY-MM-DD HH:MM:SS in UTC
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/webPush/target")
  let body = {allowRepeatMarketingSends: $allowRepeatMarketingSends, campaignId: $campaignId, dataFields: $dataFields, recipientEmail: $recipientEmail, recipientUserId: $recipientUserId, sendAt: $sendAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get webhooks
#
# GET /api/webhooks
# operationId: getWebhooks
export def "webhooks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<webhooks: table<authType: string, blastSendEnabled: bool, channelIds: list, enabled: bool, endpoint: string, id: int, messageTypeIds: list, triggeredSendEnabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update webhook
#
# POST /api/webhooks
# operationId: updateWebhook
# --headers item shape: {key: string, value: string}
export def "webhooks updateWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authToken: string # Auth token
  --authType: string@authType-completer # The type of authentication Iterable uses when calling this webhook
  --blastSendEnabled: string@bool-completer # Whether or not Iterable calls this webhook for blast campaigns
  --enabled: string@bool-completer # Whether or not Iterable will call the webhook when sending campaigns
  --endpoint: string # The URL associated with the webhook
  --headers: list # Headers — item shape: {key: string, value: string}
  id: int # The ID of the webhook in Iterable (format: int64)
  --triggeredSendEnabled: string@bool-completer # Whether or not Iterable calls this webhook for triggered campaigns
]: any -> record<authType: string, blastSendEnabled: bool, channelIds: list<record>, enabled: bool, endpoint: string, id: int, messageTypeIds: list<record>, triggeredSendEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/webhooks")
  let body = {authToken: $authToken, authType: $authType, blastSendEnabled: $blastSendEnabled, enabled: $enabled, endpoint: $endpoint, headers: $headers, id: $id, triggeredSendEnabled: $triggeredSendEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel a scheduled WhatsApp message
#
# POST /api/whatsApp/cancel
# operationId: cancel
export def "whats-app-cancel cancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaignId: float # The ID of the campaign associated with the scheduled message you'd like to cancel. If you provide a <code>campaignId</code>, you must also provide an <code>email</code> or <code>userId</code>, depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --email: string # An email address that identifies a user profile in Iterable. If you provide a <code>campaignId</code>, you must also provide an <code>email</code> or a <code>userId</code>, depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --scheduledMessageId: float
  --userId: string # A user ID that identifies a user profile in Iterable. If you provide a <code>campaignId</code>, you must also provide an <code>email</code> or a <code>userId</code>, depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/whatsApp/cancel")
  let body = {campaignId: $campaignId, email: $email, scheduledMessageId: $scheduledMessageId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send a WhatsApp message to a user
#
# POST /api/whatsApp/target
# operationId: target
export def "whats-app-target target" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowRepeatMarketingSends: string@bool-completer # Allow repeat marketing sends? Defaults to true.
  campaignId: int # Campaign ID (format: int64)
  --dataFields: record # Data fields that can be referenced in the template or campaign content
  --recipientEmail: string # An email address that identifies a user profile in Iterable. Provide a <code>recipientEmail</code> or a <code>recipientUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --recipientUserId: string # A user ID that identifies a user profile in Iterable. Provide a <code>recipientEmail</code> or a <code>recipientUserId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --sendAt: string # Schedule the message for up to 365 days in the future. If set in the past, message is sent immediately. Format is <code>YYYY-MM-DD HH:MM:SS</code> (UTC).
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/whatsApp/target")
  let body = {allowRepeatMarketingSends: $allowRepeatMarketingSends, campaignId: $campaignId, dataFields: $dataFields, recipientEmail: $recipientEmail, recipientUserId: $recipientUserId, sendAt: $sendAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Trigger a journey (workflow)
#
# POST /api/workflows/triggerWorkflow
# operationId: triggerWorkflow
export def "workflows-trigger-workflow triggerWorkflow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataFields: record # Additional data associated triggering event
  --email: string # An email address that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  --listId: int # (Optional) Trigger the journey for all users in a list (standard or dynamic) (format: int32)
  --userId: string # A user ID that identifies a user profile in Iterable. Provide an <code>email</code> or a <code>userId</code> (but not both), depending on <a href="https://support.iterable.com/hc/articles/29156459027348">how your project identifies users</a>.
  workflowId: int # ID of journey (workflow) to trigger (format: int64)
]: any -> record<code: string, msg: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/workflows/triggerWorkflow")
  let body = {dataFields: $dataFields, email: $email, listId: $listId, userId: $userId, workflowId: $workflowId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
