# Auto-generated client for Prime ReportStream v0.2.0-oas3
# Source: https://api.apis.guru/v2/specs/cdcgov.local/prime-data-hub/0.2.0-oas3/openapi.json
# Auth: --token flag or $env.PRIME_REPORTSTREAM_TOKEN

const BASE_URL = "http://cdcgov.local"
const DEFAULT_AUTH = "x-functions-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PRIME_REPORTSTREAM_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-functions-key" => { {headers: {x-functions-key: $token_val}, query: ""} }
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

def base-url-completer [] { ["http://cdcgov.local"] }
def auth-scheme-completer [] { ["x-functions-key" "bearer"] }

# Completers for enum parameters
def option-completer [] { ["CheckConnections" "SendImmediately" "SkipInvalidItems" "SkipSend" "ValidatePayload"] }
def jurisdiction-completer [] { ["County" "National" "State"] }
def format-completer [] { ["CSV"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "reports post" } } | get name | first)
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

# Post a report to the data hub
#
# POST /reports
export def "reports post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client: string # The client's name that matches the client name in metadata (e.g. simple_report)
  --option: string@option-completer # Optional ways to process the request (e.g. ValidatePayload)
  --default: list # Dynamic default values for an element. ':' or %3A is used to seperate element name and value (e.g. processing_mode_code%3AD)
  --route-to: list # A comma speparated list of receiver names. Limit the list of possible receivers to these receivers. (e.g. fl-phd.elr,fl-phd.download)
  --body: record
]: any -> record<destinationCount: int, destinations: table<itemCount: int, organization: string, organization_id: string, sending_at: string, service: string>, errorCount: int, errors: table<detail: string, id: string, scope: string>, id: string, reportItemCount: int, routing: table<destinations: list, reportIndex: int, trackingId: string>, timestamp: string, topic: string, warningCount: int, warnings: table<detail: string, id: string, scope: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-functions-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client" $client "scalar") (serialize-qp "option" $option "scalar") (serialize-qp "default" $default "csv") (serialize-qp "routeTo" $route_to "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/reports" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/csv" $body
}

# The settings for all organizations of the system. Must have admin access.
#
# GET /settings/organizations
export def "settings-organizations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<countyName: string, description: string, jurisdiction: string, meta: record<createdAt: string, createdBy: string, version: float>, name: string, stateCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings/organizations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrived the last modified for all settings of the system. Must have admin access.
#
# HEAD /settings/organizations
export def "settings-organizations head" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings/organizations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an organization (and the associated receivers and senders)
#
# DELETE /settings/organizations/{organizationName}
export def "settings-organizations delete" [
  organization_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countyName: string, description: string, jurisdiction: string, meta: record<createdAt: string, createdBy: string, version: float>, name: string, stateCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_name: $organization_name} | format pattern "/settings/organizations/{organization_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A single organization settings
#
# GET /settings/organizations/{organizationName}
export def "settings-organizations get" [
  organization_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countyName: string, description: string, jurisdiction: string, meta: record<createdAt: string, createdBy: string, version: float>, name: string, stateCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_name: $organization_name} | format pattern "/settings/organizations/{organization_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update the direct settings associated with an organization
