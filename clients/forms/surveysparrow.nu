# Auto-generated client for API Documentation v1.0.0
# Source: https://api.surveysparrow.com/swagger.json
# Auth: --token flag or $env.API_DOCUMENTATION_TOKEN

const BASE_URL = "https://api.surveysparrow.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o API_DOCUMENTATION_TOKEN | default "" }
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
def base-url-completer [] { ["https://api.surveysparrow.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def eventType-completer [] { ["CONTACT_CREATED" "CONTACT_DELETED" "CONTACT_PROPERTY_CREATED" "CONTACT_PROPERTY_DELETED" "CONTACT_PROPERTY_EDITED" "CONTACT_UPDATED" "CUSTOM_METRIC_CREATED" "CUSTOM_METRIC_DELETED" "CUSTOM_METRIC_UPDATED" "CUSTOM_RESPONSE_RATE_SWITCHED" "FIREWALL_RULE_CREATED" "FIREWALL_RULE_DELETED" "FIREWALL_RULE_UPDATED" "FOLDER_TEAM_ACCESS_GRANT" "FOLDER_TEAM_ACCESS_REMOVE" "FOLDER_USER_ACCESS_GRANT" "FOLDER_USER_ACCESS_REMOVE" "LOGIN" "LOGOUT" "QUESTION_CATALOG_CREATED" "QUESTION_CATALOG_DELETED" "SANDBOX_ACCOUNT_CREATED" "SANDBOX_BULK_CLONE_TO_SANDBOX" "SANDBOX_SURVEY_CLONED_TO_MAIN" "SANDBOX_SURVEY_CLONED_TO_SANDBOX" "SANDBOX_SURVEY_SYNCED" "SANDBOX_USERS_ADDED" "SURVEY_CLOSED" "SURVEY_CREATED" "SURVEY_DELETED" "SURVEY_EDITED" "SURVEY_FOLDER_MOVED" "SURVEY_MOVED" "SURVEY_OWNERSHIP_TRANSFER" "SURVEY_PASSWORD_CREATED" "SURVEY_PASSWORD_DELETED" "SURVEY_PASSWORD_EDITED" "SURVEY_RESPONSE_DELETION" "SURVEY_RESPONSE_IMPORT" "SURVEY_RESTORED" "SYNC_DEVICES" "THEME_ADDED" "THEME_DELETED" "THEME_EDITED" "TICKET_TEMPLATE_CREATED" "TICKET_TEMPLATE_DELETED" "TICKET_TEMPLATE_UPDATED" "USER_CREATED" "USER_DELETED" "USER_EDITED" "WORKSPACE_CREATED" "WORKSPACE_DELETED" "WORKSPACE_EDITED"] }
def type-completer [] { ["active" "bounced" "unsubscribed"] }
def contact-type-completer [] { ["contact" "employee"] }
def surveyType-completer [] { ["ClassicForm"] }
def visibility-completer [] { ["Mine" "Public"] }
def surveyType-completer-1 [] { ["CES" "CESChat" "CSAT" "CSATChat" "ClassicForm" "Conversational" "Employee360" "Kiosk" "NPS" "NPSChat" "OfflineApp" "Poll"] }
def type-completer-1 [] { ["SURVEY" "TICKET"] }
def httpMethod-completer [] { ["DELETE" "GET" "PATCH" "POST" "PUT"] }
def visibility-completer-1 [] { ["ALL" "PRIVATE"] }
def event-type-completer [] { ["CONTACT_CREATED" "CONTACT_DELETED" "CONTACT_PROPERTY_CREATED" "CONTACT_PROPERTY_DELETED" "CONTACT_PROPERTY_EDITED" "CONTACT_UPDATED" "CUSTOM_METRIC_CREATED" "CUSTOM_METRIC_DELETED" "CUSTOM_METRIC_UPDATED" "CUSTOM_RESPONSE_RATE_SWITCHED" "FIREWALL_RULE_CREATED" "FIREWALL_RULE_DELETED" "FIREWALL_RULE_UPDATED" "FOLDER_TEAM_ACCESS_GRANT" "FOLDER_TEAM_ACCESS_REMOVE" "FOLDER_USER_ACCESS_GRANT" "FOLDER_USER_ACCESS_REMOVE" "LOGIN" "LOGOUT" "QUESTION_CATALOG_CREATED" "QUESTION_CATALOG_DELETED" "SANDBOX_ACCOUNT_CREATED" "SANDBOX_BULK_CLONE_TO_SANDBOX" "SANDBOX_SURVEY_CLONED_TO_MAIN" "SANDBOX_SURVEY_CLONED_TO_SANDBOX" "SANDBOX_SURVEY_SYNCED" "SANDBOX_USERS_ADDED" "SURVEY_CLOSED" "SURVEY_CREATED" "SURVEY_DELETED" "SURVEY_EDITED" "SURVEY_FOLDER_MOVED" "SURVEY_MOVED" "SURVEY_OWNERSHIP_TRANSFER" "SURVEY_PASSWORD_CREATED" "SURVEY_PASSWORD_DELETED" "SURVEY_PASSWORD_EDITED" "SURVEY_RESPONSE_DELETION" "SURVEY_RESPONSE_IMPORT" "SURVEY_RESTORED" "SYNC_DEVICES" "THEME_ADDED" "THEME_DELETED" "THEME_EDITED" "TICKET_TEMPLATE_CREATED" "TICKET_TEMPLATE_DELETED" "TICKET_TEMPLATE_UPDATED" "USER_CREATED" "USER_DELETED" "USER_EDITED" "WORKSPACE_CREATED" "WORKSPACE_DELETED" "WORKSPACE_EDITED"] }
def type-completer-2 [] { ["EMAIL" "EMAIL_EMBED" "EMBED" "INAPP" "INTERCOM" "KIOSK" "LINK" "MOBILE_SDK" "OFFLINE" "PORTAL" "QR_CODE" "SFTP" "SLACK" "SMART_REACH" "SMS" "SOCIAL_FACEBOOK" "SOCIAL_GOOGLE" "SOCIAL_TWITTER" "SPOTCHECK" "SYSTEM" "TEAMS" "TEST_EMAIL" "WHATSAPP"] }
def type-completer-3 [] { ["EMAIL" "LINK" "OFFLINE" "SMS"] }
def mode-completer [] { ["BLAST" "RECURRING" "RELATIVE_RECURRING"] }
def type-completer-4 [] { ["DATE" "DOUBLE" "DROPDOWN" "EMAIL" "MULTI_LINE_TEXT" "MULTI_SELECT" "NUMBER" "SINGLE_LINE_TEXT" "STRING" "UNIQUE" "URL"] }
def type-completer-5 [] { ["CES" "CSAT" "NPS"] }
def frequency-completer [] { ["Days" "Months" "Weeks" "Years"] }
def type-completer-6 [] { ["NOT_RESPONDED" "PARTIALLY_RESPONDED"] }
def state-completer [] { ["all" "completed" "started"] }
def order-by-completer [] { ["completedTime" "id" "startTime"] }
def order-completer [] { ["ASC" "DESC"] }
def survey-type-completer [] { ["CES" "CESChat" "CSAT" "CSATChat" "ClassicForm" "Conversational" "Employee360" "Kiosk" "NPS" "NPSChat" "OfflineApp"] }
def survey-type-completer-1 [] { ["CES" "CESChat" "CSAT" "CSATChat" "ClassicForm" "Conversational" "NPS" "NPSChat"] }
def trash-completer [] { ["false" "null" "true"] }
def type-completer-7 [] { ["DATE" "NUMBER" "STRING"] }
def http-method-completer [] { ["DELETE" "GET" "PATCH" "POST" "PUT"] }
def http-method-completer-1 [] { ["DELETE" "GET" "POST" "PUT"] }
def category-completer [] { ["Detractors" "Passives" "Promoters"] }
def type-completer-8 [] { ["EMAIL" "EMAIL_EMBED" "INAPP" "LINK" "MOBILE_SDK" "OFFLINE" "QR_CODE" "SLACK" "SMART_REACH" "SMS" "SPOTCHECK" "SYSTEM" "TEAMS" "WHATSAPP"] }
def mode-completer-1 [] { ["BLAST" "EMAIL_EMBED" "INAPP" "INTERCOM" "LINK" "MOBILE_SDK" "OFFLINE" "QR_CODE" "RECURRING" "RELATIVE_RECURRING" "SPOTCHECK" "TEST" "WHATSAPP"] }
def surveyType-completer-2 [] { ["CES" "CESChat"] }
def surveyType-completer-3 [] { ["CSAT" "CSATChat"] }
def surveyType-completer-4 [] { ["NPS" "NPSChat"] }
def httpMethod-completer-1 [] { ["DELETE" "GET" "POST" "PUT"] }
def channelType-completer [] { ["EMAIL" "EMBED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "audit-logs list" } } | get name | first)
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

# List audit logs
#
# GET /v1/audit-logs
# operationId: getV1Auditlogs
export def "audit-logs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --eventType: string@eventType-completer
  --page: float # default: 1
  --maxResults: float # default: 100
  --user: string
  --startDate: string # format: date
  --endDate: string # format: date
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "eventType" $eventType "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/audit-logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List contact lists
#
# GET /v1/contactlist
# operationId: getV1Contactlist
export def "contactlist get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contactlist")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create contact list
#
# POST /v1/contactlist
# operationId: postV1Contactlist
export def "contactlist post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --description: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contactlist")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

#  Get Contacts
#
# GET /v1/contacts
# operationId: getV1Contacts
export def "contacts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: float # default: 50
  --page: float # default: 1
  --type: string@type-completer # filters type of contact
  --search: string # search string which will search all the properties of a contact for a matching value
  --authorization: string # Custom Token generated from the App
]: nothing -> record<contacts: table<id: float, name: string, email: string, active: bool, unsubscribed: bool, phone: string, mobile: string, jobTitle: string>, hasNextPage: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/contacts" $qp)
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create contact
#
# POST /v1/contacts
# operationId: postV1Contacts
export def "contacts post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authorization: string # Custom Token generated from the App
  --name: string # Full Name of contact (e.g. Jane Doe)
  --phone: string # Phone number of the contact (e.g. 91234567833)
  --mobile: string # Mobile number of the contact (e.g. 1653452783)
  --email: string # Email of contact (e.g. janedoe@surveysparrow.com)
  --jobTitle: string # Job Title of the contact (e.g. Manager)
  --list: list # ID of Labels the contact has to be added into ? (e.g. [])
  --contact-type: string@contact-type-completer # Type of contact (default: contact)
]: any -> record<id: float, active: bool, unsubscribed: bool, fullName: string, mobile: string, email: string, jobTitle: string, list: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contacts")
  let body = {name: $name, phone: $phone, mobile: $mobile, email: $email, jobTitle: $jobTitle, list: $list, contact_type: $contact_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List roles
#
# GET /v1/roles
# operationId: getV1Roles
export def "roles get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get surveys
#
# GET /v1/surveys
# operationId: getV1Surveys
export def "surveys get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: float # default: 50
  --page: float
  --surveyTypes: string
  --archived: string@bool-completer # default: false
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "surveyTypes" $surveyTypes "scalar") (serialize-qp "archived" $archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/surveys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create survey
#
# POST /v1/surveys
# operationId: postV1Surveys
# --thankyou_json item shape: {preAdded?: bool, message?: string, description?: string, redirectBoolean?: bool, redirectMultiBoolean?: bool, redirect?: record, branding?: bool}
export def "surveys post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  surveyType: string@surveyType-completer
  --workspace-id: float
  --visibility: string@visibility-completer # default: Public
  --theme-id: float
  --primaryLanguage: string
  --welcomeScreenYesButtonText: string
  --welcomeText: string
  --welcomeDescription: string
  --thankyou-json: list # item shape: {preAdded?: bool, message?: string, description?: string, redirectBoolean?: bool, redirectMultiBoolean?: bool, redirect?: record, branding?: bool}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/surveys")
  let body = {name: $name, surveyType: $surveyType, workspace_id: $workspace_id, visibility: $visibility, theme_id: $theme_id, primaryLanguage: $primaryLanguage, welcomeScreenYesButtonText: $welcomeScreenYesButtonText, welcomeText: $welcomeText, welcomeDescription: $welcomeDescription, thankyou_json: $thankyou_json} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get public themes for a Survey
#
# GET /v1/surveythemes
# operationId: getV1Surveythemes
export def "surveythemes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --surveyType: string@surveyType-completer-1
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "surveyType" $surveyType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/surveythemes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List targets
#
# GET /v1/targets
# operationId: getV1Targets
export def "targets get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: float # default: 50
  --page: float
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/targets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List teams
#
# GET /v1/teams
# operationId: getV1Teams
export def "teams get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/teams")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create team
#
# POST /v1/teams
# operationId: postV1Teams
export def "teams post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --type: string@type-completer-1 # Team type, if not provided will be "SURVEY" by default (default: SURVEY)
  --userIds: list
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/teams")
  let body = {name: $name, type: $type, userIds: $userIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List users
#
# GET /v1/users
# operationId: getV1Users
export def "users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create user
#
# POST /v1/users
# operationId: postV1Users
export def "users post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  email: string
  role_id: float
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users")
  let body = {name: $name, email: $email, role_id: $role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List webhooks
#
# GET /v1/webhooks
# operationId: getV1Webhooks
export def "webhooks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: float # default: 50
  --page: float
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create webhook
#
# POST /v1/webhooks
# operationId: postV1Webhooks
export def "webhooks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --description: string
  --body-url: string
  --eventType: string # default: submission_completed
  --objectType: string # default: survey
  --objectId: float
  --surveyId: float
  httpMethod: string@httpMethod-completer
  --headers: list
  --type: string # default: application
  --payload: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/webhooks")
  let body = {name: $name, description: $description, url: $body_url, eventType: $eventType, objectType: $objectType, objectId: $objectId, surveyId: $surveyId, httpMethod: $httpMethod, headers: $headers, type: $type, payload: $payload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List workspaces
#
# GET /v1/workspaces
# operationId: getV1Workspaces
export def "workspaces list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: float # default: 50
  --page: float
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/workspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create workspace
#
# POST /v1/workspaces
# operationId: postV1Workspaces
export def "workspaces post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teams: list
  --users: list
  name: string
  visibility: string@visibility-completer-1
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspaces")
  let body = {teams: $teams, users: $users, name: $name, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List audit logs
#
# GET /v3/audit_logs
# operationId: getV3Audit_logs
export def "audit-logs logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --event-type: string@event-type-completer # type of audit logs
  --page: float # The page number to start searching audit logs. Default page number is 1 (default: 1)
  --limit: float # The maximum number of audit logs response per page. Defaults is 100 if not provided. Maximum allowed value is 500. (default: 100)
  --start-date: string # Start date of data range (format: date)
  --end-date: string # End date of data range (format: date)
]: nothing -> record<has_next_page: bool, count: float, list: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "event_type" $event_type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/audit_logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all channels
#
# GET /v3/channels
# operationId: getV3Channels
export def "channels list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --survey-id: float
  --limit: float # default: 50
  --page: float
  --type: string@type-completer-2
]: nothing -> record<has_next_page: bool, data: table<id: float, name: string, status: string, type: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "survey_id" $survey_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a channel
#
# POST /v3/channels
# operationId: postV3Channels
# --contacts item shape: {email?: string, mobile?: string, referenceId?: string, variables?: record}
# --schedule shape: {frequency: "WEEKLY"|"MONTHLY"|"YEARLY", config: record}
# --relative_schedule shape: {first_nps?: record, after_first_nps_schedule: "NONE"|"EVERY_45_DAYS"|"EVERY_3_MONTHS"|"EVERY_6_MONTHS"|"EVERY_1_YEAR"}
# --reminders item shape: {subject?: string, body?: string, type: "NOT_RESPONDED"|"PARTIALLY_RESPONDED", interval: float, frequency: "Days"|"Weeks"|"Months", properties?: record}
# --sms shape: {message?: string, twilio_consent_agreed?: bool, target_id?: float}
# --email shape: {subject: string, properties?: record, theme_id?: float}
# --link shape: {title?: string, description?: string, image_link?: string}
# --offline shape: {animation_direction?: "Horizontal"|"Vertical"}
export def "channels post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-3 # Type of the channel
  --mode: string@mode-completer # Mode of the channel, not required when type is LINK and OFFLINE (default: BLAST)
  --channel-id: float # Deprecated, please use update channel instead
  --contacts: list # item shape: {email?: string, mobile?: string, referenceId?: string, variables?: record}
  --contact-list-ids: list
  --body-variables: record
  survey_id: float # Id of the survey
  name: string # Name of the channel
  --send-after-date: string # Timestamp at which survey should be sent (format: date)
  --send-after-days: float # Number of days after which survey should be shared
  --schedule: record # shape: {frequency: "WEEKLY"|"MONTHLY"|"YEARLY", config: record}
  --relative-schedule: record # shape: {first_nps?: record, after_first_nps_schedule: "NONE"|"EVERY_45_DAYS"|"EVERY_3_MONTHS"|"EVERY_6_MONTHS"|"EVERY_1_YEAR"}
  --reminders: list # Array of reminders — item shape: {subject?: string, body?: string, type: "NOT_RESPONDED"|"PARTIALLY_RESPONDED", interval: float, frequency: "Days"|"Weeks"|"Months", properties?: record}
  --sms: record # Only required when type is SMS — shape: {message?: string, twilio_consent_agreed?: bool, target_id?: float}
  --email: record # shape: {subject: string, properties?: record, theme_id?: float}
  --link: record # shape: {title?: string, description?: string, image_link?: string}
  --offline: record # shape: {animation_direction?: "Horizontal"|"Vertical"}
  --ignore-throttled-contacts: string@bool-completer # If set to true, survey will be shared even if throttling is met (default: true)
  --accept-anonymous-response: string@bool-completer # Only applicable for CX survey types (default: false)
]: any -> record<data: record<id: float, name: string, status: string, type: string, properties: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/channels")
  let body = {type: $type, mode: $mode, channel_id: $channel_id, contacts: $contacts, contact_list_ids: $contact_list_ids, variables: $body_variables, survey_id: $survey_id, name: $name, send_after_date: $send_after_date, send_after_days: $send_after_days, schedule: $schedule, relative_schedule: $relative_schedule, reminders: $reminders, sms: $sms, email: $email, link: $link, offline: $offline, ignore_throttled_contacts: $ignore_throttled_contacts, accept_anonymous_response: $accept_anonymous_response} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all contact lists
#
# GET /v3/contact_lists
# operationId: getV3Contact_lists
export def "contact-lists lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: float, name: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/contact_lists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a contact list
#
# POST /v3/contact_lists
# operationId: postV3Contact_lists
export def "contact-lists lists-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --description: string
]: any -> record<data: record<id: float, name: string, description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/contact_lists")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all contact properties
#
# GET /v3/contact_properties
# operationId: getV3Contact_properties
export def "contact-properties properties" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: float, name: string, label: string, type: string, description: string, contact_property_group_id: float, group: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/contact_properties")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a contact property
#
# POST /v3/contact_properties
# operationId: postV3Contact_properties
export def "contact-properties properties-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-4
  label: string
  --description: string
  --contact-property-group-id: float
]: any -> record<data: record<id: float, name: string, label: string, type: string, description: string, contact_property_group_id: float, group: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/contact_properties")
  let body = {type: $type, label: $label, description: $description, contact_property_group_id: $contact_property_group_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all Contacts
#
# GET /v3/contacts
# operationId: getV3Contacts
export def "contacts get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contact-list-id: float # Contact List Id
  --type: string@type-completer # Filters type of contact
  --search: string # Search string which will search all the properties of a contact for a matching value
  --limit: float # Number of records you would like in a request (default: 50)
  --page: float # Page of results (default: 1)
  --contact-type: string@contact-type-completer # Type of contact
  --created-dategte: string # Filter contacts created after the given date (format: date)
  --created-datelte: string # Filter contacts created before the given date (format: date)
]: nothing -> record<has_next_page: bool, data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contact_list_id" $contact_list_id "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "contact_type" $contact_type "scalar") (serialize-qp "created_date.gte" $created_dategte "scalar") (serialize-qp "created_date.lte" $created_datelte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/contacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a contact
#
# POST /v3/contacts
# operationId: postV3Contacts
export def "contacts post-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full-name: string # Full Name of contact (e.g. Jane Doe)
  --email: string # Email of contact. Can be optional only if anonymous contact feature is enabled. (e.g. janedoe@surveysparrow.com)
  --phone: string # Phone number of the contact (e.g. 91234567833)
  --mobile: string # Mobile number of the contact (e.g. 1653452783)
  --job-title: string # Job Title of the contact (e.g. Manager)
  --contact-type: string@contact-type-completer # Type of contact (default: contact)
  --referenceId: string # Reference ID of the anonymous contact (e.g. 123456)
  --unique-id: string # Unique ID of the contact (e.g. abc123)
  --unsubscribed: string@bool-completer # Unsubscribed status of the contact (e.g. false)
  --unsubscribe-text: string # Reason for unsubscribing (e.g. Not interested)
]: any -> record<data: record<full_name: string, email: string, phone: string, mobile: string, job_title: string, contact_type: string, referenceId: string, unique_id: string, unsubscribed: bool, unsubscribe_text: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/contacts")
  let body = {full_name: $full_name, email: $email, phone: $phone, mobile: $mobile, job_title: $job_title, contact_type: $contact_type, referenceId: $referenceId, unique_id: $unique_id, unsubscribed: $unsubscribed, unsubscribe_text: $unsubscribe_text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get email themes
#
# GET /v3/email_themes
# operationId: getV3Email_themes
export def "email-themes themes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: float, name: string, created_at: string, updated_at: string, properties: record, is_public: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/email_themes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all survey expressions
#
# GET /v3/expressions
# operationId: getV3Expressions
export def "expressions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --survey-id: float # Id of Survey
  --limit: float # Record limit per request; default is 50, maximum is 100. (default: 50)
  --page: float # Page of results
]: nothing -> record<data: table<id: float, name: string, representation: list>, has_next_page: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "survey_id" $survey_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/expressions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all languages available for translation
#
# GET /v3/languages
# operationId: getV3Languages
export def "languages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<standardLanguages: list<record>, customLanguages: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/languages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get metrics
#
# GET /v3/metrics
# operationId: getV3Metrics
export def "metrics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-5 # Value should be one of NPS
  --survey-id: float # If survey_id is not passed, metrics for all CX surveys in the account will be fetched
  --dategte: string # format: date
  --datelte: string # format: date
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "survey_id" $survey_id "scalar") (serialize-qp "date.gte" $dategte "scalar") (serialize-qp "date.lte" $datelte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all survey questions
#
# GET /v3/questions
# operationId: getV3Questions
export def "questions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # default: 50
  --page: float # default: 1
  --tag-name: string
  --survey-id: float # Id of Survey
  --language-label: string
]: nothing -> record<has_next_page: bool, data: table<id: float, type: string, position: string, hasDisplayLogic: bool, properties: record, survey_id: float, section_id: float, account_id: float, parent_question_id: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "tag_name" $tag_name "scalar") (serialize-qp "survey_id" $survey_id "scalar") (serialize-qp "language_label" $language_label "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/questions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a question
#
# POST /v3/questions
# operationId: postV3Questions
# --question shape: {text: string, description?: string, type: "FileInput"|"TextInput"|"OpinionScale"|"MultiChoice"|"BipolarMatrix"|"CameraInput"|"Consent"|"ConstantSum"|"ContactForm"|"DateTime"|"Dropdown"|"EmailInput"|"GroupRating"|"Matrix"|"Message"|"NumberInput"|"PhoneNumber"|"RankOrder"|"Rating"|"Signature"|"Slider"|"URLInput"|"YesNo"|"GroupRank"|"AudioInput"|"PaymentQuestion"|"NPSFeedback"|"CESFeedback"|"CSATFeedback", required?: bool, randomized?: bool, tags?: list, multiple_answers?: bool, choices?: list, hasScore?: bool, other?: bool, all_of_the_above?: bool, none_of_the_above?: bool, other_text?: record, all_of_the_above_text?: record, none_of_the_above_text?: record, properties?: record, column?: list, row?: list, display_logic?: record}
export def "questions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  survey_id: float # Survey Id (e.g. 1)
  --section-id: float # Section Id (e.g. 2)
  question: record # shape: {text: string, description?: string, type: "FileInput"|"TextInput"|"OpinionScale"|"MultiChoice"|"BipolarMatrix"|"CameraInput"|"Consent"|"ConstantSum"|"ContactForm"|"DateTime"|"Dropdown"|"EmailInput"|"GroupRating"|"Matrix"|"Message"|"NumberInput"|"PhoneNumber"|"RankOrder"|"Rating"|"Signature"|"Slider"|"URLInput"|"YesNo"|"GroupRank"|"AudioInput"|"PaymentQuestion"|"NPSFeedback"|"CESFeedback"|"CSATFeedback", required?: bool, randomized?: bool, tags?: list, multiple_answers?: bool, choices?: list, hasScore?: bool, other?: bool, all_of_the_above?: bool, none_of_the_above?: bool, other_text?: record, all_of_the_above_text?: record, none_of_the_above_text?: record, properties?: record, column?: list, row?: list, display_logic?: record}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/questions")
  let body = {survey_id: $survey_id, section_id: $section_id, question: $question} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Channel reminders
#
# GET /v3/reminders
# operationId: getV3Reminders
export def "reminders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --survey-id: float # Id of the survey
  --channel-id: float # Id of the channel
  --limit: float # default: 50
  --page: float
]: nothing -> record<has_next_page: bool, data: table<id: float, subject: string, frequency: string, type: string, after_days: float, sent_count: float, created_at: string, updated_at: string, survey_id: float, account_id: float, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "survey_id" $survey_id "scalar") (serialize-qp "channel_id" $channel_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/reminders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Reminder for a channel
#
# POST /v3/reminders
# operationId: postV3Reminders
# --properties shape: {embed_first_question: bool, custom_footer: bool, custom_footer_value?: string}
export def "reminders post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  channel_id: float # Id of the channel (e.g. 1)
  survey_id: float # Id of Survey (e.g. 1)
  --body-body: string
  --subject: string
  frequency: string@frequency-completer
  type: string@type-completer-6
  interval: float
  --properties: record # Properties of the reminder (default: {embed_first_question: true, custom_footer: false}) — shape: {embed_first_question: bool, custom_footer: bool, custom_footer_value?: string}
  --preview-text: string
]: any -> record<data: record<id: float, subject: string, frequency: string, type: string, after_days: float, sent_count: float, created_at: string, updated_at: string, survey_id: float, account_id: float, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/reminders")
  let body = {channel_id: $channel_id, survey_id: $survey_id, body: $body_body, subject: $subject, frequency: $frequency, type: $type, interval: $interval, properties: $properties, preview_text: $preview_text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get responses report public link
#
# GET /v3/reports
# operationId: getV3Reports
export def "reports get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --survey-id: float # ID of the survey
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "survey_id" $survey_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get response properties
#
# GET /v3/response_properties
# operationId: getV3Response_properties
export def "response-properties properties" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/response_properties")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all responses
#
# GET /v3/responses
# operationId: getV3Responses
export def "responses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # default: 50
  --survey-id: float
  --contact-id: float
  --contacts: record # Filter using contact properties. Custom contact properties are not supported. Encode parameters when using special characters.
  --qp-variables: record # Filter using custom variables. Encode parameters when using special characters. Provide the date values in either MM-DD-YYYY or YYYY-MM-DD format.
  --page: float
  --dategte: string # format: date
  --datelte: string # format: date
  --created-dategte: string # format: date
  --created-datelte: string # format: date
  --state: string@state-completer
  --order-by: string@order-by-completer # default: completedTime
  --order: string@order-completer # default: DESC
  --preserve-format: string@bool-completer # default: false
  --response-url: string@bool-completer # default: false
]: nothing -> record<total_count: float, has_next_page: bool, data: table<id: float, survey_id: float, contact_id: float, completed: string, channel_id: float, language: string, completed_time: string, answers: list, channel: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "survey_id" $survey_id "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "contacts" $contacts "scalar") (serialize-qp "variables" $qp_variables "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "date.gte" $dategte "scalar") (serialize-qp "date.lte" $datelte "scalar") (serialize-qp "created_date.gte" $created_dategte "scalar") (serialize-qp "created_date.lte" $created_datelte "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "preserve_format" $preserve_format "scalar") (serialize-qp "response_url" $response_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/responses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a response
#
# POST /v3/responses
# operationId: postV3Responses
# --meta_data shape: {os?: string, browser?: string, time_zone?: string, browser_language?: string, date_time?: string, tags?: list, ip?: string, device_type?: string, language?: string}
# --answers item shape: {question_id: float, parent_question_id?: float, answer: string, other_txt?: string, matrix_txt?: list, matrix_int?: list, region_code?: string, time?: string, time_zone?: string}
export def "responses post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  survey_id: float # ID of the survey (e.g. 1)
  --contact-id: float # ID of the contact (e.g. 2)
  --channel-id: float # ID of the channel (e.g. 3)
  --body-variables: record
  --trigger-workflow: string@bool-completer # Should this response trigger workflow (default: true)
  --meta-data: record # shape: {os?: string, browser?: string, time_zone?: string, browser_language?: string, date_time?: string, tags?: list, ip?: string, device_type?: string, language?: string}
  answers: list # item shape: {question_id: float, parent_question_id?: float, answer: string, other_txt?: string, matrix_txt?: list, matrix_int?: list, region_code?: string, time?: string, time_zone?: string}
]: any -> record<data: record<id: float, state: string, time_taken: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/responses")
  let body = {survey_id: $survey_id, contact_id: $contact_id, channel_id: $channel_id, variables: $body_variables, trigger_workflow: $trigger_workflow, meta_data: $meta_data, answers: $answers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all roles
#
# GET /v3/roles
# operationId: getV3Roles
export def "roles get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # Number of records you would like in a request (default: 50)
  --page: float # Page of results
]: nothing -> record<data: table<id: float, name: string, label: string, description: string, account_id: float, created_at: string, updated_at: string, deleted_at: string>, has_next_page: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all survey folders
#
# GET /v3/survey_folders
# operationId: getV3Survey_folders
export def "survey-folders folders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # default: 50
  --page: float
  --enable-subfolders: string@bool-completer # Pass true to get the survey folder with its subfolders, surveys, and echoes (default: false)
]: nothing -> record<data: table<id: float, name: string, description: string, auto_created: bool, visibility: string, teams: list, surveys: list, parent_survey_folder_id: float, users: list, subfolders: list, echoes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "enable_subfolders" $enable_subfolders "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/survey_folders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a survey folder
#
# POST /v3/survey_folders
# operationId: postV3Survey_folders
export def "survey-folders folders-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable-subfolders: string@bool-completer # Pass true to get the survey folder with its subfolders, surveys, and echoes (default: false)
  --teams: list
  --users: list
  name: string
  --parent-survey-folder-id: float
  --visibility: string@visibility-completer-1
]: any -> record<data: record<id: float, name: string, description: string, auto_created: bool, visibility: string, teams: list<float>, surveys: list<record>, parent_survey_folder_id: float, users: list<float>, subfolders: list<record>, echoes: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enable_subfolders" $enable_subfolders "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/survey_folders" $qp)
  let body = {teams: $teams, users: $users, name: $name, parent_survey_folder_id: $parent_survey_folder_id, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all surveys
#
# GET /v3/surveys
# operationId: getV3Surveys
export def "surveys get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --survey-type: string@survey-type-completer # Type of survey
  --archived: string@bool-completer # Is the survey archived (default: false)
  --survey-folder-id: float # Survey folder Id of the survey
  --created-dategte: string # Survey created date greater than or equal to (format: date)
  --created-datelte: string # Survey created date less than or equal to (format: date)
  --updated-dategte: string # Survey updated date greater than or equal to (format: date)
  --updated-datelte: string # Survey updated date less than or equal to (format: date)
  --limit: float # Number of records you would like in a request (default: 50)
  --page: float # Page of results
]: nothing -> record<has_next_page: bool, data: table<id: float, name: string, archived: bool, survey_type: string, created_at: string, updated_at: string, survey_folder_id: float, survey_folder_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "survey_type" $survey_type "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "survey_folder_id" $survey_folder_id "scalar") (serialize-qp "created_date.gte" $created_dategte "scalar") (serialize-qp "created_date.lte" $created_datelte "scalar") (serialize-qp "updated_date.gte" $updated_dategte "scalar") (serialize-qp "updated_date.lte" $updated_datelte "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/surveys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a survey
#
# POST /v3/surveys
# operationId: postV3Surveys
# --thankyou_json item shape: {preAdded?: bool, message?: string, description?: string, redirect_url?: string, branding?: bool}
# --settings shape: {survey_randomize?: bool, submission_per_user?: record, throttling?: record, track_ip?: bool, track_location?: bool, edit_response?: bool, copy_of_response?: bool, partial_submission?: bool, auto_submission?: bool, response_limit?: float, cut_off_date?: string, dynamic_cut_off?: record, enable_offline_support?: bool, password?: string, disable_scroll_back?: bool, disable_contact_tracking?: bool}
export def "surveys post-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # e.g. Employee satisfaction survey
  survey_type: string@survey-type-completer-1
  --workspace-id: float # "workspace" has been renamed to "survey folder". We suggest using survey_folder_id instead of workspace_id
  --survey-folder-id: float
  --visibility: string@visibility-completer # default: Public
  --theme-id: float
  --primary-language: string
  --welcome-screen-button-text: string
  --welcome-text: string
  --welcome-description: string
  --thankyou-json: list # item shape: {preAdded?: bool, message?: string, description?: string, redirect_url?: string, branding?: bool}
  --settings: record # shape: {survey_randomize?: bool, submission_per_user?: record, throttling?: record, track_ip?: bool, track_location?: bool, edit_response?: bool, copy_of_response?: bool, partial_submission?: bool, auto_submission?: bool, response_limit?: float, cut_off_date?: string, dynamic_cut_off?: record, enable_offline_support?: bool, password?: string, disable_scroll_back?: bool, disable_contact_tracking?: bool}
]: any -> record<data: record<id: float, name: string, archived: bool, survey_type: string, created_at: string, updated_at: string, survey_folder_id: float, survey_folder_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/surveys")
  let body = {name: $name, survey_type: $survey_type, workspace_id: $workspace_id, survey_folder_id: $survey_folder_id, visibility: $visibility, theme_id: $theme_id, primary_language: $primary_language, welcome_screen_button_text: $welcome_screen_button_text, welcome_text: $welcome_text, welcome_description: $welcome_description, thankyou_json: $thankyou_json, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List targets
#
# GET /v3/targets
# operationId: getV3Targets
export def "targets get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # Number of records you would like in a request (default: 50)
  --page: float # Page of results (default: 1)
]: nothing -> record<data: record<targets: list<string>, page: float, count: float, has_next_page: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/targets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all teams
#
# GET /v3/teams
# operationId: getV3Teams
export def "teams get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # Number of records you would like in a request (default: 50)
  --page: float # Page of results
  --type: string@type-completer-1 # Type of team
]: nothing -> record<data: table<id: float, name: string, description: string, type: string, account_id: float, business_hour_id: float, round_robin_enabled: bool, created_at: string, updated_at: string, deleted_at: string>, has_next_page: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a team
#
# POST /v3/teams
# operationId: postV3Teams
export def "teams post-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Team name (e.g. Avengers)
  --type: string@type-completer-1 # Team type, if not provided will be "SURVEY" by default (default: SURVEY)
  --user-id: list # Id of users who should be added to the team (e.g. [1, 2, 3])
  --enable-round-robin: string@bool-completer # Enable round robin for the team (default: false, e.g. true)
]: any -> record<data: record<id: float, name: string, description: string, type: string, account_id: float, business_hour_id: float, round_robin_enabled: bool, created_at: string, updated_at: string, deleted_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/teams")
  let body = {name: $name, type: $type, user_id: $user_id, enable_round_robin: $enable_round_robin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all ticket templates
#
# GET /v3/templates
# operationId: getV3Templates
export def "templates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # Page of results
]: nothing -> record<data: table<id: float, name: string, description: string, created_at: string, updated_at: string, deleted_at: string, fields: list>, has_next_page: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all ticket fields
#
# GET /v3/ticket_fields
# operationId: getV3Ticket_fields
export def "ticket-fields fields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --created-dategte: string # Ticket field created date greater than or equal to. Should be in the format YYYY-MM-DDTHH:MM:SS (format: date)
  --created-datelte: string # Ticket field created date less than or equal to. Should be in the format YYYY-MM-DDTHH:MM:SS (format: date)
  --updated-dategte: string # Ticket field updated date greater than or equal to. Should be in the format YYYY-MM-DDTHH:MM:SS (format: date)
  --updated-datelte: string # Ticket field updated date less than or equal to. Should be in the format YYYY-MM-DDTHH:MM:SS (format: date)
  --limit: float # Record limit per request; default is 50, maximum is 100. (default: 50)
  --page: float # Page of results
]: nothing -> record<data: table<id: float, name: string, description: string, internal_name: string, type: string, is_default: bool, mandatory: bool, options: list, created_at: string, updated_at: string>, has_next_page: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "created_date.gte" $created_dategte "scalar") (serialize-qp "created_date.lte" $created_datelte "scalar") (serialize-qp "updated_date.gte" $updated_dategte "scalar") (serialize-qp "updated_date.lte" $updated_datelte "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/ticket_fields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all tickets
#
# GET /v3/tickets
# operationId: getV3Tickets
export def "tickets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # Record limit per request; default is 50, maximum is 100. (default: 50)
  --page: float # Page of results
  --requester-id: float # Ticket requester's contact id
  --assignee-id: float # Ticket agent's user id
  --team-id: float # Ticket team
  --priority: float # Ticket priority
  --status: float # Ticket status
  --created-dategte: string # Ticket created date greater than or equal to. Should be in the format YYYY-MM-DDTHH:MM:SS (format: date)
  --created-datelte: string # Ticket created date less than or equal to. Should be in the format YYYY-MM-DDTHH:MM:SS (format: date)
  --updated-dategte: string # Ticket updated date greater than or equal to. Should be in the format YYYY-MM-DDTHH:MM:SS (format: date)
  --updated-datelte: string # Ticket updated date less than or equal to. Should be in the format YYYY-MM-DDTHH:MM:SS (format: date)
  --trash: string@trash-completer # Filter tickets based on trash status. 'true' returns only trashed tickets, 'false' or 'null' returns only active tickets (default: false)
]: nothing -> record<data: table<id: float, requester: record, subject: string, description: string, description_html: string, priority: record, status: record, template_id: float, custom_fields: record, source: record, agent: record, team: record, created_at: string, updated_at: string, deleted_at: string, first_response_due: string, resolution_due: string>, has_next_page: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "requester_id" $requester_id "scalar") (serialize-qp "assignee_id" $assignee_id "scalar") (serialize-qp "team_id" $team_id "scalar") (serialize-qp "priority" $priority "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "created_date.gte" $created_dategte "scalar") (serialize-qp "created_date.lte" $created_datelte "scalar") (serialize-qp "updated_date.gte" $updated_dategte "scalar") (serialize-qp "updated_date.lte" $updated_datelte "scalar") (serialize-qp "trash" $trash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/tickets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a ticket
#
# POST /v3/tickets
# operationId: postV3Tickets
export def "tickets post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --requester-id: float # Ticket requester's contact id (e.g. 1)
  --email: string # Ticket requester's contact email (e.g. abc@ymail.com)
  --phone: string # Ticket requester's contact phone (e.g. + 123 23)
  --mobile: string # Ticket requester's contact mobile (e.g. + 098 76)
  subject: string # Ticket subject (e.g. Ticket subject 1)
  --description: string # Ticket description. Supports mentioning contacts using @email format. (e.g. Ticket description 1)
  --attachments: path # Following file types are allowed: pdf, png, jpeg, mp3, csv, wav. Maximum file size allowed is 15MB.
  priority: float # Ticket priority (e.g. 2)
  status: float # Ticket status (e.g. 3)
  --template-id: float # Ticket template id (e.g. 12532)
  --parent-ticket-id: float # The ID of the parent ticket to which this ticket is related (e.g. 12532)
  --child-ticket-ids: list # An array of ticket IDs representing the child tickets associated with this ticket
  --body-source: float # Ticket source (e.g. 4)
  --submission-id: float # Response ID (e.g. 5)
  --nps-submission-id: float # NPS Response ID (e.g. 6)
  --assignee-id: float # Ticket agent's user id (e.g. 7)
  --team-id: float # Ticket team's id (e.g. 8)
  --custom-fields: record
  --update-on-submission-change: string@bool-completer # Update the existing ticket using the submission ID. (e.g. true)
]: any -> record<data: record<id: float, requester: record, subject: string, description: string, description_html: string, priority: record, status: record, template_id: float, custom_fields: record, source: record, agent: record, team: record, created_at: string, updated_at: string, deleted_at: string, first_response_due: string, resolution_due: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/tickets")
  let body = {requester_id: $requester_id, email: $email, phone: $phone, mobile: $mobile, subject: $subject, description: $description, attachments: $attachments, priority: $priority, status: $status, template_id: $template_id, parent_ticket_id: $parent_ticket_id, child_ticket_ids: $child_ticket_ids, source: $body_source, submission_id: $submission_id, nps_submission_id: $nps_submission_id, assignee_id: $assignee_id, team_id: $team_id, custom_fields: $custom_fields, update_on_submission_change: $update_on_submission_change} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all users
