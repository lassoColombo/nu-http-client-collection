# Auto-generated client for API Endpoints v1.0.0
# Source: https://developer.close.com/openapi.json
# Auth: --token flag or $env.API_ENDPOINTS_TOKEN

const BASE_URL = "https://api.close.com/api/v1"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o API_ENDPOINTS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://api.close.com/api/v1"] }
def auth-scheme-completer [] { ["basic" "bearer"] }

# Completers for enum parameters
def value-period-completer [] { ["annual" "monthly" "one_time"] }
def type-completer [] { ["lead"] }
def priority-completer [] { ["high" "medium"] }
def direction-completer [] { ["inbound" "outbound"] }
def source-completer [] { ["Close.io" "External"] }
def status-completer [] { ["busy" "cancel" "completed" "created" "failed" "in-progress" "no-answer" "timeout"] }
def status-completer-1 [] { ["draft" "error" "inbox" "outbox" "scheduled" "sent"] }
def direction-completer-1 [] { ["incoming" "outgoing"] }
def status-completer-2 [] { ["draft" "published"] }
def transform-y-completer [] { ["avg" "max" "min" "sum"] }
def object-type-completer [] { ["contact" "lead"] }
def type-completer-1 [] { ["contact" "lead" "opportunity"] }
def bulk-object-type-completer [] { ["contact" "lead"] }
def contact-preference-completer [] { ["all" "contact" "lead"] }
def mode-completer [] { ["contact" "lead"] }
def status-completer-3 [] { ["active" "archived"] }
def type-completer-2 [] { ["custom" "vm-dropped"] }
def sharing-completer [] { ["group" "personal"] }
def order-by-completer [] { ["first_name,last_name" "last_name,first_name"] }
def auto-record-calls-completer [] { ["disabled" "enabled" "unset"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "lead list" } } | get name | first)
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

# List Leads
#
# GET /lead/
# operationId: list
export def "lead list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<data: table<addresses: list, contact_ids: list, contacts: list, contacts_summary: string, created_by: string, created_by_name: string, date_created: string, date_updated: string, description: string, display_name: string, html_url: string, id: string, integration_links: list, localtime: string, name: string, opportunities: list, organization_id: string, primary_address_summary: string, primary_email: any, primary_phone: any, recent_calls: list, source: string, status_id: string, status_label: string, summaries: list, tasks: list, updated_by: string, updated_by_name: string, url: string>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lead/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new lead
#
# POST /lead/
# operationId: create
export def "lead create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record<addresses: table<address_1: string, address_2: string, city: string, country: string, label: string, state: string, tz_ids: list, zipcode: string>, contact_ids: list<string>, contacts: table<created_by: string, date_created: string, date_updated: string, display_name: string, emails: list, id: string, integration_links: list, lead_id: string, lead_suggestions_operation_id: string, name: string, organization_id: string, phones: list, recent_calls: list, subscriptions: list, timezone: string, timezone_source: string, title: string, updated_by: string, urls: list>, contacts_summary: string, created_by: string, created_by_name: string, date_created: string, date_updated: string, description: string, display_name: string, html_url: string, id: string, integration_links: table<name: string, url: string>, localtime: string, name: string, opportunities: table<annualized_expected_value: int, annualized_value: int, attachments: list, comment_summary: any, confidence: int, contact_id: string, contact_name: string, created_by: string, created_by_name: string, date_created: string, date_lost: string, date_updated: string, date_won: string, expected_value: int, id: string, integration_links: list, is_stalled: bool, lead_id: string, lead_name: string, lead_primary_email: any, lead_primary_phone: list, note: string, organization_id: string, pipeline_id: string, pipeline_name: string, stall_status: any, status_display_name: string, status_id: string, status_label: string, status_type: string, suggested_action: any, updated_by: string, updated_by_name: string, user_id: string, user_name: string, value: int, value_currency: string, value_formatted: string, value_period: string>, organization_id: string, primary_address_summary: string, primary_email: any, primary_phone: any, recent_calls: list<record>, source: string, status_id: string, status_label: string, summaries: list<record>, tasks: list<record>, updated_by: string, updated_by_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lead/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Merge two leads
#
# POST /lead/merge/
# operationId: merge
export def "lead-merge merge" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lead/merge/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single Lead
#
# GET /lead/{id}/
# operationId: get
export def "lead get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<addresses: table<address_1: string, address_2: string, city: string, country: string, label: string, state: string, tz_ids: list, zipcode: string>, contact_ids: list<string>, contacts: table<created_by: string, date_created: string, date_updated: string, display_name: string, emails: list, id: string, integration_links: list, lead_id: string, lead_suggestions_operation_id: string, name: string, organization_id: string, phones: list, recent_calls: list, subscriptions: list, timezone: string, timezone_source: string, title: string, updated_by: string, urls: list>, contacts_summary: string, created_by: string, created_by_name: string, date_created: string, date_updated: string, description: string, display_name: string, html_url: string, id: string, integration_links: table<name: string, url: string>, localtime: string, name: string, opportunities: table<annualized_expected_value: int, annualized_value: int, attachments: list, comment_summary: any, confidence: int, contact_id: string, contact_name: string, created_by: string, created_by_name: string, date_created: string, date_lost: string, date_updated: string, date_won: string, expected_value: int, id: string, integration_links: list, is_stalled: bool, lead_id: string, lead_name: string, lead_primary_email: any, lead_primary_phone: list, note: string, organization_id: string, pipeline_id: string, pipeline_name: string, stall_status: any, status_display_name: string, status_id: string, status_label: string, status_type: string, suggested_action: any, updated_by: string, updated_by_name: string, user_id: string, user_name: string, value: int, value_currency: string, value_formatted: string, value_period: string>, organization_id: string, primary_address_summary: string, primary_email: any, primary_phone: any, recent_calls: list<record>, source: string, status_id: string, status_label: string, summaries: list<record>, tasks: list<record>, updated_by: string, updated_by_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lead/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing lead
#
# PUT /lead/{id}/
# operationId: update
export def "lead update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record<addresses: table<address_1: string, address_2: string, city: string, country: string, label: string, state: string, tz_ids: list, zipcode: string>, contact_ids: list<string>, contacts: table<created_by: string, date_created: string, date_updated: string, display_name: string, emails: list, id: string, integration_links: list, lead_id: string, lead_suggestions_operation_id: string, name: string, organization_id: string, phones: list, recent_calls: list, subscriptions: list, timezone: string, timezone_source: string, title: string, updated_by: string, urls: list>, contacts_summary: string, created_by: string, created_by_name: string, date_created: string, date_updated: string, description: string, display_name: string, html_url: string, id: string, integration_links: table<name: string, url: string>, localtime: string, name: string, opportunities: table<annualized_expected_value: int, annualized_value: int, attachments: list, comment_summary: any, confidence: int, contact_id: string, contact_name: string, created_by: string, created_by_name: string, date_created: string, date_lost: string, date_updated: string, date_won: string, expected_value: int, id: string, integration_links: list, is_stalled: bool, lead_id: string, lead_name: string, lead_primary_email: any, lead_primary_phone: list, note: string, organization_id: string, pipeline_id: string, pipeline_name: string, stall_status: any, status_display_name: string, status_id: string, status_label: string, status_type: string, suggested_action: any, updated_by: string, updated_by_name: string, user_id: string, user_name: string, value: int, value_currency: string, value_formatted: string, value_period: string>, organization_id: string, primary_address_summary: string, primary_email: any, primary_phone: any, recent_calls: list<record>, source: string, status_id: string, status_label: string, summaries: list<record>, tasks: list<record>, updated_by: string, updated_by_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lead/($id)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a lead
#
# DELETE /lead/{id}/
# operationId: delete
export def "lead delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lead/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List contacts
#
# GET /contact/
# operationId: list
export def "contact list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --lead-id: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<data: table<created_by: string, date_created: string, date_updated: string, display_name: string, emails: list, id: string, integration_links: list, lead_id: string, lead_suggestions_operation_id: string, name: string, organization_id: string, phones: list, recent_calls: list, subscriptions: list, timezone: string, timezone_source: string, title: string, updated_by: string, urls: list>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "_fields" $qp_fields "scalar") (serialize-qp "lead_id" $lead_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contact/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new contact
#
# POST /contact/
# operationId: create
# --emails item shape: {email: string, type?: string}
# --phones item shape: {phone?: string, type?: string}
# --urls item shape: {type?: string, url: string}
export def "contact create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
  --created-by: string # nullable
  --date-created: string # nullable, format: date-time
  --emails: list # nullable — item shape: {email: string, type?: string}
  --lead-id: string # nullable
  --name: string # nullable
  --phones: list # nullable — item shape: {phone?: string, type?: string}
  --timezone: string # IANA timezone identifier (nullable)
  --title: string # nullable
  --urls: list # nullable — item shape: {type?: string, url: string}
]: any -> record<created_by: string, date_created: string, date_updated: string, display_name: string, emails: table<email: string, is_unsubscribed: bool, type: string>, id: string, integration_links: table<name: string, url: string>, lead_id: string, lead_suggestions_operation_id: string, name: string, organization_id: string, phones: table<country: string, outbound_sms_blocked: bool, phone: string, phone_formatted: string, type: string, tz_ids: list>, recent_calls: table<dialer_id: string, duration: int, finish_timestamp: string, id: string, status: string>, subscriptions: table<contact_email: string, date_created: string, initial_email_id: string, sequence_id: string, sequence_name: string, sequence_status: string, start_date: string, subscription_id: string, subscription_status: string, subscription_status_reason: any>, timezone: string, timezone_source: string, title: string, updated_by: string, urls: table<type: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contact/" $qp)
  let body = {created_by: $created_by, date_created: $date_created, emails: $emails, lead_id: $lead_id, name: $name, phones: $phones, timezone: $timezone, title: $title, urls: $urls} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a single contact
#
# GET /contact/{id}/
# operationId: get
export def "contact get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<created_by: string, date_created: string, date_updated: string, display_name: string, emails: table<email: string, is_unsubscribed: bool, type: string>, id: string, integration_links: table<name: string, url: string>, lead_id: string, lead_suggestions_operation_id: string, name: string, organization_id: string, phones: table<country: string, outbound_sms_blocked: bool, phone: string, phone_formatted: string, type: string, tz_ids: list>, recent_calls: table<dialer_id: string, duration: int, finish_timestamp: string, id: string, status: string>, subscriptions: table<contact_email: string, date_created: string, initial_email_id: string, sequence_id: string, sequence_name: string, sequence_status: string, start_date: string, subscription_id: string, subscription_status: string, subscription_status_reason: any>, timezone: string, timezone_source: string, title: string, updated_by: string, urls: table<type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contact/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing contact
#
# PUT /contact/{id}/
# operationId: update
# --emails item shape: {email: string, type?: string}
# --phones item shape: {phone?: string, type?: string}
# --urls item shape: {type?: string, url: string}
export def "contact update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
  --emails: list # nullable — item shape: {email: string, type?: string}
  --lead-id: string # nullable
  --name: string # nullable
  --phones: list # nullable — item shape: {phone?: string, type?: string}
  --timezone: string # IANA timezone identifier (nullable)
  --title: string # nullable
  --urls: list # nullable — item shape: {type?: string, url: string}
]: any -> record<created_by: string, date_created: string, date_updated: string, display_name: string, emails: table<email: string, is_unsubscribed: bool, type: string>, id: string, integration_links: table<name: string, url: string>, lead_id: string, lead_suggestions_operation_id: string, name: string, organization_id: string, phones: table<country: string, outbound_sms_blocked: bool, phone: string, phone_formatted: string, type: string, tz_ids: list>, recent_calls: table<dialer_id: string, duration: int, finish_timestamp: string, id: string, status: string>, subscriptions: table<contact_email: string, date_created: string, initial_email_id: string, sequence_id: string, sequence_name: string, sequence_status: string, start_date: string, subscription_id: string, subscription_status: string, subscription_status_reason: any>, timezone: string, timezone_source: string, title: string, updated_by: string, urls: table<type: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contact/($id)/" $qp)
  let body = {emails: $emails, lead_id: $lead_id, name: $name, phones: $phones, timezone: $timezone, title: $title, urls: $urls} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a contact
#
# DELETE /contact/{id}/
# operationId: delete
export def "contact delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contact/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or filter opportunities
#
# GET /opportunity/
# operationId: list
export def "opportunity list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --lead-id: string
  --organization-id: string
  --user-id: string
  --user-id-in: string
  --status-id: string
  --status-id-in: string
  --status-type: string
  --status-type-in: string
  --status-label: string
  --status-label-in: string
  --status: string
  --status-in: string
  --date-won: string
  --date-won-gte: string
  --date-won-gt: string
  --date-won-lte: string
  --date-won-lt: string
  --date-created: string
  --date-created-gte: string
  --date-created-gt: string
  --date-created-lte: string
  --date-created-lt: string
  --date-updated: string
  --date-updated-gte: string
  --date-updated-gt: string
  --date-updated-lte: string
  --date-updated-lt: string
  --value-period: string
  --value-period-in: string
  --qp-query: string
  --lead-query: string
  --lead-saved-search-id: string
  --is-stalled: string
  --order-by: string
  --group-by: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<data: table<annualized_expected_value: int, annualized_value: int, attachments: list, comment_summary: any, confidence: int, contact_id: string, contact_name: string, created_by: string, created_by_name: string, date_created: string, date_lost: string, date_updated: string, date_won: string, expected_value: int, id: string, integration_links: list, is_stalled: bool, lead_id: string, lead_name: string, lead_primary_email: any, lead_primary_phone: list, note: string, organization_id: string, pipeline_id: string, pipeline_name: string, stall_status: any, status_display_name: string, status_id: string, status_label: string, status_type: string, suggested_action: any, updated_by: string, updated_by_name: string, user_id: string, user_name: string, value: int, value_currency: string, value_formatted: string, value_period: string>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "_fields" $qp_fields "scalar") (serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "user_id__in" $user_id_in "scalar") (serialize-qp "status_id" $status_id "scalar") (serialize-qp "status_id__in" $status_id_in "scalar") (serialize-qp "status_type" $status_type "scalar") (serialize-qp "status_type__in" $status_type_in "scalar") (serialize-qp "status_label" $status_label "scalar") (serialize-qp "status_label__in" $status_label_in "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "status__in" $status_in "scalar") (serialize-qp "date_won" $date_won "scalar") (serialize-qp "date_won__gte" $date_won_gte "scalar") (serialize-qp "date_won__gt" $date_won_gt "scalar") (serialize-qp "date_won__lte" $date_won_lte "scalar") (serialize-qp "date_won__lt" $date_won_lt "scalar") (serialize-qp "date_created" $date_created "scalar") (serialize-qp "date_created__gte" $date_created_gte "scalar") (serialize-qp "date_created__gt" $date_created_gt "scalar") (serialize-qp "date_created__lte" $date_created_lte "scalar") (serialize-qp "date_created__lt" $date_created_lt "scalar") (serialize-qp "date_updated" $date_updated "scalar") (serialize-qp "date_updated__gte" $date_updated_gte "scalar") (serialize-qp "date_updated__gt" $date_updated_gt "scalar") (serialize-qp "date_updated__lte" $date_updated_lte "scalar") (serialize-qp "date_updated__lt" $date_updated_lt "scalar") (serialize-qp "value_period" $value_period "scalar") (serialize-qp "value_period__in" $value_period_in "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "lead_query" $lead_query "scalar") (serialize-qp "lead_saved_search_id" $lead_saved_search_id "scalar") (serialize-qp "is_stalled" $is_stalled "scalar") (serialize-qp "_order_by" $order_by "scalar") (serialize-qp "_group_by" $group_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/opportunity/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an opportunity
#
# POST /opportunity/
# operationId: create
# --attachments item shape: {content_type?: string, filename: string, url: string}
export def "opportunity create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --attachments: list # nullable — item shape: {content_type?: string, filename: string, url: string}
  --confidence: int # nullable
  --contact-id: string # nullable
  --created-by: string # nullable
  --date-created: string # nullable, format: date-time
  --date-won: string # If not set on the resource or in the request, `date_won` will be set automatically to today's date when setting `status_id` to a status with type `won`. The `x-tz-offset` header, used to pass your timezone's UTC offset, will be taken into account. (nullable, format: date-time)
  --lead-id: string # Opportunities belong to exactly one Lead. If not provided, a new lead will be created (appearing as "Untitled" in the UI). (nullable)
  --note: string # nullable
  --pipeline-id: string # Specify which pipeline this opportunity should belong to. When supplied without `status_id`, the opportunity will be created with the first available status of that pipeline. When supplied with `status_id`, the status must belong to the specified pipeline or a 400 error will be returned. If the pipeline does not exist, a 400 error will be returned. See the [Pipelines API](https://developer.close.com/api/resources/pipelines). (nullable)
  --status-id: string # Post a `status_id` to create an opportunity with a specific status. If omitted, the organization's default (first) status will be used (or the first status of the `pipeline_id` if provided). See the [Opportunity Status API](https://developer.close.com/api/resources/opportunity-statuses). (nullable)
  --user-id: string # nullable
  --value: int # nullable
  --value-period: any
]: any -> record<annualized_expected_value: int, annualized_value: int, attachments: table<content_type: string, filename: string, size: int, thumbnail_url: string, url: string>, comment_summary: any, confidence: int, contact_id: string, contact_name: string, created_by: string, created_by_name: string, date_created: string, date_lost: string, date_updated: string, date_won: string, expected_value: int, id: string, integration_links: table<name: string, url: string>, is_stalled: bool, lead_id: string, lead_name: string, lead_primary_email: any, lead_primary_phone: table<country: string, outbound_sms_blocked: bool, phone: string, phone_formatted: string, type: string, tz_ids: list>, note: string, organization_id: string, pipeline_id: string, pipeline_name: string, stall_status: any, status_display_name: string, status_id: string, status_label: string, status_type: string, suggested_action: any, updated_by: string, updated_by_name: string, user_id: string, user_name: string, value: int, value_currency: string, value_formatted: string, value_period: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/opportunity/")
  let body = {attachments: $attachments, confidence: $confidence, contact_id: $contact_id, created_by: $created_by, date_created: $date_created, date_won: $date_won, lead_id: $lead_id, note: $note, pipeline_id: $pipeline_id, status_id: $status_id, user_id: $user_id, value: $value, value_period: $value_period} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an opportunity
