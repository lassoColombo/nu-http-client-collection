# Auto-generated client for Toggl API v9
# Source: https://engineering.toggl.com/assets/files/api-d56ecbd7b19d9020283019e0581d80ca.json
# Auth: --token flag or $env.TOGGL_API_TOKEN

const BASE_URL = "https://localhost:8080/api/v9"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TOGGL_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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
def base-url-completer [] { ["https://localhost:8080/api/v9"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/plain"] }
def is-unified-completer [] { ["false" "true"] }
def level-completer [] { ["project" "project_user" "task" "workspace" "workspace_user"] }
def mode-completer [] { ["override-all" "override-current" "start-today"] }
def reminder-day-completer [] { ["0" "1" "2" "3" "4" "5" "6"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "audit-logs get-audit-logs" } } | get name | first)
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

# Fetch audit logs.
#
# GET /audit_logs/{organization_id}/{from}/{to}
# operationId: get-audit-logs
export def "audit-logs get-audit-logs" [
  organization_id: int
  from: string
  to: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-export: string@bool-completer # If set to true, returns all audit logs without pagination
  --workspace-id: int # Workspace ID
  --entity-type: string # Entity Type
  --entity-id: int # Entity ID
  --action: string # Action
  --user-id: int # User ID
  --page-size: int # Page Size
  --page-number: int # Page Number
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "export" $qp_export "scalar") (serialize-qp "workspace_id" $workspace_id "scalar") (serialize-qp "entity_type" $entity_type "scalar") (serialize-qp "entity_id" $entity_id "scalar") (serialize-qp "action" $action "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_number" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/audit_logs/($organization_id)/($from)/($to)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# SAML2 Identity Provider URL
#
# GET /auth/saml2/login
# operationId: get-saml2-login-url
export def "auth-saml2-login get-saml2-login-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # User email
  --client: string # Client identification (webapp/toggl-button/client) TODO: add desktop identification
  --state: string # State to be preserved when redirecting to Accounts API
]: nothing -> record<sso_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "client" $client "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/auth/saml2/login" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# SAML2 Identity Provider Callback
#
# POST /auth/saml2/login/{workspace_id}
# operationId: post-saml2-callback
export def "auth-saml2-login post-saml2-callback" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  SAMLResponse: string # SAML2 assertion with authentication response
  --RelayState: string # Encoded string containing client and host which originated the requests
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/auth/saml2/login/($workspace_id)")
  let body = {SAMLResponse: $SAMLResponse, RelayState: $RelayState} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Avatars
#
# POST /avatars
# operationId: post-avatars
export def "avatars post-avatars" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: string # file form data
]: any -> record<avatar_urls: record, fileType: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/avatars")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Avatars
#
# DELETE /avatars
# operationId: delete-avatars
export def "avatars delete-avatars" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/avatars")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UseGravatar
#
# POST /avatars/use_gravatar
# operationId: post-use-gravatar
export def "avatars-use-gravatar post-use-gravatar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<avatar_urls: record, fileType: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/avatars/use_gravatar")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Countries
#
# GET /countries
# operationId: get-countries
export def "countries get-countries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<country_code: string, default_currency_id: int, id: int, name: string, requires_postal_code: bool, vat_applicable: bool, vat_percentage: float, vat_regex: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/countries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CountrySubdivisions
#
# GET /countries/{country_id}/subdivisions
# operationId: get-countries-country_id-subdivisions
export def "countries-subdivisions id-subdivisions" [
  country_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<company_id: int, country_id: int, country_subdivision_id: int, iso_code: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/countries/($country_id)/subdivisions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Currencies
#
# GET /currencies
# operationId: get-currencies
export def "currencies get-currencies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<currency_id: int, iso_code: string, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/currencies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get desktop login token
#
# GET /desktop_login
export def "desktop-login get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/desktop_login")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Post desktop login token
#
# POST /desktop_login_tokens
export def "desktop-login-tokens post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<login_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/desktop_login_tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Feedback
#
# POST /feedback
# operationId: post-unified-feedback
export def "feedback post-unified-feedback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  toggl_version: string # Toggl version.
  date: string # Feedback date.
  details: string # Feedback details.
  --update-channel: string # Update channel.
  --subject: string # Email subject.
  --device-model: string # Device Model.
  --build-number: string # Build Number.
  --operating-system: string # Operating system.
  --latest: string@bool-completer # Latest feedback.
  --files: path # One or more files.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/feedback")
  let body = {toggl_version: $toggl_version, date: $date, details: $details, update_channel: $update_channel, subject: $subject, device_model: $device_model, build_number: $build_number, operating_system: $operating_system, latest: $latest, files: $files} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($files | is-not-empty) { $body | upsert files (open -r $files) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Ical file
#
# GET /ical/workspace_user/{token}
# operationId: get-ical
export def "ical-workspace-user get-ical" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ical/workspace_user/($token)")
  let accept_val = "text/calendar"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all integrations a user has.
#
# GET /integrations/calendar
export def "integrations-calendar get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<auto_track: bool, calendar_integration_id: int, created_at: string, email: string, error_status: string, has_write_scope: bool, origin_product_id: int, provider: string, scopes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/calendar")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all calendars for a given user.
#
# GET /integrations/calendar/calendars
export def "integrations-calendar-calendars list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: string # Max results per page
  --page-token: string # Token for next page. Used in pagination when the number of results exceed 'limit'
  --integration-id: int # Filter calendars by the integration ID
  --selected: string@bool-completer # filter calendars by selected value
]: nothing -> record<calendars: table<auto_track: bool, background_color: string, calendar_id: int, calendar_integration_id: int, created_at: string, default_planned_task_id: int, default_project_id: int, default_workspace_id: int, deleted_at: string, external_id: string, foreground_color: string, name: string, remind_tracking: bool, selected: bool, updated_at: string>, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "integration_id" $integration_id "scalar") (serialize-qp "selected" $selected "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/integrations/calendar/calendars" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all selected calendars for a given user.
#
# GET /integrations/calendar/calendars/selected
export def "integrations-calendar-calendars-selected get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: string # Max results per page
  --page-token: string # Token for next page. Used in pagination when the number of results exceed 'limit'
]: nothing -> record<calendars: table<auto_track: bool, background_color: string, calendar_id: int, calendar_integration_id: int, created_at: string, default_planned_task_id: int, default_project_id: int, default_workspace_id: int, deleted_at: string, external_id: string, foreground_color: string, name: string, remind_tracking: bool, selected: bool, updated_at: string>, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/integrations/calendar/calendars/selected" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all events for the caller user.
#
# GET /integrations/calendar/events
export def "integrations-calendar-events get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # Smallest boundary date to search for calendar events
  --end-date: string # Biggest boundary date to search for calendar events
  --limit: string # Max results per page
  --page-token: string # Token for next page. Used in pagination when the number of results exceed 'limit'
]: nothing -> record<events: table<all_day: bool, calendar_event_id: int, calendar_id: int, color: record, created_at: string, end_time: string, external_id: string, html_link: string, ical_uid: string, internal_ref_id: int, internal_ref_product_id: int, internal_ref_type: string, meeting_link: string, provider: string, start_time: string, title: string, updated: string, updated_at: string>, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/integrations/calendar/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details suggestion for given events.
#
# POST /integrations/calendar/events/details-suggestion
export def "integrations-calendar-events-details-suggestion post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --event-ids: list
  --workspace-id: int
]: any -> record<suggestions: table<event_id: int, suggestion: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/calendar/events/details-suggestion")
  let body = {event_ids: $event_ids, workspace_id: $workspace_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update all events from selected calendars for a user.
#
# POST /integrations/calendar/events/update
export def "integrations-calendar-events-update post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fetched_events: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/calendar/events/update")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details suggestion for a given event.
#
# GET /integrations/calendar/events/{event_id}/details-suggestion
export def "integrations-calendar-events-details-suggestion get" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<accuracy: float, billable: bool, description_match: bool, last_seen: string, project_active: bool, project_color: string, project_id: int, project_name: string, tag_ids: list<int>, tags: list<string>, task_id: int, task_name: string, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integrations/calendar/events/($event_id)/details-suggestion")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get URL for setting up a calendar integration with given provider.
#
# GET /integrations/calendar/setup
export def "integrations-calendar-setup get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --provider: string # Calendar service provider which the calendars will be retrieved
  --return-to: string # Page to which the user will be redirected after authenticating
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "provider" $provider "scalar") (serialize-qp "return_to" $return_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/integrations/calendar/setup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a given integration.
#
# PUT /integrations/calendar/{integration_id}
export def "integrations-calendar put" [
  integration_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integrations/calendar/($integration_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a given integration.
#
# DELETE /integrations/calendar/{integration_id}
export def "integrations-calendar delete" [
  integration_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integrations/calendar/($integration_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all calendars for a given integration.
#
# GET /integrations/calendar/{integration_id}/calendars
export def "integrations-calendar-calendars get" [
  integration_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Max results per page
  --selected: string@bool-completer # if we should get the selected or not calendars, or all calendars, in case of omission
  --page-token: string # Token for next page. Used in pagination when the number of results exceed 'limit'
]: nothing -> record<calendars: table<auto_track: bool, background_color: string, calendar_id: int, calendar_integration_id: int, created_at: string, default_planned_task_id: int, default_project_id: int, default_workspace_id: int, deleted_at: string, external_id: string, foreground_color: string, name: string, remind_tracking: bool, selected: bool, updated_at: string>, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "selected" $selected "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/integrations/calendar/($integration_id)/calendars" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates calendar data according to provider API.
#
# POST /integrations/calendar/{integration_id}/calendars/update
export def "integrations-calendar-calendars-update post" [
  integration_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fetched_calendars: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integrations/calendar/($integration_id)/calendars/update")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sets whether a calendar is or not selected by the user.
#
# PATCH /integrations/calendar/{integration_id}/calendars/{calendar_id}
export def "integrations-calendar-calendars patch" [
  integration_id: int
  calendar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --default-planned-task-id: int
  --default-project-id: int
  --default-workspace-id: int
  --remind-tracking: string@bool-completer # The following fields are deprecated but we need to keep them for backward compatibility with previous versions of mobile apps
  --selected: string@bool-completer
]: any -> table<auto_track: bool, background_color: string, calendar_id: int, calendar_integration_id: int, created_at: string, default_planned_task_id: int, default_project_id: int, default_workspace_id: int, deleted_at: string, external_id: string, foreground_color: string, name: string, remind_tracking: bool, selected: bool, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integrations/calendar/($integration_id)/calendars/($calendar_id)")
  let body = {default_planned_task_id: $default_planned_task_id, default_project_id: $default_project_id, default_workspace_id: $default_workspace_id, remind_tracking: $remind_tracking, selected: $selected} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all attendees for a given calendar event.
#
# GET /integrations/calendar/{integration_id}/calendars/{calendar_id}/events/{event_id}/attendees
export def "integrations-calendar-calendars-events-attendees get" [
  integration_id: int
  calendar_id: int
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<email: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integrations/calendar/($integration_id)/calendars/($calendar_id)/events/($event_id)/attendees")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# (DEPRECATED) Get all events for a given calendar in a given integration.
#
# GET /integrations/calendar/{integration_id}/calendars/{id_calendar}/events
export def "integrations-calendar-calendars-events get" [
  integration_id: int
  id_calendar: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # Smallest boundary date to search for calendar events
  --end-date: string # Biggest boundary date to search for calendar events
  --limit: string # Max results per page
  --page-token: string # Token for next page. Used in pagination when the number of results exceed 'limit'
]: nothing -> record<events: table<all_day: bool, calendar_event_id: int, calendar_id: int, color: record, created_at: string, end_time: string, external_id: string, html_link: string, ical_uid: string, internal_ref_id: int, internal_ref_product_id: int, internal_ref_type: string, meeting_link: string, provider: string, start_time: string, title: string, updated: string, updated_at: string>, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/integrations/calendar/($integration_id)/calendars/($id_calendar)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an invitation
#
# GET /invitations/{invitation_code}
# operationId: get-invitations
export def "invitations get-invitations" [
  invitation_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<accounts_signup_url: string, code: string, email: string, organization_id: int, organization_name: string, sender_email: string, sender_name: string, sso: bool, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invitations/($invitation_code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get keys
#
# GET /keys
# operationId: get-keys
export def "keys get-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Me
#
# GET /me
# operationId: get-me
export def "me get-me" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with-related-data: string@bool-completer # Retrieve user related data (clients, projects, tasks, tags, workspaces, time entries, etc.)
]: nothing -> record<2fa_enabled: bool, api_token: string, at: string, authorization_updated_at: string, beginning_of_week: int, clients: table<archived: bool, at: string, creator_id: int, external_reference: string, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, name: string, notes: string, permissions: list, total_count: int, wid: int>, country_id: int, created_at: string, default_workspace_id: int, email: string, fullname: string, has_password: bool, id: int, image_url: string, intercom_hash: string, oauth_providers: list<string>, openid_email: string, openid_enabled: bool, options: record, projects: table<active: bool, actual_hours: int, actual_seconds: int, at: string, auto_estimates: bool, billable: bool, can_track_time: bool, cid: int, client_id: int, client_name: string, color: string, created_at: string, currency: string, current_period: record, end_date: string, estimated_hours: int, estimated_seconds: int, external_reference: string, fixed_fee: float, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, is_private: bool, name: string, permissions: list, pinned: bool, rate: float, rate_last_updated: string, recurring: bool, recurring_parameters: list, start_date: string, status: record, template: bool, template_id: int, total_count: int, wid: int, workspace_id: int>, tags: table<at: string, creator_id: int, deleted_at: string, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, name: string, permissions: list, workspace_id: int>, tasks: table<active: bool, at: string, avatar_url: string, client_id: int, client_name: string, estimated_seconds: int, external_reference: string, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, name: string, permissions: list, project_billable: bool, project_color: string, project_id: int, project_is_private: bool, project_name: string, rate: float, rate_last_updated: string, recurring: bool, toggl_accounts_id: string, tracked_seconds: int, user_id: int, user_name: string, workspace_id: int>, time_entries: table<at: string, billable: bool, client_id: int, client_name: string, description: string, duration: int, duronly: bool, expense_ids: list, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, permissions: list, pid: int, project_active: bool, project_billable: bool, project_color: string, project_id: int, project_name: string, shared_with: list, start: string, stop: string, tag_ids: list, tags: list, task_id: int, task_name: string, tid: int, uid: int, user_avatar_url: string, user_id: int, user_name: string, wid: int, workspace_id: int>, timezone: string, updated_at: string, workspaces: table<admin: bool, api_token: string, at: string, business_ws: bool, csv_upload: record, default_currency: string, default_hourly_rate: float, disable_approvals: bool, disable_expenses: bool, disable_timesheet_view: bool, hide_start_end_times: bool, ical_enabled: bool, ical_url: string, id: int, last_modified: string, limit_public_project_data: bool, logo_url: string, max_data_retention_days: record, name: string, only_admins_may_create_projects: bool, only_admins_may_create_tags: bool, only_admins_see_team_dashboard: bool, organization_id: int, permissions: list, premium: bool, projects_billable_by_default: bool, projects_enforce_billable: bool, projects_private_by_default: bool, rate_last_updated: string, reports_collapse: bool, role: string, rounding: int, rounding_minutes: int, subscription: record, suspended_at: string, te_constraints: record, working_hours_in_minutes: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_related_data" $with_related_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Me
#
# PUT /me
# operationId: put-me
export def "me put-me" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --beginning-of-week: int # User's first day of the week. Sunday: 0, Monday:1, etc.
  --country-id: int # User's country ID
  --current-password: string # User's current password (used to change the current password)
  --default-workspace-id: int # User's default workspace ID
  --email: string # User's email address (format: email)
  --fullname: string # User's full name
  --password: string # User's new password (current one must also be provided)
  --timezone: string # User's timezone
]: any -> record<2fa_enabled: bool, api_token: string, at: string, beginning_of_week: int, country_id: int, created_at: string, default_workspace_id: int, email: string, fullname: string, has_password: bool, id: int, image_url: string, openid_email: string, openid_enabled: bool, options: record, timezone: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let body = {beginning_of_week: $beginning_of_week, country_id: $country_id, current_password: $current_password, default_workspace_id: $default_workspace_id, email: $email, fullname: $fullname, password: $password, timezone: $timezone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# AcceptTOS
#
# POST /me/accept_tos
# operationId: post-me-accept-tos
export def "me-accept-tos post-me-accept-tos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/accept_tos")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Clients
#
# GET /me/clients
# operationId: get-clients
export def "me-clients get-clients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: int # Retrieve clients created/modified/deleted since this date using UNIX timestamp.
]: any -> table<archived: bool, at: string, creator_id: int, external_reference: string, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, name: string, notes: string, permissions: list<string>, total_count: int, wid: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/clients")
  let body = {since: $since} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# CloseAccount
#
# POST /me/close_account
# operationId: post-close-account
export def "me-close-account post-close-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/close_account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable product emails
#
# POST /me/disable_product_emails/{disable_code}
# operationId: post-me-disable-product-emails
export def "me-disable-product-emails post-me-disable-product-emails" [
  disable_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/me/disable_product_emails/($disable_code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable weekly report
#
# POST /me/disable_weekly_report/{weekly_report_code}
# operationId: post-me-disable-weekly-report
export def "me-disable-weekly-report post-me-disable-weekly-report" [
  weekly_report_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/me/disable_weekly_report/($weekly_report_code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Confirm SSO enabling for user account
#
# POST /me/enable_sso
# operationId: post-enable-sso
export def "me-enable-sso post-enable-sso" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmation-code: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/enable_sso")
  let body = {confirmation_code: $confirmation_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of objects to be downloaded
#
# GET /me/export
# operationId: get-me-export
export def "me-export get-me-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<error_message: string, state: string, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Post an object which data to be downloaded
#
# POST /me/export
# operationId: post-me-export
export def "me-export post-me-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --profile: string@bool-completer
  --timeline: string@bool-completer
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/export")
  let body = {profile: $profile, timeline: $timeline} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the zip file with download requests
#
# GET /me/export/data/{uuid}.zip
# operationId: get-me-export-data-uuid-zip
export def "me-export-data get-me-export-data-uuid-zip" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/me/export/data/($uuid).zip")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of favorites
#
# GET /me/favorites
# operationId: get-favorites
export def "me-favorites get-favorites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: int # Retrieve favorites created/deleted since this date using UNIX timestamp.
]: any -> table<billable: bool, client_name: string, created_at: string, deleted_at: string, description: string, favorite_id: int, permissions: list<string>, project_active: bool, project_billable: bool, project_color: string, project_id: int, project_name: string, project_private: bool, public: bool, rank: int, tag_ids: list<int>, tags: list<string>, task_id: int, task_name: string, user_id: int, was_public_at: string, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/favorites")
  let body = {since: $since} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update an array of favorites
#
# PUT /me/favorites
# operationId: update-favorite
export def "me-favorites update-favorite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --meta: string@bool-completer # Should the response contain data for meta entities
  --billable: string@bool-completer # e.g. true
  --description: string # e.g. Very often used TE
  --project-id: int # e.g. 222222
  --tag-ids: list # e.g. [100]
  --task-id: int # e.g. 333333
  --workspace-id: int # e.g. 111111
]: any -> record<billable: bool, client_name: string, created_at: string, deleted_at: string, description: string, favorite_id: int, permissions: list<string>, project_active: bool, project_billable: bool, project_color: string, project_id: int, project_name: string, project_private: bool, public: bool, rank: int, tag_ids: list<int>, tags: list<string>, task_id: int, task_name: string, user_id: int, was_public_at: string, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "meta" $meta "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/favorites" $qp)
  let body = {billable: $billable, description: $description, project_id: $project_id, tag_ids: $tag_ids, task_id: $task_id, workspace_id: $workspace_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a favorite
#
# POST /me/favorites
# operationId: create-favorite
export def "me-favorites create-favorite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --meta: string@bool-completer # Should the response contain data for meta entities
  --billable: string@bool-completer # e.g. true
  --description: string # e.g. Very often used TE
  --project-id: int # e.g. 222222
  --tag-ids: list # e.g. [100]
  --task-id: int # e.g. 333333
  --workspace-id: int # e.g. 111111
]: any -> record<billable: bool, client_name: string, created_at: string, deleted_at: string, description: string, favorite_id: int, permissions: list<string>, project_active: bool, project_billable: bool, project_color: string, project_id: int, project_name: string, project_private: bool, public: bool, rank: int, tag_ids: list<int>, tags: list<string>, task_id: int, task_name: string, user_id: int, was_public_at: string, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "meta" $meta "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/favorites" $qp)
  let body = {billable: $billable, description: $description, project_id: $project_id, tag_ids: $tag_ids, task_id: $task_id, workspace_id: $workspace_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generates and returns a list of suggested favorites.
#
# POST /me/favorites/suggestions
# operationId: post-favorites-suggestions
export def "me-favorites-suggestions post-favorites-suggestions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<billable: bool, client_name: string, created_at: string, deleted_at: string, description: string, favorite_id: int, permissions: list<string>, project_active: bool, project_billable: bool, project_color: string, project_id: int, project_name: string, project_private: bool, public: bool, rank: int, tag_ids: list<int>, tags: list<string>, task_id: int, task_name: string, user_id: int, was_public_at: string, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/favorites/suggestions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a given favorite
#
# DELETE /me/favorites/{favorite_id}
# operationId: delete-favorite
export def "me-favorites delete-favorite" [
  favorite_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/me/favorites/($favorite_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Features
#
# GET /me/features
# operationId: get-me-features
export def "me-features get-me-features" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<features: list<record>, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/features")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Flags
#
# GET /me/flags
# operationId: get-me-flags
export def "me-flags get-me-flags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/flags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Flags
#
# POST /me/flags
# operationId: post-me-flags
export def "me-flags post-me-flags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/flags")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Local user ID
#
# GET /me/id
# operationId: get-me-id
export def "me-id get-me-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> float {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/id")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# User's last known location
#
# GET /me/location
# operationId: get-me-location
export def "me-location get-me-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<city: string, city_lat_long: string, country_code: string, country_name: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/location")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Logged
#
# GET /me/logged
export def "me-logged get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/logged")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Organizations that a user is part of
#
# GET /me/organizations
# operationId: get-organizations
export def "me-organizations get-organizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<admin: bool, at: string, created_at: string, id: int, is_multi_workspace_enabled: bool, is_unified: bool, max_data_retention_days: record, max_workspaces: int, name: string, owner: bool, permissions: list<string>, pricing_plan_enterprise: bool, pricing_plan_id: int, pricing_plan_name: string, subscription: record<billing_period_months: int, cancel_date: string, created_at: string, currency: string, current_period_ends_at: string, current_period_starts_at: string, enterprise: bool, plan: record, plan_name: string, seats: int, state: record, trial: record>, suspended_at: string, trial_info: record<can_have_trial: bool, last_pricing_plan_id: int, next_payment_date: string, trial: bool, trial_available: bool, trial_end_date: string, trial_plan_id: int>, user_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/organizations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Preferences for the current user
#
# GET /me/preferences
# operationId: get-preferences
export def "me-preferences get-preferences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<activity_timeline_display_activity: bool, activity_timeline_grouping_interval: string, activity_timeline_grouping_method: string, activity_timeline_recording_level: string, activity_timeline_sync_events: bool, alpha_features: table<alpha_feature_id: int, code: string, deleted_at: string, description: string, enabled: bool, product_id: int>, analyticsAdvancedFilters: bool, auto_tracker_delay_enabled: bool, auto_tracker_delay_in_seconds: int, auto_tracker_stop_on_no_rule_match_enabled: bool, automatic_tagging: bool, autotracking_enabled: bool, beginningOfWeek: int, calendar_snap_duration: string, calendar_snap_initial_location: string, calendar_visible_hours_end: int, calendar_visible_hours_start: int, calendar_zoom_level: string, cell_swipe_actions_enabled: bool, charts_view_type: string, collapseDetailedReportEntries: bool, collapseTimeEntries: bool, dashboards_view_type: string, date_format: string, decimal_separator: record, default_project_id: int, default_project_task: record<project_id: int, task_id: int, workspace_id: int>, default_task_id: int, displayDensity: string, distinctRates: string, duration_format: string, duration_format_on_timer_duration_field: bool, edit_popup_integration_timer: bool, extension_send_error_reports: bool, extension_send_usage_statistics: bool, firstSeenBusinessPromo: int, focus_app_on_time_entry_started: bool, focus_app_on_time_entry_stopped: bool, haptic_feedback_enabled: bool, hide_keyboard_shortcut: bool, hide_sidebar_right: bool, idle_detection_enabled: bool, idle_detection_interval_in_minutes: int, inactivity_behavior: string, ios_is_goals_view_shown: bool, is_goals_view_expanded: bool, is_goals_view_shown: bool, is_summary_total_view_visible: bool, keep_mini_timer_on_top: bool, keep_window_on_top: bool, keyboard_increment_timer_page: int, keyboard_shortcuts_enabled: bool, keyboard_shortcuts_share_time_entries: bool, mac_is_goals_view_shown: bool, macos_auto_tracking_rules: table<id: string, keyword: string, project_id: int, task_id: int, workspace_id: int>, macos_show_hide_toggl_keyboard_shortcut: record<key: int, modifiers: int>, macos_stop_continue_keyboard_shortcut: record<key: int, modifiers: int>, manualEntryMode: string, manualMode: bool, manualModeOverlaySeen: bool, modify_on_start_time_change: string, offlineMode: string, pg_time_zone_name: string, pomodoro_auto_start_break: bool, pomodoro_auto_start_focus: bool, pomodoro_break_interval_in_minutes: int, pomodoro_break_project: record<id: int, workspace_id: int>, pomodoro_break_project_id: int, pomodoro_break_start_sound_enabled: bool, pomodoro_break_tag: record<id: int, workspace_id: int>, pomodoro_break_tag_id: int, pomodoro_countdown_timer: bool, pomodoro_enabled: bool, pomodoro_focus_interval_in_minutes: int, pomodoro_focus_sound: string, pomodoro_global_sound_enabled: bool, pomodoro_interval_end_sound: bool, pomodoro_interval_end_volume: int, pomodoro_longer_break_duration_in_minutes: int, pomodoro_prevent_screen_lock: bool, pomodoro_rounds_before_longer_break: int, pomodoro_session_start_sound_enabled: bool, pomodoro_show_notifications: bool, pomodoro_stop_timer_at_interval_end: bool, pomodoro_track_breaks_as_time_entries: bool, projectDashboardActivityMode: string, project_shortcut_enabled: bool, record_timeline: bool, remember_last_project: string, reminder_days: string, reminder_enabled: bool, reminder_interval_in_minutes: int, reminder_period: string, reminder_snoozing_in_minutes: int, reportRounding: bool, reportRoundingDirection: string, reportRoundingStepInMinutes: int, reportsHideWeekends: bool, run_app_on_startup: bool, running_entry_warning: string, running_timer_notification_enabled: bool, seenFollowModal: bool, seenFooterPopup: bool, seenProjectDashboardOverlay: bool, seenTogglButtonModal: bool, send_added_to_project_notification: bool, send_daily_project_invites: bool, send_product_emails: bool, send_product_release_notification: bool, send_system_message_notification: bool, send_timer_notifications: bool, send_weekly_report: bool, sharing_shortcut_enabled: bool, showTimeInTitle: bool, show_all_entries: bool, show_changelog: bool, show_description_in_menu_bar: bool, show_dock_icon: bool, show_events_in_calendar: bool, show_project_in_menu_bar: bool, show_qr_scanner: bool, show_seconds_in_menu_bar: bool, show_timeline_in_day_view: bool, show_timer_in_menu_bar: bool, show_today_total_in_menu_bar: bool, show_total_billable_hours: bool, show_weekend_on_timer_page: bool, show_workouts_in_calendar: bool, sleep_behaviour: string, smart_alerts_option: string, snowballReportRounding: string, stack_times_on_manual_mode_after: string, start_automatically: bool, start_shortcut_mode: string, stop_at_specific_time: bool, stop_automatically: bool, stop_entry_on_shutdown: bool, stop_specified_time: string, stopped_timer_notification_enabled: bool, suggestions_enabled: bool, summaryReportAmounts: string, summaryReportDistinctRates: bool, summaryReportGrouping: string, summaryReportSortAsc: bool, summaryReportSortField: string, summaryReportSubGrouping: string, summary_total_mode: string, tags_shortcut_enabled: bool, time_entry_display_mode: string, time_entry_ghost_suggestions_enabled: bool, time_entry_invitations_notification_enabled: bool, time_entry_start_stop_input_mode: string, timeofday_format: string, timerView: string, timerViewMobile: string, toSAcceptNeeded: bool, use_mini_timer: bool, visibleFooter: string, webTimeEntryStarted: bool, webTimeEntryStopped: bool, weeklyReportGrouping: string, weeklyReportValueToShow: string, windows_auto_tracking_rules: table<billable: bool, description: string, enabled: bool, id: string, parameters: record, project_id: int, skip_when_timer_is_running: bool, start_without_confirmation: bool, tag_ids: list, task_id: int, type: int, workspace_id: int>, windows_show_hide_toggl_keyboard_shortcut: record<key: int, modifiers: int>, windows_stop_continue_keyboard_shortcut: record<key: int, modifiers: int>, windows_stop_start_keyboard_shortcut: record<key: int, modifiers: int>, windows_theme: string, workout_default_project: record<id: int, workspace_id: int>, workout_default_project_id: int, workout_default_tag: record<id: int, workspace_id: int>, workout_default_tag_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/preferences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the preferences for the current user
#
# POST /me/preferences
# operationId: post-preferences
# --alpha_features item shape: {alpha_feature_id?: int, code?: string, deleted_at?: string, description?: string, enabled?: bool, product_id?: int}
# --default_project_task shape: {project_id?: int, task_id?: int, workspace_id?: int}
# --macos_auto_tracking_rules item shape: {id?: string, keyword?: string, project_id?: int, task_id?: int, workspace_id?: int}
# --macos_show_hide_toggl_keyboard_shortcut shape: {key?: int, modifiers?: int}
# --macos_stop_continue_keyboard_shortcut shape: {key?: int, modifiers?: int}
# --pomodoro_break_project shape: {id?: int, workspace_id?: int}
# --pomodoro_break_tag shape: {id?: int, workspace_id?: int}
# --windows_auto_tracking_rules item shape: {billable?: bool, description?: string, enabled?: bool, id?: string, parameters?: record, project_id?: int, skip_when_timer_is_running?: bool, start_without_confirmation?: bool, tag_ids?: list, task_id?: int, type?: int, workspace_id?: int}
# --windows_show_hide_toggl_keyboard_shortcut shape: {key?: int, modifiers?: int}
# --windows_stop_continue_keyboard_shortcut shape: {key?: int, modifiers?: int}
# --windows_stop_start_keyboard_shortcut shape: {key?: int, modifiers?: int}
# --workout_default_project shape: {id?: int, workspace_id?: int}
# --workout_default_tag shape: {id?: int, workspace_id?: int}
export def "me-preferences post-preferences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --activity-timeline-display-activity: string@bool-completer
  --activity-timeline-grouping-interval: string
  --activity-timeline-grouping-method: string
  --activity-timeline-recording-level: string
  --activity-timeline-sync-events: string@bool-completer
  --alpha-features: list # will be omitted if empty — item shape: {alpha_feature_id?: int, code?: string, deleted_at?: string, description?: string, enabled?: bool, product_id?: int}
  --analyticsAdvancedFilters: string@bool-completer # will be omitted if empty
  --auto-tracker-delay-enabled: string@bool-completer
  --auto-tracker-delay-in-seconds: int
  --auto-tracker-stop-on-no-rule-match-enabled: string@bool-completer
  --automatic-tagging: string@bool-completer
  --autotracking-enabled: string@bool-completer
  --beginningOfWeek: int # will be omitted if empty
  --calendar-snap-duration: string
  --calendar-snap-initial-location: string
  --calendar-visible-hours-end: int
  --calendar-visible-hours-start: int
  --calendar-zoom-level: string
  --cell-swipe-actions-enabled: string@bool-completer
  --charts-view-type: string
  --collapseDetailedReportEntries: string@bool-completer # will be omitted if empty
  --collapseTimeEntries: string@bool-completer # will be omitted if empty
  --dashboards-view-type: string
  --date-format: string
  --decimal-separator: any # will be omitted if empty
  --default-project-id: int
  --default-project-task: record # shape: {project_id?: int, task_id?: int, workspace_id?: int}
  --default-task-id: int
  --displayDensity: string # will be omitted if empty
  --distinctRates: string # will be omitted if empty
  --duration-format: string
  --duration-format-on-timer-duration-field: string@bool-completer
  --edit-popup-integration-timer: string@bool-completer
  --extension-send-error-reports: string@bool-completer
  --extension-send-usage-statistics: string@bool-completer
  --firstSeenBusinessPromo: int # will be omitted if empty
  --focus-app-on-time-entry-started: string@bool-completer
  --focus-app-on-time-entry-stopped: string@bool-completer
  --haptic-feedback-enabled: string@bool-completer
  --hide-keyboard-shortcut: string@bool-completer # will be omitted if empty
  --hide-sidebar-right: string@bool-completer
  --idle-detection-enabled: string@bool-completer
  --idle-detection-interval-in-minutes: int
  --inactivity-behavior: string
  --ios-is-goals-view-shown: string@bool-completer
  --is-goals-view-expanded: string@bool-completer
  --is-goals-view-shown: string@bool-completer
  --is-summary-total-view-visible: string@bool-completer
  --keep-mini-timer-on-top: string@bool-completer
  --keep-window-on-top: string@bool-completer
  --keyboard-increment-timer-page: int
  --keyboard-shortcuts-enabled: string@bool-completer # will be omitted if empty
  --keyboard-shortcuts-share-time-entries: string@bool-completer
  --mac-is-goals-view-shown: string@bool-completer
  --macos-auto-tracking-rules: list # item shape: {id?: string, keyword?: string, project_id?: int, task_id?: int, workspace_id?: int}
  --macos-show-hide-toggl-keyboard-shortcut: record # shape: {key?: int, modifiers?: int}
  --macos-stop-continue-keyboard-shortcut: record # shape: {key?: int, modifiers?: int}
  --manualEntryMode: string # will be omitted if empty
  --manualMode: string@bool-completer # will be omitted if empty
  --manualModeOverlaySeen: string@bool-completer # will be omitted if empty
  --modify-on-start-time-change: string
  --offlineMode: string # will be omitted if empty
  --pg-time-zone-name: string
  --pomodoro-auto-start-break: string@bool-completer
  --pomodoro-auto-start-focus: string@bool-completer
  --pomodoro-break-interval-in-minutes: int
  --pomodoro-break-project: record # shape: {id?: int, workspace_id?: int}
  --pomodoro-break-project-id: int
  --pomodoro-break-start-sound-enabled: string@bool-completer
  --pomodoro-break-tag: record # shape: {id?: int, workspace_id?: int}
  --pomodoro-break-tag-id: int
  --pomodoro-countdown-timer: string@bool-completer
  --pomodoro-enabled: string@bool-completer
  --pomodoro-focus-interval-in-minutes: int
  --pomodoro-focus-sound: string
  --pomodoro-global-sound-enabled: string@bool-completer
  --pomodoro-interval-end-sound: string@bool-completer
  --pomodoro-interval-end-volume: int
  --pomodoro-longer-break-duration-in-minutes: int
  --pomodoro-prevent-screen-lock: string@bool-completer
  --pomodoro-rounds-before-longer-break: int
  --pomodoro-session-start-sound-enabled: string@bool-completer
  --pomodoro-show-notifications: string@bool-completer
  --pomodoro-stop-timer-at-interval-end: string@bool-completer
  --pomodoro-track-breaks-as-time-entries: string@bool-completer
  --projectDashboardActivityMode: string # will be omitted if empty
  --project-shortcut-enabled: string@bool-completer
  --record-timeline: string@bool-completer
  --remember-last-project: string
  --reminder-days: string
  --reminder-enabled: string@bool-completer
  --reminder-interval-in-minutes: int
  --reminder-period: string
  --reminder-snoozing-in-minutes: int
  --reportRounding: string@bool-completer # will be omitted if empty
  --reportRoundingDirection: string # will be omitted if empty
  --reportRoundingStepInMinutes: int # will be omitted if empty
  --reportsHideWeekends: string@bool-completer # will be omitted if empty
  --run-app-on-startup: string@bool-completer
  --running-entry-warning: string
  --running-timer-notification-enabled: string@bool-completer
  --seenFollowModal: string@bool-completer # will be omitted if empty
  --seenFooterPopup: string@bool-completer # will be omitted if empty
  --seenProjectDashboardOverlay: string@bool-completer # will be omitted if empty
  --seenTogglButtonModal: string@bool-completer # will be omitted if empty
  --send-added-to-project-notification: string@bool-completer
  --send-daily-project-invites: string@bool-completer
  --send-product-emails: string@bool-completer
  --send-product-release-notification: string@bool-completer
  --send-system-message-notification: string@bool-completer
  --send-timer-notifications: string@bool-completer
  --send-weekly-report: string@bool-completer
  --sharing-shortcut-enabled: string@bool-completer
  --showTimeInTitle: string@bool-completer # will be omitted if empty
  --show-all-entries: string@bool-completer
  --show-changelog: string@bool-completer
  --show-description-in-menu-bar: string@bool-completer
  --show-dock-icon: string@bool-completer
  --show-events-in-calendar: string@bool-completer
  --show-project-in-menu-bar: string@bool-completer
  --show-qr-scanner: string@bool-completer
  --show-seconds-in-menu-bar: string@bool-completer
  --show-timeline-in-day-view: string@bool-completer # will be omitted if empty
  --show-timer-in-menu-bar: string@bool-completer
  --show-today-total-in-menu-bar: string@bool-completer
  --show-total-billable-hours: string@bool-completer # will be omitted if empty
  --show-weekend-on-timer-page: string@bool-completer # will be omitted if empty
  --show-workouts-in-calendar: string@bool-completer
  --sleep-behaviour: string
  --smart-alerts-option: string
  --snowballReportRounding: string # will be omitted if empty
  --stack-times-on-manual-mode-after: string
  --start-automatically: string@bool-completer
  --start-shortcut-mode: string
  --stop-at-specific-time: string@bool-completer
  --stop-automatically: string@bool-completer
  --stop-entry-on-shutdown: string@bool-completer
  --stop-specified-time: string
  --stopped-timer-notification-enabled: string@bool-completer
  --suggestions-enabled: string@bool-completer
  --summaryReportAmounts: string # will be omitted if empty
  --summaryReportDistinctRates: string@bool-completer # will be omitted if empty
  --summaryReportGrouping: string # will be omitted if empty
  --summaryReportSortAsc: string@bool-completer # will be omitted if empty
  --summaryReportSortField: string # will be omitted if empty
  --summaryReportSubGrouping: string # will be omitted if empty
  --summary-total-mode: string
  --tags-shortcut-enabled: string@bool-completer
  --time-entry-display-mode: string
  --time-entry-ghost-suggestions-enabled: string@bool-completer
  --time-entry-invitations-notification-enabled: string@bool-completer
  --time-entry-start-stop-input-mode: string
  --timeofday-format: string
  --timerView: string # will be omitted if empty
  --timerViewMobile: string # will be omitted if empty
  --toSAcceptNeeded: string@bool-completer # ToSAcceptNeeded represents the trigger for new ToS accept dialog
  --use-mini-timer: string@bool-completer
  --visibleFooter: string # will be omitted if empty
  --webTimeEntryStarted: string@bool-completer # will be omitted if empty
  --webTimeEntryStopped: string@bool-completer # will be omitted if empty
  --weeklyReportGrouping: string # will be omitted if empty
  --weeklyReportValueToShow: string # will be omitted if empty
  --windows-auto-tracking-rules: list # item shape: {billable?: bool, description?: string, enabled?: bool, id?: string, parameters?: record, project_id?: int, skip_when_timer_is_running?: bool, start_without_confirmation?: bool, tag_ids?: list, task_id?: int, type?: int, workspace_id?: int}
  --windows-show-hide-toggl-keyboard-shortcut: record # shape: {key?: int, modifiers?: int}
  --windows-stop-continue-keyboard-shortcut: record # shape: {key?: int, modifiers?: int}
  --windows-stop-start-keyboard-shortcut: record # shape: {key?: int, modifiers?: int}
  --windows-theme: string
  --workout-default-project: record # shape: {id?: int, workspace_id?: int}
  --workout-default-project-id: int
  --workout-default-tag: record # shape: {id?: int, workspace_id?: int}
  --workout-default-tag-id: int
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/preferences")
  let body = {activity_timeline_display_activity: $activity_timeline_display_activity, activity_timeline_grouping_interval: $activity_timeline_grouping_interval, activity_timeline_grouping_method: $activity_timeline_grouping_method, activity_timeline_recording_level: $activity_timeline_recording_level, activity_timeline_sync_events: $activity_timeline_sync_events, alpha_features: $alpha_features, analyticsAdvancedFilters: $analyticsAdvancedFilters, auto_tracker_delay_enabled: $auto_tracker_delay_enabled, auto_tracker_delay_in_seconds: $auto_tracker_delay_in_seconds, auto_tracker_stop_on_no_rule_match_enabled: $auto_tracker_stop_on_no_rule_match_enabled, automatic_tagging: $automatic_tagging, autotracking_enabled: $autotracking_enabled, beginningOfWeek: $beginningOfWeek, calendar_snap_duration: $calendar_snap_duration, calendar_snap_initial_location: $calendar_snap_initial_location, calendar_visible_hours_end: $calendar_visible_hours_end, calendar_visible_hours_start: $calendar_visible_hours_start, calendar_zoom_level: $calendar_zoom_level, cell_swipe_actions_enabled: $cell_swipe_actions_enabled, charts_view_type: $charts_view_type, collapseDetailedReportEntries: $collapseDetailedReportEntries, collapseTimeEntries: $collapseTimeEntries, dashboards_view_type: $dashboards_view_type, date_format: $date_format, decimal_separator: $decimal_separator, default_project_id: $default_project_id, default_project_task: $default_project_task, default_task_id: $default_task_id, displayDensity: $displayDensity, distinctRates: $distinctRates, duration_format: $duration_format, duration_format_on_timer_duration_field: $duration_format_on_timer_duration_field, edit_popup_integration_timer: $edit_popup_integration_timer, extension_send_error_reports: $extension_send_error_reports, extension_send_usage_statistics: $extension_send_usage_statistics, firstSeenBusinessPromo: $firstSeenBusinessPromo, focus_app_on_time_entry_started: $focus_app_on_time_entry_started, focus_app_on_time_entry_stopped: $focus_app_on_time_entry_stopped, haptic_feedback_enabled: $haptic_feedback_enabled, hide_keyboard_shortcut: $hide_keyboard_shortcut, hide_sidebar_right: $hide_sidebar_right, idle_detection_enabled: $idle_detection_enabled, idle_detection_interval_in_minutes: $idle_detection_interval_in_minutes, inactivity_behavior: $inactivity_behavior, ios_is_goals_view_shown: $ios_is_goals_view_shown, is_goals_view_expanded: $is_goals_view_expanded, is_goals_view_shown: $is_goals_view_shown, is_summary_total_view_visible: $is_summary_total_view_visible, keep_mini_timer_on_top: $keep_mini_timer_on_top, keep_window_on_top: $keep_window_on_top, keyboard_increment_timer_page: $keyboard_increment_timer_page, keyboard_shortcuts_enabled: $keyboard_shortcuts_enabled, keyboard_shortcuts_share_time_entries: $keyboard_shortcuts_share_time_entries, mac_is_goals_view_shown: $mac_is_goals_view_shown, macos_auto_tracking_rules: $macos_auto_tracking_rules, macos_show_hide_toggl_keyboard_shortcut: $macos_show_hide_toggl_keyboard_shortcut, macos_stop_continue_keyboard_shortcut: $macos_stop_continue_keyboard_shortcut, manualEntryMode: $manualEntryMode, manualMode: $manualMode, manualModeOverlaySeen: $manualModeOverlaySeen, modify_on_start_time_change: $modify_on_start_time_change, offlineMode: $offlineMode, pg_time_zone_name: $pg_time_zone_name, pomodoro_auto_start_break: $pomodoro_auto_start_break, pomodoro_auto_start_focus: $pomodoro_auto_start_focus, pomodoro_break_interval_in_minutes: $pomodoro_break_interval_in_minutes, pomodoro_break_project: $pomodoro_break_project, pomodoro_break_project_id: $pomodoro_break_project_id, pomodoro_break_start_sound_enabled: $pomodoro_break_start_sound_enabled, pomodoro_break_tag: $pomodoro_break_tag, pomodoro_break_tag_id: $pomodoro_break_tag_id, pomodoro_countdown_timer: $pomodoro_countdown_timer, pomodoro_enabled: $pomodoro_enabled, pomodoro_focus_interval_in_minutes: $pomodoro_focus_interval_in_minutes, pomodoro_focus_sound: $pomodoro_focus_sound, pomodoro_global_sound_enabled: $pomodoro_global_sound_enabled, pomodoro_interval_end_sound: $pomodoro_interval_end_sound, pomodoro_interval_end_volume: $pomodoro_interval_end_volume, pomodoro_longer_break_duration_in_minutes: $pomodoro_longer_break_duration_in_minutes, pomodoro_prevent_screen_lock: $pomodoro_prevent_screen_lock, pomodoro_rounds_before_longer_break: $pomodoro_rounds_before_longer_break, pomodoro_session_start_sound_enabled: $pomodoro_session_start_sound_enabled, pomodoro_show_notifications: $pomodoro_show_notifications, pomodoro_stop_timer_at_interval_end: $pomodoro_stop_timer_at_interval_end, pomodoro_track_breaks_as_time_entries: $pomodoro_track_breaks_as_time_entries, projectDashboardActivityMode: $projectDashboardActivityMode, project_shortcut_enabled: $project_shortcut_enabled, record_timeline: $record_timeline, remember_last_project: $remember_last_project, reminder_days: $reminder_days, reminder_enabled: $reminder_enabled, reminder_interval_in_minutes: $reminder_interval_in_minutes, reminder_period: $reminder_period, reminder_snoozing_in_minutes: $reminder_snoozing_in_minutes, reportRounding: $reportRounding, reportRoundingDirection: $reportRoundingDirection, reportRoundingStepInMinutes: $reportRoundingStepInMinutes, reportsHideWeekends: $reportsHideWeekends, run_app_on_startup: $run_app_on_startup, running_entry_warning: $running_entry_warning, running_timer_notification_enabled: $running_timer_notification_enabled, seenFollowModal: $seenFollowModal, seenFooterPopup: $seenFooterPopup, seenProjectDashboardOverlay: $seenProjectDashboardOverlay, seenTogglButtonModal: $seenTogglButtonModal, send_added_to_project_notification: $send_added_to_project_notification, send_daily_project_invites: $send_daily_project_invites, send_product_emails: $send_product_emails, send_product_release_notification: $send_product_release_notification, send_system_message_notification: $send_system_message_notification, send_timer_notifications: $send_timer_notifications, send_weekly_report: $send_weekly_report, sharing_shortcut_enabled: $sharing_shortcut_enabled, showTimeInTitle: $showTimeInTitle, show_all_entries: $show_all_entries, show_changelog: $show_changelog, show_description_in_menu_bar: $show_description_in_menu_bar, show_dock_icon: $show_dock_icon, show_events_in_calendar: $show_events_in_calendar, show_project_in_menu_bar: $show_project_in_menu_bar, show_qr_scanner: $show_qr_scanner, show_seconds_in_menu_bar: $show_seconds_in_menu_bar, show_timeline_in_day_view: $show_timeline_in_day_view, show_timer_in_menu_bar: $show_timer_in_menu_bar, show_today_total_in_menu_bar: $show_today_total_in_menu_bar, show_total_billable_hours: $show_total_billable_hours, show_weekend_on_timer_page: $show_weekend_on_timer_page, show_workouts_in_calendar: $show_workouts_in_calendar, sleep_behaviour: $sleep_behaviour, smart_alerts_option: $smart_alerts_option, snowballReportRounding: $snowballReportRounding, stack_times_on_manual_mode_after: $stack_times_on_manual_mode_after, start_automatically: $start_automatically, start_shortcut_mode: $start_shortcut_mode, stop_at_specific_time: $stop_at_specific_time, stop_automatically: $stop_automatically, stop_entry_on_shutdown: $stop_entry_on_shutdown, stop_specified_time: $stop_specified_time, stopped_timer_notification_enabled: $stopped_timer_notification_enabled, suggestions_enabled: $suggestions_enabled, summaryReportAmounts: $summaryReportAmounts, summaryReportDistinctRates: $summaryReportDistinctRates, summaryReportGrouping: $summaryReportGrouping, summaryReportSortAsc: $summaryReportSortAsc, summaryReportSortField: $summaryReportSortField, summaryReportSubGrouping: $summaryReportSubGrouping, summary_total_mode: $summary_total_mode, tags_shortcut_enabled: $tags_shortcut_enabled, time_entry_display_mode: $time_entry_display_mode, time_entry_ghost_suggestions_enabled: $time_entry_ghost_suggestions_enabled, time_entry_invitations_notification_enabled: $time_entry_invitations_notification_enabled, time_entry_start_stop_input_mode: $time_entry_start_stop_input_mode, timeofday_format: $timeofday_format, timerView: $timerView, timerViewMobile: $timerViewMobile, toSAcceptNeeded: $toSAcceptNeeded, use_mini_timer: $use_mini_timer, visibleFooter: $visibleFooter, webTimeEntryStarted: $webTimeEntryStarted, webTimeEntryStopped: $webTimeEntryStopped, weeklyReportGrouping: $weeklyReportGrouping, weeklyReportValueToShow: $weeklyReportValueToShow, windows_auto_tracking_rules: $windows_auto_tracking_rules, windows_show_hide_toggl_keyboard_shortcut: $windows_show_hide_toggl_keyboard_shortcut, windows_stop_continue_keyboard_shortcut: $windows_stop_continue_keyboard_shortcut, windows_stop_start_keyboard_shortcut: $windows_stop_start_keyboard_shortcut, windows_theme: $windows_theme, workout_default_project: $workout_default_project, workout_default_project_id: $workout_default_project_id, workout_default_tag: $workout_default_tag, workout_default_tag_id: $workout_default_tag_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Preferences for an specific client of the current user
#
# GET /me/preferences/{client}
# operationId: get-preferences-client
export def "me-preferences get-preferences-client" [
  client: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: int # Retrieve preference modified since this date using UNIX timestamp.
]: any -> record<activity_timeline_display_activity: bool, activity_timeline_grouping_interval: string, activity_timeline_grouping_method: string, activity_timeline_recording_level: string, activity_timeline_sync_events: bool, alpha_features: table<alpha_feature_id: int, code: string, deleted_at: string, description: string, enabled: bool, product_id: int>, analyticsAdvancedFilters: bool, auto_tracker_delay_enabled: bool, auto_tracker_delay_in_seconds: int, auto_tracker_stop_on_no_rule_match_enabled: bool, automatic_tagging: bool, autotracking_enabled: bool, beginningOfWeek: int, calendar_snap_duration: string, calendar_snap_initial_location: string, calendar_visible_hours_end: int, calendar_visible_hours_start: int, calendar_zoom_level: string, cell_swipe_actions_enabled: bool, charts_view_type: string, collapseDetailedReportEntries: bool, collapseTimeEntries: bool, dashboards_view_type: string, date_format: string, decimal_separator: record, default_project_id: int, default_project_task: record<project_id: int, task_id: int, workspace_id: int>, default_task_id: int, displayDensity: string, distinctRates: string, duration_format: string, duration_format_on_timer_duration_field: bool, edit_popup_integration_timer: bool, extension_send_error_reports: bool, extension_send_usage_statistics: bool, firstSeenBusinessPromo: int, focus_app_on_time_entry_started: bool, focus_app_on_time_entry_stopped: bool, haptic_feedback_enabled: bool, hide_keyboard_shortcut: bool, hide_sidebar_right: bool, idle_detection_enabled: bool, idle_detection_interval_in_minutes: int, inactivity_behavior: string, ios_is_goals_view_shown: bool, is_goals_view_expanded: bool, is_goals_view_shown: bool, is_summary_total_view_visible: bool, keep_mini_timer_on_top: bool, keep_window_on_top: bool, keyboard_increment_timer_page: int, keyboard_shortcuts_enabled: bool, keyboard_shortcuts_share_time_entries: bool, mac_is_goals_view_shown: bool, macos_auto_tracking_rules: table<id: string, keyword: string, project_id: int, task_id: int, workspace_id: int>, macos_show_hide_toggl_keyboard_shortcut: record<key: int, modifiers: int>, macos_stop_continue_keyboard_shortcut: record<key: int, modifiers: int>, manualEntryMode: string, manualMode: bool, manualModeOverlaySeen: bool, modify_on_start_time_change: string, offlineMode: string, pg_time_zone_name: string, pomodoro_auto_start_break: bool, pomodoro_auto_start_focus: bool, pomodoro_break_interval_in_minutes: int, pomodoro_break_project: record<id: int, workspace_id: int>, pomodoro_break_project_id: int, pomodoro_break_start_sound_enabled: bool, pomodoro_break_tag: record<id: int, workspace_id: int>, pomodoro_break_tag_id: int, pomodoro_countdown_timer: bool, pomodoro_enabled: bool, pomodoro_focus_interval_in_minutes: int, pomodoro_focus_sound: string, pomodoro_global_sound_enabled: bool, pomodoro_interval_end_sound: bool, pomodoro_interval_end_volume: int, pomodoro_longer_break_duration_in_minutes: int, pomodoro_prevent_screen_lock: bool, pomodoro_rounds_before_longer_break: int, pomodoro_session_start_sound_enabled: bool, pomodoro_show_notifications: bool, pomodoro_stop_timer_at_interval_end: bool, pomodoro_track_breaks_as_time_entries: bool, projectDashboardActivityMode: string, project_shortcut_enabled: bool, record_timeline: bool, remember_last_project: string, reminder_days: string, reminder_enabled: bool, reminder_interval_in_minutes: int, reminder_period: string, reminder_snoozing_in_minutes: int, reportRounding: bool, reportRoundingDirection: string, reportRoundingStepInMinutes: int, reportsHideWeekends: bool, run_app_on_startup: bool, running_entry_warning: string, running_timer_notification_enabled: bool, seenFollowModal: bool, seenFooterPopup: bool, seenProjectDashboardOverlay: bool, seenTogglButtonModal: bool, send_added_to_project_notification: bool, send_daily_project_invites: bool, send_product_emails: bool, send_product_release_notification: bool, send_system_message_notification: bool, send_timer_notifications: bool, send_weekly_report: bool, sharing_shortcut_enabled: bool, showTimeInTitle: bool, show_all_entries: bool, show_changelog: bool, show_description_in_menu_bar: bool, show_dock_icon: bool, show_events_in_calendar: bool, show_project_in_menu_bar: bool, show_qr_scanner: bool, show_seconds_in_menu_bar: bool, show_timeline_in_day_view: bool, show_timer_in_menu_bar: bool, show_today_total_in_menu_bar: bool, show_total_billable_hours: bool, show_weekend_on_timer_page: bool, show_workouts_in_calendar: bool, sleep_behaviour: string, smart_alerts_option: string, snowballReportRounding: string, stack_times_on_manual_mode_after: string, start_automatically: bool, start_shortcut_mode: string, stop_at_specific_time: bool, stop_automatically: bool, stop_entry_on_shutdown: bool, stop_specified_time: string, stopped_timer_notification_enabled: bool, suggestions_enabled: bool, summaryReportAmounts: string, summaryReportDistinctRates: bool, summaryReportGrouping: string, summaryReportSortAsc: bool, summaryReportSortField: string, summaryReportSubGrouping: string, summary_total_mode: string, tags_shortcut_enabled: bool, time_entry_display_mode: string, time_entry_ghost_suggestions_enabled: bool, time_entry_invitations_notification_enabled: bool, time_entry_start_stop_input_mode: string, timeofday_format: string, timerView: string, timerViewMobile: string, toSAcceptNeeded: bool, use_mini_timer: bool, visibleFooter: string, webTimeEntryStarted: bool, webTimeEntryStopped: bool, weeklyReportGrouping: string, weeklyReportValueToShow: string, windows_auto_tracking_rules: table<billable: bool, description: string, enabled: bool, id: string, parameters: record, project_id: int, skip_when_timer_is_running: bool, start_without_confirmation: bool, tag_ids: list, task_id: int, type: int, workspace_id: int>, windows_show_hide_toggl_keyboard_shortcut: record<key: int, modifiers: int>, windows_stop_continue_keyboard_shortcut: record<key: int, modifiers: int>, windows_stop_start_keyboard_shortcut: record<key: int, modifiers: int>, windows_theme: string, workout_default_project: record<id: int, workspace_id: int>, workout_default_project_id: int, workout_default_tag: record<id: int, workspace_id: int>, workout_default_tag_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/me/preferences/($client)")
  let body = {since: $since} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update the preferences for an specific client of the current user
#
# POST /me/preferences/{client}
# operationId: post-preferences-client
# --alpha_features item shape: {alpha_feature_id?: int, code?: string, deleted_at?: string, description?: string, enabled?: bool, product_id?: int}
# --default_project_task shape: {project_id?: int, task_id?: int, workspace_id?: int}
# --macos_auto_tracking_rules item shape: {id?: string, keyword?: string, project_id?: int, task_id?: int, workspace_id?: int}
# --macos_show_hide_toggl_keyboard_shortcut shape: {key?: int, modifiers?: int}
# --macos_stop_continue_keyboard_shortcut shape: {key?: int, modifiers?: int}
# --pomodoro_break_project shape: {id?: int, workspace_id?: int}
# --pomodoro_break_tag shape: {id?: int, workspace_id?: int}
# --windows_auto_tracking_rules item shape: {billable?: bool, description?: string, enabled?: bool, id?: string, parameters?: record, project_id?: int, skip_when_timer_is_running?: bool, start_without_confirmation?: bool, tag_ids?: list, task_id?: int, type?: int, workspace_id?: int}
# --windows_show_hide_toggl_keyboard_shortcut shape: {key?: int, modifiers?: int}
# --windows_stop_continue_keyboard_shortcut shape: {key?: int, modifiers?: int}
# --windows_stop_start_keyboard_shortcut shape: {key?: int, modifiers?: int}
# --workout_default_project shape: {id?: int, workspace_id?: int}
# --workout_default_tag shape: {id?: int, workspace_id?: int}
export def "me-preferences post-preferences-client" [
  client: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --activity-timeline-display-activity: string@bool-completer
  --activity-timeline-grouping-interval: string
  --activity-timeline-grouping-method: string
  --activity-timeline-recording-level: string
  --activity-timeline-sync-events: string@bool-completer
  --alpha-features: list # will be omitted if empty — item shape: {alpha_feature_id?: int, code?: string, deleted_at?: string, description?: string, enabled?: bool, product_id?: int}
  --analyticsAdvancedFilters: string@bool-completer # will be omitted if empty
  --auto-tracker-delay-enabled: string@bool-completer
  --auto-tracker-delay-in-seconds: int
  --auto-tracker-stop-on-no-rule-match-enabled: string@bool-completer
  --automatic-tagging: string@bool-completer
  --autotracking-enabled: string@bool-completer
  --beginningOfWeek: int # will be omitted if empty
  --calendar-snap-duration: string
  --calendar-snap-initial-location: string
  --calendar-visible-hours-end: int
  --calendar-visible-hours-start: int
  --calendar-zoom-level: string
  --cell-swipe-actions-enabled: string@bool-completer
  --charts-view-type: string
  --collapseDetailedReportEntries: string@bool-completer # will be omitted if empty
  --collapseTimeEntries: string@bool-completer # will be omitted if empty
  --dashboards-view-type: string
  --date-format: string
  --decimal-separator: any # will be omitted if empty
  --default-project-id: int
  --default-project-task: record # shape: {project_id?: int, task_id?: int, workspace_id?: int}
  --default-task-id: int
  --displayDensity: string # will be omitted if empty
  --distinctRates: string # will be omitted if empty
  --duration-format: string
  --duration-format-on-timer-duration-field: string@bool-completer
  --edit-popup-integration-timer: string@bool-completer
  --extension-send-error-reports: string@bool-completer
  --extension-send-usage-statistics: string@bool-completer
  --firstSeenBusinessPromo: int # will be omitted if empty
  --focus-app-on-time-entry-started: string@bool-completer
  --focus-app-on-time-entry-stopped: string@bool-completer
  --haptic-feedback-enabled: string@bool-completer
  --hide-keyboard-shortcut: string@bool-completer # will be omitted if empty
  --hide-sidebar-right: string@bool-completer
  --idle-detection-enabled: string@bool-completer
  --idle-detection-interval-in-minutes: int
  --inactivity-behavior: string
  --ios-is-goals-view-shown: string@bool-completer
  --is-goals-view-expanded: string@bool-completer
  --is-goals-view-shown: string@bool-completer
  --is-summary-total-view-visible: string@bool-completer
  --keep-mini-timer-on-top: string@bool-completer
  --keep-window-on-top: string@bool-completer
  --keyboard-increment-timer-page: int
  --keyboard-shortcuts-enabled: string@bool-completer # will be omitted if empty
  --keyboard-shortcuts-share-time-entries: string@bool-completer
  --mac-is-goals-view-shown: string@bool-completer
  --macos-auto-tracking-rules: list # item shape: {id?: string, keyword?: string, project_id?: int, task_id?: int, workspace_id?: int}
  --macos-show-hide-toggl-keyboard-shortcut: record # shape: {key?: int, modifiers?: int}
  --macos-stop-continue-keyboard-shortcut: record # shape: {key?: int, modifiers?: int}
  --manualEntryMode: string # will be omitted if empty
  --manualMode: string@bool-completer # will be omitted if empty
  --manualModeOverlaySeen: string@bool-completer # will be omitted if empty
  --modify-on-start-time-change: string
  --offlineMode: string # will be omitted if empty
  --pg-time-zone-name: string
  --pomodoro-auto-start-break: string@bool-completer
  --pomodoro-auto-start-focus: string@bool-completer
  --pomodoro-break-interval-in-minutes: int
  --pomodoro-break-project: record # shape: {id?: int, workspace_id?: int}
  --pomodoro-break-project-id: int
  --pomodoro-break-start-sound-enabled: string@bool-completer
  --pomodoro-break-tag: record # shape: {id?: int, workspace_id?: int}
  --pomodoro-break-tag-id: int
  --pomodoro-countdown-timer: string@bool-completer
  --pomodoro-enabled: string@bool-completer
  --pomodoro-focus-interval-in-minutes: int
  --pomodoro-focus-sound: string
  --pomodoro-global-sound-enabled: string@bool-completer
  --pomodoro-interval-end-sound: string@bool-completer
  --pomodoro-interval-end-volume: int
  --pomodoro-longer-break-duration-in-minutes: int
  --pomodoro-prevent-screen-lock: string@bool-completer
  --pomodoro-rounds-before-longer-break: int
  --pomodoro-session-start-sound-enabled: string@bool-completer
  --pomodoro-show-notifications: string@bool-completer
  --pomodoro-stop-timer-at-interval-end: string@bool-completer
  --pomodoro-track-breaks-as-time-entries: string@bool-completer
  --projectDashboardActivityMode: string # will be omitted if empty
  --project-shortcut-enabled: string@bool-completer
  --record-timeline: string@bool-completer
  --remember-last-project: string
  --reminder-days: string
  --reminder-enabled: string@bool-completer
  --reminder-interval-in-minutes: int
  --reminder-period: string
  --reminder-snoozing-in-minutes: int
  --reportRounding: string@bool-completer # will be omitted if empty
  --reportRoundingDirection: string # will be omitted if empty
  --reportRoundingStepInMinutes: int # will be omitted if empty
  --reportsHideWeekends: string@bool-completer # will be omitted if empty
  --run-app-on-startup: string@bool-completer
  --running-entry-warning: string
  --running-timer-notification-enabled: string@bool-completer
  --seenFollowModal: string@bool-completer # will be omitted if empty
  --seenFooterPopup: string@bool-completer # will be omitted if empty
  --seenProjectDashboardOverlay: string@bool-completer # will be omitted if empty
  --seenTogglButtonModal: string@bool-completer # will be omitted if empty
  --send-added-to-project-notification: string@bool-completer
  --send-daily-project-invites: string@bool-completer
  --send-product-emails: string@bool-completer
  --send-product-release-notification: string@bool-completer
  --send-system-message-notification: string@bool-completer
  --send-timer-notifications: string@bool-completer
  --send-weekly-report: string@bool-completer
  --sharing-shortcut-enabled: string@bool-completer
  --showTimeInTitle: string@bool-completer # will be omitted if empty
  --show-all-entries: string@bool-completer
  --show-changelog: string@bool-completer
  --show-description-in-menu-bar: string@bool-completer
  --show-dock-icon: string@bool-completer
  --show-events-in-calendar: string@bool-completer
  --show-project-in-menu-bar: string@bool-completer
  --show-qr-scanner: string@bool-completer
  --show-seconds-in-menu-bar: string@bool-completer
  --show-timeline-in-day-view: string@bool-completer # will be omitted if empty
  --show-timer-in-menu-bar: string@bool-completer
  --show-today-total-in-menu-bar: string@bool-completer
  --show-total-billable-hours: string@bool-completer # will be omitted if empty
  --show-weekend-on-timer-page: string@bool-completer # will be omitted if empty
  --show-workouts-in-calendar: string@bool-completer
  --sleep-behaviour: string
  --smart-alerts-option: string
  --snowballReportRounding: string # will be omitted if empty
  --stack-times-on-manual-mode-after: string
  --start-automatically: string@bool-completer
  --start-shortcut-mode: string
  --stop-at-specific-time: string@bool-completer
  --stop-automatically: string@bool-completer
  --stop-entry-on-shutdown: string@bool-completer
  --stop-specified-time: string
  --stopped-timer-notification-enabled: string@bool-completer
  --suggestions-enabled: string@bool-completer
  --summaryReportAmounts: string # will be omitted if empty
  --summaryReportDistinctRates: string@bool-completer # will be omitted if empty
  --summaryReportGrouping: string # will be omitted if empty
  --summaryReportSortAsc: string@bool-completer # will be omitted if empty
  --summaryReportSortField: string # will be omitted if empty
  --summaryReportSubGrouping: string # will be omitted if empty
  --summary-total-mode: string
  --tags-shortcut-enabled: string@bool-completer
  --time-entry-display-mode: string
  --time-entry-ghost-suggestions-enabled: string@bool-completer
  --time-entry-invitations-notification-enabled: string@bool-completer
  --time-entry-start-stop-input-mode: string
  --timeofday-format: string
  --timerView: string # will be omitted if empty
  --timerViewMobile: string # will be omitted if empty
  --toSAcceptNeeded: string@bool-completer # ToSAcceptNeeded represents the trigger for new ToS accept dialog
  --use-mini-timer: string@bool-completer
  --visibleFooter: string # will be omitted if empty
  --webTimeEntryStarted: string@bool-completer # will be omitted if empty
  --webTimeEntryStopped: string@bool-completer # will be omitted if empty
  --weeklyReportGrouping: string # will be omitted if empty
  --weeklyReportValueToShow: string # will be omitted if empty
  --windows-auto-tracking-rules: list # item shape: {billable?: bool, description?: string, enabled?: bool, id?: string, parameters?: record, project_id?: int, skip_when_timer_is_running?: bool, start_without_confirmation?: bool, tag_ids?: list, task_id?: int, type?: int, workspace_id?: int}
  --windows-show-hide-toggl-keyboard-shortcut: record # shape: {key?: int, modifiers?: int}
  --windows-stop-continue-keyboard-shortcut: record # shape: {key?: int, modifiers?: int}
  --windows-stop-start-keyboard-shortcut: record # shape: {key?: int, modifiers?: int}
  --windows-theme: string
  --workout-default-project: record # shape: {id?: int, workspace_id?: int}
  --workout-default-project-id: int
  --workout-default-tag: record # shape: {id?: int, workspace_id?: int}
  --workout-default-tag-id: int
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/me/preferences/($client)")
  let body = {activity_timeline_display_activity: $activity_timeline_display_activity, activity_timeline_grouping_interval: $activity_timeline_grouping_interval, activity_timeline_grouping_method: $activity_timeline_grouping_method, activity_timeline_recording_level: $activity_timeline_recording_level, activity_timeline_sync_events: $activity_timeline_sync_events, alpha_features: $alpha_features, analyticsAdvancedFilters: $analyticsAdvancedFilters, auto_tracker_delay_enabled: $auto_tracker_delay_enabled, auto_tracker_delay_in_seconds: $auto_tracker_delay_in_seconds, auto_tracker_stop_on_no_rule_match_enabled: $auto_tracker_stop_on_no_rule_match_enabled, automatic_tagging: $automatic_tagging, autotracking_enabled: $autotracking_enabled, beginningOfWeek: $beginningOfWeek, calendar_snap_duration: $calendar_snap_duration, calendar_snap_initial_location: $calendar_snap_initial_location, calendar_visible_hours_end: $calendar_visible_hours_end, calendar_visible_hours_start: $calendar_visible_hours_start, calendar_zoom_level: $calendar_zoom_level, cell_swipe_actions_enabled: $cell_swipe_actions_enabled, charts_view_type: $charts_view_type, collapseDetailedReportEntries: $collapseDetailedReportEntries, collapseTimeEntries: $collapseTimeEntries, dashboards_view_type: $dashboards_view_type, date_format: $date_format, decimal_separator: $decimal_separator, default_project_id: $default_project_id, default_project_task: $default_project_task, default_task_id: $default_task_id, displayDensity: $displayDensity, distinctRates: $distinctRates, duration_format: $duration_format, duration_format_on_timer_duration_field: $duration_format_on_timer_duration_field, edit_popup_integration_timer: $edit_popup_integration_timer, extension_send_error_reports: $extension_send_error_reports, extension_send_usage_statistics: $extension_send_usage_statistics, firstSeenBusinessPromo: $firstSeenBusinessPromo, focus_app_on_time_entry_started: $focus_app_on_time_entry_started, focus_app_on_time_entry_stopped: $focus_app_on_time_entry_stopped, haptic_feedback_enabled: $haptic_feedback_enabled, hide_keyboard_shortcut: $hide_keyboard_shortcut, hide_sidebar_right: $hide_sidebar_right, idle_detection_enabled: $idle_detection_enabled, idle_detection_interval_in_minutes: $idle_detection_interval_in_minutes, inactivity_behavior: $inactivity_behavior, ios_is_goals_view_shown: $ios_is_goals_view_shown, is_goals_view_expanded: $is_goals_view_expanded, is_goals_view_shown: $is_goals_view_shown, is_summary_total_view_visible: $is_summary_total_view_visible, keep_mini_timer_on_top: $keep_mini_timer_on_top, keep_window_on_top: $keep_window_on_top, keyboard_increment_timer_page: $keyboard_increment_timer_page, keyboard_shortcuts_enabled: $keyboard_shortcuts_enabled, keyboard_shortcuts_share_time_entries: $keyboard_shortcuts_share_time_entries, mac_is_goals_view_shown: $mac_is_goals_view_shown, macos_auto_tracking_rules: $macos_auto_tracking_rules, macos_show_hide_toggl_keyboard_shortcut: $macos_show_hide_toggl_keyboard_shortcut, macos_stop_continue_keyboard_shortcut: $macos_stop_continue_keyboard_shortcut, manualEntryMode: $manualEntryMode, manualMode: $manualMode, manualModeOverlaySeen: $manualModeOverlaySeen, modify_on_start_time_change: $modify_on_start_time_change, offlineMode: $offlineMode, pg_time_zone_name: $pg_time_zone_name, pomodoro_auto_start_break: $pomodoro_auto_start_break, pomodoro_auto_start_focus: $pomodoro_auto_start_focus, pomodoro_break_interval_in_minutes: $pomodoro_break_interval_in_minutes, pomodoro_break_project: $pomodoro_break_project, pomodoro_break_project_id: $pomodoro_break_project_id, pomodoro_break_start_sound_enabled: $pomodoro_break_start_sound_enabled, pomodoro_break_tag: $pomodoro_break_tag, pomodoro_break_tag_id: $pomodoro_break_tag_id, pomodoro_countdown_timer: $pomodoro_countdown_timer, pomodoro_enabled: $pomodoro_enabled, pomodoro_focus_interval_in_minutes: $pomodoro_focus_interval_in_minutes, pomodoro_focus_sound: $pomodoro_focus_sound, pomodoro_global_sound_enabled: $pomodoro_global_sound_enabled, pomodoro_interval_end_sound: $pomodoro_interval_end_sound, pomodoro_interval_end_volume: $pomodoro_interval_end_volume, pomodoro_longer_break_duration_in_minutes: $pomodoro_longer_break_duration_in_minutes, pomodoro_prevent_screen_lock: $pomodoro_prevent_screen_lock, pomodoro_rounds_before_longer_break: $pomodoro_rounds_before_longer_break, pomodoro_session_start_sound_enabled: $pomodoro_session_start_sound_enabled, pomodoro_show_notifications: $pomodoro_show_notifications, pomodoro_stop_timer_at_interval_end: $pomodoro_stop_timer_at_interval_end, pomodoro_track_breaks_as_time_entries: $pomodoro_track_breaks_as_time_entries, projectDashboardActivityMode: $projectDashboardActivityMode, project_shortcut_enabled: $project_shortcut_enabled, record_timeline: $record_timeline, remember_last_project: $remember_last_project, reminder_days: $reminder_days, reminder_enabled: $reminder_enabled, reminder_interval_in_minutes: $reminder_interval_in_minutes, reminder_period: $reminder_period, reminder_snoozing_in_minutes: $reminder_snoozing_in_minutes, reportRounding: $reportRounding, reportRoundingDirection: $reportRoundingDirection, reportRoundingStepInMinutes: $reportRoundingStepInMinutes, reportsHideWeekends: $reportsHideWeekends, run_app_on_startup: $run_app_on_startup, running_entry_warning: $running_entry_warning, running_timer_notification_enabled: $running_timer_notification_enabled, seenFollowModal: $seenFollowModal, seenFooterPopup: $seenFooterPopup, seenProjectDashboardOverlay: $seenProjectDashboardOverlay, seenTogglButtonModal: $seenTogglButtonModal, send_added_to_project_notification: $send_added_to_project_notification, send_daily_project_invites: $send_daily_project_invites, send_product_emails: $send_product_emails, send_product_release_notification: $send_product_release_notification, send_system_message_notification: $send_system_message_notification, send_timer_notifications: $send_timer_notifications, send_weekly_report: $send_weekly_report, sharing_shortcut_enabled: $sharing_shortcut_enabled, showTimeInTitle: $showTimeInTitle, show_all_entries: $show_all_entries, show_changelog: $show_changelog, show_description_in_menu_bar: $show_description_in_menu_bar, show_dock_icon: $show_dock_icon, show_events_in_calendar: $show_events_in_calendar, show_project_in_menu_bar: $show_project_in_menu_bar, show_qr_scanner: $show_qr_scanner, show_seconds_in_menu_bar: $show_seconds_in_menu_bar, show_timeline_in_day_view: $show_timeline_in_day_view, show_timer_in_menu_bar: $show_timer_in_menu_bar, show_today_total_in_menu_bar: $show_today_total_in_menu_bar, show_total_billable_hours: $show_total_billable_hours, show_weekend_on_timer_page: $show_weekend_on_timer_page, show_workouts_in_calendar: $show_workouts_in_calendar, sleep_behaviour: $sleep_behaviour, smart_alerts_option: $smart_alerts_option, snowballReportRounding: $snowballReportRounding, stack_times_on_manual_mode_after: $stack_times_on_manual_mode_after, start_automatically: $start_automatically, start_shortcut_mode: $start_shortcut_mode, stop_at_specific_time: $stop_at_specific_time, stop_automatically: $stop_automatically, stop_entry_on_shutdown: $stop_entry_on_shutdown, stop_specified_time: $stop_specified_time, stopped_timer_notification_enabled: $stopped_timer_notification_enabled, suggestions_enabled: $suggestions_enabled, summaryReportAmounts: $summaryReportAmounts, summaryReportDistinctRates: $summaryReportDistinctRates, summaryReportGrouping: $summaryReportGrouping, summaryReportSortAsc: $summaryReportSortAsc, summaryReportSortField: $summaryReportSortField, summaryReportSubGrouping: $summaryReportSubGrouping, summary_total_mode: $summary_total_mode, tags_shortcut_enabled: $tags_shortcut_enabled, time_entry_display_mode: $time_entry_display_mode, time_entry_ghost_suggestions_enabled: $time_entry_ghost_suggestions_enabled, time_entry_invitations_notification_enabled: $time_entry_invitations_notification_enabled, time_entry_start_stop_input_mode: $time_entry_start_stop_input_mode, timeofday_format: $timeofday_format, timerView: $timerView, timerViewMobile: $timerViewMobile, toSAcceptNeeded: $toSAcceptNeeded, use_mini_timer: $use_mini_timer, visibleFooter: $visibleFooter, webTimeEntryStarted: $webTimeEntryStarted, webTimeEntryStopped: $webTimeEntryStopped, weeklyReportGrouping: $weeklyReportGrouping, weeklyReportValueToShow: $weeklyReportValueToShow, windows_auto_tracking_rules: $windows_auto_tracking_rules, windows_show_hide_toggl_keyboard_shortcut: $windows_show_hide_toggl_keyboard_shortcut, windows_stop_continue_keyboard_shortcut: $windows_stop_continue_keyboard_shortcut, windows_stop_start_keyboard_shortcut: $windows_stop_start_keyboard_shortcut, windows_theme: $windows_theme, workout_default_project: $workout_default_project, workout_default_project_id: $workout_default_project_id, workout_default_tag: $workout_default_tag, workout_default_tag_id: $workout_default_tag_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Projects
#
# GET /me/projects
# operationId: get-me-projects
export def "me-projects get-me-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-archived: string # Include archived projects.
  --since: int # Retrieve projects modified since this date using UNIX timestamp, including deleted ones.
]: nothing -> table<active: bool, actual_hours: int, actual_seconds: int, at: string, auto_estimates: bool, billable: bool, can_track_time: bool, cid: int, client_id: int, client_name: string, color: string, created_at: string, currency: string, current_period: record<end_date: string, start_date: string>, end_date: string, estimated_hours: int, estimated_seconds: int, external_reference: string, fixed_fee: float, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, is_private: bool, name: string, permissions: list<string>, pinned: bool, rate: float, rate_last_updated: string, recurring: bool, recurring_parameters: list<record>, start_date: string, status: record, template: bool, template_id: int, total_count: int, wid: int, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_archived" $include_archived "scalar") (serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ProjectsPaginated
#
# GET /me/projects/paginated
# operationId: get-me-projects-paginated
export def "me-projects-paginated get-me-projects-paginated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-project-id: int # Project ID to resume the next pagination from.
  --since: int # Retrieve projects created/modified/deleted since this date using UNIX timestamp.
  --per-page: int # Number of items per page, default 201.
]: any -> table<active: bool, actual_hours: int, actual_seconds: int, at: string, auto_estimates: bool, billable: bool, can_track_time: bool, cid: int, client_id: int, client_name: string, color: string, created_at: string, currency: string, current_period: record<end_date: string, start_date: string>, end_date: string, estimated_hours: int, estimated_seconds: int, external_reference: string, fixed_fee: float, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, is_private: bool, name: string, permissions: list<string>, pinned: bool, rate: float, rate_last_updated: string, recurring: bool, recurring_parameters: list<record>, start_date: string, status: record, template: bool, template_id: int, total_count: int, wid: int, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/projects/paginated")
  let body = {start_project_id: $start_project_id, since: $since, per_page: $per_page} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# PushServices
#
# GET /me/push_services
# operationId: get-push-services
export def "me-push-services get-push-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/push_services")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PushServices
#
# POST /me/push_services
# operationId: post-push-services
export def "me-push-services post-push-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fcm-registration-token: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/push_services")
  let body = {fcm_registration_token: $fcm_registration_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PushServices
#
# DELETE /me/push_services
# operationId: delete-push-services
export def "me-push-services delete-push-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fcm-registration-token: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/push_services")
  let body = {fcm_registration_token: $fcm_registration_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# API quota for the current user
#
# GET /me/quota
# operationId: get-quota
export def "me-quota get-quota" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<organization_id: int, remaining: int, resets_in_secs: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/quota")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ResetToken
#
# POST /me/reset_token
# operationId: post-reset-token
export def "me-reset-token post-reset-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/reset_token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Tags
#
# GET /me/tags
# operationId: get-tags
export def "me-tags get-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: int # Retrieve tags modified/deleted since this date using UNIX timestamp.
]: any -> table<at: string, creator_id: int, deleted_at: string, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, name: string, permissions: list<string>, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/tags")
  let body = {since: $since} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Tasks
#
# GET /me/tasks
# operationId: get-tasks
export def "me-tasks get-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --meta: string@bool-completer # Should the response contain data for meta entities
  --since: int # Retrieve tasks created/modified/deleted since this date using UNIX timestamp.
  --include-not-active: string # Include tasks marked as done.
  --offset: int # Offset to resume the next pagination from.
  --per-page: int # Number of items per page, default is all.
]: any -> table<active: bool, at: string, avatar_url: string, client_id: int, client_name: string, estimated_seconds: int, external_reference: string, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, name: string, permissions: list<string>, project_billable: bool, project_color: string, project_id: int, project_is_private: bool, project_name: string, rate: float, rate_last_updated: string, recurring: bool, toggl_accounts_id: string, tracked_seconds: int, user_id: int, user_name: string, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "meta" $meta "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/tasks" $qp)
  let body = {since: $since, include_not_active: $include_not_active, offset: $offset, per_page: $per_page} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# TimeEntries
#
# GET /me/time_entries
# operationId: get-time-entries
export def "me-time-entries get-time-entries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: int # Get entries modified since this date using UNIX timestamp, including deleted ones.
  --before: string # Get entries with start time, before given date (YYYY-MM-DD) or with time in RFC3339 format.
  --start-date: string # Get entries with start time, from start_date YYYY-MM-DD or with time in RFC3339 format. To be used with end_date.
  --end-date: string # Get entries with start time, until end_date YYYY-MM-DD or with time in RFC3339 format. To be used with start_date.
  --meta: string@bool-completer # Should the response contain data for meta entities
  --include-sharing: string@bool-completer # Include sharing details in the response
]: nothing -> table<at: string, billable: bool, client_id: int, client_name: string, description: string, duration: int, duronly: bool, expense_ids: list<int>, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, permissions: list<string>, pid: int, project_active: bool, project_billable: bool, project_color: string, project_id: int, project_name: string, shared_with: list<record>, start: string, stop: string, tag_ids: list<int>, tags: list<string>, task_id: int, task_name: string, tid: int, uid: int, user_avatar_url: string, user_id: int, user_name: string, wid: int, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "meta" $meta "scalar") (serialize-qp "include_sharing" $include_sharing "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/time_entries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# TimeEntries
#
# GET /me/time_entries/checklist
# operationId: get-time-entries-checklist
export def "me-time-entries-checklist get-time-entries-checklist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<time_entries_count_check: bool, time_entries_created_check: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/time_entries/checklist")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current time entry
#
# GET /me/time_entries/current
# operationId: get-current-time-entry
export def "me-time-entries-current get-current-time-entry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<at: string, billable: bool, client_id: int, client_name: string, description: string, duration: int, duronly: bool, expense_ids: list<int>, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, permissions: list<string>, pid: int, project_active: bool, project_billable: bool, project_color: string, project_id: int, project_name: string, shared_with: table<accepted: bool, user_id: int, user_name: string>, start: string, stop: string, tag_ids: list<int>, tags: list<string>, task_id: int, task_name: string, tid: int, uid: int, user_avatar_url: string, user_id: int, user_name: string, wid: int, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/time_entries/current")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a time entry by ID.
#
# GET /me/time_entries/{time_entry_id}
# operationId: get-time-entry-by-id
export def "me-time-entries get-time-entry-by-id" [
  time_entry_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --meta: string@bool-completer # Should the response contain data for meta entities
  --include-sharing: string@bool-completer # Include sharing details in the response
]: nothing -> record<at: string, billable: bool, client_id: int, client_name: string, description: string, duration: int, duronly: bool, expense_ids: list<int>, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, permissions: list<string>, pid: int, project_active: bool, project_billable: bool, project_color: string, project_id: int, project_name: string, shared_with: table<accepted: bool, user_id: int, user_name: string>, start: string, stop: string, tag_ids: list<int>, tags: list<string>, task_id: int, task_name: string, tid: int, uid: int, user_avatar_url: string, user_id: int, user_name: string, wid: int, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "meta" $meta "scalar") (serialize-qp "include_sharing" $include_sharing "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/me/time_entries/($time_entry_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# TimeEntries
#
# POST /me/time_entries_shared_with
# operationId: post-me-time-entries-shared-with
export def "me-time-entries-shared-with post-me-time-entries-shared-with" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<is_accepted: bool, time_entry_id: int, time_entry_invitation_id: int, user_id: int, user_name: string, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/time_entries_shared_with")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# User's Timesheets
#
# GET /me/timesheets
# operationId: get-me-timesheets
export def "me-timesheets get-me-timesheets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<approved_or_rejected_at: string, approved_or_rejected_id: int, created_at: string, deleted_at: string, force_approved: bool, rejection_comment: string, reminder_sent_at: string, review_layer: int, start_date: string, status: string, submission_email_sent_at: string, submitted_at: string, timesheet_id: int, timesheet_setup_id: int, timezone: string, updated_at: string, working_hours_in_minutes: int, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/timesheets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# TrackReminders
#
# GET /me/track_reminders
# operationId: get-me-track-reminders
export def "me-track-reminders get-me-track-reminders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<created_at: string, email_reminder_enabled: bool, frequency: int, group_ids: list<int>, reminder_id: int, slack_reminder_enabled: bool, threshold: int, user_ids: list<int>, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/track_reminders")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# WebTimer
#
# GET /me/web-timer
# operationId: get-web-timer
export def "me-web-timer get-web-timer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/web-timer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Workspaces
#
# GET /me/workspaces
# operationId: get-workspaces
export def "me-workspaces get-workspaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: int # Retrieve workspaces created/modified/deleted since this date using UNIX timestamp, including the dates a workspace member got added, removed or updated in the workspace.
]: any -> table<active_project_count: int, admin: bool, api_token: string, at: string, business_ws: bool, csv_upload: record<at: string, log_id: int>, default_currency: string, default_hourly_rate: float, disable_approvals: bool, disable_expenses: bool, disable_timesheet_view: bool, hide_start_end_times: bool, ical_enabled: bool, ical_url: string, id: int, last_modified: string, limit_public_project_data: bool, logo_url: string, max_data_retention_days: record, name: string, only_admins_may_create_projects: bool, only_admins_may_create_tags: bool, only_admins_see_team_dashboard: bool, organization_id: int, permissions: list<string>, premium: bool, projects_billable_by_default: bool, projects_enforce_billable: bool, projects_private_by_default: bool, rate_last_updated: string, reports_collapse: bool, role: string, rounding: int, rounding_minutes: int, subscription: record<auto_renew: bool, card_details: record, company_id: int, contact_detail: record, created_at: string, currency: string, customer_id: int, deleted_at: string, last_pricing_plan_id: int, organization_id: int, payment_details: record, pricing_plan_id: int, renewal_at: string, subscription_id: int, subscription_period: record, workspace_id: int>, suspended_at: string, te_constraints: record<description_present: bool, max_tags: int, project_present: bool, tag_present: bool, task_present: bool, time_entry_constraints_enabled: bool>, working_hours_in_minutes: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/workspaces")
  let body = {since: $since} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Creates a new organization