#
# GET /v3/users
# operationId: getV3Users
export def "users get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # number of records to be fetched (default: 50)
  --page: float # Page of the contacts
]: nothing -> record<data: table<id: float, name: string, email: string, phone: string, admin: bool, owner: bool, agency_owner: bool, verified: bool, role_id: float>, has_next_page: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create user
#
# POST /v3/users
# operationId: postV3Users
export def "users post-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  email: string
  role_id: float
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/users")
  let body = {name: $name, email: $email, role_id: $role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all survey variables
#
# GET /v3/variables
# operationId: getV3Variables
export def "variables get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --survey-id: float # Id of Survey
  --limit: float # Number of records you would like in a request (default: 50)
  --page: float # Page of results
]: nothing -> record<data: table<id: float, label: string, name: string, description: string, type: string>, has_next_page: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "survey_id" $survey_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/variables" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a survey variable
#
# POST /v3/variables
# operationId: postV3Variables
export def "variables post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  survey_id: float # Id of Survey (e.g. 1)
  label: string
  name: string
  --description: string
  type: string@type-completer-7
]: any -> record<data: record<id: float, label: string, name: string, description: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/variables")
  let body = {survey_id: $survey_id, label: $label, name: $name, description: $description, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all webhooks
#
# GET /v3/webhooks
# operationId: getV3Webhooks
export def "webhooks get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # Maximum results per page (default: 50)
  --page: float # Page number in pagination
  --survey-id: float # Id of Survey
]: nothing -> record<has_next_page: bool, data: table<id: float, name: string, url: string, eventType: string, description: string, objectType: string, httpMethod: string, headers: list, properties: record, disabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "survey_id" $survey_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a webhook
#
# POST /v3/webhooks
# operationId: postV3Webhooks
export def "webhooks post-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --description: string
  --body-url: string
  --event-type: string # default: submission_completed
  --object-type: string # default: survey
  survey_id: float
  http_method: string@http-method-completer
  --headers: list
  --type: string # default: application
  --payload: record
  --include-partial-submission: string@bool-completer # default: false, e.g. true
]: any -> record<data: record<id: float, name: string, url: string, eventType: string, description: string, objectType: string, httpMethod: string, headers: list<record>, properties: record<payload: string, includePartialSubmission: bool>, disabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/webhooks")
  let body = {name: $name, description: $description, url: $body_url, event_type: $event_type, object_type: $object_type, survey_id: $survey_id, http_method: $http_method, headers: $headers, type: $type, payload: $payload, include_partial_submission: $include_partial_submission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List subscribed events
#
# GET /v1/audit-logs/events
# operationId: getV1AuditlogsEvents
export def "audit-logs-events get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --eventType: string@eventType-completer
  --page: float # default: 1
  --maxResults: float # default: 50
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "eventType" $eventType "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/audit-logs/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get audit log
#
# GET /v1/audit-logs/{id}
# operationId: getV1AuditlogsId
export def "audit-logs get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/audit-logs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List contact properties
#
# GET /v1/contacts/properties
# operationId: getV1ContactsProperties
export def "contacts-properties get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contacts/properties")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create contact property
#
# POST /v1/contacts/properties
# operationId: postV1ContactsProperties
export def "contacts-properties post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-4
  label: string
  --description: string
  --contact-property-group-id: float
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contacts/properties")
  let body = {type: $type, label: $label, description: $description, contact_property_group_id: $contact_property_group_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get contact
#
# GET /v1/contacts/{id}
# operationId: getV1ContactsId
export def "contacts get-by-id" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authorization: string # Custom Token generated from the App
]: nothing -> record<id: float, name: string, email: string, active: bool, unsubscribed: bool, unsubscribed_at: string, phone: string, mobile: string, jobTitle: string, list: table<id: float, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/contacts/($id)")
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update contact
#
# PUT /v1/contacts/{id}
# operationId: putV1ContactsId
export def "contacts put-by-id" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authorization: string # Custom Token generated from the App
  --name: string # Full Name of contact (e.g. Jane Doe)
  --email: string # Email of contact (e.g. janedoe@surveysparrow.com)
  --phone: string # Phone number of the contact (e.g. 91234567833)
  --mobile: string # Mobile number of the contact (e.g. 1653452783)
  --jobTitle: string # Job Title of the contact (e.g. Manager)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/contacts/($id)")
  let body = {name: $name, email: $email, phone: $phone, mobile: $mobile, jobTitle: $jobTitle} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete contact