#
# GET /opportunity/{id}/
# operationId: get
export def "opportunity get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<annualized_expected_value: int, annualized_value: int, attachments: table<content_type: string, filename: string, size: int, thumbnail_url: string, url: string>, comment_summary: any, confidence: int, contact_id: string, contact_name: string, created_by: string, created_by_name: string, date_created: string, date_lost: string, date_updated: string, date_won: string, expected_value: int, id: string, integration_links: table<name: string, url: string>, is_stalled: bool, lead_id: string, lead_name: string, lead_primary_email: any, lead_primary_phone: table<country: string, outbound_sms_blocked: bool, phone: string, phone_formatted: string, type: string, tz_ids: list>, note: string, organization_id: string, pipeline_id: string, pipeline_name: string, stall_status: any, status_display_name: string, status_id: string, status_label: string, status_type: string, suggested_action: any, updated_by: string, updated_by_name: string, user_id: string, user_name: string, value: int, value_currency: string, value_formatted: string, value_period: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/opportunity/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an opportunity
#
# PUT /opportunity/{id}/
# operationId: update
# --attachments item shape: {content_type?: string, filename: string, url: string}
export def "opportunity update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --attachments: list # item shape: {content_type?: string, filename: string, url: string}
  --confidence: int
  --contact-id: string # nullable
  --date-won: string # If not set on the resource or in the request, `date_won` will be set automatically to today's date when setting `status_id` to a status with type `won`. The `x-tz-offset` header, used to pass your timezone's UTC offset, will be taken into account. (nullable, format: date-time)
  --note: string
  --status: string
  --status-id: string # Setting the `status_id` to a status with a type of `won` will automatically set the `date_won` field if it is not already set or provided in the request. Reverting it from a `won` status to an `active` or `lost` will not automatically change `date_won`.
  --user-id: string # nullable
  --value: int
  --value-period: string@value-period-completer
]: any -> record<annualized_expected_value: int, annualized_value: int, attachments: table<content_type: string, filename: string, size: int, thumbnail_url: string, url: string>, comment_summary: any, confidence: int, contact_id: string, contact_name: string, created_by: string, created_by_name: string, date_created: string, date_lost: string, date_updated: string, date_won: string, expected_value: int, id: string, integration_links: table<name: string, url: string>, is_stalled: bool, lead_id: string, lead_name: string, lead_primary_email: any, lead_primary_phone: table<country: string, outbound_sms_blocked: bool, phone: string, phone_formatted: string, type: string, tz_ids: list>, note: string, organization_id: string, pipeline_id: string, pipeline_name: string, stall_status: any, status_display_name: string, status_id: string, status_label: string, status_type: string, suggested_action: any, updated_by: string, updated_by_name: string, user_id: string, user_name: string, value: int, value_currency: string, value_formatted: string, value_period: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/opportunity/($id)/")
  let body = {attachments: $attachments, confidence: $confidence, contact_id: $contact_id, date_won: $date_won, note: $note, status: $status, status_id: $status_id, user_id: $user_id, value: $value, value_period: $value_period} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an opportunity