#
# POST /organizations
# operationId: post-organization
export def "organizations post-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the organization
  --workspace-name: string # Name of the workspace
]: any -> record<id: int, name: string, permissions: list<string>, workspace_id: int, workspace_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organizations")
  let body = {name: $name, workspace_name: $workspace_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Accepts invitation
#
# POST /organizations/invitations/{invitation_code}/accept
# operationId: post-organization-accept-invitation
export def "organizations-invitations-accept post-organization-accept-invitation" [
  invitation_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/invitations/($invitation_code)/accept")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rejects invitation
#
# POST /organizations/invitations/{invitation_code}/reject
# operationId: post-reject-invitation
export def "organizations-invitations-reject post-reject-invitation" [
  invitation_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/invitations/($invitation_code)/reject")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Organization data
#
# GET /organizations/{organization_id}
# operationId: get-organization
export def "organizations get-organization" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<admin: bool, at: string, created_at: string, id: int, is_multi_workspace_enabled: bool, is_unified: bool, max_data_retention_days: record, max_workspaces: int, name: string, owner: bool, permissions: list<string>, pricing_plan_enterprise: bool, pricing_plan_id: int, pricing_plan_name: string, subscription: record<billing_period_months: int, cancel_date: string, created_at: string, currency: string, current_period_ends_at: string, current_period_starts_at: string, enterprise: bool, plan: record, plan_name: string, seats: int, state: record, trial: record<active: bool, available: bool, end_date: string, plan: record, start_date: string>>, suspended_at: string, trial_info: record<can_have_trial: bool, last_pricing_plan_id: int, next_payment_date: string, trial: bool, trial_available: bool, trial_end_date: string, trial_plan_id: int>, user_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates an existing organization
#
# PUT /organizations/{organization_id}
# operationId: put-organization
export def "organizations put-organization" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the organization
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List of groups in organization with user and workspace assignments
#
# GET /organizations/{organization_id}/groups
# operationId: get-organization-groups
export def "organizations-groups get-organization-groups" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Returns records where name contains this string
  --workspace: string # ID of workspace. Returns groups assigned to this workspace
]: nothing -> table<at: string, group_id: int, name: string, permissions: list<string>, users: list<record>, workspaces: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "workspace" $workspace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create group
#
# POST /organizations/{organization_id}/groups
# operationId: post-organization-group
export def "organizations-groups post-organization-group" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Group name
  --users: list # Group users, optional
  --workspaces: list # Group workspaces
]: any -> record<at: string, group_id: int, name: string, permissions: list<string>, users: table<avatar_url: string, inactive: bool, joined: bool, name: string, user_id: int>, workspaces: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/groups")
  let body = {name: $name, users: $users, workspaces: $workspaces} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Edit group
#
# PUT /organizations/{organization_id}/groups/{group_id}
# operationId: put-organization-group
export def "organizations-groups put-organization-group" [
  organization_id: int
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Group name
  --users: list # Group users, optional
  --workspaces: list # Group workspaces
]: any -> record<at: string, group_id: int, name: string, permissions: list<string>, users: table<avatar_url: string, inactive: bool, joined: bool, name: string, user_id: int>, workspaces: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/groups/($group_id)")
  let body = {name: $name, users: $users, workspaces: $workspaces} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes group
#
# DELETE /organizations/{organization_id}/groups/{group_id}
# operationId: delete-organization-group
export def "organizations-groups delete-organization-group" [
  organization_id: int
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/groups/($group_id)")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch group
#
# PATCH /organizations/{organization_id}/groups/{group_id}
# operationId: patch-organization-group
export def "organizations-groups patch-organization-group" [
  organization_id: int
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<failure: table<message: string, patch: record>, success: table<op: string, path: string, value: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/groups/($group_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Request Slack integration from org admins
#
# POST /organizations/{organization_id}/integrations/slack/request
# operationId: post-organization-slack-integration-request
export def "organizations-integrations-slack-request post-organization-slack-integration-request" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/integrations/slack/request")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new invitation for the user
#
# POST /organizations/{organization_id}/invitations
# operationId: post-organization-invitation
# --project_invite shape: {manager?: bool, project_id?: int, workspace_id?: int}
# --workspaces item shape: {admin?: bool, integration_data?: record, role?: string, role_id?: int, workspace_id?: int}
export def "organizations-invitations post-organization-invitation" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --emails: list
  --groups: list
  --project-invite: record # shape: {manager?: bool, project_id?: int, workspace_id?: int}
  --skip-email: string@bool-completer
  --workspaces: list # item shape: {admin?: bool, integration_data?: record, role?: string, role_id?: int, workspace_id?: int}
]: any -> record<data: table<email: string, invitation_id: int, invite_url: string, organization_id: int, recipient_id: int, sender_id: int, workspaces: list>, invitations: table<code: string, email: string, organization_id: int, organization_name: string, sender_email: string, sender_name: string>, messages: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/invitations")
  let body = {emails: $emails, groups: $groups, project_invite: $project_invite, skip_email: $skip_email, workspaces: $workspaces} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resends user their invitation
#
# PUT /organizations/{organization_id}/invitations/{invitation_id}/resend
# operationId: put-invitation
export def "organizations-invitations-resend put-invitation" [
  organization_id: int
  invitation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/invitations/($invitation_id)/resend")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# InvoicePdf
#
# GET /organizations/{organization_id}/invoices/{invoice_uid}.pdf
# operationId: get-organization-invoice
export def "organizations-invoices get-organization-invoice" [
  organization_id: int
  invoice_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/invoices/($invoice_uid).pdf")
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get owner of the organization
#
# GET /organizations/{organization_id}/owner
# operationId: get-organization-owner
export def "organizations-owner get-organization-owner" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<avatar_url: string, email: string, id: int, name: string, organization_id: int, organization_user_created_at: string, organization_user_id: int, organization_user_updated_at: string, toggl_accounts_id: string, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/owner")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns list of organization transfers made in the organization
#
# GET /organizations/{organization_id}/owner/transfer
# operationId: get-ownership-transfers
export def "organizations-owner-transfer get-ownership-transfers" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ongoing: string # If true, returns only current, not finished transfer
]: nothing -> table<created_at: string, current_owner_accepted: bool, current_owner_answered_at: string, current_owner_id: int, finished_at: string, new_owner_accepted: bool, new_owner_answered_at: string, new_owner_id: int, organization_id: int, outcome_name: string, owner_transfer_id: int, requester_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ongoing" $ongoing "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/owner/transfer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates new ownership transfer process
#
# POST /organizations/{organization_id}/owner/transfer
# operationId: post-ownership-transfer
export def "organizations-owner-transfer post-ownership-transfer" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: string, current_owner_accepted: bool, current_owner_answered_at: string, current_owner_id: int, finished_at: string, new_owner_accepted: bool, new_owner_answered_at: string, new_owner_id: int, organization_id: int, outcome_name: string, owner_transfer_id: int, requester_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/owner/transfer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns single organization transfer in the organization
#
# GET /organizations/{organization_id}/owner/transfer/{transfer_id}
# operationId: get-ownership-transfer
export def "organizations-owner-transfer get-ownership-transfer" [
  organization_id: int
  transfer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: string, current_owner_accepted: bool, current_owner_answered_at: string, current_owner_id: int, finished_at: string, new_owner_accepted: bool, new_owner_answered_at: string, new_owner_id: int, organization_id: int, outcome_name: string, owner_transfer_id: int, requester_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/owner/transfer/($transfer_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates transfer process and emails stakeholders
#
# POST /organizations/{organization_id}/owner/transfer/{transfer_id}/{action}
# operationId: post-ownership-transfer-actions
export def "organizations-owner-transfer post-ownership-transfer-actions" [
  organization_id: int
  transfer_id: int
  action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: string, current_owner_accepted: bool, current_owner_answered_at: string, current_owner_id: int, finished_at: string, new_owner_accepted: bool, new_owner_answered_at: string, new_owner_id: int, organization_id: int, outcome_name: string, owner_transfer_id: int, requester_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/owner/transfer/($transfer_id)/($action)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# OrganizationsPaymentRecords
#
# GET /organizations/{organization_id}/payment_records
# operationId: get-organizations-payments-records
export def "organizations-payment-records get-organizations-payments-records" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --is-unified: string@bool-completer # If 'true', returns unified invoices
  --cursor: string # Next cursor for unified subsriptions. Cannot be used without `last_inv`
  --last-inv: string # Last invoice ID from the previous call.
]: nothing -> table<items: list<record>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "is_unified" $is_unified "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "last_inv" $last_inv "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/payment_records" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# OrganizationsPlans
#
# GET /organizations/{organization_id}/plans
# operationId: get-organizations-plans
export def "organizations-plans get-organizations-plans" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<currency_id: int, discount_percentage: int, discount_to: string, plans: table<name: string, plan_id: int, pricing_plans: list>, tax_included: bool, tax_percentage: float, tax_type: string, user_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/plans")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# OrganizationsPlan
#
# GET /organizations/{organization_id}/plans/{plan_id}
# operationId: get-organizations-plan
export def "organizations-plans get-organizations-plan" [
  organization_id: int
  plan_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<currency_id: int, discount_percentage: int, discount_to: string, plans: table<name: string, plan_id: int, pricing_plans: list>, tax_included: bool, tax_percentage: float, tax_type: string, user_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/plans/($plan_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send the Premium-annual 30% upgrade email to org admins
#
# POST /organizations/{organization_id}/premium-upgrade-discount-email
# operationId: post-organization-premium-upgrade-discount-email
export def "organizations-premium-upgrade-discount-email post-organization-premium-upgrade-discount-email" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<already_sent: bool, sent_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/premium-upgrade-discount-email")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Organization roles.
#
# GET /organizations/{organization_id}/roles
# operationId: get-organization-roles
export def "organizations-roles get-organization-roles" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-permissions: string@bool-completer # Whether roles should include permissions
]: nothing -> table<code: string, description: string, entity: string, name: string, organization_id: int, permissions: list<record>, privilege_level: int, role_id: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_permissions" $include_permissions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Organization segmentation data
#
# GET /organizations/{organization_id}/segmentation
# operationId: get-organization-segmentation
export def "organizations-segmentation get-organization-segmentation" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<demo_requested: bool, full_name: string, heard: list<string>, industries: list<string>, members_range: string, organization_id: int, reasons: list<string>, skipped_step: string, user_id: int, user_segments: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/segmentation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Organization segmentation data
#
# PUT /organizations/{organization_id}/segmentation
# operationId: put-organization-segmentation
export def "organizations-segmentation put-organization-segmentation" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<demo_requested: bool, full_name: string, heard: list<string>, industries: list<string>, members_range: string, organization_id: int, reasons: list<string>, skipped_step: string, user_id: int, user_segments: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/segmentation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscription
#
# GET /organizations/{organization_id}/subscription
# operationId: get-organization-subscription
export def "organizations-subscription get-organization-subscription" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active_users: int, auto_renew: bool, billing_period_in_months: int, campaign_available: bool, cancel_date: string, card_details: record<added_at: string, card_number: string, card_type: string, creator_id: int, creator_name: string, expiry_date: string, holder_name: string>, company_id: int, contact_details: record<company_address: string, company_city: string, company_name: string, contact_detail_id: int, contact_email: string, contact_person: string, country_id: int, country_subdivision_id: int, created_at: string, customer_id: int, is_eu_resident: bool, updated_at: string, user_id: int, vat_number: string, vat_number_valid: bool, vat_number_validated_at: string, zip_code: string>, currency: string, current_period_ends_at: string, current_period_starts_at: string, customer_id: int, end_date: string, enterprise: bool, is_subscription_beta: bool, is_unified: bool, keep_trial_on_subscription: bool, last_invoice: record<amount: int, created_at: string, currency_id: int, due: string, id: int, paid_at: string, tax_percentage: float, total_amount: int>, last_payment: record<created_at: string, description: string, id: int, status: string>, last_pricing_plan_id: int, new_signup_trial: bool, next_payment_date: string, payment_failed: bool, payment_method: string, plan_id: int, plan_name: string, pricing_plan_id: int, renewal_at: string, renewal_date: string, seat_cost_in_cents: int, seats: int, site: string, start_date: string, state: string, subscription_created_at: string, subscription_period: record<created_at: string, finished_on: string, started_on: string, subscription_id: int, subscription_period_id: int, trial: bool, user_count: int>, trial_available: bool, trial_end_date: string, trial_start_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscription
#
# PUT /organizations/{organization_id}/subscription
# operationId: put-organization-subscription
export def "organizations-subscription put-organization-subscription" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pricing-plan-tag: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription")
  let body = {pricing_plan_tag: $pricing_plan_tag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Subscription
#
# POST /organizations/{organization_id}/subscription
# operationId: post-organization-subscription
export def "organizations-subscription post-organization-subscription" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pricing-plan-tag: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription")
  let body = {pricing_plan_tag: $pricing_plan_tag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Subscription
#
# DELETE /organizations/{organization_id}/subscription
# operationId: delete-organization-subscription
export def "organizations-subscription delete-organization-subscription" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --immediateCancel: string # If true, the subscription is canceled immediately otherwise canceled at period end
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "immediateCancel" $immediateCancel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscription cancellation feedback
#
# POST /organizations/{organization_id}/subscription/cancellation_feedback
# operationId: post-organization-subscription-cancellation-feedback
export def "organizations-subscription-cancellation-feedback post-organization-subscription-cancellation-feedback" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription/cancellation_feedback")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve unified customer
#
# GET /organizations/{organization_id}/subscription/customer
# operationId: get-unified-customer
export def "organizations-subscription-customer get-unified-customer" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address_line: string, country_id: string, currency: string, customer_name: string, default_payment_method: record<card: record<brand: string, country: string, exp_month: int, exp_year: int, last4: string>, sepa_debit: record<bank_code: string, country: string, last4: string>, type: string, us_bank_account: record<bank_name: string, blocked: bool, blocked_reason: string, last4: string>>, discount: record<coupon: record<amount_off: int, deleted: bool, duration: string, duration_in_months: int, id: string, name: string, percent_off: float, valid: bool>, promotion_code: record<active: bool, code: string, expires_at: string, id: string>>, id: string, postal_code: string, site: string, state: string, tax_number: string, toggl_user_email: string, toggl_user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription/customer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update unified customer
#
# PUT /organizations/{organization_id}/subscription/customer
# operationId: put-unified-customer
export def "organizations-subscription-customer put-unified-customer" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address_line: string, country_id: string, currency: string, customer_name: string, default_payment_method: record<card: record<brand: string, country: string, exp_month: int, exp_year: int, last4: string>, sepa_debit: record<bank_code: string, country: string, last4: string>, type: string, us_bank_account: record<bank_name: string, blocked: bool, blocked_reason: string, last4: string>>, discount: record<coupon: record<amount_off: int, deleted: bool, duration: string, duration_in_months: int, id: string, name: string, percent_off: float, valid: bool>, promotion_code: record<active: bool, code: string, expires_at: string, id: string>>, id: string, postal_code: string, site: string, state: string, tax_number: string, toggl_user_email: string, toggl_user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription/customer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create unified customer
#
# POST /organizations/{organization_id}/subscription/customer
# operationId: post-unified-customer
export def "organizations-subscription-customer post-unified-customer" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address_line: string, country_id: string, currency: string, customer_name: string, default_payment_method: record<card: record<brand: string, country: string, exp_month: int, exp_year: int, last4: string>, sepa_debit: record<bank_code: string, country: string, last4: string>, type: string, us_bank_account: record<bank_name: string, blocked: bool, blocked_reason: string, last4: string>>, discount: record<coupon: record<amount_off: int, deleted: bool, duration: string, duration_in_months: int, id: string, name: string, percent_off: float, valid: bool>, promotion_code: record<active: bool, code: string, expires_at: string, id: string>>, id: string, postal_code: string, site: string, state: string, tax_number: string, toggl_user_email: string, toggl_user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription/customer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Discount request
#
# POST /organizations/{organization_id}/subscription/discount_request
# operationId: post-organization-subscription-discount-request
# --responses_submitted shape: {negative_answers: list, negative_feedback?: string, positive_answers: list, positive_feedback?: string}
export def "organizations-subscription-discount-request post-organization-subscription-discount-request" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --responses-submitted: record # shape: {negative_answers: list, negative_feedback?: string, positive_answers: list, positive_feedback?: string}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription/discount_request")
  let body = {responses_submitted: $responses_submitted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get feature upsell for multiple organizations
#
# POST /organizations/{organization_id}/subscription/feature_upsell_multi
# operationId: get-feature-upsell-multi
export def "organizations-subscription-feature-upsell-multi get-feature-upsell-multi" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription/feature_upsell_multi")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invoice Summary
#
# GET /organizations/{organization_id}/subscription/invoice_summary
# operationId: get-organization-invoice-summary
export def "organizations-subscription-invoice-summary get-organization-invoice-summary" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --quantity: int # Quantity of the subscription
  --pricing-plan-tag: string # Pricing plan tag
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quantity" $quantity "scalar") (serialize-qp "pricing_plan_tag" $pricing_plan_tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription/invoice_summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscription Payment Failed
#
# GET /organizations/{organization_id}/subscription/payment_failed
# operationId: get-organization-subscription-payment-failed
export def "organizations-subscription-payment-failed get-organization-subscription-payment-failed" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, decline_code: string, doc_url: string, invoice_total_amount: int, message: string, next_payment_attempt: string, organization_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription/payment_failed")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Applies the given promotion code to organization's customer
#
# POST /organizations/{organization_id}/subscription/promocode
# operationId: post-promotion-code
export def "organizations-subscription-promocode post-promotion-code" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription/promocode")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Removes any discount (promotion code) applied to the organization's customer
#
# DELETE /organizations/{organization_id}/subscription/promocode
# operationId: delete-promotion-code
export def "organizations-subscription-promocode delete-promotion-code" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription/promocode")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PurchaseOrderPdf
#
# GET /organizations/{organization_id}/subscription/purchase_orders/{purchase_order_uid}.pdf
# operationId: get-organization-purchase-order-pdf
export def "organizations-subscription-purchase-orders get-organization-purchase-order-pdf" [
  organization_id: int
  purchase_order_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription/purchase_orders/($purchase_order_uid).pdf")
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a setup intent for collecting customer's payment method
#
# POST /organizations/{organization_id}/subscription/setup_intent
# operationId: create-setup-intent
export def "organizations-subscription-setup-intent create-setup-intent" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription/setup_intent")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscription
#
# POST /organizations/{organization_id}/subscription/trial
# operationId: post-organization-subscription-create-trial
export def "organizations-subscription-trial post-organization-subscription-create-trial" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription/trial")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscription
#
# DELETE /organizations/{organization_id}/subscription/trial
# operationId: delete-organization-trial
export def "organizations-subscription-trial delete-organization-trial" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription/trial")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check opt-in trial eligibility
#
# GET /organizations/{organization_id}/subscription/trial/opt-in
# operationId: get-organization-subscription-trial-opt-in-eligibility
export def "organizations-subscription-trial-opt-in get-organization-subscription-trial-opt-in-eligibility" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription/trial/opt-in")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start opt-in trial
#
# POST /organizations/{organization_id}/subscription/trial/opt-in
# operationId: post-organization-subscription-trial-opt-in
export def "organizations-subscription-trial-opt-in post-organization-subscription-trial-opt-in" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription/trial/opt-in")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upgrade request for a feature
#
# POST /organizations/{organization_id}/subscription/upgrade_request/{feature_id}
# operationId: post-organization-subscription-upgrade-request
export def "organizations-subscription-upgrade-request post-organization-subscription-upgrade-request" [
  organization_id: int
  feature_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription/upgrade_request/($feature_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Endpoint for applying a usage based discount given a variant of the discount
#
# POST /organizations/{organization_id}/subscription/usage_based_discount
# operationId: post-organization-subscription-usage-based-discount
export def "organizations-subscription-usage-based-discount post-organization-subscription-usage-based-discount" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription/usage_based_discount")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Endpoint for removing a usage based discount given to organization
#
# DELETE /organizations/{organization_id}/subscription/usage_based_discount
# operationId: delete-organization-subscription-usage-based-discount
export def "organizations-subscription-usage-based-discount delete-organization-subscription-usage-based-discount" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/subscription/usage_based_discount")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Applies a discount directly to the org's active Track subscription item
#
# POST /organizations/{organization_id}/subscriptions/item/discount
# operationId: post-subscription-item-discount
export def "organizations-subscriptions-item-discount post-subscription-item-discount" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/subscriptions/item/discount")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List of users in organization
#
# GET /organizations/{organization_id}/users
# operationId: get-organization-users
export def "organizations-users get-organization-users" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # Returns records where name or email contains this string
  --active-status: string # List of `active` `inactive` `invited` comma separated(if not present, all statuses)
  --only-admins: string # If true returns admins only
  --groups: string # Comma-separated list of groups ids, returns users belonging to these groups only
  --workspaces: string # Comma-separated list of workspaces ids, returns users belonging to this workspaces only
  --page: int # Page number, default 1
  --per-page: int # Number of items per page, default 50
  --sort-dir: string # Values 'asc' or 'desc', result is sorted on 'names' column, default 'asc'
]: nothing -> table<2fa_enabled: bool, admin: bool, avatar_url: string, can_edit_email: bool, email: string, groups: list<record>, id: int, inactive: bool, invitation_id: int, joined: bool, name: string, organization_id: int, owner: bool, role_id: int, user_id: int, workspace_count: int, workspaces: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "active_status" $active_status "scalar") (serialize-qp "only_admins" $only_admins "scalar") (serialize-qp "groups" $groups "scalar") (serialize-qp "workspaces" $workspaces "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_dir" $sort_dir "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Apply changes in bulk to users in an organization
#
# PATCH /organizations/{organization_id}/users
# operationId: patch-organization-users
export def "organizations-users patch-organization-users" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete: list # Organization user IDs to be deleted
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/users")
  let body = {delete: $delete} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List of users in organization with details
#
# GET /organizations/{organization_id}/users/detailed
# operationId: get-organization-users-detailed
export def "organizations-users-detailed get-organization-users-detailed" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # Returns records where name or email contains this string
  --active-status: string # List of `active` `inactive` `invited` comma separated(if not present, all statuses)
  --only-admins: string # If true returns admins only
  --groups: string # Comma-separated list of groups ids, returns users belonging to these groups only
  --workspaces: string # Comma-separated list of workspaces ids, returns users belonging to this workspaces only
  --page: int # Page number, default 1
  --per-page: int # Number of items per page, default 50
  --sort-dir: string # Values 'asc' or 'desc', result is sorted on 'names' column, default 'asc'
]: nothing -> table<2fa_enabled: bool, admin: bool, avatar_url: string, can_edit_email: bool, email: string, groups: list<record>, id: int, inactive: bool, invitation_id: int, joined: bool, name: string, organization_id: int, owner: bool, role_id: int, user_id: int, workspace_count: int, workspaces: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "active_status" $active_status "scalar") (serialize-qp "only_admins" $only_admins "scalar") (serialize-qp "groups" $groups "scalar") (serialize-qp "workspaces" $workspaces "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_dir" $sort_dir "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/users/detailed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Leaves organization
#
# DELETE /organizations/{organization_id}/users/leave
# operationId: delete-organization-users-leave
export def "organizations-users-leave delete-organization-users-leave" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/users/leave")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Changes a single organization-user
#
# PUT /organizations/{organization_id}/users/{organization_user_id}
# operationId: put-organization-users
# --workspaces item shape: {active?: bool, admin?: bool, cost?: float, default_currency?: string, groups?: list, inactive?: bool, rate?: float, role?: string, role_id?: int, view_edit_billable_rates?: bool, view_edit_labor_costs?: bool, working_hours?: float, workspace_id?: int, workspace_name?: string, workspace_user_id?: int}
export def "organizations-users put-organization-users" [
  organization_id: int
  organization_user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string
  --groups: list
  --inactive: string@bool-completer
  --name: string
  --organization-admin: string@bool-completer
  --role-id: int
  --workspaces: list # item shape: {active?: bool, admin?: bool, cost?: float, default_currency?: string, groups?: list, inactive?: bool, rate?: float, role?: string, role_id?: int, view_edit_billable_rates?: bool, view_edit_labor_costs?: bool, working_hours?: float, workspace_id?: int, workspace_name?: string, workspace_user_id?: int}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/users/($organization_user_id)")
  let body = {email: $email, groups: $groups, inactive: $inactive, name: $name, organization_admin: $organization_admin, role_id: $role_id, workspaces: $workspaces} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new workspace.
#
# POST /organizations/{organization_id}/workspaces
# operationId: post-organization-workspaces
export def "organizations-workspaces post-organization-workspaces" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --admins: list # List of admins, optional
  --default-currency: string # Default currency, premium feature, optional, only for existing WS, will be 'USD' initially
  --default-hourly-rate: float # The default hourly rate, premium feature, optional, only for existing WS, will be 0.0 initially
  --initial-pricing-plan: int # The subscription plan for the workspace, deprecated
  --limit-public-project-data: string@bool-completer # Whether the workspace limits public projects data in reports to admins.
  --name: string # Workspace name
  --only-admins-may-create-projects: string@bool-completer # Only admins will be able to create projects, optional, only for existing WS, will be false initially
  --only-admins-may-create-tags: string@bool-completer # Only admins will be able to create tags, optional, only for existing WS, will be false initially
  --only-admins-see-team-dashboard: string@bool-completer # Only admins will be able to see the team dashboard, optional, only for existing WS, will be false initially
  --projects-billable-by-default: string@bool-completer # Whether projects will be set as billable by default, premium feature, optional, only for existing WS. Will be true initially
  --projects-enforce-billable: string@bool-completer # Whether tracking time to projects will enforce billable setting to be respected.
  --projects-private-by-default: string@bool-completer # Whether projects will be set to private by default, optional. Will be true initially.
  --rate-change-mode: string # The rate change mode, premium feature, optional, only for existing WS. Can be "start-today", "override-current", "override-all"
  --reports-collapse: string@bool-completer # Whether reports should be collapsed by default, optional, only for existing WS, will be true initially
  --rounding: int # Default rounding, premium feature, optional, only for existing WS
  --rounding-minutes: int # Default rounding in minutes, premium feature, optional, only for existing WS
]: any -> record<admin: bool, api_token: string, at: string, business_ws: bool, csv_upload: record<at: string, log_id: int>, default_currency: string, default_hourly_rate: float, disable_approvals: bool, disable_expenses: bool, disable_timesheet_view: bool, hide_start_end_times: bool, ical_enabled: bool, ical_url: string, id: int, last_modified: string, limit_public_project_data: bool, logo_url: string, max_data_retention_days: record, name: string, only_admins_may_create_projects: bool, only_admins_may_create_tags: bool, only_admins_see_team_dashboard: bool, organization_id: int, permissions: list<string>, premium: bool, projects_billable_by_default: bool, projects_enforce_billable: bool, projects_private_by_default: bool, rate_last_updated: string, reports_collapse: bool, role: string, rounding: int, rounding_minutes: int, subscription: record<auto_renew: bool, card_details: record<added_at: string, card_number: string, card_type: string, creator_id: int, creator_name: string, expiry_date: string, holder_name: string>, company_id: int, contact_detail: record<company_address: string, company_city: string, company_name: string, contact_detail_id: int, contact_email: string, contact_person: string, country_id: int, country_subdivision_id: int, created_at: string, customer_id: int, is_eu_resident: bool, updated_at: string, user_id: int, vat_number: string, vat_number_valid: bool, vat_number_validated_at: string, zip_code: string>, created_at: string, currency: string, customer_id: int, deleted_at: string, last_pricing_plan_id: int, organization_id: int, payment_details: record<created_at: string, currency: string, customer_id: int, payment_type: string, reference: string, user_id: int>, pricing_plan_id: int, renewal_at: string, subscription_id: int, subscription_period: record<created_at: string, finished_on: string, started_on: string, subscription_id: int, subscription_period_id: int, trial: bool, user_count: int>, workspace_id: int>, suspended_at: string, te_constraints: record<description_present: bool, max_tags: int, project_present: bool, tag_present: bool, task_present: bool, time_entry_constraints_enabled: bool>, working_hours_in_minutes: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/workspaces")
  let body = {admins: $admins, default_currency: $default_currency, default_hourly_rate: $default_hourly_rate, initial_pricing_plan: $initial_pricing_plan, limit_public_project_data: $limit_public_project_data, name: $name, only_admins_may_create_projects: $only_admins_may_create_projects, only_admins_may_create_tags: $only_admins_may_create_tags, only_admins_see_team_dashboard: $only_admins_see_team_dashboard, projects_billable_by_default: $projects_billable_by_default, projects_enforce_billable: $projects_enforce_billable, projects_private_by_default: $projects_private_by_default, rate_change_mode: $rate_change_mode, reports_collapse: $reports_collapse, rounding: $rounding, rounding_minutes: $rounding_minutes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Statistics for all workspaces in the organization
#
# GET /organizations/{organization_id}/workspaces/statistics
# operationId: get-organization-workspaces-statistics
export def "organizations-workspaces-statistics get-organization-workspaces-statistics" [
  organization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/workspaces/statistics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List of groups in a workspace within an organization with user assignments.
#
# GET /organizations/{organization_id}/workspaces/{workspace_id}/groups
# operationId: get-organization-workspaces-groups
export def "organizations-workspaces-groups get-organization-workspaces-groups" [
  organization_id: int
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<at: string, group_id: int, name: string, permissions: list<string>, users: list<record>, workspaces: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/workspaces/($workspace_id)/groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List of users who belong to the given workspace.
#
# GET /organizations/{organization_id}/workspaces/{workspace_id}/workspace_users
# operationId: get-organization-workspaces-workspaceusers
export def "organizations-workspaces-workspace-users get-organization-workspaces-workspaceusers" [
  organization_id: int
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number
  --per-page: int # Number of items per page
  --custom-rates: string@bool-completer # Returns only users with or without a custom hourly rate respectively
  --active: string@bool-completer # Returns only active users
  name: string # Workspace user name to filter by
  search: string # Workspace filter by name or email
]: any -> table<2fa_enabled: bool, active: bool, admin: bool, at: string, avatar_file_name: string, email: string, group_ids: list<int>, id: int, inactive: bool, invitation_code: string, invite_url: string, is_direct: bool, labor_cost: float, labor_cost_last_updated: string, name: string, organization_admin: bool, rate: float, rate_last_updated: string, role: string, role_id: int, timezone: string, uid: int, user_id: int, view_edit_billable_rates: bool, view_edit_labor_costs: bool, wid: int, working_hours_in_minutes: int, workspace_admin: bool, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "custom_rates" $custom_rates "scalar") (serialize-qp "active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization_id)/workspaces/($workspace_id)/workspace_users" $qp)
  let body = {name: $name, search: $search} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Changes the users in a workspace.
#
# PATCH /organizations/{organization_id}/workspaces/{workspace_id}/workspace_users
# operationId: patch-organization-workspace-users
export def "organizations-workspaces-workspace-users patch-organization-workspace-users" [
  organization_id: int
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete: list # Workspace user IDs to be deleted
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization_id)/workspaces/($workspace_id)/workspace_users")
  let body = {delete: $delete} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send an email to a contact
#
# POST /smail/contact
# operationId: post-smail-contact
export def "smail-contact post-smail-contact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Email: string
  --Message: string
  --Name: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/smail/contact")
  let body = {Email: $Email, Message: $Message, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send an email for a demo
#
# POST /smail/demo
# operationId: post-smail-demo
export def "smail-demo post-smail-demo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Email: string
  --FirstName: string
  --LastName: string
  --Phone: string
  --Purpose: string
  --Source: string
  --TeamSize: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/smail/demo")
  let body = {Email: $Email, FirstName: $FirstName, LastName: $LastName, Phone: $Phone, Purpose: $Purpose, Source: $Source, TeamSize: $TeamSize} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send an email for meet
#
# POST /smail/meet
# operationId: post-smail-meet
export def "smail-meet post-smail-meet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string
  --location: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/smail/meet")
  let body = {email: $email, location: $location} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Status
#
# GET /status
# operationId: get-status
export def "status get-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all available plans and features.
#
# GET /subscriptions/plans
# operationId: get-all-plans
export def "subscriptions-plans get-all-plans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<table<active_at: string, features: list, inactive_at: string, max_user_count: int, name: string, plan_at: string, plan_id: int, prices: list, product_handle: string, toggl_product_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscriptions/plans")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of user goals
#
# GET /sync-server/me/goals
export def "sync-server-me-goals get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # archived goals
]: nothing -> table<active: bool, billable: bool, comparison: string, creator_user_id: int, creator_user_name: string, current_recurrence_end_date: string, current_recurrence_start_date: string, current_recurrence_tracked_seconds: int, end_date: string, goal_id: int, icon: string, last_completed_recurrence_end_date: string, last_notified_at: string, name: string, permissions: list<string>, project_ids: list<int>, recurrence: string, start_date: string, status: string, streak: int, tag_ids: list<int>, tags: list<string>, target_seconds: int, task_ids: list<int>, team_goal: bool, user_id: int, user_name: string, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sync-server/me/goals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get timeline events
#
# GET /timeline
export def "timeline get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: int # Unix timestamp of the start date
  --end-date: int # Unix timestamp of the end date
]: nothing -> table<desktop_id: string, end_time: int, filename: string, id: int, idle: bool, start_time: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timeline" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Save timeline events
#
# POST /timeline
export def "timeline post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<record_timeline: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/timeline")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete all timeline data
#
# DELETE /timeline
export def "timeline delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/timeline")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Timezones
#
# GET /timezones
# operationId: get-timezones
export def "timezones get-timezones" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/timezones")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Offsets
#
# GET /timezones/offsets
# operationId: get-offsets
export def "timezones-offsets get-offsets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<name: string, utc: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/timezones/offsets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Public Subscription Plans
#
# GET /workspaces/plans
# operationId: get-public-subscription-plans
export def "workspaces-plans get-public-subscription-plans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<name: string, plan_id: int, pricing_plans: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/workspaces/plans")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get single workspace
#
# GET /workspaces/{workspace_id}
# operationId: get-workspace
export def "workspaces get-workspace" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<admin: bool, api_token: string, at: string, business_ws: bool, csv_upload: record<at: string, log_id: int>, default_currency: string, default_hourly_rate: float, disable_approvals: bool, disable_expenses: bool, disable_timesheet_view: bool, hide_start_end_times: bool, ical_enabled: bool, ical_url: string, id: int, last_modified: string, limit_public_project_data: bool, logo_url: string, max_data_retention_days: record, name: string, only_admins_may_create_projects: bool, only_admins_may_create_tags: bool, only_admins_see_team_dashboard: bool, organization_id: int, permissions: list<string>, premium: bool, projects_billable_by_default: bool, projects_enforce_billable: bool, projects_private_by_default: bool, rate_last_updated: string, reports_collapse: bool, role: string, rounding: int, rounding_minutes: int, subscription: record<auto_renew: bool, card_details: record<added_at: string, card_number: string, card_type: string, creator_id: int, creator_name: string, expiry_date: string, holder_name: string>, company_id: int, contact_detail: record<company_address: string, company_city: string, company_name: string, contact_detail_id: int, contact_email: string, contact_person: string, country_id: int, country_subdivision_id: int, created_at: string, customer_id: int, is_eu_resident: bool, updated_at: string, user_id: int, vat_number: string, vat_number_valid: bool, vat_number_validated_at: string, zip_code: string>, created_at: string, currency: string, customer_id: int, deleted_at: string, last_pricing_plan_id: int, organization_id: int, payment_details: record<created_at: string, currency: string, customer_id: int, payment_type: string, reference: string, user_id: int>, pricing_plan_id: int, renewal_at: string, subscription_id: int, subscription_period: record<created_at: string, finished_on: string, started_on: string, subscription_id: int, subscription_period_id: int, trial: bool, user_count: int>, workspace_id: int>, suspended_at: string, te_constraints: record<description_present: bool, max_tags: int, project_present: bool, tag_present: bool, task_present: bool, time_entry_constraints_enabled: bool>, working_hours_in_minutes: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update workspace
#
# PUT /workspaces/{workspace_id}
# operationId: put-workspaces
export def "workspaces put-workspaces" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --admins: list # List of admins, optional
  --default-currency: string # Default currency, premium feature, optional, only for existing WS, will be 'USD' initially
  --default-hourly-rate: float # The default hourly rate, premium feature, optional, only for existing WS, will be 0.0 initially
  --initial-pricing-plan: int # The subscription plan for the workspace, deprecated
  --limit-public-project-data: string@bool-completer # Whether the workspace limits public projects data in reports to admins.
  --name: string # Workspace name
  --only-admins-may-create-projects: string@bool-completer # Only admins will be able to create projects, optional, only for existing WS, will be false initially
  --only-admins-may-create-tags: string@bool-completer # Only admins will be able to create tags, optional, only for existing WS, will be false initially
  --only-admins-see-team-dashboard: string@bool-completer # Only admins will be able to see the team dashboard, optional, only for existing WS, will be false initially
  --projects-billable-by-default: string@bool-completer # Whether projects will be set as billable by default, premium feature, optional, only for existing WS. Will be true initially
  --projects-enforce-billable: string@bool-completer # Whether tracking time to projects will enforce billable setting to be respected.
  --projects-private-by-default: string@bool-completer # Whether projects will be set to private by default, optional. Will be true initially.
  --rate-change-mode: string # The rate change mode, premium feature, optional, only for existing WS. Can be "start-today", "override-current", "override-all"
  --reports-collapse: string@bool-completer # Whether reports should be collapsed by default, optional, only for existing WS, will be true initially
  --rounding: int # Default rounding, premium feature, optional, only for existing WS
  --rounding-minutes: int # Default rounding in minutes, premium feature, optional, only for existing WS
]: any -> record<admin: bool, api_token: string, at: string, business_ws: bool, csv_upload: record<at: string, log_id: int>, default_currency: string, default_hourly_rate: float, disable_approvals: bool, disable_expenses: bool, disable_timesheet_view: bool, hide_start_end_times: bool, ical_enabled: bool, ical_url: string, id: int, last_modified: string, limit_public_project_data: bool, logo_url: string, max_data_retention_days: record, name: string, only_admins_may_create_projects: bool, only_admins_may_create_tags: bool, only_admins_see_team_dashboard: bool, organization_id: int, permissions: list<string>, premium: bool, projects_billable_by_default: bool, projects_enforce_billable: bool, projects_private_by_default: bool, rate_last_updated: string, reports_collapse: bool, role: string, rounding: int, rounding_minutes: int, subscription: record<auto_renew: bool, card_details: record<added_at: string, card_number: string, card_type: string, creator_id: int, creator_name: string, expiry_date: string, holder_name: string>, company_id: int, contact_detail: record<company_address: string, company_city: string, company_name: string, contact_detail_id: int, contact_email: string, contact_person: string, country_id: int, country_subdivision_id: int, created_at: string, customer_id: int, is_eu_resident: bool, updated_at: string, user_id: int, vat_number: string, vat_number_valid: bool, vat_number_validated_at: string, zip_code: string>, created_at: string, currency: string, customer_id: int, deleted_at: string, last_pricing_plan_id: int, organization_id: int, payment_details: record<created_at: string, currency: string, customer_id: int, payment_type: string, reference: string, user_id: int>, pricing_plan_id: int, renewal_at: string, subscription_id: int, subscription_period: record<created_at: string, finished_on: string, started_on: string, subscription_id: int, subscription_period_id: int, trial: bool, user_count: int>, workspace_id: int>, suspended_at: string, te_constraints: record<description_present: bool, max_tags: int, project_present: bool, tag_present: bool, task_present: bool, time_entry_constraints_enabled: bool>, working_hours_in_minutes: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)")
  let body = {admins: $admins, default_currency: $default_currency, default_hourly_rate: $default_hourly_rate, initial_pricing_plan: $initial_pricing_plan, limit_public_project_data: $limit_public_project_data, name: $name, only_admins_may_create_projects: $only_admins_may_create_projects, only_admins_may_create_tags: $only_admins_may_create_tags, only_admins_see_team_dashboard: $only_admins_see_team_dashboard, projects_billable_by_default: $projects_billable_by_default, projects_enforce_billable: $projects_enforce_billable, projects_private_by_default: $projects_private_by_default, rate_change_mode: $rate_change_mode, reports_collapse: $reports_collapse, rounding: $rounding, rounding_minutes: $rounding_minutes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Alerts
#
# GET /workspaces/{workspace_id}/alerts
# operationId: get-alerts
export def "workspaces-alerts get-alerts" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<billable: bool, client_id: int, client_name: string, errors: list<record>, estimatedHours: int, id: int, isFixedFee: bool, isPrivate: bool, object_type: int, project_color: string, project_id: int, project_name: string, receiver_groups: list<int>, receiver_roles: list<string>, receiver_users: list<int>, receiver_users_name: list<string>, receivers: int, source_kind: string, threshold: int, threshold_type: string, thresholds: list<int>, wid: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/alerts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Alerts
#
# POST /workspaces/{workspace_id}/alerts
# operationId: post-alerts
export def "workspaces-alerts post-alerts" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project-id: int
  --receiver-roles: list
  --receiver-users: list
  --source-kind: string
  --threshold-type: string
  --thresholds: list
]: any -> record<billable: bool, client_id: int, client_name: string, errors: table<code: string, message: string>, estimatedHours: int, id: int, isFixedFee: bool, isPrivate: bool, object_type: int, project_color: string, project_id: int, project_name: string, receiver_groups: list<int>, receiver_roles: list<string>, receiver_users: list<int>, receiver_users_name: list<string>, receivers: int, source_kind: string, threshold: int, threshold_type: string, thresholds: list<int>, wid: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/alerts")
  let body = {project_id: $project_id, receiver_roles: $receiver_roles, receiver_users: $receiver_users, source_kind: $source_kind, threshold_type: $threshold_type, thresholds: $thresholds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Alerts
#
# PUT /workspaces/{workspace_id}/alerts/{alert_id}
# operationId: put-alerts
export def "workspaces-alerts put-alerts" [
  workspace_id: int
  alert_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project-id: int
  --receiver-roles: list
  --receiver-users: list
  --source-kind: string
  --threshold-type: string
  --thresholds: list
]: any -> record<billable: bool, client_id: int, client_name: string, errors: table<code: string, message: string>, estimatedHours: int, id: int, isFixedFee: bool, isPrivate: bool, object_type: int, project_color: string, project_id: int, project_name: string, receiver_groups: list<int>, receiver_roles: list<string>, receiver_users: list<int>, receiver_users_name: list<string>, receivers: int, source_kind: string, threshold: int, threshold_type: string, thresholds: list<int>, wid: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/alerts/($alert_id)")
  let body = {project_id: $project_id, receiver_roles: $receiver_roles, receiver_users: $receiver_users, source_kind: $source_kind, threshold_type: $threshold_type, thresholds: $thresholds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Alerts
#
# DELETE /workspaces/{workspace_id}/alerts/{alert_id}
# operationId: delete-alerts
export def "workspaces-alerts delete-alerts" [
  workspace_id: int
  alert_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/alerts/($alert_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List clients
#
# GET /workspaces/{workspace_id}/clients
# operationId: get-workspace-clients
export def "workspaces-clients get-workspace-clients" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string # Use 'active' to only list active clients, 'archived' to only list archived clients and 'both' to retrieve active and archived clients. If not provided, only active clients are returned.
  --name: string # If provided, allows to filter by client name in a case insensitive manner, returning all the ones that contain the given string.
]: nothing -> table<archived: bool, at: string, creator_id: int, external_reference: string, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, name: string, notes: string, permissions: list<string>, total_count: int, wid: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/clients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create client
#
# POST /workspaces/{workspace_id}/clients
# operationId: post-workspace-clients
export def "workspaces-clients post-workspace-clients" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --external-reference: string
  --name: string # Client name
  --notes: string
]: any -> record<archived: bool, at: string, creator_id: int, external_reference: string, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, name: string, notes: string, permissions: list<string>, total_count: int, wid: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/clients")
  let body = {external_reference: $external_reference, name: $name, notes: $notes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archives one or more clients in bulk
#
# POST /workspaces/{workspace_id}/clients/archive
# operationId: archive-clients
export def "workspaces-clients-archive archive-clients" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<client_ids: list<int>, project_ids: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/clients/archive")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List clients for given client_ids
#
# POST /workspaces/{workspace_id}/clients/data
# operationId: get-workspace-clients-data
export def "workspaces-clients-data get-workspace-clients-data" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<archived: bool, at: string, creator_id: int, external_reference: string, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, name: string, notes: string, permissions: list<string>, total_count: int, wid: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/clients/data")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete clients
#
# POST /workspaces/{workspace_id}/clients/delete
# operationId: delete-workspace-clients
export def "workspaces-clients-delete delete-workspace-clients" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/clients/delete")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Load client from ID
#
# GET /workspaces/{workspace_id}/clients/{client_id}
# operationId: get-workspace-client
export def "workspaces-clients get-workspace-client" [
  workspace_id: int
  client_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<archived: bool, at: string, creator_id: int, external_reference: string, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, name: string, notes: string, permissions: list<string>, total_count: int, wid: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/clients/($client_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change client
#
# PUT /workspaces/{workspace_id}/clients/{client_id}
# operationId: put-workspace-clients
export def "workspaces-clients put-workspace-clients" [
  workspace_id: int
  client_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --external-reference: string
  --name: string # Client name
  --notes: string
]: any -> record<archived: bool, at: string, creator_id: int, external_reference: string, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, name: string, notes: string, permissions: list<string>, total_count: int, wid: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/clients/($client_id)")
  let body = {external_reference: $external_reference, name: $name, notes: $notes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete client
#
# DELETE /workspaces/{workspace_id}/clients/{client_id}
# operationId: delete-workspace-client
export def "workspaces-clients delete-workspace-client" [
  workspace_id: int
  client_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> float {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/clients/($client_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archives client
#
# POST /workspaces/{workspace_id}/clients/{client_id}/archive
# operationId: archive-client
export def "workspaces-clients-archive archive-client" [
  workspace_id: int
  client_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/clients/($client_id)/archive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restores client and related projects.
#
# POST /workspaces/{workspace_id}/clients/{client_id}/restore
# operationId: restore-client
export def "workspaces-clients-restore restore-client" [
  workspace_id: int
  client_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projects: list
  --restore-all-projects: string@bool-completer
]: any -> record<archived: bool, at: string, creator_id: int, external_reference: string, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, name: string, notes: string, permissions: list<string>, total_count: int, wid: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/clients/($client_id)/restore")
  let body = {projects: $projects, restore_all_projects: $restore_all_projects} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get workspace currencies
#
# GET /workspaces/{workspace_id}/currencies
# operationId: get-workspace-currencies
export def "workspaces-currencies get-workspace-currencies" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/currencies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get last activity for every workspace user
#
# GET /workspaces/{workspace_id}/dashboard/all_activity
# operationId: get-workspace-all-activities
export def "workspaces-dashboard-all-activity get-workspace-all-activities" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: int # Filter activities since this date using UNIX timestamp.
]: any -> table<description: string, duration: int, project_id: int, stop: string, tid: int, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/dashboard/all_activity")
  let body = {since: $since} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get most active users
#
# GET /workspaces/{workspace_id}/dashboard/most_active
# operationId: get-workspace-most-active
export def "workspaces-dashboard-most-active get-workspace-most-active" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: int # Filter activities since this date using UNIX timestamp.
]: any -> table<avatar_file_name: string, duration: int, email: string, fullname: string, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/dashboard/most_active")
  let body = {since: $since} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get top activities
#
# GET /workspaces/{workspace_id}/dashboard/top_activity
# operationId: get-workspace-top-activity
export def "workspaces-dashboard-top-activity get-workspace-top-activity" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: int # Filter activities since this date using UNIX timestamp.
]: any -> table<description: string, duration: int, project_id: int, stop: string, tid: int, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/dashboard/top_activity")
  let body = {since: $since} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get work expenses
#
# GET /workspaces/{workspace_id}/expenses
# operationId: get-expense
export def "workspaces-expenses get-expense" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<approved_at: string, approved_by: int, category: string, chat_gpt_output: string, comment: string, created_at: string, currency: string, date_of_expense: string, deleted_at: string, description: string, download_url: string, exchange_rate: float, exchange_rate_timestamp: string, id: int, ocr_output: string, original_description: string, original_receipt_location: string, receipt_location: string, receipt_mime_type: string, receipt_no: string, rejection_reason: string, service_provider: string, service_provider_address: string, service_provider_country: string, state: string, tax_amount: int, tax_amount_converted: int, timezone: string, total_amount: int, total_amount_converted: int, trip_id: int, update_reason: string, updated_at: string, updated_by: int, user_id: int, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/expenses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a work expense
#
# POST /workspaces/{workspace_id}/expenses/upload
# operationId: post-expense
export def "workspaces-expenses-upload post-expense" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: path # Expense file.
]: any -> record<approved_at: string, approved_by: int, category: string, chat_gpt_output: string, comment: string, created_at: string, currency: string, date_of_expense: string, deleted_at: string, description: string, download_url: string, exchange_rate: float, exchange_rate_timestamp: string, id: int, ocr_output: string, original_description: string, original_receipt_location: string, receipt_location: string, receipt_mime_type: string, receipt_no: string, rejection_reason: string, service_provider: string, service_provider_address: string, service_provider_country: string, state: string, tax_amount: int, tax_amount_converted: int, timezone: string, total_amount: int, total_amount_converted: int, trip_id: int, update_reason: string, updated_at: string, updated_by: int, user_id: int, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/expenses/upload")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($file | is-not-empty) { $body | upsert file (open -r $file) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get a list with the workspace download requests
#
# GET /workspaces/{workspace_id}/exports
# operationId: get-workspace-exports
export def "workspaces-exports get-workspace-exports" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<error_message: string, state: string, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/exports")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Post a list with the workspace to be downloaded
#
# POST /workspaces/{workspace_id}/exports
# operationId: post-workspace-exports
export def "workspaces-exports post-workspace-exports" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/exports")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the zip file with workspace download requests
#
# GET /workspaces/{workspace_id}/exports/data/{uuid}.zip
# operationId: get-workspace-exports-data-uuid-zip
export def "workspaces-exports-data get-workspace-exports-data-uuid-zip" [
  workspace_id: int
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/exports/data/($uuid).zip")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of favorites
#
# GET /workspaces/{workspace_id}/favorites
# operationId: get-workspace-favorites
export def "workspaces-favorites get-workspace-favorites" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: int # Retrieve favorites created/deleted since this date using UNIX timestamp.
]: any -> table<billable: bool, client_name: string, created_at: string, deleted_at: string, description: string, favorite_id: int, permissions: list<string>, project_active: bool, project_billable: bool, project_color: string, project_id: int, project_name: string, project_private: bool, public: bool, rank: int, tag_ids: list<int>, tags: list<string>, task_id: int, task_name: string, user_id: int, was_public_at: string, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/favorites")
  let body = {since: $since} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update an array of favorites
#
# PUT /workspaces/{workspace_id}/favorites
# operationId: update-workspace-favorite
export def "workspaces-favorites update-workspace-favorite" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --meta: string@bool-completer # Should the response contain data for meta entities
  --billable: string@bool-completer
  --description: string
  --favorite-id: int
  --postedFields: list
  --project-id: int
  --public: string@bool-completer
  --rank: int
  --tag-ids: list
  --task-id: int
]: any -> record<billable: bool, client_name: string, created_at: string, deleted_at: string, description: string, favorite_id: int, permissions: list<string>, project_active: bool, project_billable: bool, project_color: string, project_id: int, project_name: string, project_private: bool, public: bool, rank: int, tag_ids: list<int>, tags: list<string>, task_id: int, task_name: string, user_id: int, was_public_at: string, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "meta" $meta "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/favorites" $qp)
  let body = {billable: $billable, description: $description, favorite_id: $favorite_id, postedFields: $postedFields, project_id: $project_id, public: $public, rank: $rank, tag_ids: $tag_ids, task_id: $task_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a favorite
#
# POST /workspaces/{workspace_id}/favorites
# operationId: create-workspace-favorite
export def "workspaces-favorites create-workspace-favorite" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --meta: string@bool-completer # Should the response contain data for meta entities
  --billable: string@bool-completer
  --description: string
  --project-id: int
  --public: string@bool-completer
  --rank: int
  --tag-ids: list
  --task-id: int
]: any -> record<billable: bool, client_name: string, created_at: string, deleted_at: string, description: string, favorite_id: int, permissions: list<string>, project_active: bool, project_billable: bool, project_color: string, project_id: int, project_name: string, project_private: bool, public: bool, rank: int, tag_ids: list<int>, tags: list<string>, task_id: int, task_name: string, user_id: int, was_public_at: string, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "meta" $meta "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/favorites" $qp)
  let body = {billable: $billable, description: $description, project_id: $project_id, public: $public, rank: $rank, tag_ids: $tag_ids, task_id: $task_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generates and returns a list of suggested favorites.
#
# POST /workspaces/{workspace_id}/favorites/suggestions
# operationId: post-workspace-favorites-suggestions
export def "workspaces-favorites-suggestions post-workspace-favorites-suggestions" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<billable: bool, client_name: string, created_at: string, deleted_at: string, description: string, favorite_id: int, permissions: list<string>, project_active: bool, project_billable: bool, project_color: string, project_id: int, project_name: string, project_private: bool, public: bool, rank: int, tag_ids: list<int>, tags: list<string>, task_id: int, task_name: string, user_id: int, was_public_at: string, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/favorites/suggestions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a given favorite
#
# DELETE /workspaces/{workspace_id}/favorites/{favorite_id}
# operationId: workspace-delete-favorite
export def "workspaces-favorites workspace-delete-favorite" [
  workspace_id: int
  favorite_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/favorites/($favorite_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of goals
#
# GET /workspaces/{workspace_id}/goals
export def "workspaces-goals list" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-goals: string@bool-completer # team goals
  --active: string@bool-completer # archived goals
  --page: int # Page number, default 1.
  --per-page: int # Number of items per page, default 20. Also defaults to 100 if provided a value greater than 100.
]: nothing -> table<active: bool, billable: bool, comparison: string, creator_user_id: int, creator_user_name: string, current_recurrence_end_date: string, current_recurrence_start_date: string, current_recurrence_tracked_seconds: int, end_date: string, goal_id: int, icon: string, last_completed_recurrence_end_date: string, last_notified_at: string, name: string, permissions: list<string>, project_ids: list<int>, recurrence: string, start_date: string, status: string, streak: int, tag_ids: list<int>, tags: list<string>, target_seconds: int, task_ids: list<int>, team_goal: bool, user_id: int, user_name: string, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_goals" $team_goals "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/goals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Goal
#
# POST /workspaces/{workspace_id}/goals
export def "workspaces-goals post" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --billable: string@bool-completer
  --comparison: string
  --end-date: string
  --icon: string
  --name: string
  --project-ids: list
  --recurrence: string
  --start-date: string
  --tag-ids: list
  --target-seconds: int
  --task-ids: list
  --user-id: int
]: any -> record<active: bool, billable: bool, comparison: string, creatorUserID: int, creatorUserName: string, currentRecurrenceEndDate: string, currentRecurrenceStartDate: string, currentRecurrenceTrackedSeconds: int, deletedAt: string, endDate: string, icon: string, id: int, lastCompletedRecurrenceEndDate: string, lastNotifiedAt: string, name: string, permissions: list<string>, previousStreak: int, projectIDs: list<int>, recurrence: string, startDate: string, status: string, streak: int, streakConsolidatedAt: string, tagIDs: list<int>, tags: list<string>, targetSeconds: int, taskIDs: list<int>, teamGoal: bool, userID: int, userName: string, workspaceID: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/goals")
  let body = {billable: $billable, comparison: $comparison, end_date: $end_date, icon: $icon, name: $name, project_ids: $project_ids, recurrence: $recurrence, start_date: $start_date, tag_ids: $tag_ids, target_seconds: $target_seconds, task_ids: $task_ids, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get one goal
#
# GET /workspaces/{workspace_id}/goals/{goal_id}
export def "workspaces-goals get" [
  workspace_id: int
  goal_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active: bool, billable: bool, comparison: string, creator_user_id: int, creator_user_name: string, current_recurrence_end_date: string, current_recurrence_start_date: string, current_recurrence_tracked_seconds: int, end_date: string, goal_id: int, icon: string, last_completed_recurrence_end_date: string, last_notified_at: string, name: string, permissions: list<string>, project_ids: list<int>, recurrence: string, start_date: string, status: string, streak: int, tag_ids: list<int>, tags: list<string>, target_seconds: int, task_ids: list<int>, team_goal: bool, user_id: int, user_name: string, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/goals/($goal_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Goal
#
# PUT /workspaces/{workspace_id}/goals/{goal_id}
export def "workspaces-goals put" [
  workspace_id: int
  goal_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer
  --comparison: string
  --end-date: string
  --icon: string
  --last-notified-at: string
  --name: string
  --target-seconds: int
]: any -> record<active: bool, billable: bool, comparison: string, creatorUserID: int, creatorUserName: string, currentRecurrenceEndDate: string, currentRecurrenceStartDate: string, currentRecurrenceTrackedSeconds: int, deletedAt: string, endDate: string, icon: string, id: int, lastCompletedRecurrenceEndDate: string, lastNotifiedAt: string, name: string, permissions: list<string>, previousStreak: int, projectIDs: list<int>, recurrence: string, startDate: string, status: string, streak: int, streakConsolidatedAt: string, tagIDs: list<int>, tags: list<string>, targetSeconds: int, taskIDs: list<int>, teamGoal: bool, userID: int, userName: string, workspaceID: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/goals/($goal_id)")
  let body = {active: $active, comparison: $comparison, end_date: $end_date, icon: $icon, last_notified_at: $last_notified_at, name: $name, target_seconds: $target_seconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete one goal
#
# DELETE /workspaces/{workspace_id}/goals/{goal_id}
export def "workspaces-goals delete" [
  workspace_id: int
  goal_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/goals/($goal_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get workspace groups
#
# GET /workspaces/{workspace_id}/groups
# DEPRECATED
# operationId: get-workspace-groups
@deprecated
export def "workspaces-groups get-workspace-groups" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<at: string, has_users: bool, id: int, name: string, permissions: list<string>, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create group
#
# POST /workspaces/{workspace_id}/groups
# operationId: post-workspace-group
export def "workspaces-groups post-workspace-group" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
]: any -> record<at: string, has_users: bool, id: int, name: string, permissions: list<string>, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/groups")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update group
#
# PUT /workspaces/{workspace_id}/groups/{group_id}
# operationId: put-workspace-group
export def "workspaces-groups put-workspace-group" [
  workspace_id: int
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
]: any -> record<at: string, has_users: bool, id: int, name: string, permissions: list<string>, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/groups/($group_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete group
#
# DELETE /workspaces/{workspace_id}/groups/{group_id}
# operationId: delete-workspace-group
export def "workspaces-groups delete-workspace-group" [
  workspace_id: int
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset iCal token
#
# POST /workspaces/{workspace_id}/ical/reset
# operationId: post-workspace-ical-reset
export def "workspaces-ical-reset post-workspace-ical-reset" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/ical/reset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Toggle the iCal token
#
# POST /workspaces/{workspace_id}/ical/toggle
# operationId: post-workspace-ical-toggle
export def "workspaces-ical-toggle post-workspace-ical-toggle" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/ical/toggle")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get workspace invoices.
#
# GET /workspaces/{workspace_id}/invoices
# operationId: get-workspace-invoices
export def "workspaces-invoices get-workspace-invoices" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-order: string # Sort order, default ASC.
  --per-page: int # Number of items per page, default 50.
  --page: int # Page number, default 1.
  --sort-field: string # Sort field, default created_at.
]: any -> table<billing_address: string, created_at: string, currency: string, date: string, deleted_at: string, document_id: string, due_date: string, integration_ext_id: string, integration_ext_type: string, integration_provider: record, items: list<record>, message: string, payment_terms: string, purchase_number: string, taxes: list<record>, updated_at: string, user_id: int, user_invoice_id: int, workspace_address: string, workspace_id: int, workspace_logo: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/invoices")
  let body = {sort_order: $sort_order, per_page: $per_page, page: $page, sort_field: $sort_field} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create user invoice
#
# POST /workspaces/{workspace_id}/invoices
# operationId: post-workspace-user-invoice
# --items item shape: {amount?: float, description?: string, item_id?: int, quantity?: float}
# --taxes item shape: {amount?: float, name?: string, tax_id?: int}
export def "workspaces-invoices post-workspace-user-invoice" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --billing-address: string
  --created-at: string
  --currency: string
  --date: string
  --deleted-at: string
  --document-id: string
  --due-date: string
  --integration-ext-id: string # The external ID of the linked entity in the external system (e.g. JIRA/SalesForce)
  --integration-ext-type: string # The external type of the linked entity in the external system (e.g. JIRA/SalesForce)
  --integration-provider: any # The provider (e.g. JIRA/SalesForce) that has an entity linked to this Toggl Track entity
  --items: list # item shape: {amount?: float, description?: string, item_id?: int, quantity?: float}
  --message: string
  --payment-terms: string
  --purchase-number: string
  --taxes: list # item shape: {amount?: float, name?: string, tax_id?: int}
  --updated-at: string
  --user-id: int
  --user-invoice-id: int
  --workspace-address: string
  --body-workspace-id: int
  --workspace-logo: string
]: any -> table<billing_address: string, created_at: string, currency: string, date: string, deleted_at: string, document_id: string, due_date: string, integration_ext_id: string, integration_ext_type: string, integration_provider: record, items: list<record>, message: string, payment_terms: string, purchase_number: string, taxes: list<record>, updated_at: string, user_id: int, user_invoice_id: int, workspace_address: string, workspace_id: int, workspace_logo: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/invoices")
  let body = {billing_address: $billing_address, created_at: $created_at, currency: $currency, date: $date, deleted_at: $deleted_at, document_id: $document_id, due_date: $due_date, integration_ext_id: $integration_ext_id, integration_ext_type: $integration_ext_type, integration_provider: $integration_provider, items: $items, message: $message, payment_terms: $payment_terms, purchase_number: $purchase_number, taxes: $taxes, updated_at: $updated_at, user_id: $user_id, user_invoice_id: $user_invoice_id, workspace_address: $workspace_address, workspace_id: $body_workspace_id, workspace_logo: $workspace_logo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# InvoicePdf
#
# GET /workspaces/{workspace_id}/invoices/{invoice_id}.pdf
# operationId: get-workspace-invoice
export def "workspaces-invoices get-workspace-invoice" [
  workspace_id: int
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/invoices/($invoice_id).pdf")
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete user invoice.
#
# DELETE /workspaces/{workspace_id}/invoices/{user_invoice_id}
# operationId: delete-workspace-invoice
export def "workspaces-invoices delete-workspace-invoice" [
  workspace_id: int
  user_invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/invoices/($user_invoice_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get linked SSO profiles for a workspace
#
# GET /workspaces/{workspace_id}/linked_sso_profiles
# operationId: get-workspace-sso
export def "workspaces-linked-sso-profiles get-workspace-sso" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<domain: string, name: string, sso_profile_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/linked_sso_profiles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Link SSO profile to a workspace
#
# PUT /workspaces/{workspace_id}/linked_sso_profiles/{sso_profile_id}
# operationId: put-workspace-sso
export def "workspaces-linked-sso-profiles put-workspace-sso" [
  workspace_id: int
  sso_profile_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<domain: string, name: string, sso_profile_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/linked_sso_profiles/($sso_profile_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unlink the workspace from an SSO profile.
#
# DELETE /workspaces/{workspace_id}/linked_sso_profiles/{sso_profile_id}
# operationId: delete-workspace-linked-sso-profiles
export def "workspaces-linked-sso-profiles delete-workspace-linked-sso-profiles" [
  workspace_id: int
  sso_profile_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<domain: string, name: string, sso_profile_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/linked_sso_profiles/($sso_profile_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get workspace logo
#
# GET /workspaces/{workspace_id}/logo
# operationId: get-workspace-logo
export def "workspaces-logo get-workspace-logo" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<logo: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/logo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Post workspace logo
#
# POST /workspaces/{workspace_id}/logo
# operationId: post-workspace-logo
export def "workspaces-logo post-workspace-logo" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<logo: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/logo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete workspace logo
#
# DELETE /workspaces/{workspace_id}/logo
# operationId: delete-workspace-logo
export def "workspaces-logo delete-workspace-logo" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<logo: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/logo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PaymentReceipts
#
# GET /workspaces/{workspace_id}/payment_receipts/{payment_id}.pdf
# operationId: get-workspace-payment-receipts
export def "workspaces-payment-receipts get-workspace-payment-receipts" [
  workspace_id: int
  payment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/payment_receipts/($payment_id).pdf")
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get workspace preferences
#
# GET /workspaces/{workspace_id}/preferences
# operationId: get-workspace-preferences
export def "workspaces-preferences get-workspace-preferences" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<logo: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/preferences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update workspace preferences
#
# POST /workspaces/{workspace_id}/preferences
# operationId: post-workspace-preferences
export def "workspaces-preferences post-workspace-preferences" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --calendar-suggestion-start-date: string # Start date from which to fetch time entries for calendar suggestions (ISO 8601 timestamp)
  --disable-approvals: string@bool-completer # Completely hides the approvals feature in this workspace
  --disable-expenses: string@bool-completer # Completely hides the expenses feature in this workspace
  --disable-timesheet-view: string@bool-completer # Whether timesheet view is disabled for this workspace
  --hide-start-end-times: string@bool-completer # This workspace works with duration only time entries
  --inc-tos-accepted-at: string # Time of acceptance of the terms of service
  --inc-tos-accepted-by: int # User ID who accepted the terms of service
  --initial-pricing-plan: int # Pricing plan ID
  --report-locked-at: string # Date on which "Lock Time Entries" feature was enabled
  --single-sign-on: string@bool-completer # Whether SSO is enabled for this workspace
  --sso-requested-at: string # Date on which SSO was requested
]: any -> record<logo: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/preferences")
  let body = {calendar_suggestion_start_date: $calendar_suggestion_start_date, disable_approvals: $disable_approvals, disable_expenses: $disable_expenses, disable_timesheet_view: $disable_timesheet_view, hide_start_end_times: $hide_start_end_times, inc_tos_accepted_at: $inc_tos_accepted_at, inc_tos_accepted_by: $inc_tos_accepted_by, initial_pricing_plan: $initial_pricing_plan, report_locked_at: $report_locked_at, single_sign_on: $single_sign_on, sso_requested_at: $sso_requested_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get workspace project groups.
#
# GET /workspaces/{workspace_id}/project_groups
# operationId: get-project-groups
export def "workspaces-project-groups get-project-groups" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  project_ids: string # Project IDs separated by comma.
]: any -> table<group_id: int, id: int, pid: int, wid: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/project_groups")
  let body = {project_ids: $project_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Adds group to project.
#
# POST /workspaces/{workspace_id}/project_groups
# operationId: post-project-group
export def "workspaces-project-groups post-project-group" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --group-id: int # Group ID
  --project-id: int # Project ID
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/project_groups")
  let body = {group_id: $group_id, project_id: $project_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove project group.
#
# DELETE /workspaces/{workspace_id}/project_groups/{project_group_id}
# operationId: delete-project-group
export def "workspaces-project-groups delete-project-group" [
  workspace_id: int
  project_group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/project_groups/($project_group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get workspace projects users
#
# GET /workspaces/{workspace_id}/project_users
# operationId: get-workspace-project-users
export def "workspaces-project-users get-workspace-project-users" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project-ids: string # Numeric IDs of projects, comma-separated
  --user-id: string # Numeric ID of user, if passed returns only project users for this user's projects
  --with-group-members: string@bool-completer # Include group members
]: nothing -> table<at: string, gid: int, group_id: int, id: int, labor_cost: float, labor_cost_last_updated: string, manager: bool, project_id: int, rate: float, rate_last_updated: string, user_id: int, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project_ids" $project_ids "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "with_group_members" $with_group_members "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/project_users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an user into workspace projects users
#
# POST /workspaces/{workspace_id}/project_users
# operationId: post-workspace-project-users
export def "workspaces-project-users post-workspace-project-users" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --labor-cost: float # Labor cost for this project user
  --labor-cost-change-mode: string # Labor cost change mode for this project user. Can be "start-today", "override-current", "override-all"
  --manager: string@bool-completer # Whether the user will be manager of the project
  --project-id: int # Project ID
  --rate: float # Rate for this project user
  --rate-change-mode: string # Rate change mode for this project user. Can be "start-today", "override-current", "override-all"
  --user-id: int # User ID
]: any -> record<at: string, gid: int, group_id: int, id: int, labor_cost: float, labor_cost_last_updated: string, manager: bool, project_id: int, rate: float, rate_last_updated: string, user_id: int, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/project_users")
  let body = {labor_cost: $labor_cost, labor_cost_change_mode: $labor_cost_change_mode, manager: $manager, project_id: $project_id, rate: $rate, rate_change_mode: $rate_change_mode, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get workspace projects users paginated
#
# POST /workspaces/{workspace_id}/project_users/paginated
# operationId: post-workspace-project-users-paginated
export def "workspaces-project-users-paginated post-workspace-project-users-paginated" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-inactive: string@bool-completer # Include inactive users in the response
  --users-per-project: string # Number of users per project
  --page: int # Page number
  --body: record
]: any -> table<at: string, avatar_url: string, gid: int, group_id: int, id: int, is_active: bool, labor_cost: float, labor_cost_last_updated: string, manager: bool, project_id: int, rate: float, rate_last_updated: string, user_id: int, user_name: string, workspace_id: int, workspace_user_id: int, workspace_user_labor_cost: float, workspace_user_rate: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_inactive" $show_inactive "scalar") (serialize-qp "users_per_project" $users_per_project "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/project_users/paginated" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Patch project users from workspace
#
# PATCH /workspaces/{workspace_id}/project_users/{project_user_ids}
# operationId: patch-workspace-project-users-ids
export def "workspaces-project-users patch-workspace-project-users-ids" [
  workspace_id: int
  project_user_ids: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<failure: table<id: int, message: string>, success: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/project_users/($project_user_ids)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an user into workspace projects users
#
# PUT /workspaces/{workspace_id}/project_users/{project_user_id}
# operationId: put-workspace-project-users
export def "workspaces-project-users put-workspace-project-users" [
  workspace_id: int
  project_user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --labor-cost: float # Labor cost for this project user
  --labor-cost-change-mode: string # Labor cost change mode for this project user. Can be "start-today", "override-current", "override-all"
  --manager: string@bool-completer # Whether the user will be manager of the project
  --rate: float # Rate for this project user
  --rate-change-mode: string # Rate change mode for this project user. Can be "start-today", "override-current", "override-all"
]: any -> record<at: string, gid: int, group_id: int, id: int, labor_cost: float, labor_cost_last_updated: string, manager: bool, project_id: int, rate: float, rate_last_updated: string, user_id: int, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/project_users/($project_user_id)")
  let body = {labor_cost: $labor_cost, labor_cost_change_mode: $labor_cost_change_mode, manager: $manager, rate: $rate, rate_change_mode: $rate_change_mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a project user from workspace projects users
#
# DELETE /workspaces/{workspace_id}/project_users/{project_user_id}
# operationId: delete-workspace-project-users
export def "workspaces-project-users delete-workspace-project-users" [
  workspace_id: int
  project_user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/project_users/($project_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# WorkspaceProjects
#
# GET /workspaces/{workspace_id}/projects
# operationId: get-projects
export def "workspaces-projects get-projects" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # Return active or inactive project. You can pass 'both' to get both active and inactive projects.
  --since: int # Retrieve projects created/modified/deleted since this date using UNIX timestamp.
  --billable: string@bool-completer # billable
  --user-ids: list # user_ids
  --client-ids: list # client_ids
  --group-ids: list # group_ids
  --project-ids: list # Numeric IDs of the projects
  --statuses: list # statuses
  --name: string # name
  --page: int # page
  --sort-field: string # sort_field
  --sort-order: string # sort_order
  --only-templates: string@bool-completer # only_templates
  --only-me: string@bool-completer # get only projects assigned to the current user
  --only-editable: string@bool-completer # get only projects the current user can edit
  --per-page: int # Number of items per page, default 151. Cannot exceed 200.
  --sort-pinned: string@bool-completer # Place pinned projects at top of response
  --search: string # search
]: nothing -> table<active: bool, actual_hours: int, actual_seconds: int, at: string, auto_estimates: bool, billable: bool, can_track_time: bool, cid: int, client_id: int, client_name: string, color: string, created_at: string, currency: string, current_period: record<end_date: string, start_date: string>, end_date: string, estimated_hours: int, estimated_seconds: int, external_reference: string, fixed_fee: float, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, is_private: bool, name: string, permissions: list<string>, pinned: bool, rate: float, rate_last_updated: string, recurring: bool, recurring_parameters: list<record>, start_date: string, status: record, template: bool, template_id: int, total_count: int, wid: int, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "billable" $billable "scalar") (serialize-qp "user_ids" $user_ids "csv") (serialize-qp "client_ids" $client_ids "csv") (serialize-qp "group_ids" $group_ids "csv") (serialize-qp "project_ids" $project_ids "csv") (serialize-qp "statuses" $statuses "csv") (serialize-qp "name" $name "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "only_templates" $only_templates "scalar") (serialize-qp "only_me" $only_me "scalar") (serialize-qp "only_editable" $only_editable "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_pinned" $sort_pinned "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# WorkspaceProjects
#
# POST /workspaces/{workspace_id}/projects
# operationId: post-workspace-project-create
export def "workspaces-projects post-workspace-project-create" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # Whether the project is active or archived
  --auto-estimates: string@bool-completer # Whether estimates are based on task hours, optional, premium feature
  --billable: string@bool-completer # Whether the project is set as billable, optional, premium feature
  --cid: int # Client ID, legacy
  --client-id: int # Client ID, optional
  --client-name: string # Client name, optional
  --color: string # Project color
  --currency: string # Project currency, optional, premium feature
  --end-date: string # End date of a project timeframe
  --estimated-hours: int # Estimated hours, optional, premium feature
  --external-reference: string
  --fixed-fee: float # Project fixed fee, optional, premium feature
  --is-private: string@bool-completer # Whether the project is private or not
  --is-shared: string@bool-completer # Shared
  --name: string # Project name
  --rate: float # Hourly rate, optional, premium feature
  --rate-change-mode: string # Rate change mode, optional, premium feature. Can be "start-today", "override-current", "override-all"
  --recurring: string@bool-completer # Project is recurring, optional, premium feature
  --recurring-parameters: any # Project recurring parameters, optional, premium feature
  --start-date: string # Start date of a project timeframe
  --template: string@bool-completer # Project is template, optional, premium feature
  --template-id: int # Template ID, optional
]: any -> record<active: bool, actual_hours: int, actual_seconds: int, at: string, auto_estimates: bool, billable: bool, can_track_time: bool, cid: int, client_id: int, client_name: string, color: string, created_at: string, currency: string, current_period: record<end_date: string, start_date: string>, end_date: string, estimated_hours: int, estimated_seconds: int, external_reference: string, fixed_fee: float, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, is_private: bool, name: string, permissions: list<string>, pinned: bool, rate: float, rate_last_updated: string, recurring: bool, recurring_parameters: table<custom_period: int, estimated_seconds: int, parameter_end_date: string, parameter_start_date: string, period: string, project_start_date: string>, start_date: string, status: record, template: bool, template_id: int, total_count: int, wid: int, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/projects")
  let body = {active: $active, auto_estimates: $auto_estimates, billable: $billable, cid: $cid, client_id: $client_id, client_name: $client_name, color: $color, currency: $currency, end_date: $end_date, estimated_hours: $estimated_hours, external_reference: $external_reference, fixed_fee: $fixed_fee, is_private: $is_private, is_shared: $is_shared, name: $name, rate: $rate, rate_change_mode: $rate_change_mode, recurring: $recurring, recurring_parameters: $recurring_parameters, start_date: $start_date, template: $template, template_id: $template_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Projects
#
# POST /workspaces/{workspace_id}/projects/billable-amounts
export def "workspaces-projects-billable-amounts post" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project-ids: list
]: any -> table<active: bool, actual_hours: int, actual_seconds: int, at: string, auto_estimates: bool, billable: bool, can_track_time: bool, cid: int, client_id: int, client_name: string, color: string, created_at: string, currency: string, current_period: record<end_date: string, start_date: string>, end_date: string, estimated_hours: int, estimated_seconds: int, external_reference: string, fixed_fee: float, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, is_private: bool, name: string, permissions: list<string>, pinned: bool, rate: float, rate_last_updated: string, recurring: bool, recurring_parameters: list<record>, start_date: string, status: record, template: bool, template_id: int, total_count: int, wid: int, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/projects/billable-amounts")
  let body = {project_ids: $project_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# WorkspaceProjectsTaskCount
#
# POST /workspaces/{workspace_id}/projects/task_count
# operationId: project-task-count
export def "workspaces-projects-task-count project-task-count" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project-ids: list
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/projects/task_count")
  let body = {project_ids: $project_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# WorkspaceProjectsTemplates
#
# GET /workspaces/{workspace_id}/projects/templates
# operationId: get-projects-templates
export def "workspaces-projects-templates get-projects-templates" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/projects/templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# WorkspaceProjectsUserCount
#
# POST /workspaces/{workspace_id}/projects/user_count
# operationId: project-user-count
export def "workspaces-projects-user-count project-user-count" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project-ids: list
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/projects/user_count")
  let body = {project_ids: $project_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# WorkspaceProjects
#
# PATCH /workspaces/{workspace_id}/projects/{project_ids}
# operationId: patch-workspace-projects
export def "workspaces-projects patch-workspace-projects" [
  workspace_id: int
  project_ids: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<failure: table<id: int, message: string>, success: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/projects/($project_ids)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# WorkspaceProject
#
# GET /workspaces/{workspace_id}/projects/{project_id}
export def "workspaces-projects get" [
  workspace_id: int
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active: bool, actual_hours: int, actual_seconds: int, at: string, auto_estimates: bool, billable: bool, can_track_time: bool, cid: int, client_id: int, client_name: string, color: string, created_at: string, currency: string, current_period: record<end_date: string, start_date: string>, end_date: string, estimated_hours: int, estimated_seconds: int, external_reference: string, fixed_fee: float, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, is_private: bool, name: string, permissions: list<string>, pinned: bool, rate: float, rate_last_updated: string, recurring: bool, recurring_parameters: table<custom_period: int, estimated_seconds: int, parameter_end_date: string, parameter_start_date: string, period: string, project_start_date: string>, start_date: string, status: record, template: bool, template_id: int, total_count: int, wid: int, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/projects/($project_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# WorkspaceProject
#
# PUT /workspaces/{workspace_id}/projects/{project_id}
# operationId: put-workspace-project
export def "workspaces-projects put-workspace-project" [
  workspace_id: int
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # Whether the project is active or archived
  --auto-estimates: string@bool-completer # Whether estimates are based on task hours, optional, premium feature
  --billable: string@bool-completer # Whether the project is set as billable, optional, premium feature
  --cid: int # Client ID, legacy
  --client-id: int # Client ID, optional
  --client-name: string # Client name, optional
  --color: string # Project color
  --currency: string # Project currency, optional, premium feature
  --end-date: string # End date of a project timeframe
  --estimated-hours: int # Estimated hours, optional, premium feature
  --external-reference: string
  --fixed-fee: float # Project fixed fee, optional, premium feature
  --is-private: string@bool-completer # Whether the project is private or not
  --is-shared: string@bool-completer # Shared
  --name: string # Project name
  --rate: float # Hourly rate, optional, premium feature
  --rate-change-mode: string # Rate change mode, optional, premium feature. Can be "start-today", "override-current", "override-all"
  --recurring: string@bool-completer # Project is recurring, optional, premium feature
  --recurring-parameters: any # Project recurring parameters, optional, premium feature
  --start-date: string # Start date of a project timeframe
  --template: string@bool-completer # Project is template, optional, premium feature
  --template-id: int # Template ID, optional
]: any -> record<active: bool, actual_hours: int, actual_seconds: int, at: string, auto_estimates: bool, billable: bool, can_track_time: bool, cid: int, client_id: int, client_name: string, color: string, created_at: string, currency: string, current_period: record<end_date: string, start_date: string>, end_date: string, estimated_hours: int, estimated_seconds: int, external_reference: string, fixed_fee: float, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, is_private: bool, name: string, permissions: list<string>, pinned: bool, rate: float, rate_last_updated: string, recurring: bool, recurring_parameters: table<custom_period: int, estimated_seconds: int, parameter_end_date: string, parameter_start_date: string, period: string, project_start_date: string>, start_date: string, status: record, template: bool, template_id: int, total_count: int, wid: int, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/projects/($project_id)")
  let body = {active: $active, auto_estimates: $auto_estimates, billable: $billable, cid: $cid, client_id: $client_id, client_name: $client_name, color: $color, currency: $currency, end_date: $end_date, estimated_hours: $estimated_hours, external_reference: $external_reference, fixed_fee: $fixed_fee, is_private: $is_private, is_shared: $is_shared, name: $name, rate: $rate, rate_change_mode: $rate_change_mode, recurring: $recurring, recurring_parameters: $recurring_parameters, start_date: $start_date, template: $template, template_id: $template_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# WorkspaceProject
#
# DELETE /workspaces/{workspace_id}/projects/{project_id}
# operationId: delete-workspace-project
export def "workspaces-projects delete-workspace-project" [
  workspace_id: int
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teDeletionMode: string # Time entries deletion mode: 'delete' or 'unassign'
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teDeletionMode" $teDeletionMode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/projects/($project_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Recurring Project Periods
#
# GET /workspaces/{workspace_id}/projects/{project_id}/periods
# operationId: get-workspace-project-periods
export def "workspaces-projects-periods get-workspace-project-periods" [
  workspace_id: int
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # Smallest boundary date to search for recurring periods
  --end-date: string # Biggest boundary date to search for for recurring periods
]: nothing -> record<end_date: string, start_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/projects/($project_id)/periods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# WorkspaceProjects
#
# POST /workspaces/{workspace_id}/projects/{project_id}/pin
# operationId: post-pinned-project
export def "workspaces-projects-pin post-pinned-project" [
  workspace_id: int
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pin: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/projects/($project_id)/pin")
  let body = {pin: $pin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# WorkspaceProject
#
# GET /workspaces/{workspace_id}/projects/{project_id}/statistics
export def "workspaces-projects-statistics get" [
  workspace_id: int
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<earliest_time_entry: string, latest_time_entry: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/projects/($project_id)/statistics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# WorkspaceProjectTasks
#
# GET /workspaces/{workspace_id}/projects/{project_id}/tasks
# operationId: get-workspace-project-tasks
export def "workspaces-projects-tasks get-workspace-project-tasks" [
  workspace_id: int
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # Return only active tasks. If true, returns only active tasks. If false or omitted, returns all tasks.
]: nothing -> table<active: bool, at: string, avatar_url: string, client_id: int, client_name: string, estimated_seconds: int, external_reference: string, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, name: string, permissions: list<string>, project_billable: bool, project_color: string, project_id: int, project_is_private: bool, project_name: string, rate: float, rate_last_updated: string, recurring: bool, toggl_accounts_id: string, tracked_seconds: int, user_id: int, user_name: string, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/projects/($project_id)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# WorkspaceProjectTasks
#
# POST /workspaces/{workspace_id}/projects/{project_id}/tasks
# operationId: post-workspace-project-tasks
export def "workspaces-projects-tasks post-workspace-project-tasks" [
  workspace_id: int
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # Use false to mark the task as done
  --estimated-seconds: int # Task estimation in seconds
  --external-reference: string # Task external reference
  --name: string # Name
  --user-id: int # Creator ID, if omitted, will use requester user ID
]: any -> record<active: bool, at: string, avatar_url: string, client_id: int, client_name: string, estimated_seconds: int, external_reference: string, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, name: string, permissions: list<string>, project_billable: bool, project_color: string, project_id: int, project_is_private: bool, project_name: string, rate: float, rate_last_updated: string, recurring: bool, toggl_accounts_id: string, tracked_seconds: int, user_id: int, user_name: string, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/projects/($project_id)/tasks")
  let body = {active: $active, estimated_seconds: $estimated_seconds, external_reference: $external_reference, name: $name, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# WorkspaceProjectTasks
#
# PATCH /workspaces/{workspace_id}/projects/{project_id}/tasks/{task_ids}
# operationId: patch-workspace-project-tasks
export def "workspaces-projects-tasks patch-workspace-project-tasks" [
  workspace_id: int
  project_id: int
  task_ids: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<failure: table<id: int, message: string>, success: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/projects/($project_id)/tasks/($task_ids)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# WorkspaceProjectTask
#
# GET /workspaces/{workspace_id}/projects/{project_id}/tasks/{task_id}
# operationId: get-workspace-project-task
export def "workspaces-projects-tasks get-workspace-project-task" [
  workspace_id: int
  project_id: int
  task_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active: bool, at: string, avatar_url: string, client_id: int, client_name: string, estimated_seconds: int, external_reference: string, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, name: string, permissions: list<string>, project_billable: bool, project_color: string, project_id: int, project_is_private: bool, project_name: string, rate: float, rate_last_updated: string, recurring: bool, toggl_accounts_id: string, tracked_seconds: int, user_id: int, user_name: string, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/projects/($project_id)/tasks/($task_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# WorkspaceProjectTask
#
# PUT /workspaces/{workspace_id}/projects/{project_id}/tasks/{task_id}
# operationId: put-workspace-project-task
export def "workspaces-projects-tasks put-workspace-project-task" [
  workspace_id: int
  project_id: int
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # Use false to mark the task as done
  --estimated-seconds: int # Task estimation in seconds
  --external-reference: string # Task external reference
  --name: string # Name
  --user-id: int # Creator ID, if omitted, will use requester user ID
]: any -> record<active: bool, at: string, avatar_url: string, client_id: int, client_name: string, estimated_seconds: int, external_reference: string, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, name: string, permissions: list<string>, project_billable: bool, project_color: string, project_id: int, project_is_private: bool, project_name: string, rate: float, rate_last_updated: string, recurring: bool, toggl_accounts_id: string, tracked_seconds: int, user_id: int, user_name: string, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/projects/($project_id)/tasks/($task_id)")
  let body = {active: $active, estimated_seconds: $estimated_seconds, external_reference: $external_reference, name: $name, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# WorkspaceProjectTask
#
# DELETE /workspaces/{workspace_id}/projects/{project_id}/tasks/{task_id}
# operationId: delete-workspace-project-task
export def "workspaces-projects-tasks delete-workspace-project-task" [
  workspace_id: int
  project_id: int
  task_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/projects/($project_id)/tasks/($task_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rates creation
#
# POST /workspaces/{workspace_id}/rates
# operationId: create-rate
export def "workspaces-rates create-rate" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --amount: float # Amount of the rate, required, must be greater than 0
  level: string@level-completer # Level of the rate, required, must be one of: 'workspace', 'workspace_user', 'project', 'project_user', 'task'
  level_id: int # Identifier of the level, required
  --mode: string@mode-completer # Mode of the rate, required if Start is not informed, must be one of: 'override-all', 'override-current', 'start-today'
  --start: string # Start date time of the rate, required if Mode is not informed, must be a valid date time
  --type: string # Type of the rate, required, must be one of 'billable_rates', 'labor_rates'
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/rates")
  let body = {amount: $amount, level: $level, level_id: $level_id, mode: $mode, start: $start, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rates list
#
# GET /workspaces/{workspace_id}/rates/{level}/{level_id}
# operationId: get-rates-by-level
export def "workspaces-rates get-rates-by-level" [
  workspace_id: int
  level: string
  level_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string # Type of rate values to be returned: `billable_rates` or `labor_costs`. Default is `billable_rates`.
]: nothing -> table<amount: float, created_at: string, creator_id: int, deleted_at: string, end: string, id: int, planned_task_id: int, project_id: int, project_user_id: int, rate_change_mode: string, start: string, type: string, updated_at: string, workspace_id: int, workspace_user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/rates/($level)/($level_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# workspace.SharedReport
#
# GET /workspaces/{workspace_id}/reports/shared
# operationId: get-shared-report
export def "workspaces-reports-shared get-shared-report" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fixed-dates: string@bool-completer
  --name: string
  --page: int
  --per-page: int
  --public: string@bool-completer
  --requestingUserID: int
  --scheduled: string@bool-completer
  --sort-direction: string
  --sort-field: string
]: nothing -> table<deleted_at: string, fixed_daterange: bool, id: int, isNAResource: bool, is_commenting_enabled: bool, name: string, params: string, public: bool, scheduled_email_gids: list<int>, scheduled_email_uids: list<int>, token: string, uid: int, updated_at: string, updated_by: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fixed_dates" $fixed_dates "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "public" $public "scalar") (serialize-qp "requestingUserID" $requestingUserID "scalar") (serialize-qp "scheduled" $scheduled "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "sort_field" $sort_field "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/reports/shared" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# workspace.SharedReport
#
# PUT /workspaces/{workspace_id}/reports/shared
# operationId: put-shared-report
export def "workspaces-reports-shared put-shared-report" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<deleted_at: string, fixed_daterange: bool, id: int, isNAResource: bool, is_commenting_enabled: bool, name: string, params: string, public: bool, scheduled_email_gids: list<int>, scheduled_email_uids: list<int>, token: string, uid: int, updated_at: string, updated_by: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/reports/shared")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# workspace.SharedReport
#
# POST /workspaces/{workspace_id}/reports/shared
# operationId: post-shared-report
export def "workspaces-reports-shared post-shared-report" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fixed-daterange: string@bool-completer
  --id: int
  --name: string
  --params: record
  --public: string@bool-completer
  --regenerate-token: string@bool-completer
]: any -> record<deleted_at: string, fixed_daterange: bool, id: int, isNAResource: bool, is_commenting_enabled: bool, name: string, params: string, public: bool, scheduled_email_gids: list<int>, scheduled_email_uids: list<int>, token: string, uid: int, updated_at: string, updated_by: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/reports/shared")
  let body = {fixed_daterange: $fixed_daterange, id: $id, name: $name, params: $params, public: $public, regenerate_token: $regenerate_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# SavedReport
#
# PATCH /workspaces/{workspace_id}/reports/shared/bulk_delete
# operationId: bulk-delete-saved-report-resource
export def "workspaces-reports-shared-bulk-delete bulk-delete-saved-report-resource" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list
]: any -> table<deleted_at: string, fixed_daterange: bool, id: int, isNAResource: bool, is_commenting_enabled: bool, name: string, params: string, public: bool, scheduled_email_gids: list<int>, scheduled_email_uids: list<int>, token: string, uid: int, updated_at: string, updated_by: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/reports/shared/bulk_delete")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# models.SavedReport
#
# GET /workspaces/{workspace_id}/reports/shared/{report_id}
# operationId: get-saved-report-resource
export def "workspaces-reports-shared get-saved-report-resource" [
  workspace_id: int
  report_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deleted_at: string, fixed_daterange: bool, id: int, isNAResource: bool, is_commenting_enabled: bool, name: string, params: string, public: bool, scheduled_email_gids: list<int>, scheduled_email_uids: list<int>, token: string, uid: int, updated_at: string, updated_by: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/reports/shared/($report_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# models.SavedReport
#
# PUT /workspaces/{workspace_id}/reports/shared/{report_id}
# operationId: put-saved-report-resource
export def "workspaces-reports-shared put-saved-report-resource" [
  workspace_id: int
  report_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fixed-daterange: string@bool-completer
  --id: int
  --name: string
  --params: record
  --public: string@bool-completer
  --regenerate-token: string@bool-completer
]: any -> record<deleted_at: string, fixed_daterange: bool, id: int, isNAResource: bool, is_commenting_enabled: bool, name: string, params: string, public: bool, scheduled_email_gids: list<int>, scheduled_email_uids: list<int>, token: string, uid: int, updated_at: string, updated_by: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/reports/shared/($report_id)")
  let body = {fixed_daterange: $fixed_daterange, id: $id, name: $name, params: $params, public: $public, regenerate_token: $regenerate_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# models.SavedReport
#
# DELETE /workspaces/{workspace_id}/reports/shared/{report_id}
# operationId: delete-saved-report-resource
export def "workspaces-reports-shared delete-saved-report-resource" [
  workspace_id: int
  report_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deleted_at: string, fixed_daterange: bool, id: int, isNAResource: bool, is_commenting_enabled: bool, name: string, params: string, public: bool, scheduled_email_gids: list<int>, scheduled_email_uids: list<int>, token: string, uid: int, updated_at: string, updated_by: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/reports/shared/($report_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ScheduledReports
#
# GET /workspaces/{workspace_id}/scheduled_reports
# operationId: get-workspace-scheduled-reports
export def "workspaces-scheduled-reports get-workspace-scheduled-reports" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<bookmark_id: int, created_at: string, creator_id: int, deleted_at: string, frequency: int, group_ids: list<int>, report_id: int, user_ids: list<int>, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/scheduled_reports")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ScheduledReports
#
# POST /workspaces/{workspace_id}/scheduled_reports
# operationId: post-workspace-scheduled-reports
export def "workspaces-scheduled-reports post-workspace-scheduled-reports" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookmark-id: int
  --frequency: int
  --group-ids: list
  --user-ids: list
]: any -> record<bookmark_id: int, created_at: string, creator_id: int, deleted_at: string, frequency: int, group_ids: list<int>, report_id: int, user_ids: list<int>, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/scheduled_reports")
  let body = {bookmark_id: $bookmark_id, frequency: $frequency, group_ids: $group_ids, user_ids: $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# ScheduledReport
#
# DELETE /workspaces/{workspace_id}/scheduled_reports/{report_id}
# operationId: delete-workspace-scheduled-reports
export def "workspaces-scheduled-reports delete-workspace-scheduled-reports" [
  workspace_id: int
  report_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/scheduled_reports/($report_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Workspace statistics
#
# GET /workspaces/{workspace_id}/statistics
# operationId: get-workspace-statistics
export def "workspaces-statistics get-workspace-statistics" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<admins: table<name: string, user_id: int>, groups_count: int, members_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/statistics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscription
#
# GET /workspaces/{workspace_id}/subscription
# operationId: get-workspace-subscription
export def "workspaces-subscription get-workspace-subscription" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active_users: int, auto_renew: bool, billing_period_in_months: int, campaign_available: bool, cancel_date: string, card_details: record<added_at: string, card_number: string, card_type: string, creator_id: int, creator_name: string, expiry_date: string, holder_name: string>, company_id: int, contact_details: record<company_address: string, company_city: string, company_name: string, contact_detail_id: int, contact_email: string, contact_person: string, country_id: int, country_subdivision_id: int, created_at: string, customer_id: int, is_eu_resident: bool, updated_at: string, user_id: int, vat_number: string, vat_number_valid: bool, vat_number_validated_at: string, zip_code: string>, currency: string, current_period_ends_at: string, current_period_starts_at: string, customer_id: int, end_date: string, enterprise: bool, is_subscription_beta: bool, is_unified: bool, keep_trial_on_subscription: bool, last_invoice: record<amount: int, created_at: string, currency_id: int, due: string, id: int, paid_at: string, tax_percentage: float, total_amount: int>, last_payment: record<created_at: string, description: string, id: int, status: string>, last_pricing_plan_id: int, new_signup_trial: bool, next_payment_date: string, payment_failed: bool, payment_method: string, plan_id: int, plan_name: string, pricing_plan_id: int, renewal_at: string, renewal_date: string, seat_cost_in_cents: int, seats: int, site: string, start_date: string, state: string, subscription_created_at: string, subscription_period: record<created_at: string, finished_on: string, started_on: string, subscription_id: int, subscription_period_id: int, trial: bool, user_count: int>, trial_available: bool, trial_end_date: string, trial_start_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PurchaseOrderPdf
#
# GET /workspaces/{workspace_id}/subscription/purchase_orders/{purchase_order_id}.pdf
# operationId: get-workspace-purchase-order-pdf
export def "workspaces-subscription-purchase-orders get-workspace-purchase-order-pdf" [
  workspace_id: int
  purchase_order_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/subscription/purchase_orders/($purchase_order_id).pdf")
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Tags
#
# GET /workspaces/{workspace_id}/tags
# operationId: get-workspace-tag
export def "workspaces-tags get-workspace-tag" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number
  --per-page: int # Number of items per page
  --search: string # Search by task name
]: nothing -> table<at: string, creator_id: int, deleted_at: string, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, name: string, permissions: list<string>, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create tag
#
# POST /workspaces/{workspace_id}/tags
# operationId: post-workspace-tag
export def "workspaces-tags post-workspace-tag" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Tag name
]: any -> table<at: string, creator_id: int, deleted_at: string, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, name: string, permissions: list<string>, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/tags")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk delete tags
#
# PATCH /workspaces/{workspace_id}/tags
# operationId: patch-workspace-tags
export def "workspaces-tags patch-workspace-tags" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update tag
#
# PUT /workspaces/{workspace_id}/tags/{tag_id}
# operationId: put-workspace-tag
export def "workspaces-tags put-workspace-tag" [
  workspace_id: int
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Tag name
]: any -> table<at: string, creator_id: int, deleted_at: string, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, name: string, permissions: list<string>, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/tags/($tag_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete tag
#
# DELETE /workspaces/{workspace_id}/tags/{tag_id}
# operationId: delete-workspace-tag
export def "workspaces-tags delete-workspace-tag" [
  workspace_id: int
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/tags/($tag_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Tasks
#
# GET /workspaces/{workspace_id}/tasks
# operationId: get-workspace-tasks
export def "workspaces-tasks get-workspace-tasks" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: int # Retrieve tasks created/modified/deleted since this date using UNIX timestamp.
  --page: int # Page number, default 1
  --per-page: int # Number of items per page, default 50
  --sort-order: string # Sort order, default ASC
  --sort-field: string # Field used for sorting. Default is name. Valid values are 'name' and 'created_at'
  --active: string@bool-completer # Filter by active state. You can also pass 'both' to get both active and inactive tasks.
  --pid: int # Filter by project id
  --start-date: string # Smallest boundary date in the format YYYY-MM-DD (format: date)
  --end-date: string # Biggest boundary date in the format YYYY-MM-DD (format: date)
  --search: string # Search by task name
]: nothing -> record<data: table<active: bool, at: string, avatar_url: string, client_id: int, client_name: string, estimated_seconds: int, external_reference: string, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, name: string, permissions: list, project_billable: bool, project_color: string, project_id: int, project_is_private: bool, project_name: string, rate: float, rate_last_updated: string, recurring: bool, toggl_accounts_id: string, tracked_seconds: int, user_id: int, user_name: string, workspace_id: int>, page: int, per_page: int, sort_field: string, sort_order: string, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "pid" $pid "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Tasks
#
# GET /workspaces/{workspace_id}/tasks/basic
# operationId: get-workspace-tasks-basic
export def "workspaces-tasks-basic get-workspace-tasks-basic" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number, default 1
  --per-page: int # Number of items per page, default 50
  --sort-order: string # Sort order, default ASC
  --sort-field: string # Field used for sorting. Default is name. Valid values are 'name' and 'created_at'
  --active: string@bool-completer # Filter by active state. You can also pass 'both' to get both active and inactive tasks. Default is true.
  --search: string # Search for tasks by name.
  --project-id: int # Filter by project ID
  --project-ids: list # Filter by project IDs (comma-separated)
  --task-ids: list # Filter by task IDs (comma-separated)
  --only-me: string@bool-completer # Filter tasks from projects assigned to the current user. Default is true.
  --client-ids: list # Filter by client IDs (comma-separated)
  --project-status: string # Filter by parent project status: 'active' (default), 'archived', or 'both'.
]: nothing -> record<data: table<active: bool, at: string, avatar_url: string, client_id: int, client_name: string, estimated_seconds: int, external_reference: string, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, name: string, permissions: list, project_billable: bool, project_color: string, project_id: int, project_is_private: bool, project_name: string, rate: float, rate_last_updated: string, recurring: bool, toggl_accounts_id: string, tracked_seconds: int, user_id: int, user_name: string, workspace_id: int>, page: int, per_page: int, sort_field: string, sort_order: string, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "project_ids" $project_ids "csv") (serialize-qp "task_ids" $task_ids "csv") (serialize-qp "only_me" $only_me "scalar") (serialize-qp "client_ids" $client_ids "csv") (serialize-qp "project_status" $project_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/tasks/basic" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List tasks for given project_ids
#
# POST /workspaces/{workspace_id}/tasks/data
# operationId: getWorkspaceTasksData
export def "workspaces-tasks-data post" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # search
  --per-page: int # per_page
  --page: int # page
  --project-ids: list
  --task-ids: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/tasks/data" $qp)
  let body = {project_ids: $project_ids, task_ids: $task_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# TimeEntries
#
# POST /workspaces/{workspace_id}/time_entries
# operationId: post-workspace-time-entries
# --event_metadata shape: {origin_feature?: string, visible_goals_count?: int}
export def "workspaces-time-entries post-workspace-time-entries" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --meta: string@bool-completer # Should the response contain data for meta entities
  --billable: string@bool-completer # Whether the time entry is marked as billable, optional, default false
  --created-with: string # Must be provided when creating a time entry and should identify the service/application used to create it
  --description: string # Time entry description, optional
  --duration: int # Time entry duration. For running entries should be negative, preferable -1
  --duronly: string@bool-completer # Deprecated: Used to create a time entry with a duration but without a stop time. This parameter can be ignored.
  --event-metadata: record # shape: {origin_feature?: string, visible_goals_count?: int}
  --expense-ids: list # Work Expenses associated with the Time Entry
  --pid: int # Project ID, legacy field
  --project-id: int # Project ID, optional
  --shared-with-user-ids: list # List of user IDs to share this time entry with
  --start: string # Start time in UTC, required for creation. Format: 2006-01-02T15:04:05Z
  --start-date: string # If provided during creation, the date part will take precedence over the date part of "start". Format: 2006-11-07
  --stop: string # Stop time in UTC, can be omitted if it's still running or created with "duration". If "stop" and "duration" are provided, values must be consistent (start + duration == stop)
  --tag-action: string # Can be "add" or "delete". Used when updating an existing time entry
  --tag-ids: list # IDs of tags to add/remove
  --tags: list # Names of tags to add/remove. If name does not exist as tag, one will be created automatically
  --task-id: int # Task ID, optional
  --tid: int # Task ID, legacy field
  --uid: int # Time Entry creator ID, legacy field
  --user-id: int # Time Entry creator ID, if omitted will use the requester user ID
  --wid: int # Workspace ID, legacy field
  --body-workspace-id: int # Workspace ID, required
]: any -> record<at: string, billable: bool, client_id: int, client_name: string, description: string, duration: int, duronly: bool, expense_ids: list<int>, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, permissions: list<string>, pid: int, project_active: bool, project_billable: bool, project_color: string, project_id: int, project_name: string, shared_with: table<accepted: bool, user_id: int, user_name: string>, start: string, stop: string, tag_ids: list<int>, tags: list<string>, task_id: int, task_name: string, tid: int, uid: int, user_avatar_url: string, user_id: int, user_name: string, wid: int, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "meta" $meta "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/time_entries" $qp)
  let body = {billable: $billable, created_with: $created_with, description: $description, duration: $duration, duronly: $duronly, event_metadata: $event_metadata, expense_ids: $expense_ids, pid: $pid, project_id: $project_id, shared_with_user_ids: $shared_with_user_ids, start: $start, start_date: $start_date, stop: $stop, tag_action: $tag_action, tag_ids: $tag_ids, tags: $tags, task_id: $task_id, tid: $tid, uid: $uid, user_id: $user_id, wid: $wid, workspace_id: $body_workspace_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk editing time entries
#
# PATCH /workspaces/{workspace_id}/time_entries/{time_entry_ids}
# operationId: patch-time-entries
export def "workspaces-time-entries patch-time-entries" [
  workspace_id: int
  time_entry_ids: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --meta: string@bool-completer # Should the response contain data for meta entities
  --body: record
]: any -> record<failure: table<id: int, message: string>, success: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "meta" $meta "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/time_entries/($time_entry_ids)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# TimeEntries
#
# PUT /workspaces/{workspace_id}/time_entries/{time_entry_id}
# operationId: put-workspace-time-entry-handler
# --event_metadata shape: {origin_feature?: string, visible_goals_count?: int}
export def "workspaces-time-entries put-workspace-time-entry-handler" [
  workspace_id: int
  time_entry_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --meta: string@bool-completer # Should the response contain data for meta entities
  --include-sharing: string@bool-completer # Should the response contain time entry sharing details
  --billable: string@bool-completer # Whether the time entry is marked as billable, optional, default false
  --created-with: string # Must be provided when creating a time entry and should identify the service/application used to create it
  --description: string # Time entry description, optional
  --duration: int # Time entry duration. For running entries should be negative, preferable -1
  --duronly: string@bool-completer # Deprecated: Used to create a time entry with a duration but without a stop time. This parameter can be ignored.
  --event-metadata: record # shape: {origin_feature?: string, visible_goals_count?: int}
  --expense-ids: list # Work Expenses associated with the Time Entry
  --pid: int # Project ID, legacy field
  --project-id: int # Project ID, optional
  --shared-with-user-ids: list # List of user IDs to share this time entry with
  --start: string # Start time in UTC, required for creation. Format: 2006-01-02T15:04:05Z
  --start-date: string # If provided during creation, the date part will take precedence over the date part of "start". Format: 2006-11-07
  --stop: string # Stop time in UTC, can be omitted if it's still running or created with "duration". If "stop" and "duration" are provided, values must be consistent (start + duration == stop)
  --tag-action: string # Can be "add" or "delete". Used when updating an existing time entry
  --tag-ids: list # IDs of tags to add/remove
  --tags: list # Names of tags to add/remove. If name does not exist as tag, one will be created automatically
  --task-id: int # Task ID, optional
  --tid: int # Task ID, legacy field
  --uid: int # Time Entry creator ID, legacy field
  --user-id: int # Time Entry creator ID, if omitted will use the requester user ID
  --wid: int # Workspace ID, legacy field
  --body-workspace-id: int # Workspace ID, required
]: any -> record<at: string, billable: bool, client_id: int, client_name: string, description: string, duration: int, duronly: bool, expense_ids: list<int>, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, permissions: list<string>, pid: int, project_active: bool, project_billable: bool, project_color: string, project_id: int, project_name: string, shared_with: table<accepted: bool, user_id: int, user_name: string>, start: string, stop: string, tag_ids: list<int>, tags: list<string>, task_id: int, task_name: string, tid: int, uid: int, user_avatar_url: string, user_id: int, user_name: string, wid: int, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "meta" $meta "scalar") (serialize-qp "include_sharing" $include_sharing "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/time_entries/($time_entry_id)" $qp)
  let body = {billable: $billable, created_with: $created_with, description: $description, duration: $duration, duronly: $duronly, event_metadata: $event_metadata, expense_ids: $expense_ids, pid: $pid, project_id: $project_id, shared_with_user_ids: $shared_with_user_ids, start: $start, start_date: $start_date, stop: $stop, tag_action: $tag_action, tag_ids: $tag_ids, tags: $tags, task_id: $task_id, tid: $tid, uid: $uid, user_id: $user_id, wid: $wid, workspace_id: $body_workspace_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# TimeEntries
#
# DELETE /workspaces/{workspace_id}/time_entries/{time_entry_id}
# operationId: delete-workspace-time-entries
export def "workspaces-time-entries delete-workspace-time-entries" [
  workspace_id: int
  time_entry_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/time_entries/($time_entry_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop TimeEntry
#
# PATCH /workspaces/{workspace_id}/time_entries/{time_entry_id}/stop
# operationId: patch-workspace-stop-time-entry-handler
export def "workspaces-time-entries-stop patch-workspace-stop-time-entry-handler" [
  workspace_id: int
  time_entry_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<at: string, billable: bool, client_id: int, client_name: string, description: string, duration: int, duronly: bool, expense_ids: list<int>, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, permissions: list<string>, pid: int, project_active: bool, project_billable: bool, project_color: string, project_id: int, project_name: string, shared_with: table<accepted: bool, user_id: int, user_name: string>, start: string, stop: string, tag_ids: list<int>, tags: list<string>, task_id: int, task_name: string, tid: int, uid: int, user_avatar_url: string, user_id: int, user_name: string, wid: int, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/time_entries/($time_entry_id)/stop")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get workspace time entry constraints
#
# GET /workspaces/{workspace_id}/time_entry_constraints
# operationId: get-workspace-time-entry-constraints
export def "workspaces-time-entry-constraints get-workspace-time-entry-constraints" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description_present: bool, max_tags: int, project_present: bool, tag_present: bool, task_present: bool, time_entry_constraints_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/time_entry_constraints")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Post workspace time entry constraints
#
# POST /workspaces/{workspace_id}/time_entry_constraints
# operationId: post-workspace-time-entry-constraints
export def "workspaces-time-entry-constraints post-workspace-time-entry-constraints" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description-present: string@bool-completer
  --max-tags: int
  --project-present: string@bool-completer
  --tag-present: string@bool-completer
  --task-present: string@bool-completer
  --time-entry-constraints-enabled: string@bool-completer
]: any -> record<wid: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/time_entry_constraints")
  let body = {description_present: $description_present, max_tags: $max_tags, project_present: $project_present, tag_present: $tag_present, task_present: $task_present, time_entry_constraints_enabled: $time_entry_constraints_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# TimeEntries
#
# GET /workspaces/{workspace_id}/time_entry_invitations
# operationId: get-workspace-time-entry-invitations
export def "workspaces-time-entry-invitations get-workspace-time-entry-invitations" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<shared_by_user_id: int, shared_by_user_name: string, time_entry: record<at: string, billable: bool, client_id: int, client_name: string, description: string, duration: int, duronly: bool, expense_ids: list, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, permissions: list, pid: int, project_active: bool, project_billable: bool, project_color: string, project_id: int, project_name: string, shared_with: list, start: string, stop: string, tag_ids: list, tags: list, task_id: int, task_name: string, tid: int, uid: int, user_avatar_url: string, user_id: int, user_name: string, wid: int, workspace_id: int>, time_entry_invitation_id: int, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/time_entry_invitations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# TimeEntries
#
# POST /workspaces/{workspace_id}/time_entry_invitations/{time_entry_invitation_id}/{action}
# operationId: post-workspace-time-entry-invitation-action
export def "workspaces-time-entry-invitations post-workspace-time-entry-invitation-action" [
  workspace_id: int
  time_entry_invitation_id: int
  action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/time_entry_invitations/($time_entry_invitation_id)/($action)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get timesheet setups
#
# GET /workspaces/{workspace_id}/timesheet_setups
# operationId: get-timesheet-setups
export def "workspaces-timesheet-setups get-timesheet-setups" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --member-ids: int # Numeric ID of the members, comma-separated
  --approver-ids: int # Numeric ID of the approvers, comma-separated
  --sort-field: string # Field used for sorting, default start_date.
  --sort-order: string # Sort order.
]: nothing -> record<data: table<approver_avatar_url: string, approver_id: int, approver_name: string, approvers: list, approvers_layers: record, email_reminder_enabled: bool, end_date: string, errors: list, id: int, member_avatar_url: string, member_id: int, member_name: string, periodicity: string, permissions: list, reminder_day: int, reminder_time: string, slack_reminder_enabled: bool, start_date: string, workspace_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "member_ids" $member_ids "scalar") (serialize-qp "approver_ids" $approver_ids "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/timesheet_setups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a timesheet setup
#
# POST /workspaces/{workspace_id}/timesheet_setups
# operationId: post-timesheet-setups
export def "workspaces-timesheet-setups post-timesheet-setups" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --approver-id: int
  --approver-ids: list
  --approvers-layers: record
  --email-reminder-enabled: string@bool-completer
  --member-ids: list
  --periodicity: string
  --reminder-day: int@reminder-day-completer
  --reminder-time: string
  --slack-reminder-enabled: string@bool-completer
  --start-date: string
]: any -> table<approver_avatar_url: string, approver_id: int, approver_name: string, approvers: list<record>, approvers_layers: record, email_reminder_enabled: bool, end_date: string, errors: list<record>, id: int, member_avatar_url: string, member_id: int, member_name: string, periodicity: string, permissions: list<string>, reminder_day: int, reminder_time: string, slack_reminder_enabled: bool, start_date: string, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/timesheet_setups")
  let body = {approver_id: $approver_id, approver_ids: $approver_ids, approvers_layers: $approvers_layers, email_reminder_enabled: $email_reminder_enabled, member_ids: $member_ids, periodicity: $periodicity, reminder_day: $reminder_day, reminder_time: $reminder_time, slack_reminder_enabled: $slack_reminder_enabled, start_date: $start_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a timesheet setup
#
# POST /workspaces/{workspace_id}/timesheet_setups/{setup_id}
# operationId: put-timesheet-setups
export def "workspaces-timesheet-setups put-timesheet-setups" [
  workspace_id: int
  setup_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --approver-id: int
  --approver-ids: list
  --approvers-layers: record
  --email-reminder-enabled: string@bool-completer
  --end-date: string
  --reminder-day: int@reminder-day-completer
  --reminder-time: string
  --slack-reminder-enabled: string@bool-completer
]: any -> record<approver_avatar_url: string, approver_id: int, approver_name: string, approvers: table<active: bool, avatar_url: string, deleted: bool, name: string, user_id: int>, approvers_layers: record, email_reminder_enabled: bool, end_date: string, errors: table<code: string, message: string>, id: int, member_avatar_url: string, member_id: int, member_name: string, periodicity: string, permissions: list<string>, reminder_day: int, reminder_time: string, slack_reminder_enabled: bool, start_date: string, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/timesheet_setups/($setup_id)")
  let body = {approver_id: $approver_id, approver_ids: $approver_ids, approvers_layers: $approvers_layers, email_reminder_enabled: $email_reminder_enabled, end_date: $end_date, reminder_day: $reminder_day, reminder_time: $reminder_time, slack_reminder_enabled: $slack_reminder_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a timesheet setup
#
# DELETE /workspaces/{workspace_id}/timesheet_setups/{setup_id}
# operationId: delete-timesheet-setups
export def "workspaces-timesheet-setups delete-timesheet-setups" [
  workspace_id: int
  setup_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/timesheet_setups/($setup_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get timesheets
#
# GET /workspaces/{workspace_id}/timesheets
# operationId: get-workspace-timesheets-handler
export def "workspaces-timesheets get-workspace-timesheets-handler" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --member-ids: int # Numeric ID of the members, comma-separated
  --approver-ids: int # Numeric ID of the approvers, comma-separated
  --timesheet-setup-ids: int # Numeric ID for timesheet setup, comma-separated.
  --statuses: int # Timesheet status, comma-separated.
  --before: int # Timesheets starting before this date (YYYY-MM-DD).
  --after: int # Timesheets starting after this date (YYYY-MM-DD).
  --page: int # Page number, default 1.
  --per-page: int # Number of items per page, default 20. Also defaults to 20 if provided an greater than 1000.
  --sort-field: string # Field used for sorting, default start_date.
  --sort-order: string # Sort order.
]: nothing -> table<data: list<record>, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "member_ids" $member_ids "scalar") (serialize-qp "approver_ids" $approver_ids "scalar") (serialize-qp "timesheet_setup_ids" $timesheet_setup_ids "scalar") (serialize-qp "statuses" $statuses "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/timesheets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a batch of timesheets
#
# PUT /workspaces/{workspace_id}/timesheets
# operationId: put-workspace-timesheets-batch-handler
export def "workspaces-timesheets put-workspace-timesheets-batch-handler" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force-approved: string@bool-completer
  --rejection-comment: string
  --start-date: string
  --status: string
  --timesheet-setup-id: int
]: any -> record<approved_or_rejected_at: string, approved_or_rejected_id: int, approved_or_rejected_name: string, approver_avatar_url: string, approver_id: int, approver_name: string, approvers: table<active: bool, avatar_url: string, deleted: bool, name: string, user_id: int>, approvers_layers: record, end_date: string, errors: table<code: string, message: string>, member_avatar_url: string, member_id: int, member_name: string, period_editable: bool, period_end: string, period_locked: bool, period_start: string, periodicity: string, permissions: list<string>, rejection_comment: string, reminder_day: int, reminder_sent_at: string, reminder_time: string, review_layer: int, reviews: table<approved: bool, avatar_url: string, force_approved: bool, name: string, rejection_comment: string, review_layer: int, updated_at: string, user_id: int>, start_date: string, status: string, submitted_at: string, timesheet_setup_id: int, timezone: string, working_hours_in_minutes: int, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/timesheets")
  let body = {force_approved: $force_approved, rejection_comment: $rejection_comment, start_date: $start_date, status: $status, timesheet_setup_id: $timesheet_setup_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get timesheets hours
#
# POST /workspaces/{workspace_id}/timesheets/hours
# operationId: get-workspace-timesheet-hours-handler
export def "workspaces-timesheets-hours get-workspace-timesheet-hours-handler" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string
  --timesheet-setup-id: int
]: any -> table<start_date: string, timesheet_setup_id: int, total_seconds: int, working_hours_in_minutes: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/timesheets/hours")
  let body = {start_date: $start_date, timesheet_setup_id: $timesheet_setup_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update timesheets
#
# PUT /workspaces/{workspace_id}/timesheets/{setup_id}/{start_date}
# operationId: put-workspace-timesheets-handler
export def "workspaces-timesheets put-workspace-timesheets-handler" [
  workspace_id: int
  setup_id: int
  start_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force-approved: string@bool-completer
  --rejection-comment: string
  --status: string
]: any -> record<approved_or_rejected_at: string, approved_or_rejected_id: int, approved_or_rejected_name: string, approver_avatar_url: string, approver_id: int, approver_name: string, approvers: table<active: bool, avatar_url: string, deleted: bool, name: string, user_id: int>, approvers_layers: record, end_date: string, errors: table<code: string, message: string>, member_avatar_url: string, member_id: int, member_name: string, period_editable: bool, period_end: string, period_locked: bool, period_start: string, periodicity: string, permissions: list<string>, rejection_comment: string, reminder_day: int, reminder_sent_at: string, reminder_time: string, review_layer: int, reviews: table<approved: bool, avatar_url: string, force_approved: bool, name: string, rejection_comment: string, review_layer: int, updated_at: string, user_id: int>, start_date: string, status: string, submitted_at: string, timesheet_setup_id: int, timezone: string, working_hours_in_minutes: int, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/timesheets/($setup_id)/($start_date)")
  let body = {force_approved: $force_approved, rejection_comment: $rejection_comment, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get timesheet history
#
# GET /workspaces/{workspace_id}/timesheets/{setup_id}/{start_date}/history
# operationId: get-workspace-timesheet-history-handler
export def "workspaces-timesheets-history get-workspace-timesheet-history-handler" [
  workspace_id: int
  setup_id: int
  start_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<at: string, billable: bool, client_id: int, client_name: string, description: string, duration: int, duronly: bool, expense_ids: list<int>, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, permissions: list<string>, pid: int, project_active: bool, project_billable: bool, project_color: string, project_id: int, project_name: string, shared_with: list<record>, start: string, stop: string, tag_ids: list<int>, tags: list<string>, task_id: int, task_name: string, tid: int, uid: int, user_avatar_url: string, user_id: int, user_name: string, wid: int, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/timesheets/($setup_id)/($start_date)/history")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get timesheet time entries
#
# GET /workspaces/{workspace_id}/timesheets/{setup_id}/{start_date}/time_entries
# operationId: get-workspace-timesheet-time-entries-handler
export def "workspaces-timesheets-time-entries get-workspace-timesheet-time-entries-handler" [
  workspace_id: int
  setup_id: int
  start_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<at: string, billable: bool, client_id: int, client_name: string, description: string, duration: int, duronly: bool, expense_ids: list<int>, id: int, integration_ext_id: string, integration_ext_type: string, integration_provider: record, permissions: list<string>, pid: int, project_active: bool, project_billable: bool, project_color: string, project_id: int, project_name: string, shared_with: list<record>, start: string, stop: string, tag_ids: list<int>, tags: list<string>, task_id: int, task_name: string, tid: int, uid: int, user_avatar_url: string, user_id: int, user_name: string, wid: int, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/timesheets/($setup_id)/($start_date)/time_entries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# TrackReminders
#
# GET /workspaces/{workspace_id}/track_reminders
# operationId: get-workspace-track-reminders
export def "workspaces-track-reminders get-workspace-track-reminders" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<created_at: string, email_reminder_enabled: bool, frequency: int, group_ids: list<int>, reminder_id: int, slack_reminder_enabled: bool, threshold: int, user_ids: list<int>, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/track_reminders")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# TrackReminders
#
# POST /workspaces/{workspace_id}/track_reminders
# operationId: post-workspace-track-reminders
export def "workspaces-track-reminders post-workspace-track-reminders" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email-reminder-enabled: string@bool-completer # EmailReminderEnabled indicates if email notifications are enabled
  --frequency: int # Frequency of the reminder in days, should be either 1 or 7
  --group-ids: list # Group IDs to send the reminder to, can be omitted if user_ids is provided
  --slack-reminder-enabled: string@bool-completer # SlackReminderEnabled indicates if slack notifications are enabled
  --threshold: float # Threshold is the number of hours after which the reminder will be sent
  --user-ids: list # User IDs to send the reminder to, can be omitted if group_ids is provided
]: any -> record<created_at: string, email_reminder_enabled: bool, frequency: int, group_ids: list<int>, reminder_id: int, slack_reminder_enabled: bool, threshold: int, user_ids: list<int>, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/track_reminders")
  let body = {email_reminder_enabled: $email_reminder_enabled, frequency: $frequency, group_ids: $group_ids, slack_reminder_enabled: $slack_reminder_enabled, threshold: $threshold, user_ids: $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# TrackReminder
#
# PUT /workspaces/{workspace_id}/track_reminders/{reminder_id}
# operationId: put-workspace-track-reminder
export def "workspaces-track-reminders put-workspace-track-reminder" [
  workspace_id: int
  reminder_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email-reminder-enabled: string@bool-completer # EmailReminderEnabled indicates if email notifications are enabled
  --frequency: int # Frequency of the reminder in days, should be either 1 or 7
  --group-ids: list # Group IDs to send the reminder to, can be omitted if user_ids is provided
  --slack-reminder-enabled: string@bool-completer # SlackReminderEnabled indicates if slack notifications are enabled
  --threshold: float # Threshold is the number of hours after which the reminder will be sent
  --user-ids: list # User IDs to send the reminder to, can be omitted if group_ids is provided
]: any -> record<created_at: string, email_reminder_enabled: bool, frequency: int, group_ids: list<int>, reminder_id: int, slack_reminder_enabled: bool, threshold: int, user_ids: list<int>, workspace_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/track_reminders/($reminder_id)")
  let body = {email_reminder_enabled: $email_reminder_enabled, frequency: $frequency, group_ids: $group_ids, slack_reminder_enabled: $slack_reminder_enabled, threshold: $threshold, user_ids: $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# TrackReminder
#
# DELETE /workspaces/{workspace_id}/track_reminders/{reminder_id}
# operationId: delete-workspace-track-reminder
export def "workspaces-track-reminders delete-workspace-track-reminder" [
  workspace_id: int
  reminder_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/track_reminders/($reminder_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get workspace users
#
# GET /workspaces/{workspace_id}/users
# operationId: get-workspace-users
export def "workspaces-users get-workspace-users" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --exclude-deleted: string@bool-completer # Exclude deleted records in the response
]: nothing -> table<email: string, fullname: string, id: int, inactive: bool, is_active: bool, is_admin: bool, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "exclude_deleted" $exclude_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get workspace users data
#
# POST /workspaces/{workspace_id}/users/data
# operationId: post-workspace-users-data
export def "workspaces-users-data post-workspace-users-data" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<email: string, fullname: string, id: int, inactive: bool, is_active: bool, is_admin: bool, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/users/data")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update workspace user
#
# PUT /workspaces/{workspace_id}/users/{user_id}
# operationId: put-workspace-users
export def "workspaces-users put-workspace-users" [
  workspace_id: int
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get workspace workspace-users
#
# GET /workspaces/{workspace_id}/workspace_users
# operationId: get-workspace-workspace_users
export def "workspaces-workspace-users users-by-workspace_id" [
  workspace_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeIndirect: string # If true, includes indirect users (i.e. users assigned via group) to workspace user list
]: nothing -> table<2fa_enabled: bool, active: bool, admin: bool, at: string, avatar_file_name: string, email: string, group_ids: list<int>, id: int, inactive: bool, invitation_code: string, invite_url: string, is_direct: bool, labor_cost: float, labor_cost_last_updated: string, name: string, organization_admin: bool, rate: float, rate_last_updated: string, role: string, role_id: int, timezone: string, uid: int, user_id: int, view_edit_billable_rates: bool, view_edit_labor_costs: bool, wid: int, working_hours_in_minutes: int, workspace_admin: bool, workspace_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeIndirect" $includeIndirect "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_id)/workspace_users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update workspace-user
#
# PUT /workspaces/{workspace_id}/workspace_users/{workspace_user_id}
# operationId: put-workspace-workspace_users
export def "workspaces-workspace-users users-by-workspace_id-workspace_user_id" [
  workspace_id: int
  workspace_user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --admin: string@bool-completer # deprecated
  --inactive: string@bool-completer
  --labor-cost: float # Custom labor cost for project user
  --labor-cost-change-mode: string
  --postedFields: list # for explicit NULL-s, add field name here
  --rate: float # Paid feature
  --rate-change-mode: string # Paid feature
  --role: string # Allowed inputs: "admin", "user", "projectlead" and "teamlead"
  --role-id: int
  --view-edit-billable-rates: string@bool-completer
  --view-edit-labor-costs: string@bool-completer
  --working-hours-in-minutes: int # Paid feature
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/workspace_users/($workspace_user_id)")
  let body = {admin: $admin, inactive: $inactive, labor_cost: $labor_cost, labor_cost_change_mode: $labor_cost_change_mode, postedFields: $postedFields, rate: $rate, rate_change_mode: $rate_change_mode, role: $role, role_id: $role_id, view_edit_billable_rates: $view_edit_billable_rates, view_edit_labor_costs: $view_edit_labor_costs, working_hours_in_minutes: $working_hours_in_minutes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete workspace user
#
# DELETE /workspaces/{workspace_id}/workspace_users/{workspace_user_id}
# operationId: delete-workspace-user
export def "workspaces-workspace-users delete-workspace-user" [
  workspace_id: int
  workspace_user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_id)/workspace_users/($workspace_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