#
# DELETE /v1/contacts/{id}
# operationId: deleteV1ContactsId
export def "contacts delete-by-id" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authorization: string # Custom Token generated from the App
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/contacts/($id)")
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get survey
#
# GET /v1/surveys/{id}
# operationId: getV1SurveysId
export def "surveys get-by-id" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reportShareToken: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportShareToken" $reportShareToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/surveys/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update survey details
#
# PUT /v1/surveys/{id}
# operationId: putV1SurveysId
# --thankyou_json item shape: {preAdded?: bool, message?: string, description?: string, redirectBoolean?: bool, redirectMultiBoolean?: bool, redirect?: string, branding?: bool, redirectMulti?: record}
export def "surveys put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --workspace-id: float
  --theme-id: float
  --welcomeDescriptionEnabled: string@bool-completer # default: true
  --welcomeScreenYesButtonText: string
  --welcomeText: string
  --welcomeDescription: string
  --addThankyouPage: string@bool-completer # default: false
  --thankyou-json: list # item shape: {preAdded?: bool, message?: string, description?: string, redirectBoolean?: bool, redirectMultiBoolean?: bool, redirect?: string, branding?: bool, redirectMulti?: record}
  --archived: string@bool-completer
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/surveys/($id)")
  let body = {name: $name, workspace_id: $workspace_id, theme_id: $theme_id, welcomeDescriptionEnabled: $welcomeDescriptionEnabled, welcomeScreenYesButtonText: $welcomeScreenYesButtonText, welcomeText: $welcomeText, welcomeDescription: $welcomeDescription, addThankyouPage: $addThankyouPage, thankyou_json: $thankyou_json, archived: $archived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get user
#
# GET /v1/users/{id}
# operationId: getV1UsersId
export def "users get-by-id" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user
#
# PUT /v1/users/{id}
# operationId: putV1UsersId
export def "users put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --role-id: float
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($id)")
  let body = {name: $name, role_id: $role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete user
#
# DELETE /v1/users/{id}
# operationId: deleteV1UsersId
export def "users delete-by-id" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get workspace
#
# GET /v1/workspaces/{id}
# operationId: getV1WorkspacesId
export def "workspaces get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workspaces/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update workspace
#
# PUT /v1/workspaces/{id}
# operationId: putV1WorkspacesId
export def "workspaces put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --visibility: string@visibility-completer-1
  --teams: list
  --users: list
  --name: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workspaces/($id)")
  let body = {visibility: $visibility, teams: $teams, users: $users, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete workspace
#
# DELETE /v1/workspaces/{id}
# operationId: deleteV1WorkspacesId
export def "workspaces delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workspaces/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List subscribed events
#
# GET /v3/audit_logs/events
# operationId: getV3Audit_logsEvents
export def "audit-logs-events logsEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --event-type: string@event-type-completer # Type of the event
  --page: float # The page number to start searching audit log event. Default page number is 1 (default: 1)
  --limit: float # The maximum number of audit log event response per page. Defaults is 50 if not provided. Maximum allowed value is 100. (default: 50)
]: nothing -> record<has_next_page: bool, count: float, events: table<id: float, event: string, url: string, http_method: string, headers: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "event_type" $event_type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/audit_logs/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create subscribed event
#
# POST /v3/audit_logs/events
# operationId: postV3Audit_logsEvents
# --events item shape: {name?: "SURVEY_CREATED"|"SURVEY_EDITED"|"SURVEY_DELETED"|"THEME_ADDED"|"THEME_EDITED"|"THEME_DELETED"|"USER_CREATED"|"USER_DELETED"|"USER_EDITED"|"CONTACT_CREATED"|"CONTACT_UPDATED"|"CONTACT_DELETED"|"CONTACT_PROPERTY_CREATED"|"CONTACT_PROPERTY_EDITED"|"CONTACT_PROPERTY_DELETED"|"WORKSPACE_CREATED"|"WORKSPACE_DELETED"|"WORKSPACE_EDITED"|"SYNC_DEVICES"|"SURVEY_RESPONSE_IMPORT"|"SURVEY_RESPONSE_DELETION"|"SURVEY_CLOSED"|"SURVEY_RESTORED"|"SURVEY_OWNERSHIP_TRANSFER"|"FOLDER_USER_ACCESS_GRANT"|"FOLDER_USER_ACCESS_REMOVE"|"FOLDER_TEAM_ACCESS_GRANT"|"FOLDER_TEAM_ACCESS_REMOVE"|"SURVEY_MOVED"|"SURVEY_PASSWORD_CREATED"|"SURVEY_PASSWORD_DELETED"|"SURVEY_PASSWORD_EDITED"|"QUESTION_CATALOG_CREATED"|"QUESTION_CATALOG_DELETED"|"LOGIN"|"LOGOUT"|"TICKET_TEMPLATE_CREATED"|"TICKET_TEMPLATE_UPDATED"|"TICKET_TEMPLATE_DELETED"|"SANDBOX_SURVEY_CLONED_TO_SANDBOX"|"SANDBOX_SURVEY_CLONED_TO_MAIN"|"SANDBOX_BULK_CLONE_TO_SANDBOX"|"SANDBOX_ACCOUNT_CREATED"|"SANDBOX_USERS_ADDED"|"SANDBOX_SURVEY_SYNCED"|"FIREWALL_RULE_CREATED"|"FIREWALL_RULE_UPDATED"|"FIREWALL_RULE_DELETED"|"CUSTOM_RESPONSE_RATE_SWITCHED"|"CUSTOM_METRIC_CREATED"|"CUSTOM_METRIC_UPDATED"|"CUSTOM_METRIC_DELETED"|"SURVEY_FOLDER_MOVED"}
export def "audit-logs-events logsEvents-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  events: list # Array of event names (e.g. [{name: SURVEY_CREATED}]) — item shape: {name?: "SURVEY_CREATED"|"SURVEY_EDITED"|"SURVEY_DELETED"|"THEME_ADDED"|"THEME_EDITED"|"THEME_DELETED"|"USER_CREATED"|"USER_DELETED"|"USER_EDITED"|"CONTACT_CREATED"|"CONTACT_UPDATED"|"CONTACT_DELETED"|"CONTACT_PROPERTY_CREATED"|"CONTACT_PROPERTY_EDITED"|"CONTACT_PROPERTY_DELETED"|"WORKSPACE_CREATED"|"WORKSPACE_DELETED"|"WORKSPACE_EDITED"|"SYNC_DEVICES"|"SURVEY_RESPONSE_IMPORT"|"SURVEY_RESPONSE_DELETION"|"SURVEY_CLOSED"|"SURVEY_RESTORED"|"SURVEY_OWNERSHIP_TRANSFER"|"FOLDER_USER_ACCESS_GRANT"|"FOLDER_USER_ACCESS_REMOVE"|"FOLDER_TEAM_ACCESS_GRANT"|"FOLDER_TEAM_ACCESS_REMOVE"|"SURVEY_MOVED"|"SURVEY_PASSWORD_CREATED"|"SURVEY_PASSWORD_DELETED"|"SURVEY_PASSWORD_EDITED"|"QUESTION_CATALOG_CREATED"|"QUESTION_CATALOG_DELETED"|"LOGIN"|"LOGOUT"|"TICKET_TEMPLATE_CREATED"|"TICKET_TEMPLATE_UPDATED"|"TICKET_TEMPLATE_DELETED"|"SANDBOX_SURVEY_CLONED_TO_SANDBOX"|"SANDBOX_SURVEY_CLONED_TO_MAIN"|"SANDBOX_BULK_CLONE_TO_SANDBOX"|"SANDBOX_ACCOUNT_CREATED"|"SANDBOX_USERS_ADDED"|"SANDBOX_SURVEY_SYNCED"|"FIREWALL_RULE_CREATED"|"FIREWALL_RULE_UPDATED"|"FIREWALL_RULE_DELETED"|"CUSTOM_RESPONSE_RATE_SWITCHED"|"CUSTOM_METRIC_CREATED"|"CUSTOM_METRIC_UPDATED"|"CUSTOM_METRIC_DELETED"|"SURVEY_FOLDER_MOVED"}
  http_method: string@http-method-completer-1 # The HTTP method for the request (GET, PUT, POST, or DELETE). (e.g. POST)
  --body-url: string # URL of audit webhook event (e.g. https://subscribed.com/data)
  --headers: record
]: any -> record<events: table<id: float, event: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/audit_logs/events")
  let body = {events: $events, http_method: $http_method, url: $body_url, headers: $headers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get audit log
#
# GET /v3/audit_logs/{id}
# operationId: getV3Audit_logsId
export def "audit-logs logsId" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/audit_logs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a channel
#
# GET /v3/channels/{id}
# operationId: getV3ChannelsId
export def "channels get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --survey-id: float
]: nothing -> record<data: record<id: float, name: string, status: string, type: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "survey_id" $survey_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/channels/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a channel
#
# PUT /v3/channels/{id}
# operationId: putV3ChannelsId
export def "channels put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  survey_id: float # Id of the survey
]: any -> record<data: record<id: float, name: string, status: string, type: string, properties: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/channels/($id)")
  let body = {survey_id: $survey_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a channel
#
# DELETE /v3/channels/{id}
# operationId: deleteV3ChannelsId
export def "channels delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --survey-id: float # Id of the survey
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "survey_id" $survey_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/channels/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a contact list
#
# GET /v3/contact_lists/{id}
# operationId: getV3Contact_listsId
export def "contact-lists listsId-by-id" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: float, name: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/contact_lists/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a contact list
#
# DELETE /v3/contact_lists/{id}
# operationId: deleteV3Contact_listsId
export def "contact-lists listsId-by-id-1" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/contact_lists/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a contact list
#
# PATCH /v3/contact_lists/{id}
# operationId: patchV3Contact_listsId
export def "contact-lists listsId-by-id-2" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --description: string
]: any -> record<data: record<id: float, name: string, description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/contact_lists/($id)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a contact
#
# GET /v3/contacts/{id}
# operationId: getV3ContactsId
export def "contacts get-by-id-1" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/contacts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a contact
#
# PUT /v3/contacts/{id}
# operationId: putV3ContactsId
export def "contacts put-by-id-1" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full-name: string # Full Name of contact (e.g. Jane Doe)
  --email: string # Email of contact. Can be optional only if anonymous contact feature is enabled. (e.g. janedoe@surveysparrow.com)
  --phone: string # Phone number of the contact (e.g. 91234567833)
  --mobile: string # Mobile number of the contact (e.g. 1653452783)
  --job-title: string # Job Title of the contact (e.g. Manager)
  --referenceId: string # Reference ID of the anonymous contact (e.g. 123456)
  --unique-id: string # Unique ID of the contact (e.g. abc123)
  --unsubscribe-text: string # Reason for unsubscribing (e.g. Not interested)
]: any -> record<data: record<id: float, name: string, email: string, active: bool, unsubscribed: bool, unsubscribed_at: string, phone: string, mobile: string, jobTitle: string, contactLists: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/contacts/($id)")
  let body = {full_name: $full_name, email: $email, phone: $phone, mobile: $mobile, job_title: $job_title, referenceId: $referenceId, unique_id: $unique_id, unsubscribe_text: $unsubscribe_text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a contact
#
# DELETE /v3/contacts/{id}
# operationId: deleteV3ContactsId
export def "contacts delete-by-id-1" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/contacts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List respones based on metrics of CX surveys
#
# GET /v3/metrics/responses
# operationId: getV3MetricsResponses
export def "metrics-responses get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dategte: string # format: date
  --datelte: string # format: date
  --limit: float # Maximum results a page can have
  --page: float # Page Number
  --survey-id: float # Id of the Survey
  --type: string@type-completer-5 # Value should be one of CX metric type (default: NPS)
  --category: string@category-completer # Metric category based survey type: NPS (detractors, passives, promoters), CES (lowEfforts, highEfforts, neutral), CSAT (satisfied, neutral, dissatisfied) (default: Promoters)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date.gte" $dategte "scalar") (serialize-qp "date.lte" $datelte "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "survey_id" $survey_id "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "category" $category "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/metrics/responses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Channel reminder
#
# GET /v3/reminders/{id}
# operationId: getV3RemindersId
export def "reminders get" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --survey-id: float # Id of the survey
  --channel-id: float # Id of the channel
]: nothing -> record<data: record<id: float, subject: string, frequency: string, type: string, after_days: float, sent_count: float, created_at: string, updated_at: string, survey_id: float, account_id: float, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "survey_id" $survey_id "scalar") (serialize-qp "channel_id" $channel_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/reminders/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a channel reminder
#
# DELETE /v3/reminders/{id}
# operationId: deleteV3RemindersId
export def "reminders delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --survey-id: float # Id of the survey
  --channel-id: float # Id of the channel
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "survey_id" $survey_id "scalar") (serialize-qp "channel_id" $channel_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/reminders/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get report of the question in a survey
#
# GET /v3/reports/question
# operationId: getV3ReportsQuestion
export def "reports-question get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --survey-id: float # ID of the survey
  --question-id: float # ID of the question
  --start-date: string # Start date of the date range
  --end-date: string # End date of the date range
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "survey_id" $survey_id "scalar") (serialize-qp "question_id" $question_id "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/reports/question" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all app platforms
#
# GET /v3/reputation/app_platforms
# operationId: getV3ReputationApp_platforms
export def "reputation-app-platforms platforms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # Page of results (default: 1)
  --limit: float # Number of records you would like in a request (default: 50)
]: nothing -> record<has_next_page: bool, data: table<id: float, data_fetch_address: string, location: string, is_active: bool, platform_id: float, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/reputation/app_platforms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all platforms
#
# GET /v3/reputation/platforms
# operationId: getV3ReputationPlatforms
export def "reputation-platforms list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # Number of records you would like in a request (default: 50)
  --page: float # Page of results (default: 1)
]: nothing -> record<has_next_page: bool, data: table<id: float, label: string, type: string, logo_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/reputation/platforms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all reviews
#
# GET /v3/reputation/reviews
# operationId: getV3ReputationReviews
export def "reputation-reviews list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --app-platform-id: float # Id of AppPlatform
  --ratinglte: float # Rating greater than filer is optional
  --ratinggte: float # Rating less than filter is optional
  --review-datelte: string # less than filter is optional (format: date)
  --review-dategte: string # greater than filer is optional (format: date)
  --limit: float # Number of records you would like in a request (default: 50)
  --page: float # Page of results (default: 1)
]: nothing -> record<has_next_page: bool, data: table<id: float, rating: float, review_title: string, review_content: string, review_date: string, reviewer_name: string, reviewer_photo_url: string, app_platform_id: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_platform_id" $app_platform_id "scalar") (serialize-qp "rating.lte" $ratinglte "scalar") (serialize-qp "rating.gte" $ratinggte "scalar") (serialize-qp "review_date.lte" $review_datelte "scalar") (serialize-qp "review_date.gte" $review_dategte "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/reputation/reviews" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import a review for a custom location
#
# POST /v3/reputation/reviews
# operationId: postV3ReputationReviews
export def "reputation-reviews post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --custom-app-platform-id: float
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "custom_app_platform_id" $custom_app_platform_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/reputation/reviews" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a response
#
# GET /v3/responses/{id}
# operationId: getV3ResponsesId
export def "responses get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --survey-id: float
  --preserve-format: string@bool-completer # default: false
  --response-url: string@bool-completer # default: false
]: nothing -> record<data: record<id: float, survey_id: float, contact_id: float, completed: string, channel_id: float, language: string, completed_time: string, answers: list<record>, channel: record<name: string, type: string, status: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "survey_id" $survey_id "scalar") (serialize-qp "preserve_format" $preserve_format "scalar") (serialize-qp "response_url" $response_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/responses/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a response
#
# PUT /v3/responses/{id}
# operationId: putV3ResponsesId
# --answers item shape: {question_id: float, parent_question_id?: float, answer: string, other_txt?: string, matrix_txt?: list, matrix_int?: list, region_code?: string, time?: string, time_zone?: string}
export def "responses put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  survey_id: float # ID of the survey (e.g. 1)
  --contact-id: float # ID of the contact (e.g. 2)
  answers: list # item shape: {question_id: float, parent_question_id?: float, answer: string, other_txt?: string, matrix_txt?: list, matrix_int?: list, region_code?: string, time?: string, time_zone?: string}
  --body-variables: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/responses/($id)")
  let body = {survey_id: $survey_id, contact_id: $contact_id, answers: $answers, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a response
#
# DELETE /v3/responses/{id}
# operationId: deleteV3ResponsesId
export def "responses delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --survey-id: float
  --delete-quota: string@bool-completer # default: false
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "survey_id" $survey_id "scalar") (serialize-qp "delete_quota" $delete_quota "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/responses/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List approvers
#
# GET /v3/survey/approvers
# operationId: getV3SurveyApprovers
export def "survey-approvers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --survey-id: float # Id of the survey
  --limit: float # default: 50
  --page: float
]: nothing -> record<data: record<list: list<record>, count: float, limit: float, page: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "survey_id" $survey_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/survey/approvers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Relations
#
# GET /v3/survey/relations
# operationId: getV3SurveyRelations
export def "survey-relations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --survey-id: float # Id of the survey
]: nothing -> record<data: record<list: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "survey_id" $survey_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/survey/relations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List subjects
#
# GET /v3/survey/subjects
# operationId: getV3SurveySubjects
export def "survey-subjects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --survey-id: float # Id of the survey
  --limit: float # default: 50
  --page: float
  --email: string
]: nothing -> record<data: record<list: list<record>, count: float, limit: float, page: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "survey_id" $survey_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/survey/subjects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a survey folder
#
# GET /v3/survey_folders/{id}
# operationId: getV3Survey_foldersId
export def "survey-folders foldersId-by-id" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable-subfolders: string@bool-completer # Pass true to get the survey folder with its subfolders, surveys, and echoes (default: false)
]: nothing -> record<data: record<id: float, name: string, description: string, auto_created: bool, visibility: string, teams: list<float>, surveys: list<record>, parent_survey_folder_id: float, users: list<float>, subfolders: list<record>, echoes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enable_subfolders" $enable_subfolders "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/survey_folders/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a survey folder
#
# DELETE /v3/survey_folders/{id}
# operationId: deleteV3Survey_foldersId
export def "survey-folders foldersId-by-id-1" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable-subfolders: string@bool-completer # Pass true to get the survey folder with its subfolders, surveys, and echoes (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enable_subfolders" $enable_subfolders "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/survey_folders/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a survey folder
#
# PATCH /v3/survey_folders/{id}
# operationId: patchV3Survey_foldersId
export def "survey-folders foldersId-by-id-2" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable-subfolders: string@bool-completer # Pass true to get the survey folder with its subfolders, surveys, and echoes (default: false)
  --visibility: string@visibility-completer-1
  --teams: list
  --users: list
  --name: string
]: any -> record<data: record<id: float, name: string, description: string, auto_created: bool, visibility: string, teams: list<float>, surveys: list<record>, parent_survey_folder_id: float, users: list<float>, subfolders: list<record>, echoes: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enable_subfolders" $enable_subfolders "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/survey_folders/($id)" $qp)
  let body = {visibility: $visibility, teams: $teams, users: $users, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a survey
#
# GET /v3/surveys/{id}
# operationId: getV3SurveysId
export def "surveys get-by-id-1" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: float, name: string, archived: bool, survey_type: string, created_at: string, updated_at: string, survey_folder_id: float, survey_folder_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/surveys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a survey
#
# PATCH /v3/surveys/{id}
# operationId: patchV3SurveysId
# --thankyou_json item shape: {preAdded?: bool, message?: string, description?: string, redirect_url?: string, branding?: bool}
# --settings shape: {survey_randomize?: bool, submission_per_user?: record, throttling?: record, track_ip?: bool, track_location?: bool, edit_response?: bool, copy_of_response?: bool, partial_submission?: bool, auto_submission?: bool, response_limit?: float, cut_off_date?: string, dynamic_cut_off?: record, enable_offline_support?: bool, password?: string, disable_scroll_back?: bool, disable_contact_tracking?: bool}
export def "surveys patch" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --workspace-id: float
  --theme-id: float
  --welcome-text: string
  --thankyou-json: list # item shape: {preAdded?: bool, message?: string, description?: string, redirect_url?: string, branding?: bool}
  --archived: string@bool-completer
  --settings: record # shape: {survey_randomize?: bool, submission_per_user?: record, throttling?: record, track_ip?: bool, track_location?: bool, edit_response?: bool, copy_of_response?: bool, partial_submission?: bool, auto_submission?: bool, response_limit?: float, cut_off_date?: string, dynamic_cut_off?: record, enable_offline_support?: bool, password?: string, disable_scroll_back?: bool, disable_contact_tracking?: bool}
]: any -> record<data: table<id: float, name: string, archived: bool, survey_type: string, created_at: string, updated_at: string, survey_folder_id: float, survey_folder_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/surveys/($id)")
  let body = {name: $name, workspace_id: $workspace_id, theme_id: $theme_id, welcome_text: $welcome_text, thankyou_json: $thankyou_json, archived: $archived, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a ticket field
#
# GET /v3/ticket_fields/{id}
# operationId: getV3Ticket_fieldsId
export def "ticket-fields fieldsId" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: float, name: string, description: string, internal_name: string, type: string, is_default: bool, mandatory: bool, options: list<string>, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/ticket_fields/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a ticket
#
# GET /v3/tickets/{id}
# operationId: getV3TicketsId
export def "tickets get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: float, requester: record, subject: string, description: string, description_html: string, priority: record, status: record, template_id: float, custom_fields: record, source: record, agent: record, team: record, created_at: string, updated_at: string, deleted_at: string, first_response_due: string, resolution_due: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/tickets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a ticket
#
# PUT /v3/tickets/{id}
# operationId: putV3TicketsId
export def "tickets put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --priority: float # Ticket priority (e.g. 4)
  --status: float # Ticket status (e.g. 5)
  --assignee-id: float # Ticket agent's user id (e.g. 2)
  --team-id: float # Ticket team's id (e.g. 3)
  --parent-ticket-id: float # Links the current ticket to a parent ticket when a valid ticket ID is provided. Removes the parent-child relationship if null is provided. (e.g. 3456)
  --child-ticket-ids: list # Replaces all existing child tickets with the provided IDs, if an empty array ([]) is provided, all child associations will be removed. (e.g. [1234, 5678])
  --requester-id: float # Ticket requester's contact id (e.g. 100)
  --email: string # Ticket requester's contact email (e.g. user@example.com)
  --phone: string # Ticket requester's contact phone (e.g. +1234567890)
  --mobile: string # Ticket requester's contact mobile (e.g. +0987654321)
  --custom-fields: record
]: any -> record<data: record<id: float, requester: record, subject: string, description: string, description_html: string, priority: record, status: record, template_id: float, custom_fields: record, source: record, agent: record, team: record, created_at: string, updated_at: string, deleted_at: string, first_response_due: string, resolution_due: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/tickets/($id)")
  let body = {priority: $priority, status: $status, assignee_id: $assignee_id, team_id: $team_id, parent_ticket_id: $parent_ticket_id, child_ticket_ids: $child_ticket_ids, requester_id: $requester_id, email: $email, phone: $phone, mobile: $mobile, custom_fields: $custom_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a ticket
#
# DELETE /v3/tickets/{id}
# operationId: deleteV3TicketsId
export def "tickets delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/tickets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the specific language excel file
#
# GET /v3/translation/export
# operationId: getV3TranslationExport
export def "translation-export get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --survey-id: float # Survey ID
  --language-code: string # Language code
  --include-labels: string@bool-completer # Include labels in the file (default: true)
]: nothing -> record<data: record<translationFile: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "survey_id" $survey_id "scalar") (serialize-qp "language_code" $language_code "scalar") (serialize-qp "include_labels" $include_labels "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/translation/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user
#
# GET /v3/users/{id}
# operationId: getV3UsersId
export def "users get-by-id-1" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: float, name: string, email: string, phone: string, admin: bool, owner: bool, agency_owner: bool, verified: bool, role_id: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a user
#
# DELETE /v3/users/{id}
# operationId: deleteV3UsersId
export def "users delete-by-id-1" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user
#
# PATCH /v3/users/{id}
# operationId: patchV3UsersId
export def "users patch" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the user (e.g. John Doe)
  --role-id: float # User role Id (e.g. 1)
]: any -> record<data: record<id: float, name: string, email: string, phone: string, admin: bool, owner: bool, agency_owner: bool, verified: bool, role_id: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/users/($id)")
  let body = {name: $name, role_id: $role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List survey responses
#
# GET /v1/ces/{survey_id}/responses
# operationId: getV1CesSurvey_idResponses
export def "ces-responses idResponses" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dategte: string
  --datelte: string
  --maxResults: float # default: 100
  --page: float # default: 1
  --npsChannelId: float
  --format: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date.gte" $dategte "scalar") (serialize-qp "date.lte" $datelte "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "npsChannelId" $npsChannelId "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/ces/($survey_id)/responses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get CES metrics
#
# GET /v1/ces/{survey_id}/metrics
# operationId: getV1CesSurvey_idMetrics
export def "ces-metrics idMetrics" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dategte: string # format: date
  --datelte: string # format: date
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date.gte" $dategte "scalar") (serialize-qp "date.lte" $datelte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/ces/($survey_id)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List CES channels
#
# GET /v1/ces/{surveyId}/shares
# operationId: getV1CesSurveyidShares
export def "ces-shares list" [
  surveyId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: float # default: 100
  --page: float
  --type: string@type-completer-8
  --mode: string@mode-completer-1
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "mode" $mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/ces/($surveyId)/shares" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List contacts in a list
#
# GET /v1/contactlist/{id}/contacts
# operationId: getV1ContactlistIdContacts
export def "contactlist-contacts get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: float # default: 50
  --page: float
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/contactlist/($id)/contacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create/Add Contacts to a Custom Label
#
# POST /v1/contactlist/{id}/contacts
# operationId: postV1ContactlistIdContacts
export def "contactlist-contacts post" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authorization: string # Custom Token generated from the App
  --body: record
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/contactlist/($id)/contacts")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all shares of a contact
#
# GET /v1/contacts/{id}/shares
# operationId: getV1ContactsIdShares
export def "contacts-shares get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float
  --authorization: string # Custom Token generated from the App
]: nothing -> record<responded: table<sent_date: string, survey: record, share: record, submission: record>, pendingResponse: table<sent_date: string, survey: record, share: record, submission: string>, hasNextPage: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/contacts/($id)/shares" $qp)
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List survey responses
#
# GET /v1/csat/{survey_id}/responses
# operationId: getV1CsatSurvey_idResponses
export def "csat-responses idResponses" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dategte: string
  --datelte: string
  --maxResults: float # default: 100
  --page: float # default: 1
  --npsChannelId: float
  --format: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date.gte" $dategte "scalar") (serialize-qp "date.lte" $datelte "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "npsChannelId" $npsChannelId "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/csat/($survey_id)/responses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get csat metrics
#
# GET /v1/csat/{survey_id}/metrics
# operationId: getV1CsatSurvey_idMetrics
export def "csat-metrics idMetrics" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dategte: string # format: date
  --datelte: string # format: date
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date.gte" $dategte "scalar") (serialize-qp "date.lte" $datelte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/csat/($survey_id)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List csat channels
#
# GET /v1/csat/{surveyId}/shares
# operationId: getV1CsatSurveyidShares
export def "csat-shares list" [
  surveyId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: float # default: 100
  --page: float
  --type: string@type-completer-8
  --mode: string@mode-completer-1
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "mode" $mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/csat/($surveyId)/shares" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List NPS channels
#
# GET /v1/nps/{surveyId}/shares
# operationId: getV1NpsSurveyidShares
export def "nps-shares list" [
  surveyId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: float # default: 100
  --page: float
  --type: string@type-completer-8
  --mode: string@mode-completer-1
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "mode" $mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/nps/($surveyId)/shares" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NPS metrics
#
# GET /v1/nps/{survey_id}/metrics
# operationId: getV1NpsSurvey_idMetrics
export def "nps-metrics idMetrics" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dategte: string # format: date
  --datelte: string # format: date
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date.gte" $dategte "scalar") (serialize-qp "date.lte" $datelte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/nps/($survey_id)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List survey responses
#
# GET /v1/nps/{survey_id}/responses
# operationId: getV1NpsSurvey_idResponses
export def "nps-responses idResponses" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dategte: string
  --datelte: string
  --maxResults: float # default: 100
  --page: float # default: 1
  --npsChannelId: float
  --format: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date.gte" $dategte "scalar") (serialize-qp "date.lte" $datelte "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "npsChannelId" $npsChannelId "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/nps/($survey_id)/responses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get survey integrations
#
# GET /v1/survey/{surveyId}/integrations
# operationId: getV1SurveySurveyidIntegrations
export def "survey-integrations get" [
  surveyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/survey/($surveyId)/integrations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List subjects
#
# GET /v1/survey/{surveyId}/subjects
# operationId: getV1SurveySurveyidSubjects
export def "survey-subjects get" [
  surveyId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNo: float
  --pageLimit: float
  --email: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNo" $pageNo "scalar") (serialize-qp "pageLimit" $pageLimit "scalar") (serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/survey/($surveyId)/subjects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List approvers
#
# GET /v1/survey/{surveyId}/approvers
# operationId: getV1SurveySurveyidApprovers
export def "survey-approvers get" [
  surveyId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNo: float
  --pageLimit: float
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNo" $pageNo "scalar") (serialize-qp "pageLimit" $pageLimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/survey/($surveyId)/approvers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List survey webhooks
#
# GET /v1/surveys/{survey_id}/webhooks
# operationId: getV1SurveysSurvey_idWebhooks
export def "surveys-webhooks idWebhooks" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: float # default: 50
  --page: float
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/surveys/($survey_id)/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List survey variables
#
# GET /v1/surveys/{id}/variables
# operationId: getV1SurveysIdVariables
export def "surveys-variables get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/surveys/($id)/variables")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create survey variable
#
# POST /v1/surveys/{id}/variables
# operationId: postV1SurveysIdVariables
export def "surveys-variables post" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  label: string
  name: string
  --description: string
  type: string@type-completer-7
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/surveys/($id)/variables")
  let body = {label: $label, name: $name, description: $description, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all shares
#
# GET /v1/surveys/{survey_id}/shares
# operationId: getV1SurveysSurvey_idShares
export def "surveys-shares idShares" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: float # default: 50
  --page: float
  --type: string@type-completer-2
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/surveys/($survey_id)/shares" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get survey responses
#
# GET /v1/surveys/{survey_id}/submissions
# operationId: getV1SurveysSurvey_idSubmissions
export def "surveys-submissions idSubmissions" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: float # default: 50
  --page: float
  --dategte: string # format: date
  --datelte: string # format: date
  --state: string@state-completer
  --order-by: string@order-by-completer # default: completedTime
  --order: string@order-completer # default: DESC
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "date.gte" $dategte "scalar") (serialize-qp "date.lte" $datelte "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/surveys/($survey_id)/submissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get survey questions
#
# GET /v1/surveys/{id}/questions
# operationId: getV1SurveysIdQuestions
export def "surveys-questions get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: float # default: 50
  --page: float
  --tagName: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "tagName" $tagName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/surveys/($id)/questions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/surveys/{id}/questions
#
# operationId: postV1SurveysIdQuestions
export def "surveys-questions post" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/surveys/($id)/questions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Survey settings
#
# GET /v1/surveys/{id}/settings
# operationId: getV1SurveysIdSettings
export def "surveys-settings get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/surveys/($id)/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Survey settings
#
# PUT /v1/surveys/{id}/settings
# operationId: putV1SurveysIdSettings
export def "surveys-settings put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --partialSubmission: string@bool-completer
  --editResponse: string@bool-completer
  --anonymousResponses: string@bool-completer
  --submissionPerUser: float
  --cutOffDate: string # format: date
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/surveys/($id)/settings")
  let body = {partialSubmission: $partialSubmission, editResponse: $editResponse, anonymousResponses: $anonymousResponses, submissionPerUser: $submissionPerUser, cutOffDate: $cutOffDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Batch contact creation status
#
# GET /v3/contacts/status/{token}
# operationId: getV3ContactsStatusToken
export def "contacts-status get" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/contacts/status/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a app platform
#
# GET /v3/reputation/app_platforms/{id}
# operationId: getV3ReputationApp_platformsId
export def "reputation-app-platforms platformsId" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: float, data_fetch_address: string, location: string, is_active: bool, platform_id: float, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/reputation/app_platforms/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a platform
#
# GET /v3/reputation/platforms/{id}
# operationId: getV3ReputationPlatformsId
export def "reputation-platforms get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: float, label: string, type: string, logo_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/reputation/platforms/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a review
#
# GET /v3/reputation/reviews/{id}
# operationId: getV3ReputationReviewsId
export def "reputation-reviews get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --app-platform-id: float
]: nothing -> record<data: record<id: float, rating: float, review_title: string, review_content: string, review_date: string, reviewer_name: string, reviewer_photo_url: string, app_platform_id: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_platform_id" $app_platform_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/reputation/reviews/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Batch response creation status
#
# GET /v3/responses/status/{token}
# operationId: getV3ResponsesStatusToken
export def "responses-status get" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, data: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/responses/status/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List subject evaluators
#
# GET /v3/survey/subject/evaluators
# operationId: getV3SurveySubjectEvaluators
export def "survey-subject-evaluators get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --survey-id: float # Id of the survey
  --subject-id: float # Id of the subject
  --limit: float # default: 50
  --page: float
]: nothing -> record<data: record<list: list<record>, count: float, limit: float, page: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "survey_id" $survey_id "scalar") (serialize-qp "subject_id" $subject_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/survey/subject/evaluators" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get subject report
#
# GET /v3/survey/subject/report
# operationId: getV3SurveySubjectReport
export def "survey-subject-report get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --survey-id: float # Id of the survey
  --subject-id: float # Id of the subject
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "survey_id" $survey_id "scalar") (serialize-qp "subject_id" $subject_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/survey/subject/report" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all ticket comments
#
# GET /v3/tickets/{id}/comments
# operationId: getV3TicketsIdComments
export def "tickets-comments get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --private: string@bool-completer # Comment visibility; true for private, false for public visibility.
  --limit: float # Record limit per request; default is 50, maximum is 100. (default: 50)
  --page: float # Page of results
  --created-dategte: string # Comment created date greater than or equal to. Should be in the format YYYY-MM-DDTHH:MM:SS (format: date)
  --created-datelte: string # Comment created date less than or equal to. Should be in the format YYYY-MM-DDTHH:MM:SS (format: date)
]: nothing -> record<data: table<id: float, body: string, ticket_id: float, private: bool, agent_id: float, requester_id: float, created_at: string, attachments: list>, has_next_page: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "private" $private "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "created_date.gte" $created_dategte "scalar") (serialize-qp "created_date.lte" $created_datelte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/tickets/($id)/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a comment
#
# POST /v3/tickets/{id}/comments
# operationId: postV3TicketsIdComments
export def "tickets-comments post" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-body: string # The comment body. Supports HTML formatting with <b>, <i>, <u>, <a>, and <br /> tags. Supports mentioning contacts using @email format.
  --attachments: path # Following file types are allowed: pdf, png, jpeg, mp3, csv, wav. Maximum file size allowed is 15MB.
  --private: string@bool-completer # Comment visibility; true for private, false for public visibility. (default: false)
]: any -> record<data: record<id: float, body: string, ticket_id: float, private: bool, agent_id: float, requester_id: float, created_at: string, attachments: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/tickets/($id)/comments")
  let body = {body: $body_body, attachments: $attachments, private: $private} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get CES Channel
#
# GET /v1/ces/{surveyId}/shares/{channelId}
# operationId: getV1CesSurveyidSharesChannelid
export def "ces-shares get" [
  surveyId: float
  channelId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ces/($surveyId)/shares/($channelId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List HighEffort
#
# GET /v1/ces/{survey_id}/responses/highEffort
# operationId: getV1CesSurvey_idResponsesHigheffort
export def "ces-responses-high-effort idResponsesHigheffort" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dategte: string # format: date
  --datelte: string # format: date
  --maxResults: float
  --page: float
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date.gte" $dategte "scalar") (serialize-qp "date.lte" $datelte "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/ces/($survey_id)/responses/highEffort" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List lowEffort
#
# GET /v1/ces/{survey_id}/responses/lowEffort
# operationId: getV1CesSurvey_idResponsesLoweffort
export def "ces-responses-low-effort idResponsesLoweffort" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dategte: string # format: date
  --datelte: string # format: date
  --maxResults: float
  --page: float
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date.gte" $dategte "scalar") (serialize-qp "date.lte" $datelte "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/ces/($survey_id)/responses/lowEffort" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Neutral
#
# GET /v1/ces/{survey_id}/responses/neutral
# operationId: getV1CesSurvey_idResponsesNeutral
export def "ces-responses-neutral idResponsesNeutral" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dategte: string # format: date
  --datelte: string # format: date
  --maxResults: float
  --page: float
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date.gte" $dategte "scalar") (serialize-qp "date.lte" $datelte "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/ces/($survey_id)/responses/neutral" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get response of an CES survey submission
#
# GET /v1/ces/{survey_id}/submissions/{nps_submission_id}
# operationId: getV1CesSurvey_idSubmissionsNps_submission_id
export def "ces-submissions id" [
  nps_submission_id: float
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ces/($survey_id)/submissions/($nps_submission_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get CSAT Channel
#
# GET /v1/csat/{surveyId}/shares/{channelId}
# operationId: getV1CsatSurveyidSharesChannelid
export def "csat-shares get" [
  surveyId: float
  channelId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/csat/($surveyId)/shares/($channelId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Dissatisfied
#
# GET /v1/csat/{survey_id}/responses/dissatisfied
# operationId: getV1CsatSurvey_idResponsesDissatisfied
export def "csat-responses-dissatisfied idResponsesDissatisfied" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dategte: string # format: date
  --datelte: string # format: date
  --maxResults: float
  --page: float
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date.gte" $dategte "scalar") (serialize-qp "date.lte" $datelte "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/csat/($survey_id)/responses/dissatisfied" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Satisfied
#
# GET /v1/csat/{survey_id}/responses/satisfied
# operationId: getV1CsatSurvey_idResponsesSatisfied
export def "csat-responses-satisfied idResponsesSatisfied" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dategte: string # format: date
  --datelte: string # format: date
  --maxResults: float
  --page: float
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date.gte" $dategte "scalar") (serialize-qp "date.lte" $datelte "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/csat/($survey_id)/responses/satisfied" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Neutral
#
# GET /v1/csat/{survey_id}/responses/neutral
# operationId: getV1CsatSurvey_idResponsesNeutral
export def "csat-responses-neutral idResponsesNeutral" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dategte: string # format: date
  --datelte: string # format: date
  --maxResults: float
  --page: float
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date.gte" $dategte "scalar") (serialize-qp "date.lte" $datelte "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/csat/($survey_id)/responses/neutral" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get response of an csat survey submission
#
# GET /v1/csat/{survey_id}/submissions/{nps_submission_id}
# operationId: getV1CsatSurvey_idSubmissionsNps_submission_id
export def "csat-submissions id" [
  nps_submission_id: float
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/csat/($survey_id)/submissions/($nps_submission_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List passives
#
# GET /v1/nps/{survey_id}/responses/passives
# operationId: getV1NpsSurvey_idResponsesPassives
export def "nps-responses-passives idResponsesPassives" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dategte: string # format: date
  --datelte: string # format: date
  --maxResults: float
  --page: float
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date.gte" $dategte "scalar") (serialize-qp "date.lte" $datelte "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/nps/($survey_id)/responses/passives" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List promoters
#
# GET /v1/nps/{survey_id}/responses/promoters
# operationId: getV1NpsSurvey_idResponsesPromoters
export def "nps-responses-promoters idResponsesPromoters" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dategte: string # format: date
  --datelte: string # format: date
  --maxResults: float
  --page: float
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date.gte" $dategte "scalar") (serialize-qp "date.lte" $datelte "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/nps/($survey_id)/responses/promoters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List detractors
#
# GET /v1/nps/{survey_id}/responses/detractors
# operationId: getV1NpsSurvey_idResponsesDetractors
export def "nps-responses-detractors idResponsesDetractors" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dategte: string # format: date
  --datelte: string # format: date
  --maxResults: float
  --page: float
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date.gte" $dategte "scalar") (serialize-qp "date.lte" $datelte "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/nps/($survey_id)/responses/detractors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NPS Channel
#
# GET /v1/nps/{surveyId}/shares/{channelId}
# operationId: getV1NpsSurveyidSharesChannelid
export def "nps-shares get" [
  surveyId: float
  channelId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/nps/($surveyId)/shares/($channelId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get share details
#
# GET /v1/surveys/{survey_id}/shares/{share_id}
# operationId: getV1SurveysSurvey_idSharesShare_id
export def "surveys-shares id" [
  survey_id: float
  share_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/surveys/($survey_id)/shares/($share_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get responses report public link
#
# GET /v1/surveys/{survey_id}/report/link
# operationId: getV1SurveysSurvey_idReportLink
export def "surveys-report-link idReportLink" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --report-id: float
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "report_id" $report_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/surveys/($survey_id)/report/link" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get survey response
#
# GET /v1/surveys/{survey_id}/submissions/{id}
# operationId: getV1SurveysSurvey_idSubmissionsId
export def "surveys-submissions idSubmissionsId-by-id-survey_id" [
  id: float
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/surveys/($survey_id)/submissions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete survey response
#
# DELETE /v1/surveys/{survey_id}/submissions/{id}
# operationId: deleteV1SurveysSurvey_idSubmissionsId
export def "surveys-submissions idSubmissionsId-by-id-survey_id-1" [
  id: float
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/surveys/($survey_id)/submissions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Batch ticket creation status
#
# GET /v3/tickets/batch/status/{token}
# operationId: getV3TicketsBatchStatusToken
export def "tickets-batch-status get" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, data: table<status: string, result: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/tickets/batch/status/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List CES reminders
#
# GET /v1/ces/{surveyId}/shares/{channelId}/reminders
# operationId: getV1CesSurveyidSharesChannelidReminders
export def "ces-shares-reminders get" [
  surveyId: float
  channelId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # default: 1
  --maxResults: float # default: 50
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/ces/($surveyId)/shares/($channelId)/reminders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create reminder
#
# POST /v1/ces/{surveyId}/shares/{channelId}/reminders
# operationId: postV1CesSurveyidSharesChannelidReminders
# --properties shape: {embed_first_question: bool, custom_footer: bool, custom_footer_value?: string}
export def "ces-shares-reminders post" [
  surveyId: float
  channelId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-body: string
  --subject: string
  frequency: string@frequency-completer
  type: string@type-completer-6
  interval: float
  --properties: record # Properties of the reminder (default: {embed_first_question: true, custom_footer: false}) — shape: {embed_first_question: bool, custom_footer: bool, custom_footer_value?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ces/($surveyId)/shares/($channelId)/reminders")
  let body = {body: $body_body, subject: $subject, frequency: $frequency, type: $type, interval: $interval, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get CES Channel triggers
#
# GET /v1/ces/{surveyId}/shares/{channelId}/triggers
# operationId: getV1CesSurveyidSharesChannelidTriggers
export def "ces-shares-triggers get" [
  surveyId: float
  channelId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # default: 1
  --opened: string@bool-completer
  --blocked: string@bool-completer
  --throttled: string@bool-completer
  --maxResults: float # default: 50
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "opened" $opened "scalar") (serialize-qp "blocked" $blocked "scalar") (serialize-qp "throttled" $throttled "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/ces/($surveyId)/shares/($channelId)/triggers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List csat reminders
#
# GET /v1/csat/{surveyId}/shares/{channelId}/reminders
# operationId: getV1CsatSurveyidSharesChannelidReminders
export def "csat-shares-reminders get" [
  surveyId: float
  channelId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # default: 1
  --maxResults: float # default: 50
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/csat/($surveyId)/shares/($channelId)/reminders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create reminder
#
# POST /v1/csat/{surveyId}/shares/{channelId}/reminders
# operationId: postV1CsatSurveyidSharesChannelidReminders
# --properties shape: {embed_first_question: bool, custom_footer: bool, custom_footer_value?: string}
export def "csat-shares-reminders post" [
  surveyId: float
  channelId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-body: string
  --subject: string
  frequency: string@frequency-completer
  type: string@type-completer-6
  interval: float
  --properties: record # Properties of the reminder (default: {embed_first_question: true, custom_footer: false}) — shape: {embed_first_question: bool, custom_footer: bool, custom_footer_value?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/csat/($surveyId)/shares/($channelId)/reminders")
  let body = {body: $body_body, subject: $subject, frequency: $frequency, type: $type, interval: $interval, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get csat Channel triggers
#
# GET /v1/csat/{surveyId}/shares/{channelId}/triggers
# operationId: getV1CsatSurveyidSharesChannelidTriggers
export def "csat-shares-triggers get" [
  surveyId: float
  channelId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # default: 1
  --opened: string@bool-completer
  --blocked: string@bool-completer
  --throttled: string@bool-completer
  --maxResults: float # default: 50
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "opened" $opened "scalar") (serialize-qp "blocked" $blocked "scalar") (serialize-qp "throttled" $throttled "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/csat/($surveyId)/shares/($channelId)/triggers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NPS Channel triggers
#
# GET /v1/nps/{surveyId}/shares/{channelId}/triggers
# operationId: getV1NpsSurveyidSharesChannelidTriggers
export def "nps-shares-triggers get" [
  surveyId: float
  channelId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # default: 1
  --opened: string@bool-completer
  --blocked: string@bool-completer
  --throttled: string@bool-completer
  --maxResults: float # default: 50
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "opened" $opened "scalar") (serialize-qp "blocked" $blocked "scalar") (serialize-qp "throttled" $throttled "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/nps/($surveyId)/shares/($channelId)/triggers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List NPS reminders
#
# GET /v1/nps/{surveyId}/shares/{channelId}/reminders
# operationId: getV1NpsSurveyidSharesChannelidReminders
export def "nps-shares-reminders get" [
  surveyId: float
  channelId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # default: 1
  --maxResults: float # default: 50
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/nps/($surveyId)/shares/($channelId)/reminders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create reminder
#
# POST /v1/nps/{surveyId}/shares/{channelId}/reminders
# operationId: postV1NpsSurveyidSharesChannelidReminders
# --properties shape: {embed_first_question: bool, custom_footer: bool, custom_footer_value?: string}
export def "nps-shares-reminders post" [
  surveyId: float
  channelId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-body: string
  --subject: string
  frequency: string@frequency-completer
  type: string@type-completer-6
  interval: float
  --properties: record # default: {embed_first_question: true, custom_footer: false} — shape: {embed_first_question: bool, custom_footer: bool, custom_footer_value?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/nps/($surveyId)/shares/($channelId)/reminders")
  let body = {body: $body_body, subject: $subject, frequency: $frequency, type: $type, interval: $interval, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List subject evaluators
#
# GET /v1/survey/{surveyId}/subject/{subjectId}/evaluators
# operationId: getV1SurveySurveyidSubjectSubjectidEvaluators
export def "survey-subject-evaluators get-by-surveyId-subjectId" [
  surveyId: float
  subjectId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNo: float
  --pageLimit: float
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNo" $pageNo "scalar") (serialize-qp "pageLimit" $pageLimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/survey/($surveyId)/subject/($subjectId)/evaluators" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get subject report
#
# GET /v1/survey/{surveyId}/subject/{subjectId}/report
# operationId: getV1SurveySurveyidSubjectSubjectidReport
export def "survey-subject-report get-by-surveyId-subjectId" [
  surveyId: float
  subjectId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/survey/($surveyId)/subject/($subjectId)/report")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates CES Survey
#
# POST /v1/ces
# operationId: postV1Ces
# --email shape: {subject?: string, body?: string}
# --followUp shape: {default?: string, advanced?: bool, highEffort?: string, neutral?: string, lowEffort?: string}
# --thankYou shape: {default?: string, advanced?: bool, highEffort?: string, neutral?: string, lowEffort?: string}
export def "ces post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  surveyName: string
  --surveyType: string@surveyType-completer-2
  --visibility: string@visibility-completer # default: Public
  --email: record # shape: {subject?: string, body?: string}
  --followUp: record # shape: {default?: string, advanced?: bool, highEffort?: string, neutral?: string, lowEffort?: string}
  --thankYou: record # shape: {default?: string, advanced?: bool, highEffort?: string, neutral?: string, lowEffort?: string}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ces")
  let body = {surveyName: $surveyName, surveyType: $surveyType, visibility: $visibility, email: $email, followUp: $followUp, thankYou: $thankYou} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates csat Survey
#
# POST /v1/csat
# operationId: postV1Csat
# --email shape: {subject?: string, body?: string}
# --followUp shape: {default?: string, advanced?: bool, dissatisfied?: string, neutral?: string, satisfied?: string}
# --thankYou shape: {default?: string, advanced?: bool, dissatisfied?: string, neutral?: string, satisfied?: string}
export def "csat post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  surveyName: string
  --surveyType: string@surveyType-completer-3
  --visibility: string@visibility-completer # default: Public
  --email: record # shape: {subject?: string, body?: string}
  --followUp: record # shape: {default?: string, advanced?: bool, dissatisfied?: string, neutral?: string, satisfied?: string}
  --thankYou: record # shape: {default?: string, advanced?: bool, dissatisfied?: string, neutral?: string, satisfied?: string}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/csat")
  let body = {surveyName: $surveyName, surveyType: $surveyType, visibility: $visibility, email: $email, followUp: $followUp, thankYou: $thankYou} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates NPS Survey
#
# POST /v1/nps
# operationId: postV1Nps
# --email shape: {subject?: string, body?: string}
# --followUp shape: {default?: string, advanced?: bool, detractors?: string, passives?: string, promoters?: string}
# --thankYou shape: {default?: string, advanced?: bool, detractors?: string, passives?: string, promoters?: string}
export def "nps post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  surveyName: string
  --surveyType: string@surveyType-completer-4
  --visibility: string@visibility-completer # default: Public
  --email: record # shape: {subject?: string, body?: string}
  --followUp: record # shape: {default?: string, advanced?: bool, detractors?: string, passives?: string, promoters?: string}
  --thankYou: record # shape: {default?: string, advanced?: bool, detractors?: string, passives?: string, promoters?: string}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/nps")
  let body = {surveyName: $surveyName, surveyType: $surveyType, visibility: $visibility, email: $email, followUp: $followUp, thankYou: $thankYou} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create account
#
# POST /v1/signup
# operationId: postV1Signup
# --user shape: {email: string, name: string, phone?: string, password?: string, strategy: "password"|"google"|"linkedin"}
export def "signup post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  accountName: string # The name of the account to be created
  companyName: string # The name of the account to be created
  --user: record # shape: {email: string, name: string, phone?: string, password?: string, strategy: "password"|"google"|"linkedin"}
  --timeZone: string
  --language: string
  --template: float
  --ssTrackerLocation: string
  --ssTrackerReferrer: string
  --gSuiteDomain: string
  --referral: string
  --accountType: string # Account creation can be from ratethemeeting
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/signup")
  let body = {accountName: $accountName, companyName: $companyName, user: $user, timeZone: $timeZone, language: $language, template: $template, ssTrackerLocation: $ssTrackerLocation, ssTrackerReferrer: $ssTrackerReferrer, gSuiteDomain: $gSuiteDomain, referral: $referral, accountType: $accountType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create new custom language
#
# POST /v3/language
# operationId: postV3Language
export def "language post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  language_name: string # The language name must be between 3 and 16 characters long and can only contain uppercase and lowercase letters (A-Z, a-z) (e.g. SparrowLang)
  language_code: string # The language code must be exactly 3 lowercase letters (a-z) (e.g. ssl)
]: any -> record<data: record<message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/language")
  let body = {language_name: $language_name, language_code: $language_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create survey section
#
# POST /v3/sections
# operationId: postV3Sections
# --sections item shape: {name?: string, description?: string, position?: float, properties?: record, display_logic?: record, questions?: list}
export def "sections post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  survey_id: float # Id of Survey (e.g. 12001)
  sections: list # Array of sections — item shape: {name?: string, description?: string, position?: float, properties?: record, display_logic?: record, questions?: list}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/sections")
  let body = {survey_id: $survey_id, sections: $sections} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create new translation in a survey
#
# POST /v3/translation
# operationId: postV3Translation
export def "translation post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  survey_id: float # Survey ID (e.g. 123456)
  language_codes: list # Array of language codes (e.g. [en, fr])
  --google-translate: string@bool-completer # Translate using Google Translate (default: false, e.g. false)
]: any -> record<data: record<languageCreated: list<record>, languageSkipped: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/translation")
  let body = {survey_id: $survey_id, language_codes: $language_codes, google_translate: $google_translate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update translation
#
# PUT /v3/translation
# operationId: putV3Translation
export def "translation put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  survey_id: float # Survey ID (e.g. 123456)
  language_code: string # Language code (e.g. en)
  --google-translate: string@bool-completer # Translate using Google Translate (default: false, e.g. false)
  --file: path # Excel file containing translations
]: any -> record<data: record<message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/translation")
  let body = {survey_id: $survey_id, language_code: $language_code, google_translate: $google_translate, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete translation
#
# DELETE /v3/translation
# operationId: deleteV3Translation
export def "translation delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  language_code: string # Language code (e.g. en)
  survey_id: float # Survey ID (e.g. 123456)
]: any -> record<data: record<message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/translation")
  let body = {language_code: $language_code, survey_id: $survey_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create unique survey links
#
# POST /v3/channels/create_unique_links
# operationId: postV3ChannelsCreate_unique_links
# --contacts item shape: {full_name?: string, phone?: string, mobile?: string, email?: string, job_title?: string, contact_type?: "contact"|"employee", variables?: record, expires_at?: string}
export def "channels-create-unique-links links" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  survey_id: float # Id of Survey (e.g. 1)
  channel_id: float # Id of Channel (e.g. 1)
  --contact-ids: list # Id's of Contact
  --contacts: list # Array of contact objects — item shape: {full_name?: string, phone?: string, mobile?: string, email?: string, job_title?: string, contact_type?: "contact"|"employee", variables?: record, expires_at?: string}
  --contact-list-ids: list # Id's of Contact Lists
  --short-url: string@bool-completer # Create short link for the survey (default: false, e.g. false)
  --expires-at: string # expiry time of link in UTC (format: date, e.g. 2026-08-10T20:20:54Z)
  --body-variables: record
]: any -> record<data: table<contact_id: float, survey_link: string, short_url: string, variables: record, expires_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/channels/create_unique_links")
  let body = {survey_id: $survey_id, channel_id: $channel_id, contact_ids: $contact_ids, contacts: $contacts, contact_list_ids: $contact_list_ids, short_url: $short_url, expires_at: $expires_at, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create contacts
#
# POST /v3/contacts/batch
# operationId: postV3ContactsBatch
export def "contacts-batch post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<message: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/contacts/batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Batch create responses
#
# POST /v3/responses/batch
# operationId: postV3ResponsesBatch
# --responses item shape: {contact_id?: float, contact?: record, variables?: record, trigger_workflow?: bool, channel_id?: float, meta_data?: record, answers: list}
export def "responses-batch post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  survey_id: float # ID of the survey (e.g. 1)
  responses: list # item shape: {contact_id?: float, contact?: record, variables?: record, trigger_workflow?: bool, channel_id?: float, meta_data?: record, answers: list}
]: any -> record<token: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/responses/batch")
  let body = {survey_id: $survey_id, responses: $responses} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Start a new response
#
# POST /v3/responses/new
# operationId: postV3ResponsesNew
# --meta_data shape: {os?: string, browser?: string, time_zone?: string, browser_language?: string, date_time?: string}
export def "responses-new post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  survey_id: float # ID of the survey (e.g. 1)
  --contact-id: float # ID of the contact (e.g. 2)
  --channel-id: float # ID of the channel (e.g. 3)
  --meta-data: record # shape: {os?: string, browser?: string, time_zone?: string, browser_language?: string, date_time?: string}
]: any -> record<data: record<id: float, state: string, start_time: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/responses/new")
  let body = {survey_id: $survey_id, contact_id: $contact_id, channel_id: $channel_id, meta_data: $meta_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create invite
#
# POST /v3/survey/invite
# operationId: postV3SurveyInvite
# --subject shape: {full_name: string, email: string}
# --evaluators item shape: {full_name: string, email: string, relation: string}
# --approver shape: {full_name: string, email: string}
# --properties shape: {require_approval: bool, self_evaluation: bool, self_nomination: bool}
export def "survey-invite post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --survey-id: float
  subject: record # shape: {full_name: string, email: string}
  evaluators: list # item shape: {full_name: string, email: string, relation: string}
  approver: record # shape: {full_name: string, email: string}
  properties: record # shape: {require_approval: bool, self_evaluation: bool, self_nomination: bool}
  --invite-now: string@bool-completer
  --schedule: string # format: date
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "survey_id" $survey_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/survey/invite" $qp)
  let body = {subject: $subject, evaluators: $evaluators, approver: $approver, properties: $properties, invite_now: $invite_now, schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create tickets in batch
#
# POST /v3/tickets/batch
# operationId: postV3TicketsBatch
export def "tickets-batch post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<message: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/tickets/batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create survey variables
#
# POST /v3/variables/batch
# operationId: postV3VariablesBatch
# --variables item shape: {label: string, name: string, description?: string, type: "STRING"|"NUMBER"|"DATE"}
export def "variables-batch post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  survey_id: float # Id of Survey (e.g. 1)
  --body-variables: list # item shape: {label: string, name: string, description?: string, type: "STRING"|"NUMBER"|"DATE"}
]: any -> record<data: table<id: float, label: string, name: string, description: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/variables/batch")
  let body = {survey_id: $survey_id, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create subscribed event
#
# POST /v1/audit-logs/events/subscribe
# operationId: postV1AuditlogsEventsSubscribe
# --events item shape: {name?: "SURVEY_CREATED"|"SURVEY_EDITED"|"SURVEY_DELETED"|"THEME_ADDED"|"THEME_EDITED"|"THEME_DELETED"|"USER_CREATED"|"USER_DELETED"|"USER_EDITED"|"CONTACT_CREATED"|"CONTACT_UPDATED"|"CONTACT_DELETED"|"CONTACT_PROPERTY_CREATED"|"CONTACT_PROPERTY_EDITED"|"CONTACT_PROPERTY_DELETED"|"WORKSPACE_CREATED"|"WORKSPACE_DELETED"|"WORKSPACE_EDITED"|"SYNC_DEVICES"|"SURVEY_RESPONSE_IMPORT"|"SURVEY_RESPONSE_DELETION"|"SURVEY_CLOSED"|"SURVEY_RESTORED"|"SURVEY_OWNERSHIP_TRANSFER"|"FOLDER_USER_ACCESS_GRANT"|"FOLDER_USER_ACCESS_REMOVE"|"FOLDER_TEAM_ACCESS_GRANT"|"FOLDER_TEAM_ACCESS_REMOVE"|"SURVEY_MOVED"|"SURVEY_PASSWORD_CREATED"|"SURVEY_PASSWORD_DELETED"|"SURVEY_PASSWORD_EDITED"|"QUESTION_CATALOG_CREATED"|"QUESTION_CATALOG_DELETED"|"LOGIN"|"LOGOUT"|"TICKET_TEMPLATE_CREATED"|"TICKET_TEMPLATE_UPDATED"|"TICKET_TEMPLATE_DELETED"|"SANDBOX_SURVEY_CLONED_TO_SANDBOX"|"SANDBOX_SURVEY_CLONED_TO_MAIN"|"SANDBOX_BULK_CLONE_TO_SANDBOX"|"SANDBOX_ACCOUNT_CREATED"|"SANDBOX_USERS_ADDED"|"SANDBOX_SURVEY_SYNCED"|"FIREWALL_RULE_CREATED"|"FIREWALL_RULE_UPDATED"|"FIREWALL_RULE_DELETED"|"CUSTOM_RESPONSE_RATE_SWITCHED"|"CUSTOM_METRIC_CREATED"|"CUSTOM_METRIC_UPDATED"|"CUSTOM_METRIC_DELETED"|"SURVEY_FOLDER_MOVED"}
export def "audit-logs-events-subscribe post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  events: list # item shape: {name?: "SURVEY_CREATED"|"SURVEY_EDITED"|"SURVEY_DELETED"|"THEME_ADDED"|"THEME_EDITED"|"THEME_DELETED"|"USER_CREATED"|"USER_DELETED"|"USER_EDITED"|"CONTACT_CREATED"|"CONTACT_UPDATED"|"CONTACT_DELETED"|"CONTACT_PROPERTY_CREATED"|"CONTACT_PROPERTY_EDITED"|"CONTACT_PROPERTY_DELETED"|"WORKSPACE_CREATED"|"WORKSPACE_DELETED"|"WORKSPACE_EDITED"|"SYNC_DEVICES"|"SURVEY_RESPONSE_IMPORT"|"SURVEY_RESPONSE_DELETION"|"SURVEY_CLOSED"|"SURVEY_RESTORED"|"SURVEY_OWNERSHIP_TRANSFER"|"FOLDER_USER_ACCESS_GRANT"|"FOLDER_USER_ACCESS_REMOVE"|"FOLDER_TEAM_ACCESS_GRANT"|"FOLDER_TEAM_ACCESS_REMOVE"|"SURVEY_MOVED"|"SURVEY_PASSWORD_CREATED"|"SURVEY_PASSWORD_DELETED"|"SURVEY_PASSWORD_EDITED"|"QUESTION_CATALOG_CREATED"|"QUESTION_CATALOG_DELETED"|"LOGIN"|"LOGOUT"|"TICKET_TEMPLATE_CREATED"|"TICKET_TEMPLATE_UPDATED"|"TICKET_TEMPLATE_DELETED"|"SANDBOX_SURVEY_CLONED_TO_SANDBOX"|"SANDBOX_SURVEY_CLONED_TO_MAIN"|"SANDBOX_BULK_CLONE_TO_SANDBOX"|"SANDBOX_ACCOUNT_CREATED"|"SANDBOX_USERS_ADDED"|"SANDBOX_SURVEY_SYNCED"|"FIREWALL_RULE_CREATED"|"FIREWALL_RULE_UPDATED"|"FIREWALL_RULE_DELETED"|"CUSTOM_RESPONSE_RATE_SWITCHED"|"CUSTOM_METRIC_CREATED"|"CUSTOM_METRIC_UPDATED"|"CUSTOM_METRIC_DELETED"|"SURVEY_FOLDER_MOVED"}
  httpMethod: string@httpMethod-completer-1
  --body-url: string
  --headers: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/audit-logs/events/subscribe")
  let body = {events: $events, httpMethod: $httpMethod, url: $body_url, headers: $headers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create SMS share
#
# POST /v1/ces/{survey_id}/sms
# operationId: postV1CesSurvey_idSms
# --contacts item shape: {mobile: string, variables?: record}
# --properties shape: {content: string, smsTargetId?: float, acceptAnonymousResponse?: bool, twilio_consent_agreed?: bool}
export def "ces-sms idSms" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contacts: list # item shape: {mobile: string, variables?: record}
  --contactLists: list
  --sendNow: string@bool-completer # default: true
  --mode: string # default: BLAST
  --type: string # default: SMS
  --name: string # default: SMS Share
  --delayed: string
  --schedule: string
  --customProperties: record
  --body-variables: record
  properties: record # shape: {content: string, smsTargetId?: float, acceptAnonymousResponse?: bool, twilio_consent_agreed?: bool}
  --ignoreThrottledContacts: string@bool-completer # default: true
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ces/($survey_id)/sms")
  let body = {contacts: $contacts, contactLists: $contactLists, sendNow: $sendNow, mode: $mode, type: $type, name: $name, delayed: $delayed, schedule: $schedule, customProperties: $customProperties, variables: $body_variables, properties: $properties, ignoreThrottledContacts: $ignoreThrottledContacts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create CES Email channel
#
# POST /v1/ces/{survey_id}/email
# operationId: postV1CesSurvey_idEmail
# --contacts item shape: {email: string, variables?: record}
# --questions item shape: {id?: float, label: string}
# --properties shape: {body?: string, subject?: string, replyEmail?: string, fromAddress?: string}
# --reminders item shape: {body?: string, subject?: string, frequency: "Days"|"Weeks"|"Months"|"Years", type: "NOT_RESPONDED"|"PARTIALLY_RESPONDED", interval: float, properties?: record}
export def "ces-email idEmail" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contacts: list # item shape: {email: string, variables?: record}
  --contactLists: list
  --sendNow: string@bool-completer # default: true
  --mode: string # default: BLAST
  --type: string # default: EMAIL
  --name: string # default: Email Share
  --delayed: string
  --schedule: string
  --customProperties: record
  --body-variables: record
  --questions: list # item shape: {id?: float, label: string}
  --meetingTime: string
  --properties: record # shape: {body?: string, subject?: string, replyEmail?: string, fromAddress?: string}
  --embed-first-question: string@bool-completer # default: true
  --custom-footer: string@bool-completer # default: false
  --custom-footer-value: string
  --ignoreThrottledContacts: string@bool-completer # default: true
  --reminders: list # item shape: {body?: string, subject?: string, frequency: "Days"|"Weeks"|"Months"|"Years", type: "NOT_RESPONDED"|"PARTIALLY_RESPONDED", interval: float, properties?: record}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ces/($survey_id)/email")
  let body = {contacts: $contacts, contactLists: $contactLists, sendNow: $sendNow, mode: $mode, type: $type, name: $name, delayed: $delayed, schedule: $schedule, customProperties: $customProperties, variables: $body_variables, questions: $questions, meetingTime: $meetingTime, properties: $properties, embed_first_question: $embed_first_question, custom_footer: $custom_footer, custom_footer_value: $custom_footer_value, ignoreThrottledContacts: $ignoreThrottledContacts, reminders: $reminders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create multiple contacts
#
# POST /v1/contactlist/active/contacts
# operationId: postV1ContactlistActiveContacts
export def "contactlist-active-contacts post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authorization: string # Custom Token generated from the App
  --body: record
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contactlist/active/contacts")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create SMS share
#
# POST /v1/csat/{survey_id}/sms
# operationId: postV1CsatSurvey_idSms
# --contacts item shape: {mobile: string, variables?: record}
# --properties shape: {content: string, smsTargetId?: float, acceptAnonymousResponse?: bool, twilio_consent_agreed?: bool}
export def "csat-sms idSms" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contacts: list # item shape: {mobile: string, variables?: record}
  --contactLists: list
  --sendNow: string@bool-completer # default: true
  --mode: string # default: BLAST
  --type: string # default: SMS
  --name: string # default: SMS Share
  --delayed: string
  --schedule: string
  --customProperties: record
  --body-variables: record
  properties: record # shape: {content: string, smsTargetId?: float, acceptAnonymousResponse?: bool, twilio_consent_agreed?: bool}
  --ignoreThrottledContacts: string@bool-completer # default: true
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/csat/($survey_id)/sms")
  let body = {contacts: $contacts, contactLists: $contactLists, sendNow: $sendNow, mode: $mode, type: $type, name: $name, delayed: $delayed, schedule: $schedule, customProperties: $customProperties, variables: $body_variables, properties: $properties, ignoreThrottledContacts: $ignoreThrottledContacts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create csat Email channel
#
# POST /v1/csat/{survey_id}/email
# operationId: postV1CsatSurvey_idEmail
# --contacts item shape: {email: string, variables?: record}
# --questions item shape: {id?: float, label: string}
# --properties shape: {body?: string, subject?: string, replyEmail?: string, fromAddress?: string}
# --reminders item shape: {body?: string, subject?: string, frequency: "Days"|"Weeks"|"Months"|"Years", type: "NOT_RESPONDED"|"PARTIALLY_RESPONDED", interval: float, properties?: record}
export def "csat-email idEmail" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contacts: list # item shape: {email: string, variables?: record}
  --contactLists: list
  --sendNow: string@bool-completer # default: true
  --mode: string # default: BLAST
  --type: string # default: EMAIL
  --name: string # default: Email Share
  --delayed: string
  --schedule: string
  --customProperties: record
  --body-variables: record
  --questions: list # item shape: {id?: float, label: string}
  --meetingTime: string
  --properties: record # shape: {body?: string, subject?: string, replyEmail?: string, fromAddress?: string}
  --ignoreThrottledContacts: string@bool-completer # default: true
  --reminders: list # item shape: {body?: string, subject?: string, frequency: "Days"|"Weeks"|"Months"|"Years", type: "NOT_RESPONDED"|"PARTIALLY_RESPONDED", interval: float, properties?: record}
  --embed-first-question: string@bool-completer # default: true
  --custom-footer: string@bool-completer # default: false
  --custom-footer-value: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/csat/($survey_id)/email")
  let body = {contacts: $contacts, contactLists: $contactLists, sendNow: $sendNow, mode: $mode, type: $type, name: $name, delayed: $delayed, schedule: $schedule, customProperties: $customProperties, variables: $body_variables, questions: $questions, meetingTime: $meetingTime, properties: $properties, ignoreThrottledContacts: $ignoreThrottledContacts, reminders: $reminders, embed_first_question: $embed_first_question, custom_footer: $custom_footer, custom_footer_value: $custom_footer_value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create NPS Email channel
#
# POST /v1/nps/{survey_id}/email
# operationId: postV1NpsSurvey_idEmail
# --contacts item shape: {email: string, variables?: record}
# --questions item shape: {id?: float, label: string}
# --properties shape: {body?: string, subject?: string, replyEmail?: string, fromAddress?: string}
# --reminders item shape: {body?: string, subject?: string, frequency: "Days"|"Weeks"|"Months"|"Years", type: "NOT_RESPONDED"|"PARTIALLY_RESPONDED", interval: float, properties?: record}
export def "nps-email idEmail" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contacts: list # item shape: {email: string, variables?: record}
  --contactLists: list
  --sendNow: string@bool-completer # default: true
  --mode: string # default: BLAST
  --type: string # default: EMAIL
  --name: string # default: Email Share
  --delayed: string
  --schedule: string
  --customProperties: record
  --body-variables: record
  --questions: list # item shape: {id?: float, label: string}
  --meetingTime: string
  --properties: record # shape: {body?: string, subject?: string, replyEmail?: string, fromAddress?: string}
  --ignoreThrottledContacts: string@bool-completer # default: true
  --reminders: list # item shape: {body?: string, subject?: string, frequency: "Days"|"Weeks"|"Months"|"Years", type: "NOT_RESPONDED"|"PARTIALLY_RESPONDED", interval: float, properties?: record}
  --embed-first-question: string@bool-completer # default: true
  --custom-footer: string@bool-completer # default: false
  --custom-footer-value: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/nps/($survey_id)/email")
  let body = {contacts: $contacts, contactLists: $contactLists, sendNow: $sendNow, mode: $mode, type: $type, name: $name, delayed: $delayed, schedule: $schedule, customProperties: $customProperties, variables: $body_variables, questions: $questions, meetingTime: $meetingTime, properties: $properties, ignoreThrottledContacts: $ignoreThrottledContacts, reminders: $reminders, embed_first_question: $embed_first_question, custom_footer: $custom_footer, custom_footer_value: $custom_footer_value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create SMS share
#
# POST /v1/nps/{survey_id}/sms
# operationId: postV1NpsSurvey_idSms
# --contacts item shape: {mobile: string, variables?: record}
# --properties shape: {content: string, smsTargetId?: float, acceptAnonymousResponse?: bool, twilio_consent_agreed?: bool}
export def "nps-sms idSms" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contacts: list # item shape: {mobile: string, variables?: record}
  --contactLists: list
  --sendNow: string@bool-completer # default: true
  --mode: string # default: BLAST
  --type: string # default: SMS
  --name: string # default: SMS Share
  --delayed: string
  --schedule: string
  --customProperties: record
  --body-variables: record
  properties: record # shape: {content: string, smsTargetId?: float, acceptAnonymousResponse?: bool, twilio_consent_agreed?: bool}
  --ignoreThrottledContacts: string@bool-completer # default: true
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/nps/($survey_id)/sms")
  let body = {contacts: $contacts, contactLists: $contactLists, sendNow: $sendNow, mode: $mode, type: $type, name: $name, delayed: $delayed, schedule: $schedule, customProperties: $customProperties, variables: $body_variables, properties: $properties, ignoreThrottledContacts: $ignoreThrottledContacts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create question
#
# POST /v1/sections/{id}/questions
# operationId: postV1SectionsIdQuestions
export def "sections-questions post" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sections/($id)/questions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create email share
#
# POST /v1/shares/email/{share_id}
# operationId: postV1SharesEmailShare_id
export def "shares-email id" [
  share_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contacts: list
  --lists: list
  --body-variables: record
  --customParams: record
  --sendLaterInDays: float
  --sendLater: string # format: date
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/shares/email/($share_id)")
  let body = {contacts: $contacts, lists: $lists, variables: $body_variables, customParams: $customParams, sendLaterInDays: $sendLaterInDays, sendLater: $sendLater} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create invite
#
# POST /v1/survey/{surveyId}/invite
# operationId: postV1SurveySurveyidInvite
# --subject shape: {fullName: string, email: string}
# --evaluators item shape: {fullName: string, email: string, relation: string}
# --approver shape: {fullName: string, email: string}
# --properties shape: {requireApproval: bool, selfEvaluation: bool, selfNomination: bool}
export def "survey-invite post-by-surveyId" [
  surveyId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  subject: record # shape: {fullName: string, email: string}
  evaluators: list # item shape: {fullName: string, email: string, relation: string}
  approver: record # shape: {fullName: string, email: string}
  properties: record # shape: {requireApproval: bool, selfEvaluation: bool, selfNomination: bool}
  --inviteNow: string@bool-completer
  --schedule: string # format: date
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/survey/($surveyId)/invite")
  let body = {subject: $subject, evaluators: $evaluators, approver: $approver, properties: $properties, inviteNow: $inviteNow, schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a section
#
# POST /v1/surveys/{id}/sections
# operationId: postV1SurveysIdSections
# --properties shape: {label?: string, sectionRandomise?: bool}
# --displayLogic shape: {logics?: list}
# --questions item shape: {text: string, description?: string, required?: bool, type: "FileInput"|"TextInput"|"OpinionScale"|"MultiChoice", desc?: string, optionsStacked?: bool, randomized?: bool, multipleAnswers?: bool, img?: string, video?: string, audio?: string, tags?: list, choices?: list, hasScore?: bool, other?: bool, allOfTheAbove?: bool, noneOfTheAbove?: bool, otherText?: record, noneOfTheAboveText?: record, allOfTheAboveText?: record, properties?: record, displayLogic?: record}
export def "surveys-sections post" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --description: string
  --properties: record # shape: {label?: string, sectionRandomise?: bool}
  --displayLogic: record # shape: {logics?: list}
  --questions: list # item shape: {text: string, description?: string, required?: bool, type: "FileInput"|"TextInput"|"OpinionScale"|"MultiChoice", desc?: string, optionsStacked?: bool, randomized?: bool, multipleAnswers?: bool, img?: string, video?: string, audio?: string, tags?: list, choices?: list, hasScore?: bool, other?: bool, allOfTheAbove?: bool, noneOfTheAbove?: bool, otherText?: record, noneOfTheAboveText?: record, allOfTheAboveText?: record, properties?: record, displayLogic?: record}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/surveys/($id)/sections")
  let body = {name: $name, description: $description, properties: $properties, displayLogic: $displayLogic, questions: $questions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Clone survey
#
# POST /v1/surveys/{id}/clone
# operationId: postV1SurveysIdClone
export def "surveys-clone post-by-id" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --surveyType: string@surveyType-completer-1
  --name: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/surveys/($id)/clone")
  let body = {surveyType: $surveyType, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get channel analytics metrics
#
# POST /v3/channels/{id}/summary
# operationId: postV3ChannelsIdSummary
export def "channels-summary post" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  survey_id: float # Id of the survey (e.g. 1)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/channels/($id)/summary")
  let body = {survey_id: $survey_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Clone a channel
#
# POST /v3/channels/{id}/clone
# operationId: postV3ChannelsIdClone
export def "channels-clone post" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  survey_id: float # Id of the survey (e.g. 1)
]: any -> record<data: record<id: float, name: string, status: string, type: string, properties: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/channels/($id)/clone")
  let body = {survey_id: $survey_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Clone a survey
#
# POST /v3/surveys/{id}/clone
# operationId: postV3SurveysIdClone
export def "surveys-clone post-by-id-1" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --survey-type: string@survey-type-completer # Survey type to be Cloned. (e.g. Conversational)
  --name: string # Name of the Cloned Survey (e.g. Employee satisfaction survey)
]: any -> record<data: record<id: float, name: string, archived: bool, survey_type: string, created_at: string, updated_at: string, survey_folder_id: float, survey_folder_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/surveys/($id)/clone")
  let body = {survey_type: $survey_type, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send CES channel Blast
#
# POST /v1/ces/{survey_id}/email/{channel_id}
# operationId: postV1CesSurvey_idEmailChannel_id
# --contacts item shape: {email: string, variables?: record}
export def "ces-email id" [
  survey_id: float
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contacts: list # item shape: {email: string, variables?: record}
  --name: string
  --contactLists: list
  --sendLaterInDays: float
  --customProperties: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ces/($survey_id)/email/($channel_id)")
  let body = {contacts: $contacts, name: $name, contactLists: $contactLists, sendLaterInDays: $sendLaterInDays, customProperties: $customProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Share existing SMS Share
#
# POST /v1/ces/{survey_id}/sms/{id}
# operationId: postV1CesSurvey_idSmsId
# --contacts item shape: {mobile: string, variables?: record}
export def "ces-sms idSmsId" [
  survey_id: float
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contacts: list # item shape: {mobile: string, variables?: record}
  --contactLists: list
  --body-variables: record
  --sendLaterInDays: float
  --twilio-consent-agreed: string@bool-completer # For using surveysparrow message service you need to agree the consent.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ces/($survey_id)/sms/($id)")
  let body = {contacts: $contacts, contactLists: $contactLists, variables: $body_variables, sendLaterInDays: $sendLaterInDays, twilio_consent_agreed: $twilio_consent_agreed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send csat channel Blast
#
# POST /v1/csat/{survey_id}/email/{channel_id}
# operationId: postV1CsatSurvey_idEmailChannel_id
# --contacts item shape: {email: string, variables?: record}
export def "csat-email id" [
  survey_id: float
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contacts: list # item shape: {email: string, variables?: record}
  --name: string
  --contactLists: list
  --sendLaterInDays: float
  --customProperties: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/csat/($survey_id)/email/($channel_id)")
  let body = {contacts: $contacts, name: $name, contactLists: $contactLists, sendLaterInDays: $sendLaterInDays, customProperties: $customProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Share existing SMS Share
#
# POST /v1/csat/{survey_id}/sms/{id}
# operationId: postV1CsatSurvey_idSmsId
# --contacts item shape: {mobile: string, variables?: record}
export def "csat-sms idSmsId" [
  survey_id: float
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contacts: list # item shape: {mobile: string, variables?: record}
  --contactLists: list
  --body-variables: record
  --sendLaterInDays: float
  --twilio-consent-agreed: string@bool-completer # For using surveysparrow message service you need to agree the consent.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/csat/($survey_id)/sms/($id)")
  let body = {contacts: $contacts, contactLists: $contactLists, variables: $body_variables, sendLaterInDays: $sendLaterInDays, twilio_consent_agreed: $twilio_consent_agreed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Share existing SMS Share
#
# POST /v1/nps/{survey_id}/sms/{id}
# operationId: postV1NpsSurvey_idSmsId
# --contacts item shape: {mobile: string, variables?: record}
export def "nps-sms idSmsId" [
  survey_id: float
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contacts: list # item shape: {mobile: string, variables?: record}
  --contactLists: list
  --body-variables: record
  --sendLaterInDays: float
  --twilio-consent-agreed: string@bool-completer # For using surveysparrow message service you need to agree the consent.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/nps/($survey_id)/sms/($id)")
  let body = {contacts: $contacts, contactLists: $contactLists, variables: $body_variables, sendLaterInDays: $sendLaterInDays, twilio_consent_agreed: $twilio_consent_agreed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send NPS channel Blast
#
# POST /v1/nps/{survey_id}/email/{channel_id}
# operationId: postV1NpsSurvey_idEmailChannel_id
# --contacts item shape: {email: string, variables?: record}
export def "nps-email id" [
  survey_id: float
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contacts: list # item shape: {email: string, variables?: record}
  --name: string
  --contactLists: list
  --sendLaterInDays: float
  --customProperties: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/nps/($survey_id)/email/($channel_id)")
  let body = {contacts: $contacts, name: $name, contactLists: $contactLists, sendLaterInDays: $sendLaterInDays, customProperties: $customProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create link share for Survey
#
# POST /v1/surveys/{survey_id}/share/link
# operationId: postV1SurveysSurvey_idShareLink
export def "surveys-share-link idShareLink" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/surveys/($survey_id)/share/link")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start submission
#
# POST /v1/surveys/{survey_id}/submission/start
# operationId: postV1SurveysSurvey_idSubmissionStart
# --metaData shape: {os?: string, browser?: string, timeZone?: string, browserLanguage?: string, date_time?: string}
export def "surveys-submission-start idSubmissionStart" [
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contact-id: float
  --channel-id: float
  --metaData: record # shape: {os?: string, browser?: string, timeZone?: string, browserLanguage?: string, date_time?: string}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/surveys/($survey_id)/submission/start")
  let body = {contact_id: $contact_id, channel_id: $channel_id, metaData: $metaData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Trigger email share V2
#
# POST /v2/survey/{surveyId}/shares/email/{share_id}
# operationId: postV2SurveySurveyidSharesEmailShare_id
# --contacts item shape: {email: string, variables?: record}
# --lists item shape: {name: string, variables?: record}
export def "survey-shares-email id" [
  share_id: float
  surveyId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contacts: list # item shape: {email: string, variables?: record}
  --lists: list # item shape: {name: string, variables?: record}
  --body-variables: record
  --sendLaterInDays: float
  --sendLater: string # format: date
  --ignoreThrottledContacts: string@bool-completer # default: true
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/survey/($surveyId)/shares/email/($share_id)")
  let body = {contacts: $contacts, lists: $lists, variables: $body_variables, sendLaterInDays: $sendLaterInDays, sendLater: $sendLater, ignoreThrottledContacts: $ignoreThrottledContacts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unique survey link for each contact
#
# POST /v1/survey/{survey_id}/channels/{channel_id}/contacts/survey-link
# operationId: postV1SurveySurvey_idChannelsChannel_idContactsSurveylink
export def "survey-channels-contacts-survey-link idContactsSurveylink" [
  survey_id: float
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contactIds: list
  --contactListIds: list
  --channelType: string@channelType-completer # default: EMAIL
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/survey/($survey_id)/channels/($channel_id)/contacts/survey-link")
  let body = {contactIds: $contactIds, contactListIds: $contactListIds, channelType: $channelType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update contact list
#
# PUT /v1/contactlist/{id}
# operationId: putV1ContactlistId
export def "contactlist put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --description: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/contactlist/($id)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete contact list
#
# DELETE /v1/contactlist/{id}
# operationId: deleteV1ContactlistId
export def "contactlist delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/contactlist/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update webhook
#
# PUT /v1/webhooks/{id}
# operationId: putV1WebhooksId
export def "webhooks put-by-id" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --description: string
  --body-url: string
  --httpMethod: string@httpMethod-completer
  --headers: list
  --payload: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/webhooks/($id)")
  let body = {name: $name, description: $description, url: $body_url, httpMethod: $httpMethod, headers: $headers, payload: $payload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete webhook
#
# DELETE /v1/webhooks/{id}
# operationId: deleteV1WebhooksId
export def "webhooks delete-by-id" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/webhooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a question
#
# PUT /v3/questions/{question_id}
# operationId: putV3QuestionsQuestion_id
# --question shape: {text?: string, description?: string, required?: bool, properties?: record, display_logic?: record, skip_logic?: record}
export def "questions id-by-question_id" [
  question_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  survey_id: float # Survey Id (e.g. 1)
  question: record # shape: {text?: string, description?: string, required?: bool, properties?: record, display_logic?: record, skip_logic?: record}
]: any -> record<data: record<id: float, type: string, position: string, hasDisplayLogic: bool, properties: record, survey_id: float, section_id: float, account_id: float, parent_question_id: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/questions/($question_id)")
  let body = {survey_id: $survey_id, question: $question} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a question
#
# DELETE /v3/questions/{question_id}
# operationId: deleteV3QuestionsQuestion_id
export def "questions id-by-question_id-1" [
  question_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/questions/($question_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update survey section
#
# PUT /v3/sections/{section_id}
# operationId: putV3SectionsSection_id
# --section shape: {name?: string, description?: string, position?: float, properties?: record, display_logic?: record}
export def "sections id-by-section_id" [
  section_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  survey_id: float # Id of Survey (e.g. 12001)
  section: record # Section object is required — shape: {name?: string, description?: string, position?: float, properties?: record, display_logic?: record}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/sections/($section_id)")
  let body = {survey_id: $survey_id, section: $section} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a section
#
# DELETE /v3/sections/{section_id}
# operationId: deleteV3SectionsSection_id
export def "sections id-by-section_id-1" [
  section_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  survey_id: float # Id of Survey (e.g. 12001)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/sections/($section_id)")
  let body = {survey_id: $survey_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a webhook
#
# PUT /v3/webhooks/{id}
# operationId: putV3WebhooksId
export def "webhooks put-by-id-1" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --description: string
  --body-url: string
  --http-method: string@http-method-completer
  --headers: list
  --payload: record
  --include-partial-submission: string@bool-completer # e.g. true
]: any -> record<data: record<id: float, name: string, url: string, eventType: string, description: string, objectType: string, httpMethod: string, headers: list<record>, properties: record<payload: string, includePartialSubmission: bool>, disabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/webhooks/($id)")
  let body = {name: $name, description: $description, url: $body_url, http_method: $http_method, headers: $headers, payload: $payload, include_partial_submission: $include_partial_submission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a webhook
#
# DELETE /v3/webhooks/{id}
# operationId: deleteV3WebhooksId
export def "webhooks delete-by-id-1" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/webhooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update contact property
#
# PUT /v1/contacts/properties/{id}
# operationId: putV1ContactsPropertiesId
export def "contacts-properties put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4
  --label: string
  --description: string
  --contact-property-group-id: float
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/contacts/properties/($id)")
  let body = {type: $type, label: $label, description: $description, contact_property_group_id: $contact_property_group_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete contact property
#
# DELETE /v1/contacts/properties/{id}
# operationId: deleteV1ContactsPropertiesId
export def "contacts-properties delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/contacts/properties/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Complete response
#
# PUT /v3/responses/{response_id}/complete
# operationId: putV3ResponsesResponse_idComplete
export def "responses-complete idComplete" [
  response_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  survey_id: float # ID of the survey (e.g. 1)
]: any -> record<data: record<state: string, time_taken: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/responses/($response_id)/complete")
  let body = {survey_id: $survey_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add answers for response
#
# PUT /v3/responses/{response_id}/update
# operationId: putV3ResponsesResponse_idUpdate
# --answers item shape: {question_id: float, parent_question_id?: float, answer: string, other_txt?: string, matrix_txt?: list, matrix_int?: list, region_code?: string, time?: string, time_zone?: string}
export def "responses-update idUpdate" [
  response_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  survey_id: float # ID of the survey (e.g. 1)
  answers: list # item shape: {question_id: float, parent_question_id?: float, answer: string, other_txt?: string, matrix_txt?: list, matrix_int?: list, region_code?: string, time?: string, time_zone?: string}
  --body-variables: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/responses/($response_id)/update")
  let body = {survey_id: $survey_id, answers: $answers, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update invite
#
# PUT /v3/survey/subject/updateinvite
# operationId: putV3SurveySubjectUpdateinvite
# --evaluators item shape: {full_name: string, email: string, relation: string}
export def "survey-subject-updateinvite put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --survey-id: float
  --subject-id: float
  evaluators: list # item shape: {full_name: string, email: string, relation: string}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "survey_id" $survey_id "scalar") (serialize-qp "subject_id" $subject_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/survey/subject/updateinvite" $qp)
  let body = {evaluators: $evaluators} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update question
#
# PUT /v1/surveys/{id}/questions/{question_id}
# operationId: putV1SurveysIdQuestionsQuestion_id
# --properties shape: {data?: record}
# --displayLogic shape: {logics?: list}
export def "surveys-questions id-by-id-question_id" [
  id: float
  question_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --text: string
  --description: string
  --required: string@bool-completer
  --properties: record # shape: {data?: record}
  --displayLogic: record # shape: {logics?: list}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/surveys/($id)/questions/($question_id)")
  let body = {text: $text, description: $description, required: $required, properties: $properties, displayLogic: $displayLogic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete question
#
# DELETE /v1/surveys/{id}/questions/{question_id}
# operationId: deleteV1SurveysIdQuestionsQuestion_id
export def "surveys-questions id-by-id-question_id-1" [
  id: float
  question_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/surveys/($id)/questions/($question_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update survey section
#
# PUT /v1/surveys/{id}/sections/{section_id}
# operationId: putV1SurveysIdSectionsSection_id
# --properties shape: {label?: string, sectionRandomise?: bool}
# --displayLogic shape: {logics?: list}
export def "surveys-sections id-by-section_id-id" [
  section_id: float
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --description: string
  --properties: record # shape: {label?: string, sectionRandomise?: bool}
  --displayLogic: record # shape: {logics?: list}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/surveys/($id)/sections/($section_id)")
  let body = {name: $name, description: $description, properties: $properties, displayLogic: $displayLogic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a section
#
# DELETE /v1/surveys/{id}/sections/{section_id}
# operationId: deleteV1SurveysIdSectionsSection_id
export def "surveys-sections id-by-id-section_id" [
  id: float
  section_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/surveys/($id)/sections/($section_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update invite
#
# PUT /v1/survey/{surveyId}/subject/{subjectId}/invite
# operationId: putV1SurveySurveyidSubjectSubjectidInvite
# --evaluators item shape: {fullName: string, email: string, relation: string}
export def "survey-subject-invite put" [
  surveyId: float
  subjectId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  evaluators: list # item shape: {fullName: string, email: string, relation: string}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/survey/($surveyId)/subject/($subjectId)/invite")
  let body = {evaluators: $evaluators} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update SMS share
#
# PUT /v1/survey/{surveyId}/shares/sms/{channelId}
# operationId: putV1SurveySurveyidSharesSmsChannelid
export def "survey-shares-sms put-by-surveyId-channelId" [
  surveyId: float
  channelId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contacts: list
  --contactList: list
  --message: string
  --smsTargetId: float
  --body-variables: record
  --twilio-consent-agreed: string@bool-completer # For using surveysparrow message service you need to agree the consent.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/survey/($surveyId)/shares/sms/($channelId)")
  let body = {contacts: $contacts, contactList: $contactList, message: $message, smsTargetId: $smsTargetId, variables: $body_variables, twilio_consent_agreed: $twilio_consent_agreed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Complete submission
#
# PUT /v1/survey/{survey_id}/submissions/{submission_id}/complete
# operationId: putV1SurveySurvey_idSubmissionsSubmission_idComplete
export def "survey-submissions-complete idComplete" [
  survey_id: float
  submission_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/survey/($survey_id)/submissions/($submission_id)/complete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update SMS survey V2
#
# PUT /v2/survey/{surveyId}/shares/sms/{channelId}
# operationId: putV2SurveySurveyidSharesSmsChannelid
# --contacts item shape: {mobile: string, variables?: record}
# --contactList item shape: {id: float, variables?: record}
export def "survey-shares-sms put-by-surveyId-channelId-1" [
  surveyId: float
  channelId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contacts: list # item shape: {mobile: string, variables?: record}
  --contactList: list # item shape: {id: float, variables?: record}
  --message: string
  --smsTargetId: float
  --body-variables: record
  --sendLaterInDays: float
  --twilio-consent-agreed: string@bool-completer # For using surveysparrow message service you need to agree the consent.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/survey/($surveyId)/shares/sms/($channelId)")
  let body = {contacts: $contacts, contactList: $contactList, message: $message, smsTargetId: $smsTargetId, variables: $body_variables, sendLaterInDays: $sendLaterInDays, twilio_consent_agreed: $twilio_consent_agreed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete account
#
# DELETE /v1/delete
# operationId: deleteV1Delete
export def "delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/delete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete survey response
#
# DELETE /v1/submissions/{id}
# operationId: deleteV1SubmissionsId
export def "submissions delete" [
  id: float
  survey_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/submissions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a contact property
#
# DELETE /v3/contact_properties/{id}
# operationId: deleteV3Contact_propertiesId
export def "contact-properties propertiesId-by-id" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/contact_properties/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a contact property
#
# PATCH /v3/contact_properties/{id}
# operationId: patchV3Contact_propertiesId
export def "contact-properties propertiesId-by-id-1" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4
  --label: string
  --description: string
  --contact-property-group-id: float
]: any -> record<data: record<id: float, name: string, label: string, type: string, description: string, contact_property_group_id: float, group: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/contact_properties/($id)")
  let body = {type: $type, label: $label, description: $description, contact_property_group_id: $contact_property_group_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a survey variable
#
# DELETE /v3/variables/{variable_id}
# operationId: deleteV3VariablesVariable_id
export def "variables id" [
  variable_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/variables/($variable_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete subscribed event
#
# DELETE /v1/audit-logs/events/{id}
# operationId: deleteV1AuditlogsEventsId
export def "audit-logs-events delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/audit-logs/events/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete subscribed event
#
# DELETE /v3/audit_logs/events/{id}
# operationId: deleteV3Audit_logsEventsId
export def "audit-logs-events logsEventsId" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/audit_logs/events/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete survey variable
#
# DELETE /v1/surveys/{id}/variables/{variable_id}
# operationId: deleteV1SurveysIdVariablesVariable_id
export def "surveys-variables id" [
  variable_id: float
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/surveys/($id)/variables/($variable_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete CES reminder
#
# DELETE /v1/ces/{surveyId}/shares/{channelId}/reminders/{reminderId}
# operationId: deleteV1CesSurveyidSharesChannelidRemindersReminderid
export def "ces-shares-reminders delete" [
  surveyId: float
  channelId: float
  reminderId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ces/($surveyId)/shares/($channelId)/reminders/($reminderId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete csat reminder
#
# DELETE /v1/csat/{surveyId}/shares/{channelId}/reminders/{reminderId}
# operationId: deleteV1CsatSurveyidSharesChannelidRemindersReminderid
export def "csat-shares-reminders delete" [
  surveyId: float
  channelId: float
  reminderId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<succsats: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/csat/($surveyId)/shares/($channelId)/reminders/($reminderId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete NPS reminder
#
# DELETE /v1/nps/{surveyId}/shares/{channelId}/reminders/{reminderId}
# operationId: deleteV1NpsSurveyidSharesChannelidRemindersReminderid
export def "nps-shares-reminders delete" [
  surveyId: float
  channelId: float
  reminderId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/nps/($surveyId)/shares/($channelId)/reminders/($reminderId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