#
# PUT /settings/organizations/{organizationName}
export def "settings-organizations put" [
  organization_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --county-name: string # the county name (must match FIPS name) (e.g. Pima)
  description: string # the displayable description of the organization (e.g. Arizona PHD)
  jurisdiction: string@jurisdiction-completer
  --meta: record # The metadata associated with an setting
  name: string # the unique id for the organization (e.g. az-phd)
  --state-code: string # the two letter code for the organization (e.g. AZ)
]: any -> record<countyName: string, description: string, jurisdiction: string, meta: record<createdAt: string, createdBy: string, version: float>, name: string, stateCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_name: $organization_name} | format pattern "/settings/organizations/{organization_name}"))
  let body = {"countyName": $county_name, "description": $description, "jurisdiction": $jurisdiction, "meta": $meta, "name": $name, "stateCode": $state_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# A list of receivers and their current settings
#
# GET /settings/organizations/{organizationName}/receivers
export def "settings-organizations-receivers list" [
  organization_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, jurisdictionalFilters: list<record>, meta: record<createdAt: string, createdBy: string, version: float>, name: string, organizationName: string, timing: record<dailyAt: float, frequency: string>, topic: string, translations: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_name: $organization_name} | format pattern "/settings/organizations/{organization_name}/receivers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a receiver
#
# DELETE /settings/organizations/{organizationName}/receivers/{receiverName}
export def "settings-organizations-receivers delete" [
  organization_name: string
  receiver_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, jurisdictionalFilters: table<doesNotMatch: bool, matchFields: string, matchValues: list>, meta: record<createdAt: string, createdBy: string, version: float>, name: string, organizationName: string, timing: record<dailyAt: float, frequency: string>, topic: string, translations: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_name: $organization_name, receiver_name: $receiver_name} | format pattern "/settings/organizations/{organization_name}/receivers/{receiver_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The settings of a single of receiver
#
# GET /settings/organizations/{organizationName}/receivers/{receiverName}
export def "settings-organizations-receivers get" [
  organization_name: string
  receiver_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, jurisdictionalFilters: table<doesNotMatch: bool, matchFields: string, matchValues: list>, meta: record<createdAt: string, createdBy: string, version: float>, name: string, organizationName: string, timing: record<dailyAt: float, frequency: string>, topic: string, translations: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_name: $organization_name, receiver_name: $receiver_name} | format pattern "/settings/organizations/{organization_name}/receivers/{receiver_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single reciever
#
# PUT /settings/organizations/{organizationName}/receivers/{receiverName}
# --jurisdictionalFilters item shape: {doesNotMatch?: bool, matchFields?: "FACILITY_OR_PATIENT_ADDRESS"|"FACILITY_ADDRESS"|"FACILITY_NAME"|"ABNORMAL_VALUE", matchValues?: list}
# --timing shape: {dailyAt?: float, frequency: "REAL_TIME"|"HOURLY"|"DAILY"}
export def "settings-organizations-receivers put" [
  organization_name: string
  receiver_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # Display ready description of the receiver (e.g. Arizona PHD ELR feed)
  --jurisdictional-filters: list # What items to include in the report. — item shape: {doesNotMatch?: bool, matchFields?: "FACILITY_OR_PATIENT_ADDRESS"|"FACILITY_ADDRESS"|"FACILITY_NAME"|"ABNORMAL_VALUE", matchValues?: list}
  --meta: record # The metadata associated with an setting
  name: string # The unique name for the receiver. Should include the organization name as a prefix. (e.g. az-phd.elr)
  timing: record # When the report is sent if not immediately — shape: {dailyAt?: float, frequency: "REAL_TIME"|"HOURLY"|"DAILY"}
  topic: string # The topic of for this receiver. Must match the supported topics. (e.g. covid-19)
  --translations: list # How the report is translated from the sender. A report can be sent in multiple ways.
]: any -> record<description: string, jurisdictionalFilters: table<doesNotMatch: bool, matchFields: string, matchValues: list>, meta: record<createdAt: string, createdBy: string, version: float>, name: string, organizationName: string, timing: record<dailyAt: float, frequency: string>, topic: string, translations: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_name: $organization_name, receiver_name: $receiver_name} | format pattern "/settings/organizations/{organization_name}/receivers/{receiver_name}"))
  let body = {"description": $description, "jurisdictionalFilters": $jurisdictional_filters, "meta": $meta, "name": $name, "timing": $timing, "topic": $topic, "translations": $translations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# A list of senders
#
# GET /settings/organizations/{organizationName}/senders
export def "settings-organizations-senders list" [
  organization_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, format: string, meta: record<createdAt: string, createdBy: string, version: float>, name: string, organizationName: string, schema: string, topic: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_name: $organization_name} | format pattern "/settings/organizations/{organization_name}/senders"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a sender
#
# DELETE /settings/organizations/{organizationName}/senders/{senderName}
export def "settings-organizations-senders delete" [
  organization_name: string
  sender_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, format: string, meta: record<createdAt: string, createdBy: string, version: float>, name: string, organizationName: string, schema: string, topic: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_name: $organization_name, sender_name: $sender_name} | format pattern "/settings/organizations/{organization_name}/senders/{sender_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The settings of a single of sender
#
# GET /settings/organizations/{organizationName}/senders/{senderName}
export def "settings-organizations-senders get" [
  organization_name: string
  sender_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, format: string, meta: record<createdAt: string, createdBy: string, version: float>, name: string, organizationName: string, schema: string, topic: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_name: $organization_name, sender_name: $sender_name} | format pattern "/settings/organizations/{organization_name}/senders/{sender_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a single sender
#
# PUT /settings/organizations/{organizationName}/senders/{senderName}
export def "settings-organizations-senders put" [
  organization_name: string
  sender_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # Display ready description of the sender
  format: string@format-completer # the payload format
  --meta: record # The metadata associated with an setting
  name: string # Unique name for the senders, includes the orgninzation name (e.g. simple_report.default)
  schema: string # the schema name for this sender (e.g. az-phd-covid-19)
  topic: string # Topic of for this sender. Must match the supported topics. (e.g. covid-19)
]: any -> table<description: string, format: string, meta: record<createdAt: string, createdBy: string, version: float>, name: string, organizationName: string, schema: string, topic: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_name: $organization_name, sender_name: $sender_name} | format pattern "/settings/organizations/{organization_name}/senders/{sender_name}"))
  let body = {"description": $description, "format": $format, "meta": $meta, "name": $name, "schema": $schema, "topic": $topic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
