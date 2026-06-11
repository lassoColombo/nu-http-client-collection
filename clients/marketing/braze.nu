# Auto-generated client for Braze Endpoints v1.0.0
# Source: https://api.apis.guru/v2/specs/braze.com/1.0.0/openapi.json
# Auth: --token flag or $env.BRAZE_ENDPOINTS_TOKEN

const BASE_URL = "https://rest.iad-01.braze.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BRAZE_ENDPOINTS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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
def base-url-completer [] { ["https://rest.iad-01.braze.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "campaigns-data-series campaignAnalytics" } } | get name | first)
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

# Campaign Analytics
#
# GET /campaigns/data_series
# operationId: campaignAnalytics
export def "campaigns-data-series campaignAnalytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaign-id: string # (Required) String  Campaign API identifier (e.g. {{campaign_identifier}})
  --length: string # (Required) Integer  Max number of days before ending_at to include in the returned series - must be between 1 and 100 inclusive (e.g. 7)
  --ending-at: string # (Optional) DateTime (ISO 8601 string)  Date on which the data series should end - defaults to time of the request (e.g. 2020-06-28T23:59:59-5:00)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "campaign_id" $campaign_id "scalar") (serialize-qp "length" $length "scalar") (serialize-qp "ending_at" $ending_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/campaigns/data_series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Campaign Details
#
# GET /campaigns/details
# operationId: campaignDetails
export def "campaigns-details campaignDetails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaign-id: string # (Required) String  Campaign API identifier (e.g. {{campaign_identifier}})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "campaign_id" $campaign_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/campaigns/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Campaign List
#
# GET /campaigns/list
# operationId: campaignList
export def "campaigns-list campaignList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # (Optional) Integer  The page of campaigns to return, defaults to 0 (returns the first set of up to 100) (e.g. 0)
  --include-archived: string # (Optional) Boolean  Whether or not to include archived campaigns, defaults to false (e.g. false)
  --sort-direction: string # (Optional) String  Pass in the value `desc` to sort by creation time from newest to oldest. Pass in `asc` to sort from oldest to newest. If sort_direction is not included, the default order is oldest to newest. (e.g. desc)
  --last-edittimegt: string # (Optional) DateTime (ISO 8601 string)  Filters the results and only returns campaigns that were edited greater than the time provided till now.  (e.g. 2020-06-28T23:59:59-5:00)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "include_archived" $include_archived "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "last_edit.time[gt]" $last_edittimegt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/campaigns/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Canvas Data Series Analytics
#
# GET /canvas/data_series
# operationId: canvasDataSeriesAnalytics
export def "canvas-data-series canvasDataSeriesAnalytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --canvas-id: string # (Required) String  Canvas API Identifier (e.g. {{canvas_id}})
  --ending-at: string # (Required) DateTime (ISO 8601 string)  Date on which the data export should end - defaults to time of the request (e.g. 2018-05-30T23:59:59-5:00)
  --starting-at: string # (Optional) DateTime (ISO 8601 string)   Date on which the data export should begin (either length or starting_at are required) (e.g. 2018-05-28T23:59:59-5:00)
  --length: string # (Optional) DateTime (ISO 8601 string)  Max number of days before ending_at to include in the returned series - must be between 1 and 14 inclusive (either length or starting_at required) (e.g. 10)
  --include-variant-breakdown: string # (Optional) Boolean  Whether or not to include variant stats (defaults to false) (e.g. true)
  --include-step-breakdown: string # (Optional) Boolean  Whether or not to include step stats (defaults to false) (e.g. true)
  --include-deleted-step-data: string # (Optional) Boolean  Whether or not to include step stats for deleted steps (defaults to false) (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "canvas_id" $canvas_id "scalar") (serialize-qp "ending_at" $ending_at "scalar") (serialize-qp "starting_at" $starting_at "scalar") (serialize-qp "length" $length "scalar") (serialize-qp "include_variant_breakdown" $include_variant_breakdown "scalar") (serialize-qp "include_step_breakdown" $include_step_breakdown "scalar") (serialize-qp "include_deleted_step_data" $include_deleted_step_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/canvas/data_series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Canvas Data Analytics Summary
#
# GET /canvas/data_summary
# operationId: canvasDataAnalyticsSummary
export def "canvas-data-summary canvasDataAnalyticsSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --canvas-id: string # (Required) String   Canvas API identifier (e.g. {{canvas_id}})
  --ending-at: string # (Required) DateTime (ISO 8601 string)  Date on which the data export should end - defaults to time of the request (e.g. 2018-05-30T23:59:59-5:00)
  --starting-at: string # (Optional) DateTime (ISO 8601 string)  Date on which the data export should begin (either length or starting_at required) (e.g. 2018-05-28T23:59:59-5:00)
  --length: string # (Optional) Integer  Max number of days before ending_at to include in the returned series - must be between 1 and 14 inclusive (either length or starting_at required) (e.g. 5)
  --include-variant-breakdown: string # (Optional) Boolean  Whether or not to include variant stats (defaults to false) (e.g. true)
  --include-step-breakdown: string # (Optional) Boolean  Whether or not to include step stats (defaults to false) (e.g. true)
  --include-deleted-step-data: string # (Optional) Boolean  Whether or not to include step stats for deleted steps (defaults to false) (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "canvas_id" $canvas_id "scalar") (serialize-qp "ending_at" $ending_at "scalar") (serialize-qp "starting_at" $starting_at "scalar") (serialize-qp "length" $length "scalar") (serialize-qp "include_variant_breakdown" $include_variant_breakdown "scalar") (serialize-qp "include_step_breakdown" $include_step_breakdown "scalar") (serialize-qp "include_deleted_step_data" $include_deleted_step_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/canvas/data_summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Canvas Details
#
# GET /canvas/details
# operationId: canvasDetails
export def "canvas-details canvasDetails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --canvas-id: string # (Required) String  Canvas API Identifier  (e.g. {{canvas_identifier}})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "canvas_id" $canvas_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/canvas/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Canvas List
#
# GET /canvas/list
# operationId: canvasList
export def "canvas-list canvasList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # (Optional) Integer  The page of Canvases to return, defaults to `0` (returns the first set of up to 100) (e.g. 1)
  --include-archived: string # (Optional) Boolean  Whether or not to include archived Canvases, defaults to `false`. (e.g. false)
  --sort-direction: string # (Optional) String  Pass in the value `desc` to sort by creation time from newest to oldest. Pass in `asc` to sort from oldest to newest. If sort_direction is not included, the default order is oldest to newest. (e.g. desc)
  --last-edittimegt: string # (Optional) DateTime (ISO 8601 string)  Filters the results and only returns Canvases that were edited greater than the time provided till now. (e.g. 2020-06-28T23:59:59-5:00)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "include_archived" $include_archived "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "last_edit.time[gt]" $last_edittimegt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/canvas/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Schedule API Triggered Canvases
#
# POST /canvas/trigger/schedule/create
# operationId: scheduleApiTriggeredCanvases
# --audience shape: {AND?: list}
# --recipients item shape: {canvas_entry_properties?: record, external_user_id?: string, trigger_properties?: string, user_alias?: string}
# --schedule shape: {at_optimal_time?: bool, in_local_time?: bool, time?: string}
export def "canvas-trigger-schedule-create scheduleApiTriggeredCanvases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --audience: record # shape: {AND?: list}
  --broadcast: string@bool-completer # e.g. false
  --canvas-entry-properties: record
  --canvas-id: string # e.g. canvas_identifier
  --recipients: list # item shape: {canvas_entry_properties?: record, external_user_id?: string, trigger_properties?: string, user_alias?: string}
  --schedule: record # shape: {at_optimal_time?: bool, in_local_time?: bool, time?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/canvas/trigger/schedule/create")
  let body = {audience: $audience, broadcast: $broadcast, canvas_entry_properties: $canvas_entry_properties, canvas_id: $canvas_id, recipients: $recipients, schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# See Content Block Information
#
# GET /content_blocks/info
# operationId: seeContentBlockInformation
export def "content-blocks-info seeContentBlockInformation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content-block-id: string # (Required) String  The Content Block ID. This can be found by either listing Content Block information or going to the Developer Console, then API Settings, then scrolling to the bottom and searching for your Content Block API Identifier. (e.g. {{content_block_id}})
  --include-inclusion-data: string # (Optional) Boolean  When set to ‘true’, the API returns back the Message Variation API ID of Campaigns and Canvases where this content block is included, to be used in subsequent calls. The results exclude archived or deleted Campaigns or Canvases. (e.g. No)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "content_block_id" $content_block_id "scalar") (serialize-qp "include_inclusion_data" $include_inclusion_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/content_blocks/info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Available Content Blocks
#
# GET /content_blocks/list
# operationId: listAvailableContentBlocks
export def "content-blocks-list listAvailableContentBlocks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --modified-after: string # (Optional) String in ISO 8601  Retrieve only content blocks updated at or after the given time. (e.g. 2020-01-01T01:01:01.000000)
  --modified-before: string # (Optional) String in ISO 8601  Retrieve only content blocks updated at or before the given time. (e.g. 2020-02-01T01:01:01.000000)
  --limit: string # (Optional) Positive Number  Maximum number of content blocks to retrieve, default to 100 if not provided, maximum acceptable value is 1000. (e.g. 100)
  --offset: string # (Optional) Positive Number  Number of content blocks to skip before returning rest of the templates that fit the search criteria. (e.g. 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "modified_after" $modified_after "scalar") (serialize-qp "modified_before" $modified_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/content_blocks/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Hard Bounced Emails
#
# GET /email/hard_bounces
# operationId: queryHardBouncedEmails
export def "email-hard-bounces queryHardBouncedEmails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # (Optional*) String in YYYY-MM-DD format   Start date of the range to retrieve hard bounces, must be earlier than `end_date`. This is treated as midnight in UTC time by the API.  *You must provide either an `email` or a `start_date`, and an `end_date`.  (e.g. 2019-01-01)
  --end-date: string # (Optional*) String in YYYY-MM-DD format  String in YYYY-MM-DD format. End date of the range to retrieve hard bounces. This is treated as midnight in UTC time by the API.  *You must provide either an `email` or a `start_date`, and an `end_date`. (e.g. 2019-02-01)
  --limit: string # (Optional) Integer  Optional field to limit the number of results returned. Defaults to 100, maximum is 500. (e.g. 100)
  --offset: string # (Optional) Integer  Optional beginning point in the list to retrieve from. (e.g. 1)
  --email: string # (Optional*) String  If provided, we will return whether or not the user has hard bounced.  *You must provide either an `email` or a `start_date`, and an `end_date`. (e.g. example@braze.com)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/email/hard_bounces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query List of Unsubscribed Email Addresses
#
# GET /email/unsubscribes
# operationId: queryListOfUnsubscribedEmailAddresses
export def "email-unsubscribes queryListOfUnsubscribedEmailAddresses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # (Optional*) String in YYYY-MM-DD format  Start date of the range to retrieve unsubscribes, must be earlier than end_date. This is treated as midnight in UTC time by the API. (e.g. 2020-01-01)
  --end-date: string # (Optional*)  String in YYYY-MM-DD format  End date of the range to retrieve unsubscribes. This is treated as midnight in UTC time by the API. (e.g. 2020-02-01)
  --limit: string # (Optional) Integer  Optional field to limit the number of results returned. Limit must be greater than 1. Defaults to 100, maximum is 500. (e.g. 1)
  --offset: string # (Optional) Integer   Optional beginning point in the list to retrieve from (e.g. 1)
  --sort-direction: string # (Optional) String  Pass in the value `asc` to sort unsubscribes from oldest to newest. Pass in `desc` to sort from newest to oldest. If sort_direction is not included, the default order is newest to oldest. (e.g. desc)
  --email: string # (Optional*) String  If provided, we will return whether or not the user has unsubscribed (e.g. example@braze.com)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/email/unsubscribes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Custom Events Analytics
#
# GET /events/data_series
# operationId: customEventsAnalytics
export def "events-data-series customEventsAnalytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --event: string # (Required) String  The name of the custom event for which to return analytics  (e.g. event_name)
  --length: string # (Required) Integer  Max number of units (days or hours) before ending_at to include in the returned series - must be between 1 and 100 inclusive (e.g. 24)
  --unit: string # (Optional) String  Unit of time between data points - can be "day" or "hour" (defaults to "day") (e.g. hour)
  --ending-at: string # (Optional) DateTime (ISO 8601 string)  Point in time when the data series should end - defaults to time of the request (e.g. 2014-12-10T23:59:59-05:00)
  --app-id: string # (Optional) String  App API identifier retrieved from the Developer Console to limit analytics to a specific app (e.g. {{app_identifier}})
  --segment-id: string # (Optional) String  Segment API identifier indicating the analytics enabled segment for which event analytics should be returned (e.g. {{segment_identifier}})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "event" $event "scalar") (serialize-qp "length" $length "scalar") (serialize-qp "unit" $unit "scalar") (serialize-qp "ending_at" $ending_at "scalar") (serialize-qp "app_id" $app_id "scalar") (serialize-qp "segment_id" $segment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events/data_series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Custom Events List
#
# GET /events/list
# operationId: customEventsList
export def "events-list customEventsList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # (Optional) Integer  The page of event names to return, defaults to 0 (returns the first set of up to 250) (e.g. 3)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# News Feed Card Analytics
#
# GET /feed/data_series
# operationId: newsFeedCardAnalytics
export def "feed-data-series newsFeedCardAnalytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --card-id: string # (Required) String  Card API identifier (e.g. {{card_identifier}})
  --length: string # (Required) Integer  Max number of units (days or hours) before ending_at to include in the returned series - must be between 1 and 100 inclusive (e.g. 14)
  --unit: string # (Optional) String  Unit of time between data points - can be "day" or "hour" (defaults to "day") (e.g. day)
  --ending-at: string # (Optional) DateTime (ISO 8601 string)  Date on which the data series should end - defaults to time of the request (e.g. 2018-06-28T23:59:59-5:00)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "card_id" $card_id "scalar") (serialize-qp "length" $length "scalar") (serialize-qp "unit" $unit "scalar") (serialize-qp "ending_at" $ending_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/feed/data_series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# News Feed Cards Details
#
# GET /feed/details
# operationId: newsFeedCardsDetails
export def "feed-details newsFeedCardsDetails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --card-id: string # (Required) String  Card API identifier  (e.g. {{card_identifier}})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "card_id" $card_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/feed/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# News Feed Cards List
#
# GET /feed/list
# operationId: newsFeedCardsList
export def "feed-list newsFeedCardsList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # (Optional) Integer  The page of cards to return, defaults to 0 (returns the first set of up to 100) (e.g. 1)
  --include-archived: string # (Optional) Boolean  Whether or not to include archived cards, defaults to false (e.g. true)
  --sort-direction: string # (Optional) String  Pass in the value `desc` to sort by creation time from newest to oldest. Pass in `asc` to sort from oldest to newest. If sort_direction is not included, the default order is oldest to newest. (e.g. desc)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "include_archived" $include_archived "scalar") (serialize-qp "sort_direction" $sort_direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/feed/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Daily Active Users by Date
#
# GET /kpi/dau/data_series
# operationId: dailyActiveUsersByDate
export def "kpi-dau-data-series dailyActiveUsersByDate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --length: string # (Required) Integer  Max number of days before ending_at to include in the returned series - must be between 1 and 100 inclusive (e.g. 10)
  --ending-at: string # (Optional) DateTime (ISO 8601 string)  Point in time when the data series should end - defaults to time of the request (e.g. 2018-06-28T23:59:59-5:00)
  --app-id: string # (Optional) String  App API identifier; if excluded, results for all apps in app group will be returned (e.g. {{app_identifier}})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "length" $length "scalar") (serialize-qp "ending_at" $ending_at "scalar") (serialize-qp "app_id" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kpi/dau/data_series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Monthly Active Users for Last 30 Days
#
# GET /kpi/mau/data_series
# operationId: monthlyActiveUsersForLast30Days
export def "kpi-mau-data-series monthlyActiveUsersForLast30Days" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --length: string # (Required) Integer  Max number of days before ending_at to include in the returned series - must be between 1 and 100 inclusive (e.g. 7)
  --ending-at: string # (Optional) DateTime (ISO 8601 string)  Point in time when the data series should end - defaults to time of the request (e.g. 2018-06-28T23:59:59-05:00)
  --app-id: string # (Optional) String  App API identifier; if excluded, results for all apps in app group will be returned (e.g. {{app_identifier}})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "length" $length "scalar") (serialize-qp "ending_at" $ending_at "scalar") (serialize-qp "app_id" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kpi/mau/data_series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Daily New Users by Date
#
# GET /kpi/new_users/data_series
# operationId: dailyNewUsersByDate
export def "kpi-new-users-data-series dailyNewUsersByDate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --length: string # (Required) Integer  Max number of days before ending_at to include in the returned series - must be between 1 and 100 inclusive (e.g. 14)
  --ending-at: string # (Optional) DateTime (ISO 8601 string)  Point in time when the data series should end - defaults to time of the request (e.g. 2018-06-28T23:59:59-5:00)
  --app-id: string # (Optional) String  App API identifier; if excluded, results for all apps in app group will be returned (e.g. {{app_identifier}})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "length" $length "scalar") (serialize-qp "ending_at" $ending_at "scalar") (serialize-qp "app_id" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kpi/new_users/data_series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# KPIs for Daily App Uninstalls by Date
#
# GET /kpi/uninstalls/data_series
# operationId: kpIsForDailyAppUninstallsByDate
export def "kpi-uninstalls-data-series kpIsForDailyAppUninstallsByDate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --length: string # (Required) Integer  Max number of days before ending_at to include in the returned series - must be between 1 and 100 inclusive (e.g. 14)
  --ending-at: string # (Optional) DateTime (ISO 8601 string)  Point in time when the data series should end - defaults to time of the request (e.g. 2018-06-28T23:59:59-5:00)
  --app-id: string # (Optional) String  App API identifier; if excluded, results for all apps in app group will be returned (e.g. {{app_identifier}})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "length" $length "scalar") (serialize-qp "ending_at" $ending_at "scalar") (serialize-qp "app_id" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/kpi/uninstalls/data_series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Upcoming Scheduled Campaigns and Canvases
#
# GET /messages/scheduled_broadcasts
# operationId: getUpcomingScheduledCampaignsAndCanvases
export def "messages-scheduled-broadcasts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --end-time: string # (Required) String in ISO 8601 format  End date of the range to retrieve upcoming scheduled Campaigns and Canvases. This is treated as midnight in UTC time by the API. (e.g. 2018-09-01T00:00:00-04:00)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messages/scheduled_broadcasts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Segment Analytics
#
# GET /segments/data_series
# operationId: segmentAnalytics
export def "segments-data-series segmentAnalytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --segment-id: string # (Required) String  Segment API identifier. (e.g. {{segment_identifier}})
  --length: string # (Required) Integer  Max number of days before `ending_at` to include in the returned series - must be between 1 and 100 inclusive. (e.g. 14)
  --ending-at: string # (Optional) DateTime (ISO 8601 string)  Point in time when the data series should end - defaults to time of the request. (e.g. 2018-06-27T23:59:59-5:00)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "segment_id" $segment_id "scalar") (serialize-qp "length" $length "scalar") (serialize-qp "ending_at" $ending_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/segments/data_series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Segment Details
#
# GET /segments/details
# operationId: segmentDetails
export def "segments-details segmentDetails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --segment-id: string # (Required) String  Segment API identifier (e.g. {{segment_identifier}})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "segment_id" $segment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/segments/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Segment List
#
# GET /segments/list
# operationId: segmentList
export def "segments-list segmentList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # (Optional) Integer  The page of segments to return, defaults to 0 (returns the first set of up to 100) (e.g. 1)
  --sort-direction: string # (Optional) String  Pass in the value `desc` to sort by creation time from newest to oldest. Pass in `asc` to sort from oldest to newest. If `sort_direction` is not included, the default order is oldest to newest. (e.g. desc)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "sort_direction" $sort_direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/segments/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send Analytics
#
# GET /sends/data_series
# operationId: sendAnalytics
export def "sends-data-series sendAnalytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaign-id: string # (Required) String  Campaign API identifier. (e.g. {{campaign_identifier}})
  --send-id: string # (Required) String  Send API identifier. (e.g. {{send_identifier}})
  --length: string # (Required) Integer  Maximum number of days before `ending_at` to include in the returned series. Must be between 1 and 100 inclusive. (e.g. 30)
  --ending-at: string # (Optional) Datetime ISO 8601 string  Date on which the data series should end. Defaults to time of the request. (e.g. 2014-12-10T23:59:59-05:00)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "campaign_id" $campaign_id "scalar") (serialize-qp "send_id" $send_id "scalar") (serialize-qp "length" $length "scalar") (serialize-qp "ending_at" $ending_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sends/data_series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# App Sessions by Time
#
# GET /sessions/data_series
# operationId: appSessionsByTime
export def "sessions-data-series appSessionsByTime" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --length: string # (Required) Integer  Max number of units (days or hours) before ending_at to include in the returned series - must be between 1 and 100 inclusive. (e.g. 14)
  --unit: string # (Optional) String  Unit of time between data points - can be "day" or "hour" (defaults to "day").  (e.g. day)
  --ending-at: string # (Optional) DateTime (ISO 8601 string)  Point in time when the data series should end - defaults to time of the request. (e.g. 2018-06-28T23:59:59-5:00)
  --app-id: string # (Optional) String  App API identifier retrieved from the Developer Console to limit analytics to a specific app. (e.g. {{app_identifier}})
  --segment-id: string # (Optional) String  Segment API identifier indicating the analytics enabled segment for which sessions should be returned. (e.g. {{segment_identifier}})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "length" $length "scalar") (serialize-qp "unit" $unit "scalar") (serialize-qp "ending_at" $ending_at "scalar") (serialize-qp "app_id" $app_id "scalar") (serialize-qp "segment_id" $segment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sessions/data_series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User's  Subscription Group Status - SMS
#
# GET /subscription/status/get
# operationId: listUser'sSubscriptionGroupStatusSms
export def "subscription-status-get listUsersSubscriptionGroupStatusSms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscription-group-id: string # (Required) String  The `id` of your subscription group. (e.g. {{subscription_group_id}})
  --external-id: string # (Required*) String  The `external_id` of the user (must include at least one and at most 50 `external_ids`).  Only external_id or phone is accepted for SMS subscription groups  (e.g. {{external_identifier}})
  --phone: string # (Required*) String  The phone number of the user (must include at least one phone number and at most 50 phone numbers). The recommendation is to provide this in the E.164 format.  Only external_id or phone is accepted for SMS subscription groups  (e.g. +11112223333)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_group_id" $subscription_group_id "scalar") (serialize-qp "external_id" $external_id "scalar") (serialize-qp "phone" $phone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subscription/status/get" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User's Subscription Group - SMS
#
# GET /subscription/user/status
# operationId: listUser'sSubscriptionGroupSms
export def "subscription-user-status listUsersSubscriptionGroupSms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --external-id: string # (Required*) String  The external_id of the user. Must include at least one and at most 50 `external_ids`. (e.g. {{external_id}})
  --limit: string # (Optional) Integer  The limit on the maximum number of results returned. Default (and max) limit is 100. (e.g. 100)
  --offset: string # (Optional) Integer  Number of templates to skip before returning rest of the templates that fit the search criteria. (e.g. 1)
  --phone: string # (Required*) String  The phone number of the user (must include at least one phone number and at most 50 phone numbers). The recommendation is to provide this in the E.164 format.  (e.g. +11112223333)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "external_id" $external_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "phone" $phone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subscription/user/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# See Email Template Information
#
# GET /templates/email/info
# operationId: seeEmailTemplateInformation
export def "templates-email-info seeEmailTemplateInformation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email-template-id: string # (Required) String  Your email template's API Identifier. (e.g. {{email_template_id}})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email_template_id" $email_template_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/templates/email/info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Available Email Templates
#
# GET /templates/email/list
# operationId: listAvailableEmailTemplates
export def "templates-email-list listAvailableEmailTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --modified-after: string # (Optional) String in ISO 8601  Retrieve only templates updated at or after the given time. (e.g. 2020-01-01T01:01:01.000000)
  --modified-before: string # (Optional) String in ISO 8601  Retrieve only templates updated at or before the given time (e.g. 2020-02-01T01:01:01.000000)
  --limit: string # (Optional) Positive Number  Maximum number of templates to retrieve, default to 100 if not provided, maximum acceptable value is 1000. (e.g. 1)
  --offset: string # (Optional) Positive Number  Number of templates to skip before returning rest of the templates that fit the search criteria. (e.g. 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "modified_after" $modified_after "scalar") (serialize-qp "modified_before" $modified_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/templates/email/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