#
# DELETE /opportunity/{id}/
# operationId: delete
export def "opportunity delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/opportunity/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or filter tasks
#
# GET /task/
# operationId: list
export def "task list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --assigned-to: string
  --format: string
  --id: string
  --id-in: string
  --is-complete: string
  --lead-id: string
  --order-by: string
  --organization-id: string
  --type: string
  --type-in: string
  --view: string
  --date: string
  --date-lt: string
  --date-lte: string
  --date-gt: string
  --date-gte: string
  --due-date: string
  --due-date-lt: string
  --due-date-lte: string
  --due-date-gt: string
  --due-date-gte: string
  --date-created-lt: string
  --date-created-lte: string
  --date-created-gt: string
  --date-created-gte: string
  --date-updated-lt: string
  --date-updated-lte: string
  --date-updated-gt: string
  --date-updated-gte: string
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "assigned_to" $assigned_to "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "id__in" $id_in "scalar") (serialize-qp "is_complete" $is_complete "scalar") (serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "_order_by" $order_by "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "_type" $type "scalar") (serialize-qp "_type__in" $type_in "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "date__lt" $date_lt "scalar") (serialize-qp "date__lte" $date_lte "scalar") (serialize-qp "date__gt" $date_gt "scalar") (serialize-qp "date__gte" $date_gte "scalar") (serialize-qp "due_date" $due_date "scalar") (serialize-qp "due_date__lt" $due_date_lt "scalar") (serialize-qp "due_date__lte" $due_date_lte "scalar") (serialize-qp "due_date__gt" $due_date_gt "scalar") (serialize-qp "due_date__gte" $due_date_gte "scalar") (serialize-qp "date_created__lt" $date_created_lt "scalar") (serialize-qp "date_created__lte" $date_created_lte "scalar") (serialize-qp "date_created__gt" $date_created_gt "scalar") (serialize-qp "date_created__gte" $date_created_gte "scalar") (serialize-qp "date_updated__lt" $date_updated_lt "scalar") (serialize-qp "date_updated__lte" $date_updated_lte "scalar") (serialize-qp "date_updated__gt" $date_updated_gt "scalar") (serialize-qp "date_updated__gte" $date_updated_gte "scalar") (serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/task/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a task
#
# POST /task/
# Discriminator (request): _type
# operationId: create
export def "task create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
  type: string@type-completer # Discriminator value: lead
  --assigned-to: string # nullable
  --contact-id: string # nullable
  --created-by: string
  --date: any
  --date-created: any
  --disable-notification: oneof<nothing, bool> # default: false
  --due-date: any
  --is-complete: oneof<nothing, bool>
  --is-dateless: oneof<nothing, bool>
  --lead-id: string
  --organization-id: string
  --priority: string@priority-completer
  --text: string
  --agent-config-id: string # nullable
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/task/" $qp)
  let body = {_type: $type, assigned_to: $assigned_to, contact_id: $contact_id, created_by: $created_by, date: $date, date_created: $date_created, disable_notification: $disable_notification, due_date: $due_date, is_complete: $is_complete, is_dateless: $is_dateless, lead_id: $lead_id, organization_id: $organization_id, priority: $priority, text: $text, agent_config_id: $agent_config_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk-update tasks
#
# PUT /task/
# operationId: bulk-update
export def "task bulk-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --assigned-to: string
  --format: string
  --id: string
  --id-in: string
  --is-complete: string
  --lead-id: string
  --order-by: string
  --organization-id: string
  --type: string
  --type-in: string
  --view: string
  --date: string
  --date-lt: string
  --date-lte: string
  --date-gt: string
  --date-gte: string
  --due-date: string
  --due-date-lt: string
  --due-date-lte: string
  --due-date-gt: string
  --due-date-gte: string
  --date-created-lt: string
  --date-created-lte: string
  --date-created-gt: string
  --date-created-gte: string
  --date-updated-lt: string
  --date-updated-lte: string
  --date-updated-gt: string
  --date-updated-gte: string
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
  --assigned-to: string
  --date: any
  --is-complete: oneof<nothing, bool>
  --organization-id: string
  --priority: string@priority-completer
  --resolution: any
  --text: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assigned_to" $assigned_to "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "id__in" $id_in "scalar") (serialize-qp "is_complete" $is_complete "scalar") (serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "_order_by" $order_by "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "_type" $type "scalar") (serialize-qp "_type__in" $type_in "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "date__lt" $date_lt "scalar") (serialize-qp "date__lte" $date_lte "scalar") (serialize-qp "date__gt" $date_gt "scalar") (serialize-qp "date__gte" $date_gte "scalar") (serialize-qp "due_date" $due_date "scalar") (serialize-qp "due_date__lt" $due_date_lt "scalar") (serialize-qp "due_date__lte" $due_date_lte "scalar") (serialize-qp "due_date__gt" $due_date_gt "scalar") (serialize-qp "due_date__gte" $due_date_gte "scalar") (serialize-qp "date_created__lt" $date_created_lt "scalar") (serialize-qp "date_created__lte" $date_created_lte "scalar") (serialize-qp "date_created__gt" $date_created_gt "scalar") (serialize-qp "date_created__gte" $date_created_gte "scalar") (serialize-qp "date_updated__lt" $date_updated_lt "scalar") (serialize-qp "date_updated__lte" $date_updated_lte "scalar") (serialize-qp "date_updated__gt" $date_updated_gt "scalar") (serialize-qp "date_updated__gte" $date_updated_gte "scalar") (serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/task/" $qp)
  let body = {assigned_to: $assigned_to, date: $date, is_complete: $is_complete, organization_id: $organization_id, priority: $priority, resolution: $resolution, text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a task's details
#
# GET /task/{id}/
# operationId: get
export def "task get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/task/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a task
#
# PUT /task/{id}/
# operationId: update
export def "task update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
  --agent-config-id: string # nullable
  --assigned-to: string
  --contact-id: string # nullable
  --created-by: string
  --date: any
  --due-date: any
  --is-complete: oneof<nothing, bool>
  --is-dateless: oneof<nothing, bool>
  --lead-id: string
  --organization-id: string
  --priority: string@priority-completer
  --resolution: any
  --text: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/task/($id)/" $qp)
  let body = {agent_config_id: $agent_config_id, assigned_to: $assigned_to, contact_id: $contact_id, created_by: $created_by, date: $date, due_date: $due_date, is_complete: $is_complete, is_dateless: $is_dateless, lead_id: $lead_id, organization_id: $organization_id, priority: $priority, resolution: $resolution, text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a task
#
# DELETE /task/{id}/
# operationId: delete
export def "task delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/task/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate a signed S3 POST
#
# POST /files/upload/
# operationId: create
export def "files-upload create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  content_type: string
  filename: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files/upload/")
  let body = {content_type: $content_type, filename: $filename} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Custom Object instances
#
# GET /custom_object/
# operationId: list
export def "custom-object list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lead-id: string
  --custom-object-type-id: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "custom_object_type_id" $custom_object_type_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_object/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Custom Object instance
#
# POST /custom_object/
# operationId: create
export def "custom-object create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom_object/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a single Custom Object instance
#
# GET /custom_object/{id}/
# operationId: get
export def "custom-object get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_object/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updating a Custom Object instance
#
# PUT /custom_object/{id}/
# operationId: update
export def "custom-object update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_object/($id)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Custom Object instance
#
# DELETE /custom_object/{id}/
# operationId: delete
export def "custom-object delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_object/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch multiple comments
#
# GET /comment/
# operationId: list
export def "comment list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --thread-id: string
  --object-id: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "thread_id" $thread_id "scalar") (serialize-qp "object_id" $object_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/comment/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Comment
#
# POST /comment/
# operationId: create
export def "comment create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body-body: string
  object_id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/comment/")
  let body = {body: $body_body, object_id: $object_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch an individual comment
#
# GET /comment/{id}/
# operationId: get
export def "comment get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comment/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Comment
#
# PUT /comment/{id}/
# operationId: update
export def "comment update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body-body: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comment/($id)/")
  let body = {body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a comment
#
# DELETE /comment/{id}/
# operationId: delete
export def "comment delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comment/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch multiple comment threads
#
# GET /comment_thread/
# operationId: list-threads
export def "comment-thread list-threads" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --ids: list
  --object-ids: list
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "ids" $ids "scalar") (serialize-qp "object_ids" $object_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/comment_thread/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch an individual comment thread
#
# GET /comment_thread/{id}/
# operationId: get-thread
export def "comment-thread get-thread" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comment_thread/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or filter all activity types
#
# GET /activity/
# operationId: list
export def "activity list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --id-in: list # Filter by activity IDs (comma-separated)
  --lead-id: list # Filter by lead IDs (comma-separated)
  --contact-id: list # Filter by contact IDs (comma-separated)
  --user-id: list # Filter by user IDs (comma-separated)
  --organization-id: string
  --type: list # Filter by activity type, e.g. Call (comma-separated)
  --date-created-gte: string
  --date-created-lte: string
  --date-created-gt: string
  --date-created-lt: string
  --activity-at-gte: string
  --activity-at-lte: string
  --activity-at-gt: string
  --activity-at-lt: string
  --lead-id-in: string
  --user-id-in: string
  --contact-id-in: string
  --type-in: string
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --order-by: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "id__in" $id_in "scalar") (serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "_type" $type "scalar") (serialize-qp "date_created__gte" $date_created_gte "scalar") (serialize-qp "date_created__lte" $date_created_lte "scalar") (serialize-qp "date_created__gt" $date_created_gt "scalar") (serialize-qp "date_created__lt" $date_created_lt "scalar") (serialize-qp "activity_at__gte" $activity_at_gte "scalar") (serialize-qp "activity_at__lte" $activity_at_lte "scalar") (serialize-qp "activity_at__gt" $activity_at_gt "scalar") (serialize-qp "activity_at__lt" $activity_at_lt "scalar") (serialize-qp "lead_id__in" $lead_id_in "scalar") (serialize-qp "user_id__in" $user_id_in "scalar") (serialize-qp "contact_id__in" $contact_id_in "scalar") (serialize-qp "_type__in" $type_in "scalar") (serialize-qp "_fields" $qp_fields "scalar") (serialize-qp "_order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activity/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or filter all Note activities
#
# GET /activity/note/
# operationId: list
export def "activity-note list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --id-in: list # Filter by activity IDs (comma-separated)
  --lead-id: list # Filter by lead IDs (comma-separated)
  --contact-id: list # Filter by contact IDs (comma-separated)
  --user-id: list # Filter by user IDs (comma-separated)
  --organization-id: string
  --type: list # Filter by activity type, e.g. Call (comma-separated)
  --date-created-gte: string
  --date-created-lte: string
  --date-created-gt: string
  --date-created-lt: string
  --activity-at-gte: string
  --activity-at-lte: string
  --activity-at-gt: string
  --activity-at-lt: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<data: table<_type: string, activity_at: string, contact_id: string, created_by: string, created_by_name: string, date_created: string, date_updated: string, id: string, lead_id: string, organization_id: string, updated_by: string, updated_by_name: string, user_id: string, user_name: string, users: list>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "id__in" $id_in "scalar") (serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "_type" $type "scalar") (serialize-qp "date_created__gte" $date_created_gte "scalar") (serialize-qp "date_created__lte" $date_created_lte "scalar") (serialize-qp "date_created__gt" $date_created_gt "scalar") (serialize-qp "date_created__lt" $date_created_lt "scalar") (serialize-qp "activity_at__gte" $activity_at_gte "scalar") (serialize-qp "activity_at__lte" $activity_at_lte "scalar") (serialize-qp "activity_at__gt" $activity_at_gt "scalar") (serialize-qp "activity_at__lt" $activity_at_lt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activity/note/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Note activity
#
# POST /activity/note/
# operationId: create
# --attachments item shape: {content_type?: string, filename: string, url: string}
export def "activity-note create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --activity-at: string # nullable, format: date-time
  --attachments: list # nullable — item shape: {content_type?: string, filename: string, url: string}
  --contact-id: string # nullable
  --created-by: string # nullable
  --date-created: string # nullable, format: date-time
  lead_id: string
  --note: string # nullable
  --note-html: string # nullable
  --organization-id: string # nullable
  --pinned: oneof<nothing, bool> # nullable
  --title: string # nullable
  --user-id: string # nullable
]: any -> record<_type: string, activity_at: string, contact_id: string, created_by: string, created_by_name: string, date_created: string, date_updated: string, id: string, lead_id: string, organization_id: string, updated_by: string, updated_by_name: string, user_id: string, user_name: string, users: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/activity/note/")
  let body = {activity_at: $activity_at, attachments: $attachments, contact_id: $contact_id, created_by: $created_by, date_created: $date_created, lead_id: $lead_id, note: $note, note_html: $note_html, organization_id: $organization_id, pinned: $pinned, title: $title, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single Note activity
#
# GET /activity/note/{id}/
# operationId: get
export def "activity-note get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<_type: string, activity_at: string, contact_id: string, created_by: string, created_by_name: string, date_created: string, date_updated: string, id: string, lead_id: string, organization_id: string, updated_by: string, updated_by_name: string, user_id: string, user_name: string, users: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/note/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Note activity
#
# PUT /activity/note/{id}/
# operationId: update
# --attachments item shape: {content_type?: string, filename: string, url: string}
export def "activity-note update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --activity-at: string # nullable, format: date-time
  --attachments: list # nullable — item shape: {content_type?: string, filename: string, url: string}
  --contact-id: string # nullable
  --note: string # nullable
  --note-html: string # nullable
  --pinned: oneof<nothing, bool> # nullable
  --title: string # nullable
]: any -> record<_type: string, activity_at: string, contact_id: string, created_by: string, created_by_name: string, date_created: string, date_updated: string, id: string, lead_id: string, organization_id: string, updated_by: string, updated_by_name: string, user_id: string, user_name: string, users: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/note/($id)/")
  let body = {activity_at: $activity_at, attachments: $attachments, contact_id: $contact_id, note: $note, note_html: $note_html, pinned: $pinned, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Note activity
#
# DELETE /activity/note/{id}/
# operationId: delete
export def "activity-note delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/note/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or filter all Call activities
#
# GET /activity/call/
# operationId: list
export def "activity-call list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --id-in: list # Filter by activity IDs (comma-separated)
  --lead-id: list # Filter by lead IDs (comma-separated)
  --contact-id: list # Filter by contact IDs (comma-separated)
  --user-id: list # Filter by user IDs (comma-separated)
  --organization-id: string
  --type: list # Filter by activity type, e.g. Call (comma-separated)
  --date-created-gte: string
  --date-created-lte: string
  --date-created-gt: string
  --date-created-lt: string
  --activity-at-gte: string
  --activity-at-lte: string
  --activity-at-gt: string
  --activity-at-lt: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<data: table<_type: string, activity_at: string, contact_id: string, created_by: string, created_by_name: string, date_created: string, date_updated: string, id: string, lead_id: string, organization_id: string, outcome_id: string, sequence_id: string, sequence_name: string, sequence_subscription_id: string, source: string, status: string, updated_by: string, updated_by_name: string, user_id: string, user_name: string, users: list>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "id__in" $id_in "scalar") (serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "_type" $type "scalar") (serialize-qp "date_created__gte" $date_created_gte "scalar") (serialize-qp "date_created__lte" $date_created_lte "scalar") (serialize-qp "date_created__gt" $date_created_gt "scalar") (serialize-qp "date_created__lt" $date_created_lt "scalar") (serialize-qp "activity_at__gte" $activity_at_gte "scalar") (serialize-qp "activity_at__lte" $activity_at_lte "scalar") (serialize-qp "activity_at__gt" $activity_at_gt "scalar") (serialize-qp "activity_at__lt" $activity_at_lt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activity/call/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Log an external Call activity
#
# POST /activity/call/
# operationId: create
export def "activity-call create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --activity-at: string # nullable, format: date-time
  --contact-id: string # nullable
  --conversation-type-id: string # nullable
  --created-by: string # nullable
  --date-created: string # nullable, format: date-time
  --direction: string@direction-completer
  --duration: int # nullable
  --lead-id: string # nullable
  --note: string # nullable
  --note-html: string # nullable
  --organization-id: string # nullable
  --outcome-id: string # nullable
  --phone: string # Phone number in E.164 format (nullable)
  --playbook-id: string # nullable
  --quality-info: string # nullable
  --recording-url: string # nullable, format: uri
  --body-source: string@source-completer
  --status: string@status-completer
  --user-id: string # nullable
  --voicemail-url: string # nullable, format: uri
]: any -> record<_type: string, activity_at: string, contact_id: string, created_by: string, created_by_name: string, date_created: string, date_updated: string, id: string, lead_id: string, organization_id: string, outcome_id: string, sequence_id: string, sequence_name: string, sequence_subscription_id: string, source: string, status: string, updated_by: string, updated_by_name: string, user_id: string, user_name: string, users: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/activity/call/")
  let body = {activity_at: $activity_at, contact_id: $contact_id, conversation_type_id: $conversation_type_id, created_by: $created_by, date_created: $date_created, direction: $direction, duration: $duration, lead_id: $lead_id, note: $note, note_html: $note_html, organization_id: $organization_id, outcome_id: $outcome_id, phone: $phone, playbook_id: $playbook_id, quality_info: $quality_info, recording_url: $recording_url, source: $body_source, status: $status, user_id: $user_id, voicemail_url: $voicemail_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single Call activity
#
# GET /activity/call/{id}/
# operationId: get
export def "activity-call get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<_type: string, activity_at: string, contact_id: string, created_by: string, created_by_name: string, date_created: string, date_updated: string, id: string, lead_id: string, organization_id: string, outcome_id: string, sequence_id: string, sequence_name: string, sequence_subscription_id: string, source: string, status: string, updated_by: string, updated_by_name: string, user_id: string, user_name: string, users: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/call/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Call activity
#
# PUT /activity/call/{id}/
# operationId: update
export def "activity-call update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --activity-at: string # nullable, format: date-time
  --contact-id: string # nullable
  --conversation-type-id: string # nullable
  --duration: int # nullable
  --lead-id: string # nullable
  --note: string # nullable
  --note-html: string # nullable
  --outcome-id: string # nullable
  --phone: string # Phone number in E.164 format (nullable)
  --playbook-id: string # nullable
  --quality-info: string # nullable
  --recording-url: string # nullable, format: uri
  --status: string@status-completer
  --user-id: string # nullable
  --voicemail-url: string # nullable, format: uri
]: any -> record<_type: string, activity_at: string, contact_id: string, created_by: string, created_by_name: string, date_created: string, date_updated: string, id: string, lead_id: string, organization_id: string, outcome_id: string, sequence_id: string, sequence_name: string, sequence_subscription_id: string, source: string, status: string, updated_by: string, updated_by_name: string, user_id: string, user_name: string, users: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/call/($id)/")
  let body = {activity_at: $activity_at, contact_id: $contact_id, conversation_type_id: $conversation_type_id, duration: $duration, lead_id: $lead_id, note: $note, note_html: $note_html, outcome_id: $outcome_id, phone: $phone, playbook_id: $playbook_id, quality_info: $quality_info, recording_url: $recording_url, status: $status, user_id: $user_id, voicemail_url: $voicemail_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Call activity
#
# DELETE /activity/call/{id}/
# operationId: delete
export def "activity-call delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/call/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or filter all Email activities
#
# GET /activity/email/
# operationId: list
export def "activity-email list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --id-in: list # Filter by activity IDs (comma-separated)
  --lead-id: list # Filter by lead IDs (comma-separated)
  --contact-id: list # Filter by contact IDs (comma-separated)
  --user-id: list # Filter by user IDs (comma-separated)
  --organization-id: string
  --type: list # Filter by activity type, e.g. Call (comma-separated)
  --date-created-gte: string
  --date-created-lte: string
  --date-created-gt: string
  --date-created-lt: string
  --activity-at-gte: string
  --activity-at-lte: string
  --activity-at-gt: string
  --activity-at-lt: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<data: table<_type: string, activity_at: string, agent_action_reason: string, agent_config_id: string, attachments: list, bcc: list, body_html: string, body_preview: string, body_text: string, bulk_email_action_id: string, cc: list, contact_id: string, created_by: string, created_by_name: string, date_created: string, date_scheduled: string, date_sent: string, date_updated: string, direction: any, email_account_id: string, envelope: record, followup_sequence_add_cc_bcc: bool, followup_sequence_delay: int, followup_sequence_id: string, has_reply: bool, id: string, in_reply_to_id: string, lead_id: string, message_ids: list, need_smtp_credentials: bool, opens: list, opens_summary: string, organization_id: string, references: list, send_as_id: string, send_attempts: list, sender: string, sequence_id: string, sequence_name: string, sequence_subscription_id: string, status: string, subject: string, template_id: string, template_name: string, thread_id: string, to: list, updated_by: string, updated_by_name: string, user_id: string, user_name: string, users: list>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "id__in" $id_in "scalar") (serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "_type" $type "scalar") (serialize-qp "date_created__gte" $date_created_gte "scalar") (serialize-qp "date_created__lte" $date_created_lte "scalar") (serialize-qp "date_created__gt" $date_created_gt "scalar") (serialize-qp "date_created__lt" $date_created_lt "scalar") (serialize-qp "activity_at__gte" $activity_at_gte "scalar") (serialize-qp "activity_at__lte" $activity_at_lte "scalar") (serialize-qp "activity_at__gt" $activity_at_gt "scalar") (serialize-qp "activity_at__lt" $activity_at_lt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activity/email/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Email activity
#
# POST /activity/email/
# operationId: create
# --attachments item shape: {content_id?: string, content_type?: string, filename: string, inline_only?: bool, size: int, url: string}
# --opens item shape: {opened_at: string}
export def "activity-email create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --activity-at: string # nullable, format: date-time
  --attachments: list # nullable — item shape: {content_id?: string, content_type?: string, filename: string, inline_only?: bool, size: int, url: string}
  --bcc: list # nullable
  --body-html: string # nullable
  --body-text: string # nullable
  --cc: list # nullable
  --contact-id: string # nullable
  --created-by: string # nullable
  --date-created: string # nullable, format: date-time
  --email-account-id: string # nullable
  --followup-date: string # nullable, format: date-time
  --followup-sequence-add-cc-bcc: oneof<nothing, bool> # nullable
  --followup-sequence-delay: int # nullable
  --followup-sequence-id: string # nullable
  --in-reply-to-id: string # nullable
  lead_id: string
  --opens: list # nullable — item shape: {opened_at: string}
  --organization-id: string # nullable
  --sender: string # nullable, format: email
  status: string@status-completer-1
  --subject: string # nullable
  --template-id: string # nullable
  --body-to: list # nullable
  --user-id: string # nullable
]: any -> record<_type: string, activity_at: string, agent_action_reason: string, agent_config_id: string, attachments: table<content_type: string, filename: string, size: int, thumbnail_url: string, url: string>, bcc: list<string>, body_html: string, body_preview: string, body_text: string, bulk_email_action_id: string, cc: list<string>, contact_id: string, created_by: string, created_by_name: string, date_created: string, date_scheduled: string, date_sent: string, date_updated: string, direction: any, email_account_id: string, envelope: record, followup_sequence_add_cc_bcc: bool, followup_sequence_delay: int, followup_sequence_id: string, has_reply: bool, id: string, in_reply_to_id: string, lead_id: string, message_ids: list<string>, need_smtp_credentials: bool, opens: list<record>, opens_summary: string, organization_id: string, references: list<string>, send_as_id: string, send_attempts: list<record>, sender: string, sequence_id: string, sequence_name: string, sequence_subscription_id: string, status: string, subject: string, template_id: string, template_name: string, thread_id: string, to: list<string>, updated_by: string, updated_by_name: string, user_id: string, user_name: string, users: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/activity/email/")
  let body = {activity_at: $activity_at, attachments: $attachments, bcc: $bcc, body_html: $body_html, body_text: $body_text, cc: $cc, contact_id: $contact_id, created_by: $created_by, date_created: $date_created, email_account_id: $email_account_id, followup_date: $followup_date, followup_sequence_add_cc_bcc: $followup_sequence_add_cc_bcc, followup_sequence_delay: $followup_sequence_delay, followup_sequence_id: $followup_sequence_id, in_reply_to_id: $in_reply_to_id, lead_id: $lead_id, opens: $opens, organization_id: $organization_id, sender: $sender, status: $status, subject: $subject, template_id: $template_id, to: $body_to, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single Email activity
#
# GET /activity/email/{id}/
# operationId: get
export def "activity-email get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<_type: string, activity_at: string, agent_action_reason: string, agent_config_id: string, attachments: table<content_type: string, filename: string, size: int, thumbnail_url: string, url: string>, bcc: list<string>, body_html: string, body_preview: string, body_text: string, bulk_email_action_id: string, cc: list<string>, contact_id: string, created_by: string, created_by_name: string, date_created: string, date_scheduled: string, date_sent: string, date_updated: string, direction: any, email_account_id: string, envelope: record, followup_sequence_add_cc_bcc: bool, followup_sequence_delay: int, followup_sequence_id: string, has_reply: bool, id: string, in_reply_to_id: string, lead_id: string, message_ids: list<string>, need_smtp_credentials: bool, opens: list<record>, opens_summary: string, organization_id: string, references: list<string>, send_as_id: string, send_attempts: list<record>, sender: string, sequence_id: string, sequence_name: string, sequence_subscription_id: string, status: string, subject: string, template_id: string, template_name: string, thread_id: string, to: list<string>, updated_by: string, updated_by_name: string, user_id: string, user_name: string, users: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/email/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Email activity
#
# PUT /activity/email/{id}/
# operationId: update
# --attachments item shape: {content_id?: string, content_type?: string, filename: string, inline_only?: bool, size: int, url: string}
# --opens item shape: {opened_at: string}
export def "activity-email update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --activity-at: string # nullable, format: date-time
  --attachments: list # nullable — item shape: {content_id?: string, content_type?: string, filename: string, inline_only?: bool, size: int, url: string}
  --bcc: list # nullable
  --body-html: string # nullable
  --body-text: string # nullable
  --cc: list # nullable
  --contact-id: string # nullable
  --email-account-id: string # nullable
  --followup-date: string # nullable, format: date-time
  --followup-sequence-add-cc-bcc: oneof<nothing, bool> # nullable
  --followup-sequence-delay: int # nullable
  --followup-sequence-id: string # nullable
  --in-reply-to-id: string # nullable
  --opens: list # nullable — item shape: {opened_at: string}
  --sender: string # nullable, format: email
  --status: string@status-completer-1
  --subject: string # nullable
  --template-id: string # nullable
  --body-to: list # nullable
  --user-id: string # nullable
]: any -> record<_type: string, activity_at: string, agent_action_reason: string, agent_config_id: string, attachments: table<content_type: string, filename: string, size: int, thumbnail_url: string, url: string>, bcc: list<string>, body_html: string, body_preview: string, body_text: string, bulk_email_action_id: string, cc: list<string>, contact_id: string, created_by: string, created_by_name: string, date_created: string, date_scheduled: string, date_sent: string, date_updated: string, direction: any, email_account_id: string, envelope: record, followup_sequence_add_cc_bcc: bool, followup_sequence_delay: int, followup_sequence_id: string, has_reply: bool, id: string, in_reply_to_id: string, lead_id: string, message_ids: list<string>, need_smtp_credentials: bool, opens: list<record>, opens_summary: string, organization_id: string, references: list<string>, send_as_id: string, send_attempts: list<record>, sender: string, sequence_id: string, sequence_name: string, sequence_subscription_id: string, status: string, subject: string, template_id: string, template_name: string, thread_id: string, to: list<string>, updated_by: string, updated_by_name: string, user_id: string, user_name: string, users: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/email/($id)/")
  let body = {activity_at: $activity_at, attachments: $attachments, bcc: $bcc, body_html: $body_html, body_text: $body_text, cc: $cc, contact_id: $contact_id, email_account_id: $email_account_id, followup_date: $followup_date, followup_sequence_add_cc_bcc: $followup_sequence_add_cc_bcc, followup_sequence_delay: $followup_sequence_delay, followup_sequence_id: $followup_sequence_id, in_reply_to_id: $in_reply_to_id, opens: $opens, sender: $sender, status: $status, subject: $subject, template_id: $template_id, to: $body_to, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Email activity
#
# DELETE /activity/email/{id}/
# operationId: delete
export def "activity-email delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/email/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or filter all EmailThread activities
#
# GET /activity/emailthread/
# operationId: list
export def "activity-emailthread list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --id-in: list # Filter by activity IDs (comma-separated)
  --lead-id: list # Filter by lead IDs (comma-separated)
  --contact-id: list # Filter by contact IDs (comma-separated)
  --user-id: list # Filter by user IDs (comma-separated)
  --organization-id: string
  --type: list # Filter by activity type, e.g. Call (comma-separated)
  --date-created-gte: string
  --date-created-lte: string
  --date-created-gt: string
  --date-created-lt: string
  --activity-at-gte: string
  --activity-at-lte: string
  --activity-at-gt: string
  --activity-at-lt: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "id__in" $id_in "scalar") (serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "_type" $type "scalar") (serialize-qp "date_created__gte" $date_created_gte "scalar") (serialize-qp "date_created__lte" $date_created_lte "scalar") (serialize-qp "date_created__gt" $date_created_gt "scalar") (serialize-qp "date_created__lt" $date_created_lt "scalar") (serialize-qp "activity_at__gte" $activity_at_gte "scalar") (serialize-qp "activity_at__lte" $activity_at_lte "scalar") (serialize-qp "activity_at__gt" $activity_at_gt "scalar") (serialize-qp "activity_at__lt" $activity_at_lt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activity/emailthread/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single EmailThread activity
#
# GET /activity/emailthread/{id}/
# operationId: get
export def "activity-emailthread get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/emailthread/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an EmailThread activity
#
# DELETE /activity/emailthread/{id}/
# operationId: delete
export def "activity-emailthread delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/emailthread/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or filter all SMS activities
#
# GET /activity/sms/
# operationId: list
export def "activity-sms list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --id-in: list # Filter by activity IDs (comma-separated)
  --lead-id: list # Filter by lead IDs (comma-separated)
  --contact-id: list # Filter by contact IDs (comma-separated)
  --user-id: list # Filter by user IDs (comma-separated)
  --organization-id: string
  --type: list # Filter by activity type, e.g. Call (comma-separated)
  --date-created-gte: string
  --date-created-lte: string
  --date-created-gt: string
  --date-created-lt: string
  --activity-at-gte: string
  --activity-at-lte: string
  --activity-at-gt: string
  --activity-at-lt: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<data: table<_type: string, activity_at: string, agent_action_reason: string, agent_config_id: string, contact_id: string, cost: string, created_by: string, created_by_name: string, date_created: string, date_scheduled: string, date_sent: string, date_updated: string, direction: string, error_message: string, id: string, lead_id: string, local_country_iso: string, local_phone: string, local_phone_formatted: string, organization_id: string, remote_country_iso: string, remote_phone: string, remote_phone_formatted: string, sequence_id: string, sequence_name: string, sequence_subscription_id: string, source: string, status: string, template_id: string, text: string, updated_by: string, updated_by_name: string, user_id: string, user_name: string, users: list>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "id__in" $id_in "scalar") (serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "_type" $type "scalar") (serialize-qp "date_created__gte" $date_created_gte "scalar") (serialize-qp "date_created__lte" $date_created_lte "scalar") (serialize-qp "date_created__gt" $date_created_gt "scalar") (serialize-qp "date_created__lt" $date_created_lt "scalar") (serialize-qp "activity_at__gte" $activity_at_gte "scalar") (serialize-qp "activity_at__lte" $activity_at_lte "scalar") (serialize-qp "activity_at__gt" $activity_at_gt "scalar") (serialize-qp "activity_at__lt" $activity_at_lt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activity/sms/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an SMS activity
#
# POST /activity/sms/
# operationId: create
# --attachments item shape: {content_type: "application/pdf"|"application/vcard"|"audio/3gpp"|"audio/3gpp2"|"audio/L24"|"audio/ac3"|"audio/amr"|"audio/amr-nb"|"audio/basic"|"audio/mp4"|"audio/mpeg"|"audio/ogg"|"audio/vnd.rn-realaudio"|"audio/vnd.wave"|"audio/webm"|"image/bmp"|"image/gif"|"image/jpeg"|"image/jpg"|"image/png"|"image/tiff"|"text/calendar"|"text/csv"|"text/directory"|"text/richtext"|"text/rtf"|"text/vcard"|"text/x-vcard"|"video/3gpp"|"video/3gpp-tt"|"video/3gpp2"|"video/H261"|"video/H263"|"video/H263-1998"|"video/H263-2000"|"video/H264"|"video/mp4"|"video/mpeg"|"video/quicktime"|"video/webm", filename: string, url: string}
export def "activity-sms create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --send-to-inbox: oneof<nothing, bool>
  --Authorization: string # Use your API key as the username and leave the password empty.
  --activity-at: string # nullable, format: date-time
  --attachments: list # nullable — item shape: {content_type: "application/pdf"|"application/vcard"|"audio/3gpp"|"audio/3gpp2"|"audio/L24"|"audio/ac3"|"audio/amr"|"audio/amr-nb"|"audio/basic"|"audio/mp4"|"audio/mpeg"|"audio/ogg"|"audio/vnd.rn-realaudio"|"audio/vnd.wave"|"audio/webm"|"image/bmp"|"image/gif"|"image/jpeg"|"image/jpg"|"image/png"|"image/tiff"|"text/calendar"|"text/csv"|"text/directory"|"text/richtext"|"text/rtf"|"text/vcard"|"text/x-vcard"|"video/3gpp"|"video/3gpp-tt"|"video/3gpp2"|"video/H261"|"video/H263"|"video/H263-1998"|"video/H263-2000"|"video/H264"|"video/mp4"|"video/mpeg"|"video/quicktime"|"video/webm", filename: string, url: string}
  --contact-id: string # nullable
  --created-by: string # nullable
  --date-created: string # nullable, format: date-time
  --direction: string@direction-completer
  --lead-id: string # nullable
  --local-phone: string # Phone number in E.164 format (nullable)
  --organization-id: string # nullable
  --remote-phone: string # Phone number in E.164 format (nullable)
  --body-source: string@source-completer
  status: string@status-completer-1
  --template-id: string # nullable
  --text: string # nullable
  --user-id: string # nullable
]: any -> record<_type: string, activity_at: string, agent_action_reason: string, agent_config_id: string, contact_id: string, cost: string, created_by: string, created_by_name: string, date_created: string, date_scheduled: string, date_sent: string, date_updated: string, direction: string, error_message: string, id: string, lead_id: string, local_country_iso: string, local_phone: string, local_phone_formatted: string, organization_id: string, remote_country_iso: string, remote_phone: string, remote_phone_formatted: string, sequence_id: string, sequence_name: string, sequence_subscription_id: string, source: string, status: string, template_id: string, text: string, updated_by: string, updated_by_name: string, user_id: string, user_name: string, users: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "send_to_inbox" $send_to_inbox "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activity/sms/" $qp)
  let body = {activity_at: $activity_at, attachments: $attachments, contact_id: $contact_id, created_by: $created_by, date_created: $date_created, direction: $direction, lead_id: $lead_id, local_phone: $local_phone, organization_id: $organization_id, remote_phone: $remote_phone, source: $body_source, status: $status, template_id: $template_id, text: $text, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single SMS activity
#
# GET /activity/sms/{id}/
# operationId: get
export def "activity-sms get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<_type: string, activity_at: string, agent_action_reason: string, agent_config_id: string, contact_id: string, cost: string, created_by: string, created_by_name: string, date_created: string, date_scheduled: string, date_sent: string, date_updated: string, direction: string, error_message: string, id: string, lead_id: string, local_country_iso: string, local_phone: string, local_phone_formatted: string, organization_id: string, remote_country_iso: string, remote_phone: string, remote_phone_formatted: string, sequence_id: string, sequence_name: string, sequence_subscription_id: string, source: string, status: string, template_id: string, text: string, updated_by: string, updated_by_name: string, user_id: string, user_name: string, users: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/sms/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an SMS activity
#
# PUT /activity/sms/{id}/
# operationId: update
# --attachments item shape: {content_type: "application/pdf"|"application/vcard"|"audio/3gpp"|"audio/3gpp2"|"audio/L24"|"audio/ac3"|"audio/amr"|"audio/amr-nb"|"audio/basic"|"audio/mp4"|"audio/mpeg"|"audio/ogg"|"audio/vnd.rn-realaudio"|"audio/vnd.wave"|"audio/webm"|"image/bmp"|"image/gif"|"image/jpeg"|"image/jpg"|"image/png"|"image/tiff"|"text/calendar"|"text/csv"|"text/directory"|"text/richtext"|"text/rtf"|"text/vcard"|"text/x-vcard"|"video/3gpp"|"video/3gpp-tt"|"video/3gpp2"|"video/H261"|"video/H263"|"video/H263-1998"|"video/H263-2000"|"video/H264"|"video/mp4"|"video/mpeg"|"video/quicktime"|"video/webm", filename: string, url: string}
export def "activity-sms update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --activity-at: string # nullable, format: date-time
  --attachments: list # nullable — item shape: {content_type: "application/pdf"|"application/vcard"|"audio/3gpp"|"audio/3gpp2"|"audio/L24"|"audio/ac3"|"audio/amr"|"audio/amr-nb"|"audio/basic"|"audio/mp4"|"audio/mpeg"|"audio/ogg"|"audio/vnd.rn-realaudio"|"audio/vnd.wave"|"audio/webm"|"image/bmp"|"image/gif"|"image/jpeg"|"image/jpg"|"image/png"|"image/tiff"|"text/calendar"|"text/csv"|"text/directory"|"text/richtext"|"text/rtf"|"text/vcard"|"text/x-vcard"|"video/3gpp"|"video/3gpp-tt"|"video/3gpp2"|"video/H261"|"video/H263"|"video/H263-1998"|"video/H263-2000"|"video/H264"|"video/mp4"|"video/mpeg"|"video/quicktime"|"video/webm", filename: string, url: string}
  --contact-id: string # nullable
  --lead-id: string # nullable
  --local-phone: string # Phone number in E.164 format (nullable)
  --remote-phone: string # Phone number in E.164 format (nullable)
  --status: string@status-completer-1
  --template-id: string # nullable
  --text: string # nullable
  --user-id: string # nullable
]: any -> record<_type: string, activity_at: string, agent_action_reason: string, agent_config_id: string, contact_id: string, cost: string, created_by: string, created_by_name: string, date_created: string, date_scheduled: string, date_sent: string, date_updated: string, direction: string, error_message: string, id: string, lead_id: string, local_country_iso: string, local_phone: string, local_phone_formatted: string, organization_id: string, remote_country_iso: string, remote_phone: string, remote_phone_formatted: string, sequence_id: string, sequence_name: string, sequence_subscription_id: string, source: string, status: string, template_id: string, text: string, updated_by: string, updated_by_name: string, user_id: string, user_name: string, users: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/sms/($id)/")
  let body = {activity_at: $activity_at, attachments: $attachments, contact_id: $contact_id, lead_id: $lead_id, local_phone: $local_phone, remote_phone: $remote_phone, status: $status, template_id: $template_id, text: $text, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an SMS activity
#
# DELETE /activity/sms/{id}/
# operationId: delete
export def "activity-sms delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/sms/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or filter all WhatsAppMessage activities
#
# GET /activity/whatsapp_message/
# operationId: list
export def "activity-whatsapp-message list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --id-in: list # Filter by activity IDs (comma-separated)
  --lead-id: list # Filter by lead IDs (comma-separated)
  --contact-id: list # Filter by contact IDs (comma-separated)
  --user-id: list # Filter by user IDs (comma-separated)
  --organization-id: string
  --type: list # Filter by activity type, e.g. Call (comma-separated)
  --date-created-gte: string
  --date-created-lte: string
  --date-created-gt: string
  --date-created-lt: string
  --activity-at-gte: string
  --activity-at-lte: string
  --activity-at-gt: string
  --activity-at-lt: string
  --external-whatsapp-message-id: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<data: table<_type: string, activity_at: string, attachments: list, contact_id: string, created_by: string, created_by_name: string, date_created: string, date_updated: string, direction: string, external_whatsapp_message_id: string, id: string, integration_link: string, integration_name: string, lead_id: string, local_phone: string, local_phone_formatted: string, message_html: string, message_markdown: string, organization_id: string, remote_phone: string, remote_phone_formatted: string, response_to_id: string, sequence_id: string, sequence_name: string, sequence_subscription_id: string, source: string, text: string, updated_by: string, updated_by_name: string, user_id: string, user_name: string, users: list>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "id__in" $id_in "scalar") (serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "_type" $type "scalar") (serialize-qp "date_created__gte" $date_created_gte "scalar") (serialize-qp "date_created__lte" $date_created_lte "scalar") (serialize-qp "date_created__gt" $date_created_gt "scalar") (serialize-qp "date_created__lt" $date_created_lt "scalar") (serialize-qp "activity_at__gte" $activity_at_gte "scalar") (serialize-qp "activity_at__lte" $activity_at_lte "scalar") (serialize-qp "activity_at__gt" $activity_at_gt "scalar") (serialize-qp "activity_at__lt" $activity_at_lt "scalar") (serialize-qp "external_whatsapp_message_id" $external_whatsapp_message_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activity/whatsapp_message/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a WhatsAppMessage activity
#
# POST /activity/whatsapp_message/
# operationId: create
# --attachments item shape: {content_type: string, filename: string, url: string}
export def "activity-whatsapp-message create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --send-to-inbox: oneof<nothing, bool>
  --Authorization: string # Use your API key as the username and leave the password empty.
  activity_at: string # format: date-time
  --attachments: list # item shape: {content_type: string, filename: string, url: string}
  contact_id: string
  direction: string@direction-completer-1 # Direction of communication. Outgoing means the communication flowing from the user to the lead/contact. Inbound means the opposite.
  external_whatsapp_message_id: string
  --integration-link: string # nullable, format: uri
  lead_id: string
  local_phone: string
  message_markdown: string
  remote_phone: string
  --response-to-id: string # nullable
  --user-id: string # nullable
]: any -> record<_type: string, activity_at: string, attachments: table<content_type: string, filename: string, size: int, thumbnail_url: string, url: string>, contact_id: string, created_by: string, created_by_name: string, date_created: string, date_updated: string, direction: string, external_whatsapp_message_id: string, id: string, integration_link: string, integration_name: string, lead_id: string, local_phone: string, local_phone_formatted: string, message_html: string, message_markdown: string, organization_id: string, remote_phone: string, remote_phone_formatted: string, response_to_id: string, sequence_id: string, sequence_name: string, sequence_subscription_id: string, source: string, text: string, updated_by: string, updated_by_name: string, user_id: string, user_name: string, users: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "send_to_inbox" $send_to_inbox "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activity/whatsapp_message/" $qp)
  let body = {activity_at: $activity_at, attachments: $attachments, contact_id: $contact_id, direction: $direction, external_whatsapp_message_id: $external_whatsapp_message_id, integration_link: $integration_link, lead_id: $lead_id, local_phone: $local_phone, message_markdown: $message_markdown, remote_phone: $remote_phone, response_to_id: $response_to_id, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single WhatsAppMessage activity
#
# GET /activity/whatsapp_message/{id}/
# operationId: get
export def "activity-whatsapp-message get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<_type: string, activity_at: string, attachments: table<content_type: string, filename: string, size: int, thumbnail_url: string, url: string>, contact_id: string, created_by: string, created_by_name: string, date_created: string, date_updated: string, direction: string, external_whatsapp_message_id: string, id: string, integration_link: string, integration_name: string, lead_id: string, local_phone: string, local_phone_formatted: string, message_html: string, message_markdown: string, organization_id: string, remote_phone: string, remote_phone_formatted: string, response_to_id: string, sequence_id: string, sequence_name: string, sequence_subscription_id: string, source: string, text: string, updated_by: string, updated_by_name: string, user_id: string, user_name: string, users: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/whatsapp_message/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a WhatsAppMessage activity
#
# PUT /activity/whatsapp_message/{id}/
# operationId: update
# --attachments item shape: {content_type: string, filename: string, url: string}
export def "activity-whatsapp-message update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --activity-at: string # format: date-time
  --attachments: list # item shape: {content_type: string, filename: string, url: string}
  --contact-id: string
  --direction: string@direction-completer-1 # Direction of communication. Outgoing means the communication flowing from the user to the lead/contact. Inbound means the opposite.
  --integration-link: string # nullable, format: uri
  --local-phone: string
  --message-markdown: string
  --remote-phone: string
  --response-to-id: string # nullable
  --user-id: string
]: any -> record<_type: string, activity_at: string, attachments: table<content_type: string, filename: string, size: int, thumbnail_url: string, url: string>, contact_id: string, created_by: string, created_by_name: string, date_created: string, date_updated: string, direction: string, external_whatsapp_message_id: string, id: string, integration_link: string, integration_name: string, lead_id: string, local_phone: string, local_phone_formatted: string, message_html: string, message_markdown: string, organization_id: string, remote_phone: string, remote_phone_formatted: string, response_to_id: string, sequence_id: string, sequence_name: string, sequence_subscription_id: string, source: string, text: string, updated_by: string, updated_by_name: string, user_id: string, user_name: string, users: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/whatsapp_message/($id)/")
  let body = {activity_at: $activity_at, attachments: $attachments, contact_id: $contact_id, direction: $direction, integration_link: $integration_link, local_phone: $local_phone, message_markdown: $message_markdown, remote_phone: $remote_phone, response_to_id: $response_to_id, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a WhatsAppMessage activity
#
# DELETE /activity/whatsapp_message/{id}/
# operationId: delete
export def "activity-whatsapp-message delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/whatsapp_message/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or filter all Meeting activities
#
# GET /activity/meeting/
# operationId: list
export def "activity-meeting list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --id-in: list # Filter by activity IDs (comma-separated)
  --lead-id: list # Filter by lead IDs (comma-separated)
  --contact-id: list # Filter by contact IDs (comma-separated)
  --user-id: list # Filter by user IDs (comma-separated)
  --organization-id: string
  --type: list # Filter by activity type, e.g. Call (comma-separated)
  --date-created-gte: string
  --date-created-lte: string
  --date-created-gt: string
  --date-created-lt: string
  --activity-at-gte: string
  --activity-at-lte: string
  --activity-at-gt: string
  --activity-at-lt: string
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "id__in" $id_in "scalar") (serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "_type" $type "scalar") (serialize-qp "date_created__gte" $date_created_gte "scalar") (serialize-qp "date_created__lte" $date_created_lte "scalar") (serialize-qp "date_created__gt" $date_created_gt "scalar") (serialize-qp "date_created__lt" $date_created_lt "scalar") (serialize-qp "activity_at__gte" $activity_at_gte "scalar") (serialize-qp "activity_at__lte" $activity_at_lte "scalar") (serialize-qp "activity_at__gt" $activity_at_gt "scalar") (serialize-qp "activity_at__lt" $activity_at_lt "scalar") (serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activity/meeting/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single Meeting activity
#
# GET /activity/meeting/{id}/
# operationId: get
export def "activity-meeting get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/activity/meeting/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Meeting activity
#
# PUT /activity/meeting/{id}/
# operationId: update
export def "activity-meeting update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/meeting/($id)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Meeting activity
#
# DELETE /activity/meeting/{id}/
# operationId: delete
export def "activity-meeting delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/meeting/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update third-party Meeting integration
#
# POST /activity/meeting/{id}/integration/
# operationId: create-integration
export def "activity-meeting-integration create-integration" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/meeting/($id)/integration/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List or filter all Custom Activity instances
#
# GET /activity/custom/
# operationId: list
export def "activity-custom list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --id-in: list # Filter by activity IDs (comma-separated)
  --lead-id: list # Filter by lead IDs (comma-separated)
  --contact-id: list # Filter by contact IDs (comma-separated)
  --user-id: list # Filter by user IDs (comma-separated)
  --organization-id: string
  --type: list # Filter by activity type, e.g. Call (comma-separated)
  --date-created-gte: string
  --date-created-lte: string
  --date-created-gt: string
  --date-created-lt: string
  --activity-at-gte: string
  --activity-at-lte: string
  --activity-at-gt: string
  --activity-at-lt: string
  --custom-activity-type-id: list
  --custom-activity-type-id-in: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "id__in" $id_in "scalar") (serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "_type" $type "scalar") (serialize-qp "date_created__gte" $date_created_gte "scalar") (serialize-qp "date_created__lte" $date_created_lte "scalar") (serialize-qp "date_created__gt" $date_created_gt "scalar") (serialize-qp "date_created__lt" $date_created_lt "scalar") (serialize-qp "activity_at__gte" $activity_at_gte "scalar") (serialize-qp "activity_at__lte" $activity_at_lte "scalar") (serialize-qp "activity_at__gt" $activity_at_gt "scalar") (serialize-qp "activity_at__lt" $activity_at_lt "scalar") (serialize-qp "custom_activity_type_id" $custom_activity_type_id "scalar") (serialize-qp "custom_activity_type_id__in" $custom_activity_type_id_in "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activity/custom/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Custom Activity instance
#
# POST /activity/custom/
# operationId: create
export def "activity-custom create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --activity-at: string # nullable, format: date-time
  --contact-id: string # nullable
  --created-by: string # nullable
  custom_activity_type_id: string
  --date-created: string # nullable, format: date-time
  lead_id: string
  --organization-id: string # nullable
  --pinned: oneof<nothing, bool> # nullable
  --status: string@status-completer-2
  --user-id: string # nullable
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/activity/custom/")
  let body = {activity_at: $activity_at, contact_id: $contact_id, created_by: $created_by, custom_activity_type_id: $custom_activity_type_id, date_created: $date_created, lead_id: $lead_id, organization_id: $organization_id, pinned: $pinned, status: $status, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single Custom Activity instance
#
# GET /activity/custom/{id}/
# operationId: get
export def "activity-custom get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/custom/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updating a Custom Activity instance
#
# PUT /activity/custom/{id}/
# operationId: update
export def "activity-custom update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --activity-at: string # nullable, format: date-time
  --contact-id: string # nullable
  --pinned: oneof<nothing, bool> # nullable
  --status: string@status-completer-2
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/custom/($id)/")
  let body = {activity_at: $activity_at, contact_id: $contact_id, pinned: $pinned, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Custom Activity instance
#
# DELETE /activity/custom/{id}/
# operationId: delete
export def "activity-custom delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/custom/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or filter all Created activities
#
# GET /activity/created/
# operationId: list
export def "activity-created list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --id-in: list # Filter by activity IDs (comma-separated)
  --lead-id: list # Filter by lead IDs (comma-separated)
  --contact-id: list # Filter by contact IDs (comma-separated)
  --user-id: list # Filter by user IDs (comma-separated)
  --organization-id: string
  --type: list # Filter by activity type, e.g. Call (comma-separated)
  --date-created-gte: string
  --date-created-lte: string
  --date-created-gt: string
  --date-created-lt: string
  --activity-at-gte: string
  --activity-at-lte: string
  --activity-at-gt: string
  --activity-at-lt: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "id__in" $id_in "scalar") (serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "_type" $type "scalar") (serialize-qp "date_created__gte" $date_created_gte "scalar") (serialize-qp "date_created__lte" $date_created_lte "scalar") (serialize-qp "date_created__gt" $date_created_gt "scalar") (serialize-qp "date_created__lt" $date_created_lt "scalar") (serialize-qp "activity_at__gte" $activity_at_gte "scalar") (serialize-qp "activity_at__lte" $activity_at_lte "scalar") (serialize-qp "activity_at__gt" $activity_at_gt "scalar") (serialize-qp "activity_at__lt" $activity_at_lt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activity/created/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single Created activity
#
# GET /activity/created/{id}/
# operationId: get
export def "activity-created get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/created/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or filter all FormSubmission activities
#
# GET /activity/form_submission/
# operationId: list
export def "activity-form-submission list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --id-in: list # Filter by activity IDs (comma-separated)
  --lead-id: list # Filter by lead IDs (comma-separated)
  --contact-id: list # Filter by contact IDs (comma-separated)
  --user-id: list # Filter by user IDs (comma-separated)
  --organization-id: string
  --type: list # Filter by activity type, e.g. Call (comma-separated)
  --date-created-gte: string
  --date-created-lte: string
  --date-created-gt: string
  --date-created-lt: string
  --activity-at-gte: string
  --activity-at-lte: string
  --activity-at-gt: string
  --activity-at-lt: string
  --lead-id-in: string
  --user-id-in: string
  --contact-id-in: string
  --type-in: string
  --form-id: list # Filter by a specific form ID.
  --form-id-in: string # Filter by multiple form IDs (comma-separated).
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<data: table<_type: string, activity_at: string, contact_id: string, created_by: string, created_by_name: string, date_created: string, date_updated: string, form_configuration_id: string, form_id: string, form_name: string, id: string, ip_address: string, lead_id: string, organization_id: string, origin: string, source_url: string, source_url_normalized: string, updated_by: string, updated_by_name: string, user_id: string, user_name: string, users: list, values: record, values_by_name: record>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "id__in" $id_in "scalar") (serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "_type" $type "scalar") (serialize-qp "date_created__gte" $date_created_gte "scalar") (serialize-qp "date_created__lte" $date_created_lte "scalar") (serialize-qp "date_created__gt" $date_created_gt "scalar") (serialize-qp "date_created__lt" $date_created_lt "scalar") (serialize-qp "activity_at__gte" $activity_at_gte "scalar") (serialize-qp "activity_at__lte" $activity_at_lte "scalar") (serialize-qp "activity_at__gt" $activity_at_gt "scalar") (serialize-qp "activity_at__lt" $activity_at_lt "scalar") (serialize-qp "lead_id__in" $lead_id_in "scalar") (serialize-qp "user_id__in" $user_id_in "scalar") (serialize-qp "contact_id__in" $contact_id_in "scalar") (serialize-qp "_type__in" $type_in "scalar") (serialize-qp "form_id" $form_id "scalar") (serialize-qp "form_id__in" $form_id_in "scalar") (serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activity/form_submission/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single FormSubmission activity
#
# GET /activity/form_submission/{id}/
# operationId: get
export def "activity-form-submission get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<_type: string, activity_at: string, contact_id: string, created_by: string, created_by_name: string, date_created: string, date_updated: string, form_configuration_id: string, form_id: string, form_name: string, id: string, ip_address: string, lead_id: string, organization_id: string, origin: string, source_url: string, source_url_normalized: string, updated_by: string, updated_by_name: string, user_id: string, user_name: string, users: list<string>, values: record, values_by_name: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/activity/form_submission/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a FormSubmission activity
#
# DELETE /activity/form_submission/{id}/
# operationId: delete
export def "activity-form-submission delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/form_submission/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or filter all LeadStatusChange activities
#
# GET /activity/status_change/lead/
# operationId: list
export def "activity-status-change-lead list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --id-in: list # Filter by activity IDs (comma-separated)
  --lead-id: list # Filter by lead IDs (comma-separated)
  --contact-id: list # Filter by contact IDs (comma-separated)
  --user-id: list # Filter by user IDs (comma-separated)
  --organization-id: string
  --type: list # Filter by activity type, e.g. Call (comma-separated)
  --date-created-gte: string
  --date-created-lte: string
  --date-created-gt: string
  --date-created-lt: string
  --activity-at-gte: string
  --activity-at-lte: string
  --activity-at-gt: string
  --activity-at-lt: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "id__in" $id_in "scalar") (serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "_type" $type "scalar") (serialize-qp "date_created__gte" $date_created_gte "scalar") (serialize-qp "date_created__lte" $date_created_lte "scalar") (serialize-qp "date_created__gt" $date_created_gt "scalar") (serialize-qp "date_created__lt" $date_created_lt "scalar") (serialize-qp "activity_at__gte" $activity_at_gte "scalar") (serialize-qp "activity_at__lte" $activity_at_lte "scalar") (serialize-qp "activity_at__gt" $activity_at_gt "scalar") (serialize-qp "activity_at__lt" $activity_at_lt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activity/status_change/lead/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new LeadStatusChange activity
#
# POST /activity/status_change/lead/
# operationId: create
export def "activity-status-change-lead create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/activity/status_change/lead/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single LeadStatusChange activity
#
# GET /activity/status_change/lead/{id}/
# operationId: get
export def "activity-status-change-lead get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/status_change/lead/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a single LeadStatusChange activity
#
# DELETE /activity/status_change/lead/{id}/
# operationId: delete
export def "activity-status-change-lead delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/status_change/lead/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or filter all OpportunityStatusChange activities
#
# GET /activity/status_change/opportunity/
# operationId: list
export def "activity-status-change-opportunity list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --id-in: list # Filter by activity IDs (comma-separated)
  --lead-id: list # Filter by lead IDs (comma-separated)
  --contact-id: list # Filter by contact IDs (comma-separated)
  --user-id: list # Filter by user IDs (comma-separated)
  --organization-id: string
  --type: list # Filter by activity type, e.g. Call (comma-separated)
  --date-created-gte: string
  --date-created-lte: string
  --date-created-gt: string
  --date-created-lt: string
  --activity-at-gte: string
  --activity-at-lte: string
  --activity-at-gt: string
  --activity-at-lt: string
  --opportunity-id: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "id__in" $id_in "scalar") (serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "_type" $type "scalar") (serialize-qp "date_created__gte" $date_created_gte "scalar") (serialize-qp "date_created__lte" $date_created_lte "scalar") (serialize-qp "date_created__gt" $date_created_gt "scalar") (serialize-qp "date_created__lt" $date_created_lt "scalar") (serialize-qp "activity_at__gte" $activity_at_gte "scalar") (serialize-qp "activity_at__lte" $activity_at_lte "scalar") (serialize-qp "activity_at__gt" $activity_at_gt "scalar") (serialize-qp "activity_at__lt" $activity_at_lt "scalar") (serialize-qp "opportunity_id" $opportunity_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activity/status_change/opportunity/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new OpportunityStatusChange activity
#
# POST /activity/status_change/opportunity/
# operationId: create
export def "activity-status-change-opportunity create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/activity/status_change/opportunity/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single OpportunityStatusChange activity
#
# GET /activity/status_change/opportunity/{id}/
# operationId: get
export def "activity-status-change-opportunity get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/status_change/opportunity/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a single OpportunityStatusChange activity
#
# DELETE /activity/status_change/opportunity/{id}/
# operationId: delete
export def "activity-status-change-opportunity delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/status_change/opportunity/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or filter all LeadMerge activities
#
# GET /activity/lead_merge/
# operationId: list
export def "activity-lead-merge list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --id-in: list # Filter by activity IDs (comma-separated)
  --lead-id: list # Filter by lead IDs (comma-separated)
  --contact-id: list # Filter by contact IDs (comma-separated)
  --user-id: list # Filter by user IDs (comma-separated)
  --organization-id: string
  --type: list # Filter by activity type, e.g. Call (comma-separated)
  --date-created-gte: string
  --date-created-lte: string
  --date-created-gt: string
  --date-created-lt: string
  --activity-at-gte: string
  --activity-at-lte: string
  --activity-at-gt: string
  --activity-at-lt: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "id__in" $id_in "scalar") (serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "_type" $type "scalar") (serialize-qp "date_created__gte" $date_created_gte "scalar") (serialize-qp "date_created__lte" $date_created_lte "scalar") (serialize-qp "date_created__gt" $date_created_gt "scalar") (serialize-qp "date_created__lt" $date_created_lt "scalar") (serialize-qp "activity_at__gte" $activity_at_gte "scalar") (serialize-qp "activity_at__lte" $activity_at_lte "scalar") (serialize-qp "activity_at__gt" $activity_at_gt "scalar") (serialize-qp "activity_at__lt" $activity_at_lt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activity/lead_merge/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single LeadMerge activity
#
# GET /activity/lead_merge/{id}/
# operationId: get
export def "activity-lead-merge get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/lead_merge/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or filter all TaskCompleted activities
#
# GET /activity/task_completed/
# operationId: list
export def "activity-task-completed list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --id-in: list # Filter by activity IDs (comma-separated)
  --lead-id: list # Filter by lead IDs (comma-separated)
  --contact-id: list # Filter by contact IDs (comma-separated)
  --user-id: list # Filter by user IDs (comma-separated)
  --organization-id: string
  --type: list # Filter by activity type, e.g. Call (comma-separated)
  --date-created-gte: string
  --date-created-lte: string
  --date-created-gt: string
  --date-created-lt: string
  --activity-at-gte: string
  --activity-at-lte: string
  --activity-at-gt: string
  --activity-at-lt: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "id__in" $id_in "scalar") (serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "_type" $type "scalar") (serialize-qp "date_created__gte" $date_created_gte "scalar") (serialize-qp "date_created__lte" $date_created_lte "scalar") (serialize-qp "date_created__gt" $date_created_gt "scalar") (serialize-qp "date_created__lt" $date_created_lt "scalar") (serialize-qp "activity_at__gte" $activity_at_gte "scalar") (serialize-qp "activity_at__lte" $activity_at_lte "scalar") (serialize-qp "activity_at__gt" $activity_at_gt "scalar") (serialize-qp "activity_at__lt" $activity_at_lt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activity/task_completed/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single TaskCompleted activity
#
# GET /activity/task_completed/{id}/
# operationId: get
export def "activity-task-completed get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/task_completed/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a TaskCompleted activity
#
# DELETE /activity/task_completed/{id}/
# operationId: delete
export def "activity-task-completed delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/activity/task_completed/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Webhook subscriptions
#
# GET /webhook/
# operationId: list
export def "webhook list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhook/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new Webhook subscription
#
# POST /webhook/
# operationId: create
# --events item shape: {action: string, extra_filter?: record, object_type: string}
export def "webhook create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  events: list # A list of events to subscribe to. Each event has an `object_type` and an `action` from values in the [event log](https://developer.close.com/api/resources/events/list-of-event-types). You can also use [Webhook Filters](https://developer.close.com/api/resources/webhooks/webhook-filters) while creating your subscription so that an event only fires to a Webhook when certain conditions are met. — item shape: {action: string, extra_filter?: record, object_type: string}
  --body-url: string # Destination URL for the webhook subscription
  --verify-ssl: oneof<nothing, bool> # Verify SSL certificate of destination webhook URL. Set to `false` to disable SSL certificate validation. We recommend using https to protect your data during delivery. (default: true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhook/")
  let body = {events: $events, url: $body_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a single Webhook subscription
#
# GET /webhook/{id}/
# operationId: get
export def "webhook get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhook/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update existing Webhook subscription
#
# PUT /webhook/{id}/
# operationId: update
# --events item shape: {action: string, extra_filter?: record, object_type: string}
export def "webhook update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --events: list # A list of events to subscribe to. Each event has an `object_type` and an `action` from values in the [event log](https://developer.close.com/api/resources/events/list-of-event-types). You can also use [Webhook Filters](https://developer.close.com/api/resources/webhooks/webhook-filters) while creating your subscription so that an event only fires to a Webhook when certain conditions are met. (nullable) — item shape: {action: string, extra_filter?: record, object_type: string}
  --status: any
  --body-url: string # Destination URL for the webhook subscription (nullable)
  --verify-ssl: oneof<nothing, bool> # Verify SSL certificate of destination webhook URL. Set to `false` to disable SSL certificate validation. We recommend using https to protect your data during delivery. (nullable)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhook/($id)/")
  let body = {events: $events, status: $status, url: $body_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Webhook subscription
#
# DELETE /webhook/{id}/
# operationId: delete
export def "webhook delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhook/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of events
#
# GET /event/
# operationId: list
export def "event list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --object-type: string
  --object-id: string
  --lead-id: string
  --action: string
  --user-id: string
  --date-updated-gt: string
  --date-updated-gte: string
  --date-updated-lt: string
  --date-updated-lte: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "object_type" $object_type "scalar") (serialize-qp "object_id" $object_id "scalar") (serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "action" $action "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "date_updated__gt" $date_updated_gt "scalar") (serialize-qp "date_updated__gte" $date_updated_gte "scalar") (serialize-qp "date_updated__lt" $date_updated_lt "scalar") (serialize-qp "date_updated__lte" $date_updated_lte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/event/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a single event by ID
#
# GET /event/{id}/
# operationId: get
export def "event get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Smart Views
#
# GET /saved_search/
# operationId: list
export def "saved-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --type: string
  --type-in: list
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<data: table<date_created: string, date_updated: string, description: string, id: string, is_shared: bool, is_user_dependent: bool, name: string, organization_id: string, query: string, s_query: record, selected_fields: list, shared_with: list, sharing_settings: any, type: string, user_id: string>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "type__in" $type_in "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/saved_search/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Smart View
#
# POST /saved_search/
# operationId: create
export def "saved-search create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record<date_created: string, date_updated: string, description: string, id: string, is_shared: bool, is_user_dependent: bool, name: string, organization_id: string, query: string, s_query: record, selected_fields: list<record>, shared_with: list<string>, sharing_settings: any, type: string, user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/saved_search/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single Smart View
#
# GET /saved_search/{id}/
# operationId: get
export def "saved-search get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<date_created: string, date_updated: string, description: string, id: string, is_shared: bool, is_user_dependent: bool, name: string, organization_id: string, query: string, s_query: record, selected_fields: list<record>, shared_with: list<string>, sharing_settings: any, type: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/saved_search/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Smart View
#
# PUT /saved_search/{id}/
# operationId: update
export def "saved-search update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record<date_created: string, date_updated: string, description: string, id: string, is_shared: bool, is_user_dependent: bool, name: string, organization_id: string, query: string, s_query: record, selected_fields: list<record>, shared_with: list<string>, sharing_settings: any, type: string, user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/saved_search/($id)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Smart View
#
# DELETE /saved_search/{id}/
# operationId: delete
export def "saved-search delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/saved_search/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an activity report
#
# POST /report/activity/
# operationId: get-activity
export def "report-activity get-activity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/report/activity/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the predefined metrics used in activity reports
#
# GET /report/activity/metrics/
# operationId: list-activity-metrics
export def "report-activity-metrics list-activity-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/report/activity/metrics/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get custom report (Explorer)
#
# GET /report/custom/{org_id}/
# operationId: get-custom
export def "report-custom get-custom" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string
  --x: string
  --y: string
  --group-by: string
  --transform-y: string@transform-y-completer
  --interval: string
  --start: string
  --end: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "x" $x "scalar") (serialize-qp "y" $y "scalar") (serialize-qp "group_by" $group_by "scalar") (serialize-qp "transform_y" $transform_y "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/report/custom/($org_id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a funnel report (stages)
#
# POST /report/funnel/opportunity/stages/
# operationId: get-funnel-stages
export def "report-funnel-opportunity-stages get-funnel-stages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/report/funnel/opportunity/stages/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a funnel report (totals)
#
# POST /report/funnel/opportunity/totals/
# operationId: get-funnel-totals
export def "report-funnel-opportunity-totals get-funnel-totals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/report/funnel/opportunity/totals/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get sent emails report
#
# GET /report/sent_emails/{org_id}/
# operationId: get-sent-emails
export def "report-sent-emails get-sent-emails" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date-start: string
  --date-end: string
  --user-id: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_start" $date_start "scalar") (serialize-qp "date_end" $date_end "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/report/sent_emails/($org_id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get lead status change report
#
# GET /report/statuses/lead/{org_id}/
# operationId: get-lead-statuses
export def "report-statuses-lead get-lead-statuses" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date-start: string
  --date-end: string
  --qp-query: string
  --smart-view-id: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_start" $date_start "scalar") (serialize-qp "date_end" $date_end "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "smart_view_id" $smart_view_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/report/statuses/lead/($org_id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get opportunity status change report
#
# GET /report/statuses/opportunity/{org_id}/
# operationId: get-opportunity-statuses
export def "report-statuses-opportunity get-opportunity-statuses" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date-start: string
  --date-end: string
  --qp-query: string
  --smart-view-id: string
  --user-id: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_start" $date_start "scalar") (serialize-qp "date_end" $date_end "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "smart_view_id" $smart_view_id "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/report/statuses/opportunity/($org_id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Sequences
#
# GET /sequence/
# operationId: list
export def "sequence list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sequence/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Sequence
#
# POST /sequence/
# operationId: create
export def "sequence create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sequence/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a Sequence
#
# GET /sequence/{id}/
# operationId: get
export def "sequence get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sequence/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Sequence
#
# PUT /sequence/{id}/
# operationId: update
export def "sequence update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sequence/($id)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Sequence
#
# DELETE /sequence/{id}/
# operationId: delete
export def "sequence delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sequence/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Sequence Subscriptions
#
# GET /sequence_subscription/
# operationId: list-subscriptions
export def "sequence-subscription list-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --contact-id: string
  --lead-id: string
  --sequence-id: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "sequence_id" $sequence_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sequence_subscription/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscribe a Contact to a Sequence
#
# POST /sequence_subscription/
# operationId: create-subscription
export def "sequence-subscription create-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sequence_subscription/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a single Sequence Subscription
#
# GET /sequence_subscription/{id}/
# operationId: get-subscription
export def "sequence-subscription get-subscription" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sequence_subscription/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a specific Subscription
#
# PUT /sequence_subscription/{id}/
# operationId: update-subscription
export def "sequence-subscription update-subscription" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sequence_subscription/($id)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List bulk emails
#
# GET /bulk_action/email/
# operationId: list
export def "bulk-action-email list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --template-id: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<data: table<contact_preference: any, created_by: string, date_created: string, date_updated: string, email_account_id: string, id: string, n_leads: int, n_leads_processed: int, n_objects: int, n_objects_processed: int, organization_id: string, query: string, results_limit: int, s_query: record, send_done_email: bool, sender: string, sort: list, status: any, template_id: string, updated_by: string>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "_fields" $qp_fields "scalar") (serialize-qp "template_id" $template_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bulk_action/email/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initiate a new bulk email
#
# POST /bulk_action/email/
# operationId: create
export def "bulk-action-email create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record<contact_preference: any, created_by: string, date_created: string, date_updated: string, email_account_id: string, id: string, n_leads: int, n_leads_processed: int, n_objects: int, n_objects_processed: int, organization_id: string, query: string, results_limit: int, s_query: record, send_done_email: bool, sender: string, sort: list<record>, status: any, template_id: string, updated_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bulk_action/email/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a single bulk email object
#
# GET /bulk_action/email/{id}/
# operationId: get
export def "bulk-action-email get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<contact_preference: any, created_by: string, date_created: string, date_updated: string, email_account_id: string, id: string, n_leads: int, n_leads_processed: int, n_objects: int, n_objects_processed: int, organization_id: string, query: string, results_limit: int, s_query: record, send_done_email: bool, sender: string, sort: list<record>, status: any, template_id: string, updated_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bulk_action/email/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List bulk edits
#
# GET /bulk_action/edit/
# operationId: list
export def "bulk-action-edit list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<data: table<created_by: string, custom_field_name: string, custom_field_value: string, date_created: string, date_updated: string, id: string, lead_status_id: string, n_leads: int, n_leads_processed: int, n_objects: int, n_objects_processed: int, organization_id: string, query: string, results_limit: int, s_query: record, send_done_email: bool, sort: list, status: any, type: string, updated_by: string>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bulk_action/edit/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initiate a new bulk edit
#
# POST /bulk_action/edit/
# operationId: create
export def "bulk-action-edit create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record<created_by: string, custom_field_name: string, custom_field_value: string, date_created: string, date_updated: string, id: string, lead_status_id: string, n_leads: int, n_leads_processed: int, n_objects: int, n_objects_processed: int, organization_id: string, query: string, results_limit: int, s_query: record, send_done_email: bool, sort: list<record>, status: any, type: string, updated_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bulk_action/edit/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a single bulk edit object
#
# GET /bulk_action/edit/{id}/
# operationId: get
export def "bulk-action-edit get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<created_by: string, custom_field_name: string, custom_field_value: string, date_created: string, date_updated: string, id: string, lead_status_id: string, n_leads: int, n_leads_processed: int, n_objects: int, n_objects_processed: int, organization_id: string, query: string, results_limit: int, s_query: record, send_done_email: bool, sort: list<record>, status: any, type: string, updated_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bulk_action/edit/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List bulk deletes
#
# GET /bulk_action/delete/
# operationId: list
export def "bulk-action-delete list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<data: table<bulk_object_type: string, created_by: string, date_created: string, date_updated: string, id: string, n_leads: int, n_leads_processed: int, n_objects: int, n_objects_processed: int, organization_id: string, query: string, results_limit: int, s_query: record, send_done_email: bool, sort: list, status: any, updated_by: string>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bulk_action/delete/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initiate a new bulk delete
#
# POST /bulk_action/delete/
# operationId: create
export def "bulk-action-delete create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record<bulk_object_type: string, created_by: string, date_created: string, date_updated: string, id: string, n_leads: int, n_leads_processed: int, n_objects: int, n_objects_processed: int, organization_id: string, query: string, results_limit: int, s_query: record, send_done_email: bool, sort: list<record>, status: any, updated_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bulk_action/delete/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a single bulk delete object
#
# GET /bulk_action/delete/{id}/
# operationId: get
export def "bulk-action-delete get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<bulk_object_type: string, created_by: string, date_created: string, date_updated: string, id: string, n_leads: int, n_leads_processed: int, n_objects: int, n_objects_processed: int, organization_id: string, query: string, results_limit: int, s_query: record, send_done_email: bool, sort: list<record>, status: any, updated_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bulk_action/delete/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List bulk sequence subscriptions
#
# GET /bulk_action/sequence_subscription/
# operationId: list
export def "bulk-action-sequence-subscription list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<data: table<action_type: string, calls_assigned_to: list, contact_preference: any, created_by: string, date_created: string, date_updated: string, from_phone_number_id: string, id: string, n_leads: int, n_leads_processed: int, n_objects: int, n_objects_processed: int, organization_id: string, query: string, results_limit: int, s_query: record, send_done_email: bool, sender_account_id: string, sender_email: string, sender_name: string, sequence_id: string, sort: list, status: any, updated_by: string>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bulk_action/sequence_subscription/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initiate a new bulk sequence subscription
#
# POST /bulk_action/sequence_subscription/
# operationId: create
export def "bulk-action-sequence-subscription create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record<action_type: string, calls_assigned_to: list<string>, contact_preference: any, created_by: string, date_created: string, date_updated: string, from_phone_number_id: string, id: string, n_leads: int, n_leads_processed: int, n_objects: int, n_objects_processed: int, organization_id: string, query: string, results_limit: int, s_query: record, send_done_email: bool, sender_account_id: string, sender_email: string, sender_name: string, sequence_id: string, sort: list<record>, status: any, updated_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bulk_action/sequence_subscription/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a single bulk sequence subscription object
#
# GET /bulk_action/sequence_subscription/{id}/
# operationId: get
export def "bulk-action-sequence-subscription get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<action_type: string, calls_assigned_to: list<string>, contact_preference: any, created_by: string, date_created: string, date_updated: string, from_phone_number_id: string, id: string, n_leads: int, n_leads_processed: int, n_objects: int, n_objects_processed: int, organization_id: string, query: string, results_limit: int, s_query: record, send_done_email: bool, sender_account_id: string, sender_email: string, sender_name: string, sequence_id: string, sort: list<record>, status: any, updated_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bulk_action/sequence_subscription/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all the exports
#
# GET /export/
# operationId: list
export def "export list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/export/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export leads based on a search query
#
# POST /export/lead/
# operationId: create-lead
export def "export-lead create-lead" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/export/lead/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export opportunities, based on opportunity filters
#
# POST /export/opportunity/
# operationId: create-opportunity
export def "export-opportunity create-opportunity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/export/opportunity/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single Export
#
# GET /export/{id}/
# operationId: get
export def "export get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/export/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enrich a specific field on a lead or contact using AI
#
# POST /enrich_field/
# operationId: create
export def "enrich-field create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  field_id: string
  object_id: string
  object_type: string@object-type-completer
  organization_id: string
  --overwrite-existing-value: oneof<nothing, bool> # default: false
  --set-new-value: oneof<nothing, bool> # default: true
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enrich_field/")
  let body = {field_id: $field_id, object_id: $object_id, object_type: $object_type, organization_id: $organization_id, overwrite_existing_value: $overwrite_existing_value, set_new_value: $set_new_value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a custom field schema
#
# GET /custom_field_schema/{object_type}/
# operationId: get
export def "custom-field-schema get" [
  object_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_field_schema/($object_type)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a custom field schema
#
# PUT /custom_field_schema/{object_type}/
# operationId: update
export def "custom-field-schema update" [
  object_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_field_schema/($object_type)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Lead Custom Fields
#
# GET /custom_field/lead/
# operationId: list
export def "custom-field-lead list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_field/lead/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Lead Custom Field
#
# POST /custom_field/lead/
# operationId: create
export def "custom-field-lead create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom_field/lead/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch Lead Custom Field's details
#
# GET /custom_field/lead/{id}/
# operationId: get
export def "custom-field-lead get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom_field/lead/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Lead Custom Field
#
# PUT /custom_field/lead/{id}/
# operationId: update
export def "custom-field-lead update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_field/lead/($id)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Lead Custom Field
#
# DELETE /custom_field/lead/{id}/
# operationId: delete
export def "custom-field-lead delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_field/lead/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Contact Custom Fields
#
# GET /custom_field/contact/
# operationId: list
export def "custom-field-contact list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_field/contact/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Contact Custom Field
#
# POST /custom_field/contact/
# operationId: create
export def "custom-field-contact create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom_field/contact/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch Contact Custom Field's details
#
# GET /custom_field/contact/{id}/
# operationId: get
export def "custom-field-contact get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom_field/contact/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Contact Custom Field
#
# PUT /custom_field/contact/{id}/
# operationId: update
export def "custom-field-contact update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_field/contact/($id)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Contact Custom Field
#
# DELETE /custom_field/contact/{id}/
# operationId: delete
export def "custom-field-contact delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_field/contact/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Opportunity Custom Fields
#
# GET /custom_field/opportunity/
# operationId: list
export def "custom-field-opportunity list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_field/opportunity/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Opportunity Custom Field
#
# POST /custom_field/opportunity/
# operationId: create
export def "custom-field-opportunity create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom_field/opportunity/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch Opportunity Custom Field's details
#
# GET /custom_field/opportunity/{id}/
# operationId: get
export def "custom-field-opportunity get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom_field/opportunity/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Opportunity Custom Field
#
# PUT /custom_field/opportunity/{id}/
# operationId: update
export def "custom-field-opportunity update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_field/opportunity/($id)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Opportunity Custom Field
#
# DELETE /custom_field/opportunity/{id}/
# operationId: delete
export def "custom-field-opportunity delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_field/opportunity/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Activity Custom Fields
#
# GET /custom_field/activity/
# operationId: list
export def "custom-field-activity list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_field/activity/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Activity Custom Field
#
# POST /custom_field/activity/
# operationId: create
export def "custom-field-activity create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom_field/activity/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch Activity Custom Field's details
#
# GET /custom_field/activity/{id}/
# operationId: get
export def "custom-field-activity get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom_field/activity/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Activity Custom Field
#
# PUT /custom_field/activity/{id}/
# operationId: update
export def "custom-field-activity update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_field/activity/($id)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Activity Custom Field
#
# DELETE /custom_field/activity/{id}/
# operationId: delete
export def "custom-field-activity delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_field/activity/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Custom Object Custom Fields
#
# GET /custom_field/custom_object_type/
# operationId: list
export def "custom-field-custom-object-type list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom_field/custom_object_type/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Custom Object Custom Field
#
# POST /custom_field/custom_object_type/
# operationId: create
export def "custom-field-custom-object-type create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom_field/custom_object_type/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch Custom Object Custom Field's details
#
# GET /custom_field/custom_object_type/{id}/
# operationId: get
export def "custom-field-custom-object-type get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_field/custom_object_type/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Custom Object Custom Field
#
# PUT /custom_field/custom_object_type/{id}/
# operationId: update
export def "custom-field-custom-object-type update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_field/custom_object_type/($id)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Custom Object Custom Field
#
# DELETE /custom_field/custom_object_type/{id}/
# operationId: delete
export def "custom-field-custom-object-type delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_field/custom_object_type/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Shared Custom Fields
#
# GET /custom_field/shared/
# operationId: list
export def "custom-field-shared list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_field/shared/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Shared Custom Field
#
# POST /custom_field/shared/
# operationId: create
export def "custom-field-shared create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom_field/shared/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch Shared Custom Field's details
#
# GET /custom_field/shared/{id}/
# operationId: get
export def "custom-field-shared get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom_field/shared/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Shared Custom Field
#
# PUT /custom_field/shared/{id}/
# operationId: update
export def "custom-field-shared update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_field/shared/($id)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Shared Custom Field
#
# DELETE /custom_field/shared/{id}/
# operationId: delete
export def "custom-field-shared delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_field/shared/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Associate a Shared Custom Field with an object type
#
# POST /custom_field/shared/{scf_id}/association/
# operationId: create-association
export def "custom-field-shared-association create-association" [
  scf_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_field/shared/($scf_id)/association/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a Shared Custom Field Association
#
# GET /custom_field/shared/{scf_id}/association/{object_type}/
# operationId: get-association
export def "custom-field-shared-association get-association" [
  scf_id: string
  object_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_field/shared/($scf_id)/association/($object_type)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing Shared Custom Field Association
#
# PUT /custom_field/shared/{scf_id}/association/{object_type}/
# operationId: update-association
export def "custom-field-shared-association update-association" [
  scf_id: string
  object_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_field/shared/($scf_id)/association/($object_type)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disassociate a Shared Custom Field from an object type
#
# DELETE /custom_field/shared/{scf_id}/association/{object_type}/
# operationId: delete-association
export def "custom-field-shared-association delete-association" [
  scf_id: string
  object_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_field/shared/($scf_id)/association/($object_type)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Custom Activity Types
#
# GET /custom_activity/
# operationId: list
export def "custom-activity list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom_activity/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new Custom Activity Type
#
# POST /custom_activity/
# operationId: create
export def "custom-activity create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom_activity/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a single Custom Activity Type
#
# GET /custom_activity/{id}/
# operationId: get
export def "custom-activity get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_activity/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update existing Custom Activity Type
#
# PUT /custom_activity/{id}/
# operationId: update
export def "custom-activity update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_activity/($id)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Custom Activity Type
#
# DELETE /custom_activity/{id}/
# operationId: delete
export def "custom-activity delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_activity/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Custom Object Types
#
# GET /custom_object_type/
# operationId: list
export def "custom-object-type list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom_object_type/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new Custom Object Type
#
# POST /custom_object_type/
# operationId: create
export def "custom-object-type create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom_object_type/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a single Custom Object Type
#
# GET /custom_object_type/{id}/
# operationId: get
export def "custom-object-type get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_object_type/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update existing Custom Object Type
#
# PUT /custom_object_type/{id}/
# operationId: update
export def "custom-object-type update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_object_type/($id)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Custom Object Type
#
# DELETE /custom_object_type/{id}/
# operationId: delete
export def "custom-object-type delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_object_type/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Pipelines for your organization
#
# GET /pipeline/
# operationId: list
export def "pipeline list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pipeline/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Pipeline
#
# POST /pipeline/
# operationId: create
export def "pipeline create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pipeline/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a Pipeline
#
# PUT /pipeline/{id}/
# operationId: update
export def "pipeline update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pipeline/($id)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Pipeline
#
# DELETE /pipeline/{id}/
# operationId: delete
export def "pipeline delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pipeline/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List opportunity statuses for your organization
#
# GET /status/opportunity/
# operationId: list
export def "status-opportunity list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/status/opportunity/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an opportunity status
#
# POST /status/opportunity/
# operationId: create
export def "status-opportunity create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/status/opportunity/" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rename an opportunity status
#
# PUT /status/opportunity/{id}/
# operationId: update
export def "status-opportunity update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/status/opportunity/($id)/" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an opportunity status
#
# DELETE /status/opportunity/{id}/
# operationId: delete
export def "status-opportunity delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status/opportunity/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List lead statuses for your organization
#
# GET /status/lead/
# operationId: list
export def "status-lead list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/status/lead/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new status that can be applied to leads
#
# POST /status/lead/
# operationId: create
export def "status-lead create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/status/lead/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rename a lead status
#
# PUT /status/lead/{id}/
# operationId: update
export def "status-lead update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status/lead/($id)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a lead status
#
# DELETE /status/lead/{id}/
# operationId: delete
export def "status-lead delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status/lead/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all integration links for your organization
#
# GET /integration_link/
# operationId: list
export def "integration-link list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<data: table<created_by: string, date_created: string, date_updated: string, id: string, name: string, organization_id: string, type: string, updated_by: string, url: string>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integration_link/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an integration link
#
# POST /integration_link/
# operationId: create
export def "integration-link create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  name: string
  type: string@type-completer-1
  --body-url: string
]: any -> record<created_by: string, date_created: string, date_updated: string, id: string, name: string, organization_id: string, type: string, updated_by: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integration_link/")
  let body = {name: $name, type: $type, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single integration link
#
# GET /integration_link/{id}/
# operationId: get
export def "integration-link get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<created_by: string, date_created: string, date_updated: string, id: string, name: string, organization_id: string, type: string, updated_by: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integration_link/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an integration link
#
# PUT /integration_link/{id}/
# operationId: update
export def "integration-link update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --name: string # nullable
  --type: any
  --body-url: string # nullable
]: any -> record<created_by: string, date_created: string, date_updated: string, id: string, name: string, organization_id: string, type: string, updated_by: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integration_link/($id)/")
  let body = {name: $name, type: $type, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an integration link
#
# DELETE /integration_link/{id}/
# operationId: delete
export def "integration-link delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integration_link/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Forms
#
# GET /form/
# operationId: list
export def "form list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --is-archived: oneof<nothing, bool> # Filter by archive status.
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<data: table<date_created: string, date_updated: string, field_definitions: list, id: string, is_archived: bool, name: string, organization_id: string>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "is_archived" $is_archived "scalar") (serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/form/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a Form
#
# GET /form/{id}/
# operationId: fetch
export def "form fetch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<date_created: string, date_updated: string, field_definitions: table<choices: list, id: string, name: string, type: string>, id: string, is_archived: bool, name: string, organization_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/form/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List email templates
#
# GET /email_template/
# operationId: list
export def "email-template list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --is-archived: oneof<nothing, bool>
  --is-shared: oneof<nothing, bool>
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "is_archived" $is_archived "scalar") (serialize-qp "is_shared" $is_shared "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/email_template/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an email template
#
# POST /email_template/
# operationId: create
export def "email-template create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/email_template/" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch an email template
#
# GET /email_template/{id}/
# operationId: get
export def "email-template get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --include-embedded: oneof<nothing, bool> # Include embedded templates used by Workflows.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar") (serialize-qp "include_embedded" $include_embedded "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/email_template/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an email template
#
# PUT /email_template/{id}/
# operationId: update
export def "email-template update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/email_template/($id)/" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an email template
#
# DELETE /email_template/{id}/
# operationId: delete
export def "email-template delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/email_template/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Render an email template
#
# GET /email_template/{id}/render/
# operationId: render
export def "email-template-render render" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email-account-id: string
  --bulk-object-type: string@bulk-object-type-completer
  --contact-id: string
  --contact-preference: string@contact-preference-completer
  --entry: int
  --lead-id: string
  --limit: int
  --qp-query: string
  --results-limit: int
  --s-query: string
  --sender: string # format: email
  --qp-sort: list
  --mode: string@mode-completer
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email_account_id" $email_account_id "scalar") (serialize-qp "bulk_object_type" $bulk_object_type "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "contact_preference" $contact_preference "scalar") (serialize-qp "entry" $entry "scalar") (serialize-qp "lead_id" $lead_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "results_limit" $results_limit "scalar") (serialize-qp "s_query" $s_query "scalar") (serialize-qp "sender" $sender "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "mode" $mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/email_template/($id)/render/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List SMS templates
#
# GET /sms_template/
# operationId: list
export def "sms-template list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sms_template/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an SMS template
#
# POST /sms_template/
# operationId: create
# --attachments item shape: {content_type: string, filename: string, url: string}
export def "sms-template create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --attachments: list # item shape: {content_type: string, filename: string, url: string}
  --is-shared: oneof<nothing, bool>
  name: string
  --text: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sms_template/")
  let body = {attachments: $attachments, is_shared: $is_shared, name: $name, text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch an SMS template
#
# GET /sms_template/{id}/
# operationId: get
export def "sms-template get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-attachments: oneof<nothing, bool> # Include file attachments in the response. (default: false)
  --include-embedded: oneof<nothing, bool> # Include embedded templates used by Workflows. (default: false)
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_attachments" $include_attachments "scalar") (serialize-qp "include_embedded" $include_embedded "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sms_template/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an SMS template
#
# PUT /sms_template/{id}/
# operationId: update
# --attachments item shape: {content_type: string, filename: string, url: string}
export def "sms-template update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --attachments: list # item shape: {content_type: string, filename: string, url: string}
  --is-shared: oneof<nothing, bool>
  --name: string
  --status: string@status-completer-3
  --text: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sms_template/($id)/")
  let body = {attachments: $attachments, is_shared: $is_shared, name: $name, status: $status, text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an SMS template
#
# DELETE /sms_template/{id}/
# operationId: delete
export def "sms-template delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sms_template/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or filter outcomes
#
# GET /outcome/
# operationId: list
export def "outcome list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<data: table<applies_to: list, created_by: string, date_created: string, date_updated: string, description: string, id: string, name: string, organization_id: string, type: string, updated_by: string>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/outcome/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an outcome
#
# POST /outcome/
# operationId: create
export def "outcome create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --applies-to: list # Deprecated. This field will be derived from `type` in a future update: `custom` applies to calls and meetings, `vm-dropped` applies to calls only. (nullable)
  --description: string # Explain what the outcome means and when it should be used. (nullable)
  name: string # Displayed to users wherever outcomes can be selected.
  --type: string@type-completer-2
]: any -> record<applies_to: list<string>, created_by: string, date_created: string, date_updated: string, description: string, id: string, name: string, organization_id: string, type: string, updated_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/outcome/")
  let body = {applies_to: $applies_to, description: $description, name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a single outcome
#
# GET /outcome/{id}/
# operationId: get
export def "outcome get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<applies_to: list<string>, created_by: string, date_created: string, date_updated: string, description: string, id: string, name: string, organization_id: string, type: string, updated_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/outcome/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an outcome
#
# PUT /outcome/{id}/
# operationId: update
export def "outcome update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --applies-to: list # Deprecated. This field will be derived from `type` in a future update: `custom` applies to calls and meetings, `vm-dropped` applies to calls only. (nullable)
  --description: string # Explain what the outcome means and when it should be used. (nullable)
  --name: string # Displayed to users wherever outcomes can be selected. (nullable)
  --type: any # Set to `vm-dropped` if this outcome should be automatically set on calls whenever a team member performs a Voicemail Drop. Otherwise, leave empty or explicitly set to `custom` (default).
]: any -> record<applies_to: list<string>, created_by: string, date_created: string, date_updated: string, description: string, id: string, name: string, organization_id: string, type: string, updated_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/outcome/($id)/")
  let body = {applies_to: $applies_to, description: $description, name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an outcome
#
# DELETE /outcome/{id}/
# operationId: delete
export def "outcome delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/outcome/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or filter playbooks
#
# GET /playbook/
# operationId: list
export def "playbook list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --is-archived: oneof<nothing, bool> # Filter for archived or not-archived playbooks. When not provided, both archived and not-archived playbooks will be returned.
  --position-gt: int # Filters for where the playbook's `position` is greater than the given value.
  --created-at-lt: string # Filters for where the playbook's `created_at` (creation date) is before the given value. (format: date-time)
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<data: table<archived_at: string, archived_by_id: string, created_at: string, created_by_id: string, custom_field_ids: list, description: string, id: string, name: string, organization_id: string, outcome_ids: list, position: int, summary_guidance: string, updated_at: string, updated_by_id: string>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "is_archived" $is_archived "scalar") (serialize-qp "position__gt" $position_gt "scalar") (serialize-qp "created_at__lt" $created_at_lt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playbook/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a playbook
#
# POST /playbook/
# operationId: create
export def "playbook create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --custom-field-ids: list # IDs of [Shared Custom Fields](/api/resources/custom-fields/custom-fields-shared) to associate with this Playbook.
  --description: string # Description of the playbook. (nullable)
  name: string
  --outcome-ids: list # IDs of [Outcomes](/api/resources/outcomes/) that should be associated with this Playbook.
  --summary-guidance: string # Guidance for AI summaries of calls and meetings associated with this Playbook. (nullable)
]: any -> record<archived_at: string, archived_by_id: string, created_at: string, created_by_id: string, custom_field_ids: list<string>, description: string, id: string, name: string, organization_id: string, outcome_ids: list<string>, position: int, summary_guidance: string, updated_at: string, updated_by_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/playbook/")
  let body = {custom_field_ids: $custom_field_ids, description: $description, name: $name, outcome_ids: $outcome_ids, summary_guidance: $summary_guidance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a single playbook
#
# GET /playbook/{id}/
# operationId: get
export def "playbook get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<archived_at: string, archived_by_id: string, created_at: string, created_by_id: string, custom_field_ids: list<string>, description: string, id: string, name: string, organization_id: string, outcome_ids: list<string>, position: int, summary_guidance: string, updated_at: string, updated_by_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/playbook/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a playbook
#
# PUT /playbook/{id}/
# operationId: update
export def "playbook update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --custom-field-ids: list # IDs of [Shared Custom Fields](/api/resources/custom-fields/custom-fields-shared) to associate with this Playbook.
  --description: string # Description of the playbook. (nullable)
  --name: string
  --outcome-ids: list # IDs of [Outcomes](/api/resources/outcomes/) that should be associated with this Playbook.
  --summary-guidance: string # Guidance for AI summaries of calls and meetings associated with this Playbook. (nullable)
]: any -> record<archived_at: string, archived_by_id: string, created_at: string, created_by_id: string, custom_field_ids: list<string>, description: string, id: string, name: string, organization_id: string, outcome_ids: list<string>, position: int, summary_guidance: string, updated_at: string, updated_by_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/playbook/($id)/")
  let body = {custom_field_ids: $custom_field_ids, description: $description, name: $name, outcome_ids: $outcome_ids, summary_guidance: $summary_guidance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a playbook
#
# DELETE /playbook/{id}/
# operationId: delete
export def "playbook delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/playbook/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive a playbook
#
# POST /playbook/{id}/archive/
# operationId: archive
export def "playbook-archive archive" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<archived_at: string, archived_by_id: string, created_at: string, created_by_id: string, custom_field_ids: list<string>, description: string, id: string, name: string, organization_id: string, outcome_ids: list<string>, position: int, summary_guidance: string, updated_at: string, updated_by_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/playbook/($id)/archive/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unarchive a playbook
#
# POST /playbook/{id}/unarchive/
# operationId: unarchive
export def "playbook-unarchive unarchive" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<archived_at: string, archived_by_id: string, created_at: string, created_by_id: string, custom_field_ids: list<string>, description: string, id: string, name: string, organization_id: string, outcome_ids: list<string>, position: int, summary_guidance: string, updated_at: string, updated_by_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/playbook/($id)/unarchive/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User Scheduling Links
#
# GET /scheduling_link/
# operationId: list
export def "scheduling-link list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scheduling_link/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a User Scheduling Link
#
# POST /scheduling_link/
# operationId: create
export def "scheduling-link create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scheduling_link/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create or update a Scheduling Link via OAuth
#
# POST /scheduling_link/integration/
# operationId: create-integration
export def "scheduling-link-integration create-integration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scheduling_link/integration/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a User Scheduling Link via OAuth integration
#
# DELETE /scheduling_link/integration/{source_id}/
# operationId: delete-integration
export def "scheduling-link-integration delete-integration" [
  source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scheduling_link/integration/($source_id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a User Scheduling Link
#
# GET /scheduling_link/{id}/
# operationId: get
export def "scheduling-link get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scheduling_link/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a User Scheduling Link
#
# PUT /scheduling_link/{id}/
# operationId: update
export def "scheduling-link update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scheduling_link/($id)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a User Scheduling Link
#
# DELETE /scheduling_link/{id}/
# operationId: delete
export def "scheduling-link delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scheduling_link/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Shared Scheduling Links
#
# GET /shared_scheduling_link/
# operationId: list-shared
export def "shared-scheduling-link list-shared" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shared_scheduling_link/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Shared Scheduling Link
#
# POST /shared_scheduling_link/
# operationId: create-shared
export def "shared-scheduling-link create-shared" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shared_scheduling_link/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a Shared Scheduling Link
#
# GET /shared_scheduling_link/{id}/
# operationId: get-shared
export def "shared-scheduling-link get-shared" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shared_scheduling_link/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Shared Scheduling Link
#
# PUT /shared_scheduling_link/{id}/
# operationId: update-shared
export def "shared-scheduling-link update-shared" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shared_scheduling_link/($id)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Shared Scheduling Link
#
# DELETE /shared_scheduling_link/{id}/
# operationId: delete-shared
export def "shared-scheduling-link delete-shared" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shared_scheduling_link/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Map a Shared Scheduling Link
#
# POST /shared_scheduling_link_association/
# operationId: create-shared-association
export def "shared-scheduling-link-association create-shared-association" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shared_scheduling_link_association/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unmap a Shared Scheduling Link
#
# POST /shared_scheduling_link_association/unmap/
# operationId: delete-shared-association
export def "shared-scheduling-link-association-unmap delete-shared-association" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shared_scheduling_link_association/unmap/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List connected accounts
#
# GET /connected_account/
# operationId: list
export def "connected-account list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # default: [_type, available_calendars, available_features, calendar_receive_status, calendly, date_created, default_identity, email, email_receive_status, enabled_features, has_meeting_creation_scopes, id, identities, imap, is_imap_archive_sync_enabled, latest_receive_error, latest_send_error, lead_suggestions_updated_at, organization_id, receive_status, send_status, smtp, sync_all_calendars, synced_calendars, user_id, zoom_account_plan]
  --user-id: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "multi") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/connected_account/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a single connected account
#
# GET /connected_account/{id}/
# operationId: get
export def "connected-account get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # default: [_type, available_calendars, available_features, calendar_receive_status, calendly, date_created, default_identity, email, email_receive_status, enabled_features, has_meeting_creation_scopes, id, identities, imap, is_imap_archive_sync_enabled, latest_receive_error, latest_send_error, lead_suggestions_updated_at, organization_id, receive_status, send_status, smtp, sync_all_calendars, synced_calendars, user_id, zoom_account_plan]
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/connected_account/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Send As Associations
#
# GET /send_as/
# operationId: list
export def "send-as list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowed-user-id: string
  --allowing-user-id: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allowed_user_id" $allowed_user_id "scalar") (serialize-qp "allowing_user_id" $allowing_user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/send_as/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Send As Association
#
# POST /send_as/
# operationId: create
export def "send-as create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/send_as/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Send As Association by allowed user
#
# DELETE /send_as/
# operationId: delete-by-user
export def "send-as delete-by-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowed-user-id: string
  --allowing-user-id: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allowed_user_id" $allowed_user_id "scalar") (serialize-qp "allowing_user_id" $allowing_user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/send_as/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit Send As Associations in bulk
#
# POST /send_as/bulk/
# operationId: bulk-create
export def "send-as-bulk bulk-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/send_as/bulk/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a single Send As Association
#
# GET /send_as/{id}/
# operationId: get
export def "send-as get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/send_as/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Send As Association by ID
#
# DELETE /send_as/{id}/
# operationId: delete
export def "send-as delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/send_as/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all unsubscribed emails
#
# GET /unsubscribe/email/
# operationId: list
export def "unsubscribe-email list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/unsubscribe/email/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unsubscribe an email address
#
# POST /unsubscribe/email/
# operationId: create
export def "unsubscribe-email create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  email: string # format: email
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/unsubscribe/email/")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resubscribe an email address
#
# DELETE /unsubscribe/email/{email_address}/
# operationId: delete
export def "unsubscribe-email delete" [
  email_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/unsubscribe/email/($email_address)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or search for phone numbers
#
# GET /phone_number/
# operationId: list
export def "phone-number list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --number: string
  --user-id: string
  --is-group-number: oneof<nothing, bool>
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<data: table<address_id: string, bundle_id: string, carrier: any, carrier_type: any, country: string, date_created: string, date_updated: string, forward_to: string, forward_to_enabled: bool, forward_to_formatted: string, id: string, is_group_number: bool, is_premium: bool, is_verified: bool, label: string, last_billed_price: float, mms_enabled: bool, next_billing_on: string, number: string, number_formatted: string, organization_id: string, participants: list, phone_numbers: list, phone_numbers_formatted: list, press_1_to_accept: bool, sms_enabled: bool, supports_mms_to_countries: list, supports_sms_to_countries: list, type: string, user_id: string, voicemail_greeting_url: string, was_ported: bool>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "_fields" $qp_fields "scalar") (serialize-qp "number" $number "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "is_group_number" $is_group_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone_number/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request an internal phone number
#
# POST /phone_number/request/internal/
# operationId: create
export def "phone-number-request-internal create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --bundle-id: string # nullable
  --carrier-type: any
  country: string # A two letter ISO country code (e.g. `US` for United States).
  --prefix: string # A string with the phone number prefix or area code, not including the country code. (default: )
  sharing: string@sharing-completer
  --with-mms: oneof<nothing, bool> # By default, MMS-capable numbers are rented if Close supports MMS for the given country. Renting an MMS-capable number can be forced by setting this flag to `true`. If set to `false`, certain prefixes that don't support MMS can be rented in countries where Close supports MMS. In most scenarios, this flag should not be passed. When you request an MMS number, you must set `with_sms` to `true` as well. (nullable)
  --with-sms: oneof<nothing, bool> # By default, SMS-capable numbers are rented if Close supports SMS for the given country. Renting an SMS-capable number can be forced by setting this flag to `true`. If set to `false`, certain prefixes that don't support SMS can be rented in countries where Close supports SMS. In most scenarios, this flag should not be passed unless a `has-voice-only` error status is received. (nullable)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone_number/request/internal/")
  let body = {bundle_id: $bundle_id, carrier_type: $carrier_type, country: $country, prefix: $prefix, sharing: $sharing, with_mms: $with_mms, with_sms: $with_sms} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a single phone number
#
# GET /phone_number/{id}/
# operationId: get
export def "phone-number get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<address_id: string, bundle_id: string, carrier: any, carrier_type: any, country: string, date_created: string, date_updated: string, forward_to: string, forward_to_enabled: bool, forward_to_formatted: string, id: string, is_group_number: bool, is_premium: bool, is_verified: bool, label: string, last_billed_price: float, mms_enabled: bool, next_billing_on: string, number: string, number_formatted: string, organization_id: string, participants: list<string>, phone_numbers: list<string>, phone_numbers_formatted: list<string>, press_1_to_accept: bool, sms_enabled: bool, supports_mms_to_countries: list<string>, supports_sms_to_countries: list<string>, type: string, user_id: string, voicemail_greeting_url: string, was_ported: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/phone_number/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a phone number
#
# PUT /phone_number/{id}/
# operationId: update
export def "phone-number update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --forward-to: string
  --forward-to-enabled: oneof<nothing, bool>
  --label: string
  --participants: list
  --phone-numbers: list
  --press-1-to-accept: oneof<nothing, bool>
  --voicemail-greeting-url: string # nullable
]: any -> record<address_id: string, bundle_id: string, carrier: any, carrier_type: any, country: string, date_created: string, date_updated: string, forward_to: string, forward_to_enabled: bool, forward_to_formatted: string, id: string, is_group_number: bool, is_premium: bool, is_verified: bool, label: string, last_billed_price: float, mms_enabled: bool, next_billing_on: string, number: string, number_formatted: string, organization_id: string, participants: list<string>, phone_numbers: list<string>, phone_numbers_formatted: list<string>, press_1_to_accept: bool, sms_enabled: bool, supports_mms_to_countries: list<string>, supports_sms_to_countries: list<string>, type: string, user_id: string, voicemail_greeting_url: string, was_ported: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/phone_number/($id)/")
  let body = {forward_to: $forward_to, forward_to_enabled: $forward_to_enabled, label: $label, participants: $participants, phone_numbers: $phone_numbers, press_1_to_accept: $press_1_to_accept, voicemail_greeting_url: $voicemail_greeting_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a phone number
#
# DELETE /phone_number/{id}/
# operationId: delete
export def "phone-number delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/phone_number/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Blocked Phone Numbers
#
# GET /blocked_phone_number/
# operationId: list
export def "blocked-phone-number list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<data: table<created_by: string, date_created: string, date_updated: string, id: string, organization_id: string, phone: string, reason: string, updated_by: string>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar") (serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/blocked_phone_number/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Blocked Phone Number
#
# POST /blocked_phone_number/
# operationId: create
export def "blocked-phone-number create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  phone: string # The phone number (in E.164 format) that you wish to block.
  reason: string # The reason why you wish to block a given phone number.
]: any -> record<created_by: string, date_created: string, date_updated: string, id: string, organization_id: string, phone: string, reason: string, updated_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/blocked_phone_number/")
  let body = {phone: $phone, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Blocked Phone Number settings
#
# GET /blocked_phone_number/settings/
# operationId: get-settings
export def "blocked-phone-number-settings get-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<reject_anonymous_inbound_calls: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/blocked_phone_number/settings/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Blocked Phone Number settings
#
# PUT /blocked_phone_number/settings/
# operationId: update-settings
export def "blocked-phone-number-settings update-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --reject-anonymous-inbound-calls: oneof<nothing, bool>
]: any -> record<reject_anonymous_inbound_calls: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/blocked_phone_number/settings/")
  let body = {reject_anonymous_inbound_calls: $reject_anonymous_inbound_calls} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a single Blocked Phone Number
#
# GET /blocked_phone_number/{id}/
# operationId: get
export def "blocked-phone-number get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<created_by: string, date_created: string, date_updated: string, id: string, organization_id: string, phone: string, reason: string, updated_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/blocked_phone_number/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Blocked Phone Number
#
# PUT /blocked_phone_number/{id}/
# operationId: update
export def "blocked-phone-number update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  reason: string # The updated reason for blocking the given phone number.
]: any -> record<created_by: string, date_created: string, date_updated: string, id: string, organization_id: string, phone: string, reason: string, updated_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/blocked_phone_number/($id)/")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Blocked Phone Number
#
# DELETE /blocked_phone_number/{id}/
# operationId: delete
export def "blocked-phone-number delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/blocked_phone_number/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or filter all dialer sessions
#
# GET /dialer/
# operationId: list
export def "dialer list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organization-id: string
  --source-type: string
  --source-value: string
  --status: string
  --status-in: string
  --user-id: string
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "source_type" $source_type "scalar") (serialize-qp "source_value" $source_value "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "status__in" $status_in "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dialer/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single dialer session
#
# GET /dialer/{id}/
# operationId: get
export def "dialer get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organization-id: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organization_id" $organization_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dialer/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch information about yourself
#
# GET /me/
# operationId: get-me
export def "me get-me" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List users in your organization
#
# GET /user/
# operationId: list
export def "user list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order-by: string@order-by-completer
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_order_by" $order_by "scalar") (serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List user availability statuses
#
# GET /user/availability/
# operationId: list-availabilities
export def "user-availability list-availabilities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organization-id: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organization_id" $organization_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/availability/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a single user
#
# GET /user/{id}/
# operationId: get
export def "user get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order-by: string@order-by-completer
  --limit: int # Number of results to return. (default: 100)
  --skip: int # Number of results to skip before returning, for pagination. (default: 0)
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_order_by" $order_by "scalar") (serialize-qp "_limit" $limit "scalar") (serialize-qp "_skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an organization's details
#
# GET /organization/{id}/
# operationId: get
export def "organization get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: string
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organization/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an organization
#
# PUT /organization/{id}/
# operationId: update
# --lead_statuses item shape: {id?: string, label?: string}
export def "organization update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: string
  --Authorization: string # Use your API key as the username and leave the password empty.
  --currency: string # Default currency as a three-letter [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code.
  --enable-unsubscribe-link: oneof<nothing, bool> # Enable the unsubscribe link by default in new email templates.
  --lead-statuses: list # The organization's lead statuses. Provide the full list in the desired order to reorder them. — item shape: {id?: string, label?: string}
  --name: string # The organization's name.
  --require-unsubscribe-link: oneof<nothing, bool> # Require an unsubscribe link in Bulk Emails and Workflows.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organization/($id)/" $qp)
  let body = {currency: $currency, enable_unsubscribe_link: $enable_unsubscribe_link, lead_statuses: $lead_statuses, name: $name, require_unsubscribe_link: $require_unsubscribe_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a membership
#
# POST /membership/
# operationId: create
export def "membership create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  email: string # format: email
  role_id: string # One of `admin`, `superuser`, `user`, or `restricteduser` for the corresponding predefined role, or the ID of a custom [Role](https://developer.close.com/api/resources/roles).
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/membership/")
  let body = {email: $email, role_id: $role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk update memberships
#
# PUT /membership/
# operationId: bulk-update
export def "membership bulk-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --auto-record-calls: string@auto-record-calls-completer
  --default-caller-id: string # ID of the phone number to use as this member's default outbound caller ID. (nullable)
  --hangup-recording-url: string # URL of the audio file used as this member's voicemail drop recording. (nullable)
  --may-workflows-impersonate: oneof<nothing, bool> # Whether Workflows may send emails on this member's behalf.
  --role-id: string # One of `admin`, `superuser`, `user`, or `restricteduser` for the corresponding predefined role, or the ID of a custom [Role](https://developer.close.com/api/resources/roles).
  --track-email-opens: oneof<nothing, bool> # Whether email opens are tracked for emails this member sends.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/membership/")
  let body = {auto_record_calls: $auto_record_calls, default_caller_id: $default_caller_id, hangup_recording_url: $hangup_recording_url, may_workflows_impersonate: $may_workflows_impersonate, role_id: $role_id, track_email_opens: $track_email_opens} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a membership
#
# PUT /membership/{id}/
# operationId: update
export def "membership update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --auto-record-calls: string@auto-record-calls-completer
  --default-caller-id: string # ID of the phone number to use as this member's default outbound caller ID. (nullable)
  --hangup-recording-url: string # URL of the audio file used as this member's voicemail drop recording. (nullable)
  --may-workflows-impersonate: oneof<nothing, bool> # Whether Workflows may send emails on this member's behalf.
  --role-id: string # One of `admin`, `superuser`, `user`, or `restricteduser` for the corresponding predefined role, or the ID of a custom [Role](https://developer.close.com/api/resources/roles).
  --track-email-opens: oneof<nothing, bool> # Whether email opens are tracked for emails this member sends.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/membership/($id)/")
  let body = {auto_record_calls: $auto_record_calls, default_caller_id: $default_caller_id, hangup_recording_url: $hangup_recording_url, may_workflows_impersonate: $may_workflows_impersonate, role_id: $role_id, track_email_opens: $track_email_opens} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get pinned views for a membership
#
# GET /membership/{id}/pinned_views/
# operationId: get-pinned-views
export def "membership-pinned-views get-pinned-views" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/membership/($id)/pinned_views/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update pinned views for a membership
#
# PUT /membership/{id}/pinned_views/
# operationId: update-pinned-views
export def "membership-pinned-views update-pinned-views" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  saved_view_ids: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/membership/($id)/pinned_views/")
  let body = {saved_view_ids: $saved_view_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all the roles defined for your organization
#
# GET /role/
# operationId: list
export def "role list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/role/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new role
#
# POST /role/
# operationId: create
export def "role create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/role/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a single role
#
# GET /role/{id}/
# operationId: get
export def "role get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/role/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update existing role
#
# PUT /role/{id}/
# operationId: update
export def "role update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/role/($id)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a role
#
# DELETE /role/{id}/
# operationId: delete
export def "role delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/role/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Groups for your organization
#
# GET /group/
# operationId: list
export def "group list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<data: table<id: string, members: list, name: string, organization_id: string>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/group/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Group
#
# POST /group/
# operationId: create
export def "group create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
  name: string
]: any -> record<id: string, members: table<user_id: string>, name: string, organization_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/group/" $qp)
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a User to a Group
#
# POST /group/{group_id}/member/
# operationId: add-member
export def "group-member add-member" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
  user_id: string
]: any -> record<user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/group/($group_id)/member/")
  let body = {user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a User from a Group
#
# DELETE /group/{group_id}/member/{user_id}/
# operationId: remove-member
export def "group-member remove-member" [
  group_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/group/($group_id)/member/($user_id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch an individual Group
#
# GET /group/{id}/
# operationId: get
export def "group get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> record<id: string, members: table<user_id: string>, name: string, organization_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/group/($id)/" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Group
#
# PUT /group/{id}/
# operationId: update
export def "group update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to include in the response.
  --Authorization: string # Use your API key as the username and leave the password empty.
  name: string
]: any -> record<id: string, members: table<user_id: string>, name: string, organization_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/group/($id)/" $qp)
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Group
#
# DELETE /group/{id}/
# operationId: delete
export def "group delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Use your API key as the username and leave the password empty.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/group/($id)/")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
