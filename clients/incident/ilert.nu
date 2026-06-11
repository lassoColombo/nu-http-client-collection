# Auto-generated client for ilert REST API vv2.2026.5-r.3
# Source: https://api.ilert.com/api-docs/openapi.json
# Auth: --token flag or $env.ILERT_REST_API_TOKEN

const BASE_URL = "http://localhost/api"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ILERT_REST_API_TOKEN | default "" }
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
def base-url-completer [] { ["http://localhost/api"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def timezone-completer [] { ["America/Los_Angeles" "America/New_York" "Asia/Istanbul" "Europe/Berlin"] }
def language-completer [] { ["de" "en"] }
def region-completer [] { ["CA" "CH" "CN" "DE" "ES" "FR" "GB" "IE" "IN" "US"] }
def role-completer [] { ["ADMIN" "GUEST" "RESPONDER" "STAKEHOLDER" "USER"] }
def method-completer [] { ["EMAIL" "PUSH" "SMS" "TELEGRAM" "VOICE" "WHATSAPP"] }
def type-completer [] { ["HIGH_PRIORITY" "LOW_PRIORITY"] }
def beforeMin-completer [] { ["0" "1440" "15" "180" "30" "360" "60" "720"] }
def method-completer-1 [] { ["EMAIL" "PUSH" "SMS" "TELEGRAM" "WHATSAPP"] }
def type-completer-1 [] { ["ON_CALL"] }
def type-completer-2 [] { ["ALERT_ACCEPTED" "ALERT_ESCALATED" "ALERT_RESOLVED"] }
def method-completer-2 [] { ["EMAIL" "PUSH" "SMS"] }
def priority-completer [] { ["HIGH" "LOW"] }
def lang-completer [] { ["de" "en"] }
def type-completer-3 [] { ["RECURRING" "STATIC"] }
def integrationType-completer [] { ["ALIBABACLOUD" "AMAZONSNS" "API" "APICA" "APIFORTRESS" "APPDYNAMICS" "APPSIGNAL" "AUTOTASK" "AUVIK" "AWSBUDGET" "AWSPHD" "AWX" "AZUREALERTS" "AZUREDEVOPS" "CALLFLOW" "CATCHPOINT" "CHECKLY" "CHECKMK" "CISCOMERAKI" "CISCOTHOUSANDEYES" "CLOUDFLARE" "CLOUDWATCH" "CLUSTERCONTROL" "CONNECTWISEPSA" "CONSUL" "CORTEX" "CORTEXXSOAR" "CRONITOR" "CROWDSTRIKE" "DASH0" "DATADOG" "DEADMANSSNITCH" "DOMOTZ" "DOTCOMMONITOR" "DYNATRACE" "EKARA" "EMAIL2" "ESWATCHER" "FLEETDM" "FORTISOAR" "FOURME" "FRESHSERVICE" "GATUS" "GITHUB" "GITLAB" "GOOGLECHAT" "GOOGLESCC" "GRAFANA" "GRAYLOG" "GUARDDUTY" "HALOITSM" "HALOPSA" "HEALTHCHECKSIO" "HEARTBEAT2" "HELPSCOUT" "HETRIXTOOLS" "HONEYBADGER" "HONEYCOMB" "HUMIO" "HYPERPING" "IBMCLOUDFUNCTIONS" "ICINGA" "INFLUXDB" "INSTANA" "ITCONDUCTOR" "IXON" "JIRA" "JUMPCLOUD" "KAFKA" "KAPACITOR" "KEEP" "KENTIXAM" "KIBANA" "KUBERNETES" "LEVELIO" "LIBRENMS" "LIGHTSTEP" "LIVEWATCH" "LOKI" "MEZMO" "MIMIR" "MONGODBATLAS" "MONITOR" "MQTT" "MSSCOM" "MSTEAMS" "MXTOOLBOX" "NAGIOS" "NCENTRAL" "NETDATA" "NEWRELIC" "OHDEAR" "OPMANAGER" "OPSGENIE" "PANDORAFMS" "PANTHER" "PAPRISMACLOUD" "PARTICLE" "PHAREIO" "PINGDOM" "POSTHOG" "POSTMAN" "PROMETHEUS" "PRTG" "PULSETIC" "RAPIDSPIKE" "RAYGUN" "ROLLBAR" "SALESFORCE" "SAMSARA" "SAPFRUN" "SCIENCELOGIC" "SEARCHGUARD" "SEKOIA" "SEMATEXT" "SENSU" "SENTRY" "SERVERDENSITY" "SERVERGUARD24" "SERVICENOW" "SIGNALFX" "SIGNOZ" "SITE24X7" "SLACK" "SMS" "SOLARWINDS" "SPLUNK" "STACKDRIVER" "STATUSCAKE" "STATUSHUB" "SUMOLOGIC" "SYSAID" "SYSDIG" "TEAMCITY" "TERRAFORMCLOUD" "TOOL" "TOPDESK" "TULIP" "TWILIO" "TWILIOERRORS" "UBIDOTS" "UPTIME" "UPTIMEKUMA" "UPTIMEROBOT" "VICTORIAMETRICS" "WAZUH" "WHATAP" "ZABBIX" "ZAMMAD" "ZAPIER" "ZENDESK"] }
def alertCreation-completer [] { ["INTELLIGENT_GROUPING" "ONE_ALERT_GROUPED_PER_WINDOW" "ONE_ALERT_PER_EMAIL" "ONE_ALERT_PER_EMAIL_SUBJECT" "ONE_OPEN_ALERT_ALLOWED" "ONE_PENDING_ALERT_ALLOWED" "OPEN_RESOLVE_ON_EXTRACTION"] }
def alertPriorityRule-completer [] { ["HIGH" "HIGH_DURING_SUPPORT_HOURS" "LOW" "LOW_DURING_SUPPORT_HOURS"] }
def setupStatus-completer [] { ["CREATED" "CREATED_ADVANCED" "CREATED_BIDIRECTIONAL" "FINISHED"] }
def state-completer [] { ["CLOSED" "OPEN"] }
def eventType-completer [] { ["ACCEPT" "ALERT" "COMMENT" "RESOLVE"] }
def connectorType-completer [] { ["automation_rule" "autotask" "aws_event_bridge" "dingtalk" "discord" "dynamic" "email" "github" "google_chat_bot" "google_chat_webhook" "jira" "mattermost" "microsoft_teams_bot" "microsoft_teams_webhook" "servicenow" "slack" "slack_webhook" "telegram" "topdesk" "webhook" "zabbix" "zammad" "zapier" "zendesk" "zoom_chat"] }
def triggerMode-completer [] { ["AUTOMATIC" "MANUAL"] }
def type-completer-4 [] { ["autotask" "dingtalk" "discord" "dynamic" "github" "google_chat_bot" "jira" "mattermost" "microsoft_teams_bot" "servicenow" "slack" "topdesk" "zabbix" "zammad" "zendesk" "zoom_chat"] }
def visibility-completer [] { ["PRIVATE" "PUBLIC"] }
def role-completer-1 [] { ["ADMIN" "RESPONDER" "STAKEHOLDER" "USER"] }
def accept-completer [] { ["application/json" "metric sample"] }
def status-completer [] { ["IDENTIFIED" "INVESTIGATING" "MONITORING" "RESOLVED"] }
def status-completer-1 [] { ["DEGRADED" "MAJOR_OUTAGE" "OPERATIONAL" "PARTIAL_OUTAGE" "UNDER_MAINTENANCE"] }
def pageLayout-completer [] { ["RESPONSIVE" "SINGLE_COLUMN"] }
def appearance-completer [] { ["DARK" "LIGHT"] }
def type-completer-5 [] { ["TEAM" "USER"] }
def subscriber-type-completer [] { ["TEAM" "USER"] }
def type-completer-6 [] { ["DATADOG" "PROMETHEUS"] }
def aggregationType-completer [] { ["AVG" "LAST" "MAX" "MIN" "SUM"] }
def displayType-completer [] { ["GRAPH" "SINGLE"] }
def state-completer-1 [] { ["ANY" "AVAILABLE" "USED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "users get" } } | get name | first)
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

# Get the specified user.
#
# GET /users/{user-id}
export def "users get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, firstName: string, lastName: string, email: string, timezone: string, position: string, department: string, avatarUrl: string, language: string, region: string, role: string, shiftColor: string, mutedUntil: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing user.
#
# PUT /users/{user-id}
export def "users put" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int64
  firstName: string
  lastName: string
  email: string
  --timezone: string@timezone-completer
  --position: string
  --department: string
  --language: string@language-completer
  --region: string@region-completer
  --role: string@role-completer
  --shiftColor: string # Optional hex-color code for the user's shifts in schedules calendars
  --mutedUntil: string # Date in ISO-8601 (format: date-time)
  --createdAt: string # Date in ISO-8601 (format: date-time)
  --updatedAt: string # Date in ISO-8601 (format: date-time)
]: any -> record<id: int, firstName: string, lastName: string, email: string, timezone: string, position: string, department: string, avatarUrl: string, language: string, region: string, role: string, shiftColor: string, mutedUntil: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)")
  let body = {id: $id, firstName: $firstName, lastName: $lastName, email: $email, timezone: $timezone, position: $position, department: $department, language: $language, region: $region, role: $role, shiftColor: $shiftColor, mutedUntil: $mutedUntil, createdAt: $createdAt, updatedAt: $updatedAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the specified user.
#
# DELETE /users/{user-id}
export def "users delete" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user's emails
#
# GET /users/{user-id}/contacts/emails
export def "users-contacts-emails list" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, target: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/contacts/emails")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new email
#
# POST /users/{user-id}/contacts/emails
export def "users-contacts-emails post" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --target: string
]: any -> record<id: int, target: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/contacts/emails")
  let body = {target: $target} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific email
#
# GET /users/{user-id}/contacts/emails/{id}
export def "users-contacts-emails get" [
  user_id: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, target: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/contacts/emails/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user's email
#
# PUT /users/{user-id}/contacts/emails/{id}
export def "users-contacts-emails put" [
  user_id: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --target: string
]: any -> record<id: int, target: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/contacts/emails/($id)")
  let body = {target: $target} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the user's specified email
#
# DELETE /users/{user-id}/contacts/emails/{id}
export def "users-contacts-emails delete" [
  user_id: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/contacts/emails/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user's phone numbers
#
# GET /users/{user-id}/contacts/phone-numbers
export def "users-contacts-phone-numbers list" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, regionCode: string, target: string, primary: bool, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/contacts/phone-numbers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a phone number
#
# POST /users/{user-id}/contacts/phone-numbers
export def "users-contacts-phone-numbers post" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --regionCode: string
  --target: string
  --primary: string@bool-completer # May only be enabled for a single phone number contact at a time
]: any -> record<id: int, regionCode: string, target: string, primary: bool, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/contacts/phone-numbers")
  let body = {regionCode: $regionCode, target: $target, primary: $primary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get specific phone number
#
# GET /users/{user-id}/contacts/phone-numbers/{id}
export def "users-contacts-phone-numbers get" [
  user_id: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, regionCode: string, target: string, primary: bool, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/contacts/phone-numbers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user's phone number
#
# PUT /users/{user-id}/contacts/phone-numbers/{id}
export def "users-contacts-phone-numbers put" [
  user_id: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --regionCode: string
  --target: string
  --primary: string@bool-completer # May only be enabled for a single phone number contact at a time
]: any -> record<id: int, regionCode: string, target: string, primary: bool, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/contacts/phone-numbers/($id)")
  let body = {regionCode: $regionCode, target: $target, primary: $primary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the user's specified phone number
#
# DELETE /users/{user-id}/contacts/phone-numbers/{id}
export def "users-contacts-phone-numbers delete" [
  user_id: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/contacts/phone-numbers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get alert notification preferences of a user
#
# GET /users/{user-id}/notification-preferences/alerts
export def "users-notification-preferences-alerts list" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, method: string, contact: record, delayMin: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/notification-preferences/alerts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an alert notification preference
#
# POST /users/{user-id}/notification-preferences/alerts
# --contact shape: {id?: int, regionCode?: string, target?: string, primary?: bool, status?: "OK"|"LOCKED"|"BLACKLISTED"}
export def "users-notification-preferences-alerts post" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --method: string@method-completer
  --contact: record # shape: {id?: int, regionCode?: string, target?: string, primary?: bool, status?: "OK"|"LOCKED"|"BLACKLISTED"}
  --delayMin: int
  --type: string@type-completer
]: any -> record<id: int, method: string, contact: record, delayMin: int, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/notification-preferences/alerts")
  let body = {method: $method, contact: $contact, delayMin: $delayMin, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get specific notification preferences alert
#
# GET /users/{user-id}/notification-preferences/alerts/{id}
export def "users-notification-preferences-alerts get" [
  user_id: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, method: string, contact: record, delayMin: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/notification-preferences/alerts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user's alert notification preference
#
# PUT /users/{user-id}/notification-preferences/alerts/{id}
# --contact shape: {id?: int, regionCode?: string, target?: string, primary?: bool, status?: "OK"|"LOCKED"|"BLACKLISTED"}
export def "users-notification-preferences-alerts put" [
  user_id: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --method: string@method-completer
  --contact: record # shape: {id?: int, regionCode?: string, target?: string, primary?: bool, status?: "OK"|"LOCKED"|"BLACKLISTED"}
  --delayMin: int
  --type: string@type-completer
]: any -> record<id: int, method: string, contact: record, delayMin: int, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/notification-preferences/alerts/($id)")
  let body = {method: $method, contact: $contact, delayMin: $delayMin, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the user's specified notification preferences alert
#
# DELETE /users/{user-id}/notification-preferences/alerts/{id}
export def "users-notification-preferences-alerts delete" [
  user_id: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/notification-preferences/alerts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get duty notification preferences of a user
#
# GET /users/{user-id}/notification-preferences/duties
export def "users-notification-preferences-duties list" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, beforeMin: int, contact: record, method: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/notification-preferences/duties")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a duty notification preference
#
# POST /users/{user-id}/notification-preferences/duties
# --contact shape: {id?: int, regionCode?: string, target?: string, primary?: bool, status?: "OK"|"LOCKED"|"BLACKLISTED"}
export def "users-notification-preferences-duties post" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --beforeMin: int@beforeMin-completer
  --contact: record # shape: {id?: int, regionCode?: string, target?: string, primary?: bool, status?: "OK"|"LOCKED"|"BLACKLISTED"}
  --method: string@method-completer-1
  --type: string@type-completer-1
]: any -> record<id: int, beforeMin: int, contact: record, method: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/notification-preferences/duties")
  let body = {beforeMin: $beforeMin, contact: $contact, method: $method, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get specific notification preferences duty
#
# GET /users/{user-id}/notification-preferences/duties/{id}
export def "users-notification-preferences-duties get" [
  user_id: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, beforeMin: int, contact: record, method: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/notification-preferences/duties/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user's duty notification preference
#
# PUT /users/{user-id}/notification-preferences/duties/{id}
# --contact shape: {id?: int, regionCode?: string, target?: string, primary?: bool, status?: "OK"|"LOCKED"|"BLACKLISTED"}
export def "users-notification-preferences-duties put" [
  user_id: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --beforeMin: int@beforeMin-completer
  --contact: record # shape: {id?: int, regionCode?: string, target?: string, primary?: bool, status?: "OK"|"LOCKED"|"BLACKLISTED"}
  --method: string@method-completer-1
  --type: string@type-completer-1
]: any -> record<id: int, beforeMin: int, contact: record, method: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/notification-preferences/duties/($id)")
  let body = {beforeMin: $beforeMin, contact: $contact, method: $method, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the user's specified notification preferences duty
#
# DELETE /users/{user-id}/notification-preferences/duties/{id}
export def "users-notification-preferences-duties delete" [
  user_id: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/notification-preferences/duties/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get update notification preferences of a user
#
# GET /users/{user-id}/notification-preferences/updates
export def "users-notification-preferences-updates list" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, contact: record, method: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/notification-preferences/updates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an update notification preference
#
# POST /users/{user-id}/notification-preferences/updates
# --contact shape: {id?: int, regionCode?: string, target?: string, primary?: bool, status?: "OK"|"LOCKED"|"BLACKLISTED"}
export def "users-notification-preferences-updates post" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contact: record # shape: {id?: int, regionCode?: string, target?: string, primary?: bool, status?: "OK"|"LOCKED"|"BLACKLISTED"}
  --method: string@method-completer-1
  --type: string@type-completer-2
]: any -> record<id: int, contact: record, method: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/notification-preferences/updates")
  let body = {contact: $contact, method: $method, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get specific notification preferences update
#
# GET /users/{user-id}/notification-preferences/updates/{id}
export def "users-notification-preferences-updates get" [
  user_id: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, contact: record, method: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/notification-preferences/updates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user's update notification preference
#
# PUT /users/{user-id}/notification-preferences/updates/{id}
# --contact shape: {id?: int, regionCode?: string, target?: string, primary?: bool, status?: "OK"|"LOCKED"|"BLACKLISTED"}
export def "users-notification-preferences-updates put" [
  user_id: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contact: record # shape: {id?: int, regionCode?: string, target?: string, primary?: bool, status?: "OK"|"LOCKED"|"BLACKLISTED"}
  --method: string@method-completer-1
  --type: string@type-completer-2
]: any -> record<id: int, contact: record, method: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/notification-preferences/updates/($id)")
  let body = {contact: $contact, method: $method, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the user's specified notification preferences update
#
# DELETE /users/{user-id}/notification-preferences/updates/{id}
export def "users-notification-preferences-updates delete" [
  user_id: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/notification-preferences/updates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get subscription notification preferences of a user
#
# GET /users/{user-id}/notification-preferences/subscriptions
export def "users-notification-preferences-subscriptions list" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, contact: record, method: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/notification-preferences/subscriptions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a subscription notification preference
#
# POST /users/{user-id}/notification-preferences/subscriptions
# --contact shape: {id?: int, regionCode?: string, target?: string, primary?: bool, status?: "OK"|"LOCKED"|"BLACKLISTED"}
export def "users-notification-preferences-subscriptions post" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contact: record # shape: {id?: int, regionCode?: string, target?: string, primary?: bool, status?: "OK"|"LOCKED"|"BLACKLISTED"}
  --method: string@method-completer-2
]: any -> record<id: int, contact: record, method: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/notification-preferences/subscriptions")
  let body = {contact: $contact, method: $method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get specific notification preferences subscription
#
# GET /users/{user-id}/notification-preferences/subscriptions/{id}
export def "users-notification-preferences-subscriptions get" [
  user_id: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, contact: record, method: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/notification-preferences/subscriptions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user's subscription notification preference
#
# PUT /users/{user-id}/notification-preferences/subscriptions/{id}
# --contact shape: {id?: int, regionCode?: string, target?: string, primary?: bool, status?: "OK"|"LOCKED"|"BLACKLISTED"}
export def "users-notification-preferences-subscriptions put" [
  user_id: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contact: record # shape: {id?: int, regionCode?: string, target?: string, primary?: bool, status?: "OK"|"LOCKED"|"BLACKLISTED"}
  --method: string@method-completer-2
]: any -> record<id: int, contact: record, method: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/notification-preferences/subscriptions/($id)")
  let body = {contact: $contact, method: $method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the user's specified notification preferences subscription
#
# DELETE /users/{user-id}/notification-preferences/subscriptions/{id}
export def "users-notification-preferences-subscriptions delete" [
  user_id: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/notification-preferences/subscriptions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List available phone numbers that ilert uses to send voice and SMS notifications
#
# GET /numbers
export def "numbers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<countryCode: string, phoneNumber: string, supportsInboundSms: bool, types: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/numbers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List available inbound and outbound integrations. Note: this resource is paginated.
#
# GET /integrations
export def "integrations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of entities. (format: int32, default: 50)
]: nothing -> table<id: string, name: string, type: string, iconUrl: string, documentationUrl: string, integrationPath: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/integrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List existing users.
#
# GET /users
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of entities. (format: int32, default: 50)
]: nothing -> table<id: int, firstName: string, lastName: string, email: string, timezone: string, position: string, department: string, avatarUrl: string, language: string, region: string, role: string, shiftColor: string, mutedUntil: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new user. Requires ADMIN privileges.
#
# POST /users
export def "users post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --send-no-invitation: string@bool-completer # Provide ?send-no-invitation=true if you do not wish to send an invitation email. (default: false)
  firstName: string
  lastName: string
  email: string
  --timezone: string@timezone-completer
  --position: string
  --department: string
  --language: string@language-completer
  --region: string@region-completer
  --role: string@role-completer
  --shiftColor: string # Optional hex-color code for the user's shifts in schedules calendars
]: any -> record<id: int, firstName: string, lastName: string, email: string, timezone: string, position: string, department: string, avatarUrl: string, language: string, region: string, role: string, shiftColor: string, mutedUntil: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "send-no-invitation" $send_no_invitation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let body = {firstName: $firstName, lastName: $lastName, email: $email, timezone: $timezone, position: $position, department: $department, language: $language, region: $region, role: $role, shiftColor: $shiftColor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find a user by email address.
#
# POST /users/search-email
export def "users-search-email post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # the email address of the user to find
]: any -> record<id: int, firstName: string, lastName: string, email: string, timezone: string, position: string, department: string, avatarUrl: string, language: string, region: string, role: string, shiftColor: string, mutedUntil: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/search-email")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the currently authenticated user.
#
# GET /users/current
export def "users-current get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, firstName: string, lastName: string, email: string, timezone: string, position: string, department: string, avatarUrl: string, language: string, region: string, role: string, shiftColor: string, mutedUntil: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/current")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the current user.
#
# PUT /users/current
export def "users-current put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  firstName: string
  lastName: string
  email: string
  --timezone: string@timezone-completer
  --position: string
  --department: string
  --language: string@language-completer
  --region: string@region-completer
  --role: string@role-completer
  --shiftColor: string # Optional hex-color code for the user's shifts in schedules calendars
]: any -> record<id: int, firstName: string, lastName: string, email: string, timezone: string, position: string, department: string, avatarUrl: string, language: string, region: string, role: string, shiftColor: string, mutedUntil: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/current")
  let body = {firstName: $firstName, lastName: $lastName, email: $email, timezone: $timezone, position: $position, department: $department, language: $language, region: $region, role: $role, shiftColor: $shiftColor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List alerts (optionally matching certain criteria that are specified by query parameters).
#
# GET /alerts
export def "alerts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of entities. (format: int32, default: 50)
  --include: list # Describes optional properties that should be included in the response. You may declare multiple. (nextEscalationUser)
  --states: list # state of the alert
  --sources: list # alert source IDs of the alert's alert source
  --policies: list # escalation policy IDs of the alert's escalation policy
  --responders: list # user ids of the user that is a responder of the alert
  --qp-from: string # from date, ISO-UTC e.g. 2021-05-25T21:24:56.771Z, based on reportTime (format: date-time)
  --until: string # until date, ISO-UTC e.g. 2021-05-26T21:24:56.771Z, based on reportTime (format: date-time)
]: nothing -> table<id: int, summary: string, details: string, reportTime: string, resolvedOn: string, status: string, alertSource: record<id: int, teams: list, name: string, iconUrl: string, lightIconUrl: string, darkIconUrl: string, escalationPolicy: record, integrationType: string, integrationKey: string, integrationUrl: string, autoResolutionTimeout: string, alertGroupingWindow: string, alertCreation: string, status: string, active: bool, alertPriorityRule: string, supportHours: record, bidirectional: bool, summaryTemplate: record, detailsTemplate: record, routingTemplate: record, linkTemplates: list, priorityTemplate: record, severityTemplate: record, eventFilter: string, alertKeyTemplate: record, servicesTemplate: list, eventTypeFilterCreate: string, eventTypeFilterAccept: string, eventTypeFilterResolve: string, autoRaiseAlerts: bool, scoreThreshold: float, severity: int, services: list, setupStatus: string, autoCreateServices: bool, createdAt: string, updatedAt: string>, escalationPolicy: record<id: int, name: string, escalationRules: list, teams: list, repeating: bool, frequency: int, delayMin: int, routingKey: string>, priority: string, alertKey: string, assignedTo: record<id: float>, nextEscalation: string, escalationRules: list<record>, nextEscalationUser: record<id: int, firstName: string, lastName: string, email: string, timezone: string, position: string, department: string, avatarUrl: string, language: string, region: string, role: string, shiftColor: string, mutedUntil: string, createdAt: string, updatedAt: string>, nextEscalationRuleIndex: float, images: list<record>, links: list<record>, responders: list<record>, severity: int, labels: record, customDetails: record, linkedIncidentId: int, mergedIntoId: int, mergeState: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "include" $include "multi") (serialize-qp "states" $states "multi") (serialize-qp "sources" $sources "multi") (serialize-qp "policies" $policies "multi") (serialize-qp "responders" $responders "multi") (serialize-qp "from" $qp_from "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create alerts with customised parameters without requiring events from monitoring tools that use our Events API.
#
# POST /alerts
# --alertSource shape: {id: int}
# --escalationPolicy shape: {id: int}
# --assignedTo shape: {id?: float}
# --images item shape: {src?: string, href?: string, alt?: string}
# --links item shape: {href?: string, text?: string}
# --responders item shape: {user?: record}
export def "alerts post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  summary: string
  --details: string
  alertSource: record # For POST and PUT requests only the id field is required for sub entities, e.g. status page -> service, alert source -> support hour — shape: {id: int}
  --escalationPolicy: record # For POST and PUT requests only the id field is required for sub entities, e.g. status page -> service, alert source -> support hour — shape: {id: int}
  --priority: string@priority-completer
  --assignedTo: record # This field (type: User) is deprecated, please use 'responders' instead — shape: {id?: float}
  --images: list # item shape: {src?: string, href?: string, alt?: string}
  --links: list # item shape: {href?: string, text?: string}
  --responders: list # List of responders (users), only user.id is required. — item shape: {user?: record}
]: any -> record<id: int, summary: string, details: string, reportTime: string, resolvedOn: string, status: string, alertSource: record<id: int, teams: list<record>, name: string, iconUrl: string, lightIconUrl: string, darkIconUrl: string, escalationPolicy: record<id: int, name: string, escalationRules: list, teams: list, repeating: bool, frequency: int, delayMin: int, routingKey: string>, integrationType: string, integrationKey: string, integrationUrl: string, autoResolutionTimeout: string, alertGroupingWindow: string, alertCreation: string, status: string, active: bool, alertPriorityRule: string, supportHours: record<id: int, name: string, teams: list, timezone: string, supportDays: record, exceptions: list>, bidirectional: bool, summaryTemplate: record<textTemplate: string, elements: list>, detailsTemplate: record<textTemplate: string, elements: list>, routingTemplate: record<textTemplate: string, elements: list>, linkTemplates: list<record>, priorityTemplate: record<valueTemplate: record, mappings: list>, severityTemplate: record<valueTemplate: record, mappings: list>, eventFilter: string, alertKeyTemplate: record<textTemplate: string, elements: list>, servicesTemplate: list<record>, eventTypeFilterCreate: string, eventTypeFilterAccept: string, eventTypeFilterResolve: string, autoRaiseAlerts: bool, scoreThreshold: float, severity: int, services: list<record>, setupStatus: string, autoCreateServices: bool, createdAt: string, updatedAt: string>, escalationPolicy: record<id: int, name: string, escalationRules: list<record>, teams: list<record>, repeating: bool, frequency: int, delayMin: int, routingKey: string>, priority: string, alertKey: string, assignedTo: record<id: float>, nextEscalation: string, escalationRules: table<escalationTimeout: int, user: record, schedule: record, team: record, users: list, schedules: list, teams: list>, nextEscalationUser: record<id: int, firstName: string, lastName: string, email: string, timezone: string, position: string, department: string, avatarUrl: string, language: string, region: string, role: string, shiftColor: string, mutedUntil: string, createdAt: string, updatedAt: string>, nextEscalationRuleIndex: float, images: table<src: string, href: string, alt: string>, links: table<href: string, text: string>, responders: table<user: record, status: string, acceptedAt: string>, severity: int, labels: record, customDetails: record, linkedIncidentId: int, mergedIntoId: int, mergeState: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/alerts")
  let body = {summary: $summary, details: $details, alertSource: $alertSource, escalationPolicy: $escalationPolicy, priority: $priority, assignedTo: $assignedTo, images: $images, links: $links, responders: $responders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the alert count matching the specified criteria.
#
# GET /alerts/count
export def "alerts-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --states: list # state of the alert
  --sources: list # alert source IDs of the alert's alert source
  --responders: list # user ids of the user that is a responder of the alert
  --qp-from: string # from date (format: date-time)
  --until: string # until date (format: date-time)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "states" $states "multi") (serialize-qp "sources" $sources "multi") (serialize-qp "responders" $responders "multi") (serialize-qp "from" $qp_from "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the alert with the specified id.
#
# GET /alerts/{id}
export def "alerts get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Describes optional properties that should be included in the response. You may declare multiple. (escalationRules, nextEscalationUser, customDetails)
]: nothing -> record<id: int, summary: string, details: string, reportTime: string, resolvedOn: string, status: string, alertSource: record<id: int, teams: list<record>, name: string, iconUrl: string, lightIconUrl: string, darkIconUrl: string, escalationPolicy: record<id: int, name: string, escalationRules: list, teams: list, repeating: bool, frequency: int, delayMin: int, routingKey: string>, integrationType: string, integrationKey: string, integrationUrl: string, autoResolutionTimeout: string, alertGroupingWindow: string, alertCreation: string, status: string, active: bool, alertPriorityRule: string, supportHours: record<id: int, name: string, teams: list, timezone: string, supportDays: record, exceptions: list>, bidirectional: bool, summaryTemplate: record<textTemplate: string, elements: list>, detailsTemplate: record<textTemplate: string, elements: list>, routingTemplate: record<textTemplate: string, elements: list>, linkTemplates: list<record>, priorityTemplate: record<valueTemplate: record, mappings: list>, severityTemplate: record<valueTemplate: record, mappings: list>, eventFilter: string, alertKeyTemplate: record<textTemplate: string, elements: list>, servicesTemplate: list<record>, eventTypeFilterCreate: string, eventTypeFilterAccept: string, eventTypeFilterResolve: string, autoRaiseAlerts: bool, scoreThreshold: float, severity: int, services: list<record>, setupStatus: string, autoCreateServices: bool, createdAt: string, updatedAt: string>, escalationPolicy: record<id: int, name: string, escalationRules: list<record>, teams: list<record>, repeating: bool, frequency: int, delayMin: int, routingKey: string>, priority: string, alertKey: string, assignedTo: record<id: float>, nextEscalation: string, escalationRules: table<escalationTimeout: int, user: record, schedule: record, team: record, users: list, schedules: list, teams: list>, nextEscalationUser: record<id: int, firstName: string, lastName: string, email: string, timezone: string, position: string, department: string, avatarUrl: string, language: string, region: string, role: string, shiftColor: string, mutedUntil: string, createdAt: string, updatedAt: string>, nextEscalationRuleIndex: float, images: table<src: string, href: string, alt: string>, links: table<href: string, text: string>, responders: table<user: record, status: string, acceptedAt: string>, severity: int, labels: record, customDetails: record, linkedIncidentId: int, mergedIntoId: int, mergeState: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/alerts/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get available (assignable) responders for the alert with the specified id.
#
# GET /alerts/{id}/suggested-responders
export def "alerts-suggested-responders get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lang: string # locale for response text eg. 'en' or 'de'
]: nothing -> table<group: string, id: float, name: string, disabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/alerts/($id)/suggested-responders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an additional responder to the alert.
#
# POST /alerts/{id}/responders
export def "alerts-responders post" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<user: record<id: int, firstName: string, lastName: string>, status: string, acceptedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts/($id)/responders")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a responder from the alert.
#
# DELETE /alerts/{id}/responders/{user-id}
export def "alerts-responders delete" [
  id: float
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts/($id)/responders/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign the alert.
#
# PUT /alerts/{id}/assign
export def "alerts-assign put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user: string # numeric user id
  --policy: string # numeric policy id
  --schedule: string # numeric schedule id
]: nothing -> record<id: int, summary: string, details: string, reportTime: string, resolvedOn: string, status: string, alertSource: record<id: int, teams: list<record>, name: string, iconUrl: string, lightIconUrl: string, darkIconUrl: string, escalationPolicy: record<id: int, name: string, escalationRules: list, teams: list, repeating: bool, frequency: int, delayMin: int, routingKey: string>, integrationType: string, integrationKey: string, integrationUrl: string, autoResolutionTimeout: string, alertGroupingWindow: string, alertCreation: string, status: string, active: bool, alertPriorityRule: string, supportHours: record<id: int, name: string, teams: list, timezone: string, supportDays: record, exceptions: list>, bidirectional: bool, summaryTemplate: record<textTemplate: string, elements: list>, detailsTemplate: record<textTemplate: string, elements: list>, routingTemplate: record<textTemplate: string, elements: list>, linkTemplates: list<record>, priorityTemplate: record<valueTemplate: record, mappings: list>, severityTemplate: record<valueTemplate: record, mappings: list>, eventFilter: string, alertKeyTemplate: record<textTemplate: string, elements: list>, servicesTemplate: list<record>, eventTypeFilterCreate: string, eventTypeFilterAccept: string, eventTypeFilterResolve: string, autoRaiseAlerts: bool, scoreThreshold: float, severity: int, services: list<record>, setupStatus: string, autoCreateServices: bool, createdAt: string, updatedAt: string>, escalationPolicy: record<id: int, name: string, escalationRules: list<record>, teams: list<record>, repeating: bool, frequency: int, delayMin: int, routingKey: string>, priority: string, alertKey: string, assignedTo: record<id: float>, nextEscalation: string, escalationRules: table<escalationTimeout: int, user: record, schedule: record, team: record, users: list, schedules: list, teams: list>, nextEscalationUser: record<id: int, firstName: string, lastName: string, email: string, timezone: string, position: string, department: string, avatarUrl: string, language: string, region: string, role: string, shiftColor: string, mutedUntil: string, createdAt: string, updatedAt: string>, nextEscalationRuleIndex: float, images: table<src: string, href: string, alt: string>, links: table<href: string, text: string>, responders: table<user: record, status: string, acceptedAt: string>, severity: int, labels: record, customDetails: record, linkedIncidentId: int, mergedIntoId: int, mergeState: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar") (serialize-qp "policy" $policy "scalar") (serialize-qp "schedule" $schedule "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/alerts/($id)/assign" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept the Alert.
#
# PUT /alerts/{id}/accept
export def "alerts-accept put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, summary: string, details: string, reportTime: string, resolvedOn: string, status: string, alertSource: record<id: int, teams: list<record>, name: string, iconUrl: string, lightIconUrl: string, darkIconUrl: string, escalationPolicy: record<id: int, name: string, escalationRules: list, teams: list, repeating: bool, frequency: int, delayMin: int, routingKey: string>, integrationType: string, integrationKey: string, integrationUrl: string, autoResolutionTimeout: string, alertGroupingWindow: string, alertCreation: string, status: string, active: bool, alertPriorityRule: string, supportHours: record<id: int, name: string, teams: list, timezone: string, supportDays: record, exceptions: list>, bidirectional: bool, summaryTemplate: record<textTemplate: string, elements: list>, detailsTemplate: record<textTemplate: string, elements: list>, routingTemplate: record<textTemplate: string, elements: list>, linkTemplates: list<record>, priorityTemplate: record<valueTemplate: record, mappings: list>, severityTemplate: record<valueTemplate: record, mappings: list>, eventFilter: string, alertKeyTemplate: record<textTemplate: string, elements: list>, servicesTemplate: list<record>, eventTypeFilterCreate: string, eventTypeFilterAccept: string, eventTypeFilterResolve: string, autoRaiseAlerts: bool, scoreThreshold: float, severity: int, services: list<record>, setupStatus: string, autoCreateServices: bool, createdAt: string, updatedAt: string>, escalationPolicy: record<id: int, name: string, escalationRules: list<record>, teams: list<record>, repeating: bool, frequency: int, delayMin: int, routingKey: string>, priority: string, alertKey: string, assignedTo: record<id: float>, nextEscalation: string, escalationRules: table<escalationTimeout: int, user: record, schedule: record, team: record, users: list, schedules: list, teams: list>, nextEscalationUser: record<id: int, firstName: string, lastName: string, email: string, timezone: string, position: string, department: string, avatarUrl: string, language: string, region: string, role: string, shiftColor: string, mutedUntil: string, createdAt: string, updatedAt: string>, nextEscalationRuleIndex: float, images: table<src: string, href: string, alt: string>, links: table<href: string, text: string>, responders: table<user: record, status: string, acceptedAt: string>, severity: int, labels: record, customDetails: record, linkedIncidentId: int, mergedIntoId: int, mergeState: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts/($id)/accept")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve the alert.
#
# PUT /alerts/{id}/resolve
export def "alerts-resolve put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, summary: string, details: string, reportTime: string, resolvedOn: string, status: string, alertSource: record<id: int, teams: list<record>, name: string, iconUrl: string, lightIconUrl: string, darkIconUrl: string, escalationPolicy: record<id: int, name: string, escalationRules: list, teams: list, repeating: bool, frequency: int, delayMin: int, routingKey: string>, integrationType: string, integrationKey: string, integrationUrl: string, autoResolutionTimeout: string, alertGroupingWindow: string, alertCreation: string, status: string, active: bool, alertPriorityRule: string, supportHours: record<id: int, name: string, teams: list, timezone: string, supportDays: record, exceptions: list>, bidirectional: bool, summaryTemplate: record<textTemplate: string, elements: list>, detailsTemplate: record<textTemplate: string, elements: list>, routingTemplate: record<textTemplate: string, elements: list>, linkTemplates: list<record>, priorityTemplate: record<valueTemplate: record, mappings: list>, severityTemplate: record<valueTemplate: record, mappings: list>, eventFilter: string, alertKeyTemplate: record<textTemplate: string, elements: list>, servicesTemplate: list<record>, eventTypeFilterCreate: string, eventTypeFilterAccept: string, eventTypeFilterResolve: string, autoRaiseAlerts: bool, scoreThreshold: float, severity: int, services: list<record>, setupStatus: string, autoCreateServices: bool, createdAt: string, updatedAt: string>, escalationPolicy: record<id: int, name: string, escalationRules: list<record>, teams: list<record>, repeating: bool, frequency: int, delayMin: int, routingKey: string>, priority: string, alertKey: string, assignedTo: record<id: float>, nextEscalation: string, escalationRules: table<escalationTimeout: int, user: record, schedule: record, team: record, users: list, schedules: list, teams: list>, nextEscalationUser: record<id: int, firstName: string, lastName: string, email: string, timezone: string, position: string, department: string, avatarUrl: string, language: string, region: string, role: string, shiftColor: string, mutedUntil: string, createdAt: string, updatedAt: string>, nextEscalationRuleIndex: float, images: table<src: string, href: string, alt: string>, links: table<href: string, text: string>, responders: table<user: record, status: string, acceptedAt: string>, severity: int, labels: record, customDetails: record, linkedIncidentId: int, mergedIntoId: int, mergeState: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts/($id)/resolve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get notifications for the specified alert.
#
# GET /alerts/{id}/notifications
export def "alerts-notifications get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, method: string, target: string, subject: string, alertId: int, user: record<id: int, firstname: string, lastname: string>, notificationTime: string, status: string, errorMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts/($id)/notifications")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get log entries for the specified alert.
#
# GET /alerts/{id}/log-entries
export def "alerts-log-entries get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lang: string@lang-completer # log entry language
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of entities. (format: int32, default: 50)
  --include: list # Describes optional properties that should be included in the response. You may declare multiple. (vars)
  --filter-types: list # filter-type (group) of the log
]: nothing -> table<id: int, timestamp: string, logEntryType: string, text: string, alertId: int, filterTypes: list<string>, vars: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "include" $include "multi") (serialize-qp "filter-types" $filter_types "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/alerts/($id)/log-entries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get available actions for specified alert.
#
# GET /alerts/{id}/actions
export def "alerts-actions get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<alertActionId: string, connectorId: string, type: string, name: string, iconUrl: string, history: table<id: string, alertActionId: string, connectorId: string, alertId: float, success: bool, actor: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts/($id)/actions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invoke a specific alert action.
#
# POST /alerts/{id}/actions
# --history item shape: {id?: string, alertActionId?: string, connectorId?: string, alertId?: float, success?: bool, actor?: record}
export def "alerts-actions post" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alertActionId: string
  --connectorId: string
  --type: string
  --name: string
  --iconUrl: string
  --history: list # item shape: {id?: string, alertActionId?: string, connectorId?: string, alertId?: float, success?: bool, actor?: record}
]: any -> record<id: string, alertActionId: string, connectorId: string, alertId: float, success: bool, actor: record<id: int, firstName: string, lastName: string, email: string, timezone: string, position: string, department: string, avatarUrl: string, language: string, region: string, role: string, shiftColor: string, mutedUntil: string, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts/($id)/actions")
  let body = {alertActionId: $alertActionId, connectorId: $connectorId, type: $type, name: $name, iconUrl: $iconUrl, history: $history} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List on-call schedules.
#
# GET /schedules
export def "schedules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Describes optional properties that should be included in the response. You may declare multiple. (currentShift, nextShift, scheduleLayers [only available for RECURRING schedules], shifts [only available for STATIC schedules], past [show shifts in the past, only for STATIC])
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of schedules. (format: int32, default: 20)
]: nothing -> table<id: int, name: string, timezone: string, type: string, scheduleLayers: list<record>, shifts: list<record>, showGaps: bool, defaultShiftDuration: string, currentShift: record<user: record, end: string, start: string>, nextShift: record<user: record, end: string, start: string>, teams: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new on-call schedule.
#
# POST /schedules
# --scheduleLayers item shape: {name?: string, startsOn: string, endsOn?: string, users: list, rotation: string, restrictionType?: "TIMES_OF_WEEK", restrictions?: list}
# --shifts item shape: {user?: record, end?: string, start?: string}
# --currentShift shape: {user?: record, end?: string, start?: string}
# --nextShift shape: {user?: record, end?: string, start?: string}
# --teams item shape: {id?: int, name?: string}
export def "schedules post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --abort-on-gaps: string@bool-completer # Used for static schedules to prevent creating schedules with gaps
  --id: int # format: int64
  --name: string
  --timezone: string@timezone-completer
  --type: string@type-completer-3
  --scheduleLayers: list # item shape: {name?: string, startsOn: string, endsOn?: string, users: list, rotation: string, restrictionType?: "TIMES_OF_WEEK", restrictions?: list}
  --shifts: list # item shape: {user?: record, end?: string, start?: string}
  --showGaps: string@bool-completer
  --defaultShiftDuration: string # format: P7D
  --currentShift: record # shape: {user?: record, end?: string, start?: string}
  --nextShift: record # shape: {user?: record, end?: string, start?: string}
  --teams: list # item shape: {id?: int, name?: string}
]: any -> record<id: int, name: string, timezone: string, type: string, scheduleLayers: table<name: string, startsOn: string, endsOn: string, users: list, rotation: string, restrictionType: string, restrictions: list>, shifts: table<user: record, end: string, start: string>, showGaps: bool, defaultShiftDuration: string, currentShift: record<user: record<id: int, firstName: string, lastName: string>, end: string, start: string>, nextShift: record<user: record<id: int, firstName: string, lastName: string>, end: string, start: string>, teams: table<id: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "abort-on-gaps" $abort_on_gaps "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules" $qp)
  let body = {id: $id, name: $name, timezone: $timezone, type: $type, scheduleLayers: $scheduleLayers, shifts: $shifts, showGaps: $showGaps, defaultShiftDuration: $defaultShiftDuration, currentShift: $currentShift, nextShift: $nextShift, teams: $teams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the on-call schedule with the specified id.
#
# GET /schedules/{id}
export def "schedules get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Describes optional properties that should be included in the response. You may declare multiple. (currentShift, nextShift, scheduleLayers [only available for RECURRING schedules], shifts [only available for STATIC schedules], past [show shifts in the past, only for STATIC])
]: nothing -> record<id: int, name: string, timezone: string, type: string, scheduleLayers: table<name: string, startsOn: string, endsOn: string, users: list, rotation: string, restrictionType: string, restrictions: list>, shifts: table<user: record, end: string, start: string>, showGaps: bool, defaultShiftDuration: string, currentShift: record<user: record<id: int, firstName: string, lastName: string>, end: string, start: string>, nextShift: record<user: record<id: int, firstName: string, lastName: string>, end: string, start: string>, teams: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/schedules/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an on-call schedule.
#
# PUT /schedules/{id}
# --scheduleLayers item shape: {name?: string, startsOn: string, endsOn?: string, users: list, rotation: string, restrictionType?: "TIMES_OF_WEEK", restrictions?: list}
# --shifts item shape: {user?: record, end?: string, start?: string}
# --currentShift shape: {user?: record, end?: string, start?: string}
# --nextShift shape: {user?: record, end?: string, start?: string}
# --teams item shape: {id?: int, name?: string}
export def "schedules put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --abort-on-gaps: string@bool-completer # Used for static schedules to prevent updating schedules with gaps
  --body-id: int # format: int64
  --name: string
  --timezone: string@timezone-completer
  --type: string@type-completer-3
  --scheduleLayers: list # item shape: {name?: string, startsOn: string, endsOn?: string, users: list, rotation: string, restrictionType?: "TIMES_OF_WEEK", restrictions?: list}
  --shifts: list # item shape: {user?: record, end?: string, start?: string}
  --showGaps: string@bool-completer
  --defaultShiftDuration: string # format: P7D
  --currentShift: record # shape: {user?: record, end?: string, start?: string}
  --nextShift: record # shape: {user?: record, end?: string, start?: string}
  --teams: list # item shape: {id?: int, name?: string}
]: any -> record<id: int, name: string, timezone: string, type: string, scheduleLayers: table<name: string, startsOn: string, endsOn: string, users: list, rotation: string, restrictionType: string, restrictions: list>, shifts: table<user: record, end: string, start: string>, showGaps: bool, defaultShiftDuration: string, currentShift: record<user: record<id: int, firstName: string, lastName: string>, end: string, start: string>, nextShift: record<user: record<id: int, firstName: string, lastName: string>, end: string, start: string>, teams: table<id: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "abort-on-gaps" $abort_on_gaps "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/schedules/($id)" $qp)
  let body = {id: $body_id, name: $name, timezone: $timezone, type: $type, scheduleLayers: $scheduleLayers, shifts: $shifts, showGaps: $showGaps, defaultShiftDuration: $defaultShiftDuration, currentShift: $currentShift, nextShift: $nextShift, teams: $teams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the on-call schedule with the specified id.
#
# DELETE /schedules/{id}
export def "schedules delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schedules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get shifts for the specified schedule and date range.
#
# GET /schedules/{id}/shifts
export def "schedules-shifts get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # from date, default is start of last month (format: date-time)
  --until: string # until date, default is from date plus 3 months
  --exclude-overrides: string@bool-completer # if true, shifts won't include overrides (default: false)
]: nothing -> table<user: record<id: int, firstName: string, lastName: string, email: string, timezone: string, position: string, department: string, avatarUrl: string, language: string, region: string, role: string, shiftColor: string, mutedUntil: string, createdAt: string, updatedAt: string>, end: string, start: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "exclude-overrides" $exclude_overrides "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/schedules/($id)/shifts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get overrides for the specified schedule.
#
# GET /schedules/{id}/overrides
export def "schedules-overrides get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<user: record<id: int, firstName: string, lastName: string, email: string, timezone: string, position: string, department: string, avatarUrl: string, language: string, region: string, role: string, shiftColor: string, mutedUntil: string, createdAt: string, updatedAt: string>, end: string, start: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schedules/($id)/overrides")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an override shift to a schedule.
#
# PUT /schedules/{id}/overrides
# --user shape: {id?: int, firstName: string, lastName: string, email: string, timezone?: "Europe/Berlin"|"America/New_York"|"America/Los_Angeles"|"Asia/Istanbul", position?: string, department?: string, language?: "de"|"en", region?: "DE"|"GB"|"CH"|"CN"|"IN"|"US"|"FR"|"ES"|"CA"|"IE", role?: "STAKEHOLDER"|"GUEST"|"RESPONDER"|"USER"|"ADMIN", shiftColor?: string, mutedUntil?: string, createdAt?: string, updatedAt?: string}
export def "schedules-overrides put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user: record # shape: {id?: int, firstName: string, lastName: string, email: string, timezone?: "Europe/Berlin"|"America/New_York"|"America/Los_Angeles"|"Asia/Istanbul", position?: string, department?: string, language?: "de"|"en", region?: "DE"|"GB"|"CH"|"CN"|"IN"|"US"|"FR"|"ES"|"CA"|"IE", role?: "STAKEHOLDER"|"GUEST"|"RESPONDER"|"USER"|"ADMIN", shiftColor?: string, mutedUntil?: string, createdAt?: string, updatedAt?: string}
  --end: string # format: date-time
  --start: string # format: date-time
]: any -> record<id: int, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schedules/($id)/overrides")
  let body = {user: $user, end: $end, start: $start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the user (wrapped in a shift object) on-call for the specified schedule.
#
# GET /schedules/{id}/user-on-call
export def "schedules-user-on-call get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<user: record<id: int, firstName: string, lastName: string, email: string, timezone: string, position: string, department: string, avatarUrl: string, language: string, region: string, role: string, shiftColor: string, mutedUntil: string, createdAt: string, updatedAt: string>, end: string, start: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schedules/($id)/user-on-call")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List on-calls with flexible filters
#
# GET /on-calls
export def "on-calls get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --policies: float # escalation policy ids to filter on call duties for
  --policy-levels: string # can be provided instead of 'policies', must be a serialised and urlencoded JSON object e.g. ?policy-levels="{ "id": 12, "level": 1 }" where id is the policy id and level is the escalation level that should be included
  --schedules: float # on call schedule ids to filter on call duties for
  --users: float # user ids to filter on call duties for
  --expand: string # include full entities for: policy, escalationPolicy or user
  --qp-from: string # date-time ISO-UTC e.g. 2021-05-25T21:24:56.771Z, start of the time range, may not exceed 3 months in total span, defaults to current time
  --until: string # date-time ISO-UTC e.g. 2021-05-25T21:24:56.771Z, end of the time range, must be after 'from', defaults to current time
  --timezone: string # Time zone in which the results will be rendered, defaults to UTC
  --start-index: float # offset for the search results, defaults to 0
  --max-results: float # limit for the search results, defaults to 50, may not exceed 250
]: nothing -> table<user: record<id: int, firstName: string, lastName: string, email: string, timezone: string, position: string, department: string, avatarUrl: string, language: string, region: string, role: string, shiftColor: string, mutedUntil: string, createdAt: string, updatedAt: string>, escalationPolicy: record<id: int, name: string, escalationRules: list, teams: list, repeating: bool, frequency: int, delayMin: int, routingKey: string>, schedule: record<id: int, name: string, type: string>, start: string, end: string, escalationLevel: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policies" $policies "scalar") (serialize-qp "policy-levels" $policy_levels "scalar") (serialize-qp "schedules" $schedules "scalar") (serialize-qp "users" $users "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/on-calls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List alert sources.
#
# GET /alert-sources
export def "alert-sources list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of alert sources. (format: int32, default: 50)
]: nothing -> table<id: int, teams: list<record>, name: string, iconUrl: string, lightIconUrl: string, darkIconUrl: string, escalationPolicy: record<id: int, name: string, escalationRules: list, teams: list, repeating: bool, frequency: int, delayMin: int, routingKey: string>, integrationType: string, integrationKey: string, integrationUrl: string, autoResolutionTimeout: string, alertGroupingWindow: string, alertCreation: string, status: string, active: bool, alertPriorityRule: string, supportHours: record<id: int, name: string, teams: list, timezone: string, supportDays: record, exceptions: list>, bidirectional: bool, autoRaiseAlerts: bool, scoreThreshold: float, severity: int, services: list<record>, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/alert-sources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new alert source.
#
# POST /alert-sources
# --teams item shape: {id?: int, name?: string}
# --escalationPolicy shape: {id?: int, name: string, escalationRules: list, teams?: list, repeating?: bool, frequency?: int, delayMin?: int, routingKey?: string}
# --supportHours shape: {id: int}
# --summaryTemplate shape: {textTemplate?: string, elements?: list}
# --detailsTemplate shape: {textTemplate?: string, elements?: list}
# --routingTemplate shape: {textTemplate?: string, elements?: list}
# --linkTemplates item shape: {text: string, hrefTemplate: record}
# --priorityTemplate shape: {valueTemplate: record, mappings: list}
# --severityTemplate shape: {valueTemplate: record, mappings: list}
# --alertKeyTemplate shape: {textTemplate?: string, elements?: list}
# --servicesTemplate item shape: {textTemplate?: string, elements?: list}
# --services item shape: {id?: float, name?: string, alias?: string, status?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", description?: string, oneOpenIncidentOnly?: bool, showUptimeHistory?: bool, teams?: list, uptime?: record}
export def "alert-sources post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int64
  --teams: list # item shape: {id?: int, name?: string}
  name: string
  --iconUrl: string
  --lightIconUrl: string
  --darkIconUrl: string
  escalationPolicy: record # shape: {id?: int, name: string, escalationRules: list, teams?: list, repeating?: bool, frequency?: int, delayMin?: int, routingKey?: string}
  integrationType: string@integrationType-completer
  --integrationKey: string
  --autoResolutionTimeout: string # format: ISO-8601
  --alertGroupingWindow: string # format: ISO-8601
  --alertCreation: string@alertCreation-completer # default: ONE_ALERT_PER_EMAIL
  --active: string@bool-completer # default: true
  --alertPriorityRule: string@alertPriorityRule-completer
  --supportHours: record # For POST and PUT requests only the id field is required for sub entities, e.g. status page -> service, alert source -> support hour — shape: {id: int}
  --summaryTemplate: record # shape: {textTemplate?: string, elements?: list}
  --detailsTemplate: record # shape: {textTemplate?: string, elements?: list}
  --routingTemplate: record # shape: {textTemplate?: string, elements?: list}
  --linkTemplates: list # item shape: {text: string, hrefTemplate: record}
  --priorityTemplate: record # shape: {valueTemplate: record, mappings: list}
  --severityTemplate: record # shape: {valueTemplate: record, mappings: list}
  --eventFilter: string # Defines an optional event filter condition in ICL language. This is a code based implementation, more info on syntax: https://docs.ilert.com/rest-api/icl-ilert-condition-language. For block based configuration please use the web UI. It has no effect on manually created alerts. Note: this field is an ?include, it will not appear in lists.
  --alertKeyTemplate: record # shape: {textTemplate?: string, elements?: list}
  --servicesTemplate: list # Optional list of templates that extract service identifiers from the inbound event payload. Each rendered value is comma-split, and each resulting token is resolved against the tenant's services by alias or name (case-insensitive). Unmatched tokens are silently dropped. Capped at 10 templates and at the alert's per-event services limit. Note: this field is an ?include, it will not appear in lists. — item shape: {textTemplate?: string, elements?: list}
  --eventTypeFilterCreate: string # Defines an optional create alert rule in ICL language. This is a code based implementation, more info on syntax: https://docs.ilert.com/rest-api/icl-ilert-condition-language. For block based configuration please use the web UI. It has no effect on manually created alerts. Note: this field is an ?include, it will not appear in lists.
  --eventTypeFilterAccept: string # Defines an optional accept alert rule in ICL language This is a code based implementation, more info on syntax: https://docs.ilert.com/rest-api/icl-ilert-condition-language. For block based configuration please use the web UI. It has no effect on manually created alerts. Note: this field is an ?include, it will not appear in lists.
  --eventTypeFilterResolve: string # Defines an optional resolve alert rule in ICL language This is a code based implementation, more info on syntax: https://docs.ilert.com/rest-api/icl-ilert-condition-language. For block based configuration please use the web UI. It has no effect on manually created alerts. Note: this field is an ?include, it will not appear in lists.
  --autoRaiseAlerts: string@bool-completer # Only effective when a support hour is linked to this alert source.
  --scoreThreshold: float # Only used when alertCreation is set to INTELLIGENT_GROUPING. (format: double)
  --severity: int
  --services: list # item shape: {id?: float, name?: string, alias?: string, status?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", description?: string, oneOpenIncidentOnly?: bool, showUptimeHistory?: bool, teams?: list, uptime?: record}
  --setupStatus: string@setupStatus-completer
  --autoCreateServices: string@bool-completer # default: false
]: any -> record<id: int, teams: table<id: int, name: string>, name: string, iconUrl: string, lightIconUrl: string, darkIconUrl: string, escalationPolicy: record<id: int, name: string, escalationRules: list<record>, teams: list<record>, repeating: bool, frequency: int, delayMin: int, routingKey: string>, integrationType: string, integrationKey: string, integrationUrl: string, autoResolutionTimeout: string, alertGroupingWindow: string, alertCreation: string, status: string, active: bool, alertPriorityRule: string, supportHours: record<id: int, name: string, teams: list<record>, timezone: string, supportDays: record<MONDAY: record, TUESDAY: record, WEDNESDAY: record, THURSDAY: record, FRIDAY: record, SATURDAY: record, SUNDAY: record>, exceptions: list<record>>, bidirectional: bool, summaryTemplate: record<textTemplate: string, elements: list<record>>, detailsTemplate: record<textTemplate: string, elements: list<record>>, routingTemplate: record<textTemplate: string, elements: list<record>>, linkTemplates: table<text: string, hrefTemplate: record>, priorityTemplate: record<valueTemplate: record<textTemplate: string, elements: list>, mappings: list<record>>, severityTemplate: record<valueTemplate: record<textTemplate: string, elements: list>, mappings: list<record>>, eventFilter: string, alertKeyTemplate: record<textTemplate: string, elements: list<record>>, servicesTemplate: table<textTemplate: string, elements: list>, eventTypeFilterCreate: string, eventTypeFilterAccept: string, eventTypeFilterResolve: string, autoRaiseAlerts: bool, scoreThreshold: float, severity: int, services: table<id: float, name: string, alias: string, status: string, description: string, oneOpenIncidentOnly: bool, showUptimeHistory: bool, teams: list, subscribed: bool, uptime: record, incidents: list>, setupStatus: string, autoCreateServices: bool, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/alert-sources")
  let body = {id: $id, teams: $teams, name: $name, iconUrl: $iconUrl, lightIconUrl: $lightIconUrl, darkIconUrl: $darkIconUrl, escalationPolicy: $escalationPolicy, integrationType: $integrationType, integrationKey: $integrationKey, autoResolutionTimeout: $autoResolutionTimeout, alertGroupingWindow: $alertGroupingWindow, alertCreation: $alertCreation, active: $active, alertPriorityRule: $alertPriorityRule, supportHours: $supportHours, summaryTemplate: $summaryTemplate, detailsTemplate: $detailsTemplate, routingTemplate: $routingTemplate, linkTemplates: $linkTemplates, priorityTemplate: $priorityTemplate, severityTemplate: $severityTemplate, eventFilter: $eventFilter, alertKeyTemplate: $alertKeyTemplate, servicesTemplate: $servicesTemplate, eventTypeFilterCreate: $eventTypeFilterCreate, eventTypeFilterAccept: $eventTypeFilterAccept, eventTypeFilterResolve: $eventTypeFilterResolve, autoRaiseAlerts: $autoRaiseAlerts, scoreThreshold: $scoreThreshold, severity: $severity, services: $services, setupStatus: $setupStatus, autoCreateServices: $autoCreateServices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the alert source with specified id or alternatively integration key.
#
# GET /alert-sources/{id}
export def "alert-sources get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Describes optional properties that should be included in the response. You may declare multiple. (detailsTemplate, summaryTemplate, routingTemplate, linkTemplates, priorityTemplate, severityTemplate, textTemplate, eventFilter, alertKeyTemplate, servicesTemplate, eventTypeFilterCreate, eventTypeFilterAccept, eventTypeFilterResolve); some may not work in lists; may be used for POST and PUT as well.
]: nothing -> record<id: int, teams: table<id: int, name: string>, name: string, iconUrl: string, lightIconUrl: string, darkIconUrl: string, escalationPolicy: record<id: int, name: string, escalationRules: list<record>, teams: list<record>, repeating: bool, frequency: int, delayMin: int, routingKey: string>, integrationType: string, integrationKey: string, integrationUrl: string, autoResolutionTimeout: string, alertGroupingWindow: string, alertCreation: string, status: string, active: bool, alertPriorityRule: string, supportHours: record<id: int, name: string, teams: list<record>, timezone: string, supportDays: record<MONDAY: record, TUESDAY: record, WEDNESDAY: record, THURSDAY: record, FRIDAY: record, SATURDAY: record, SUNDAY: record>, exceptions: list<record>>, bidirectional: bool, summaryTemplate: record<textTemplate: string, elements: list<record>>, detailsTemplate: record<textTemplate: string, elements: list<record>>, routingTemplate: record<textTemplate: string, elements: list<record>>, linkTemplates: table<text: string, hrefTemplate: record>, priorityTemplate: record<valueTemplate: record<textTemplate: string, elements: list>, mappings: list<record>>, severityTemplate: record<valueTemplate: record<textTemplate: string, elements: list>, mappings: list<record>>, eventFilter: string, alertKeyTemplate: record<textTemplate: string, elements: list<record>>, servicesTemplate: table<textTemplate: string, elements: list>, eventTypeFilterCreate: string, eventTypeFilterAccept: string, eventTypeFilterResolve: string, autoRaiseAlerts: bool, scoreThreshold: float, severity: int, services: table<id: float, name: string, alias: string, status: string, description: string, oneOpenIncidentOnly: bool, showUptimeHistory: bool, teams: list, subscribed: bool, uptime: record, incidents: list>, setupStatus: string, autoCreateServices: bool, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/alert-sources/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing alert source.
#
# PUT /alert-sources/{id}
# --teams item shape: {id?: int, name?: string}
# --escalationPolicy shape: {id?: int, name: string, escalationRules: list, teams?: list, repeating?: bool, frequency?: int, delayMin?: int, routingKey?: string}
# --supportHours shape: {id: int}
# --summaryTemplate shape: {textTemplate?: string, elements?: list}
# --detailsTemplate shape: {textTemplate?: string, elements?: list}
# --routingTemplate shape: {textTemplate?: string, elements?: list}
# --linkTemplates item shape: {text: string, hrefTemplate: record}
# --priorityTemplate shape: {valueTemplate: record, mappings: list}
# --severityTemplate shape: {valueTemplate: record, mappings: list}
# --alertKeyTemplate shape: {textTemplate?: string, elements?: list}
# --servicesTemplate item shape: {textTemplate?: string, elements?: list}
# --services item shape: {id?: float, name?: string, alias?: string, status?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", description?: string, oneOpenIncidentOnly?: bool, showUptimeHistory?: bool, teams?: list, uptime?: record}
export def "alert-sources put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: int # format: int64
  --teams: list # item shape: {id?: int, name?: string}
  name: string
  --iconUrl: string
  --lightIconUrl: string
  --darkIconUrl: string
  escalationPolicy: record # shape: {id?: int, name: string, escalationRules: list, teams?: list, repeating?: bool, frequency?: int, delayMin?: int, routingKey?: string}
  integrationType: string@integrationType-completer
  --integrationKey: string
  --autoResolutionTimeout: string # format: ISO-8601
  --alertGroupingWindow: string # format: ISO-8601
  --alertCreation: string@alertCreation-completer # default: ONE_ALERT_PER_EMAIL
  --active: string@bool-completer # default: true
  --alertPriorityRule: string@alertPriorityRule-completer
  --supportHours: record # For POST and PUT requests only the id field is required for sub entities, e.g. status page -> service, alert source -> support hour — shape: {id: int}
  --summaryTemplate: record # shape: {textTemplate?: string, elements?: list}
  --detailsTemplate: record # shape: {textTemplate?: string, elements?: list}
  --routingTemplate: record # shape: {textTemplate?: string, elements?: list}
  --linkTemplates: list # item shape: {text: string, hrefTemplate: record}
  --priorityTemplate: record # shape: {valueTemplate: record, mappings: list}
  --severityTemplate: record # shape: {valueTemplate: record, mappings: list}
  --eventFilter: string # Defines an optional event filter condition in ICL language. This is a code based implementation, more info on syntax: https://docs.ilert.com/rest-api/icl-ilert-condition-language. For block based configuration please use the web UI. It has no effect on manually created alerts. Note: this field is an ?include, it will not appear in lists.
  --alertKeyTemplate: record # shape: {textTemplate?: string, elements?: list}
  --servicesTemplate: list # Optional list of templates that extract service identifiers from the inbound event payload. Each rendered value is comma-split, and each resulting token is resolved against the tenant's services by alias or name (case-insensitive). Unmatched tokens are silently dropped. Capped at 10 templates and at the alert's per-event services limit. Note: this field is an ?include, it will not appear in lists. — item shape: {textTemplate?: string, elements?: list}
  --eventTypeFilterCreate: string # Defines an optional create alert rule in ICL language. This is a code based implementation, more info on syntax: https://docs.ilert.com/rest-api/icl-ilert-condition-language. For block based configuration please use the web UI. It has no effect on manually created alerts. Note: this field is an ?include, it will not appear in lists.
  --eventTypeFilterAccept: string # Defines an optional accept alert rule in ICL language This is a code based implementation, more info on syntax: https://docs.ilert.com/rest-api/icl-ilert-condition-language. For block based configuration please use the web UI. It has no effect on manually created alerts. Note: this field is an ?include, it will not appear in lists.
  --eventTypeFilterResolve: string # Defines an optional resolve alert rule in ICL language This is a code based implementation, more info on syntax: https://docs.ilert.com/rest-api/icl-ilert-condition-language. For block based configuration please use the web UI. It has no effect on manually created alerts. Note: this field is an ?include, it will not appear in lists.
  --autoRaiseAlerts: string@bool-completer # Only effective when a support hour is linked to this alert source.
  --scoreThreshold: float # Only used when alertCreation is set to INTELLIGENT_GROUPING. (format: double)
  --severity: int
  --services: list # item shape: {id?: float, name?: string, alias?: string, status?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", description?: string, oneOpenIncidentOnly?: bool, showUptimeHistory?: bool, teams?: list, uptime?: record}
  --setupStatus: string@setupStatus-completer
  --autoCreateServices: string@bool-completer # default: false
]: any -> record<id: int, teams: table<id: int, name: string>, name: string, iconUrl: string, lightIconUrl: string, darkIconUrl: string, escalationPolicy: record<id: int, name: string, escalationRules: list<record>, teams: list<record>, repeating: bool, frequency: int, delayMin: int, routingKey: string>, integrationType: string, integrationKey: string, integrationUrl: string, autoResolutionTimeout: string, alertGroupingWindow: string, alertCreation: string, status: string, active: bool, alertPriorityRule: string, supportHours: record<id: int, name: string, teams: list<record>, timezone: string, supportDays: record<MONDAY: record, TUESDAY: record, WEDNESDAY: record, THURSDAY: record, FRIDAY: record, SATURDAY: record, SUNDAY: record>, exceptions: list<record>>, bidirectional: bool, summaryTemplate: record<textTemplate: string, elements: list<record>>, detailsTemplate: record<textTemplate: string, elements: list<record>>, routingTemplate: record<textTemplate: string, elements: list<record>>, linkTemplates: table<text: string, hrefTemplate: record>, priorityTemplate: record<valueTemplate: record<textTemplate: string, elements: list>, mappings: list<record>>, severityTemplate: record<valueTemplate: record<textTemplate: string, elements: list>, mappings: list<record>>, eventFilter: string, alertKeyTemplate: record<textTemplate: string, elements: list<record>>, servicesTemplate: table<textTemplate: string, elements: list>, eventTypeFilterCreate: string, eventTypeFilterAccept: string, eventTypeFilterResolve: string, autoRaiseAlerts: bool, scoreThreshold: float, severity: int, services: table<id: float, name: string, alias: string, status: string, description: string, oneOpenIncidentOnly: bool, showUptimeHistory: bool, teams: list, subscribed: bool, uptime: record, incidents: list>, setupStatus: string, autoCreateServices: bool, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alert-sources/($id)")
  let body = {id: $body_id, teams: $teams, name: $name, iconUrl: $iconUrl, lightIconUrl: $lightIconUrl, darkIconUrl: $darkIconUrl, escalationPolicy: $escalationPolicy, integrationType: $integrationType, integrationKey: $integrationKey, autoResolutionTimeout: $autoResolutionTimeout, alertGroupingWindow: $alertGroupingWindow, alertCreation: $alertCreation, active: $active, alertPriorityRule: $alertPriorityRule, supportHours: $supportHours, summaryTemplate: $summaryTemplate, detailsTemplate: $detailsTemplate, routingTemplate: $routingTemplate, linkTemplates: $linkTemplates, priorityTemplate: $priorityTemplate, severityTemplate: $severityTemplate, eventFilter: $eventFilter, alertKeyTemplate: $alertKeyTemplate, servicesTemplate: $servicesTemplate, eventTypeFilterCreate: $eventTypeFilterCreate, eventTypeFilterAccept: $eventTypeFilterAccept, eventTypeFilterResolve: $eventTypeFilterResolve, autoRaiseAlerts: $autoRaiseAlerts, scoreThreshold: $scoreThreshold, severity: $severity, services: $services, setupStatus: $setupStatus, autoCreateServices: $autoCreateServices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the specified alert source.
#
# DELETE /alert-sources/{id}
export def "alert-sources delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alert-sources/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List heartbeat monitors.
#
# GET /heartbeat-monitors
export def "heartbeat-monitors list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A cursor identifying the current position in the pagination, leave empty to start at the first item, each call returns a 'next-cursor' header for the next page, do not alter the cursor yourself.
  --max-results: int # The maximum number of results when paging through a list of heartbeat monitors. (format: int32, default: 100)
  --include: list # Describes optional properties that should be included in the response. You may declare multiple. (integrationKey, integrationUrl)
]: nothing -> table<id: int, name: string, state: string, intervalSec: int, alertSummary: string, createdAt: string, updatedAt: string, teams: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/heartbeat-monitors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new heartbeat monitor.
#
# POST /heartbeat-monitors
# --alertSource shape: {id: int}
export def "heartbeat-monitors post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Describes optional properties that should be included in the response. You may declare multiple. (alertSource (default), integrationKey (default), integrationUrl)
  name: string
  intervalSec: int # We recommend using an interval between 3 and 5 minutes, while pinging every 60 seconds. Of course if you are tracking use-cases like backup jobs that run once a week, a larger timeout and less pings suffice. (format: int32)
  --alertSummary: string
  --alertSource: record # For POST and PUT requests only the id field is required for sub entities, e.g. status page -> service, alert source -> support hour — shape: {id: int}
]: any -> record<id: int, name: string, state: string, intervalSec: int, alertSummary: string, createdAt: string, updatedAt: string, alertSource: record<id: int, teams: list<record>, name: string, iconUrl: string, lightIconUrl: string, darkIconUrl: string, escalationPolicy: record<id: int, name: string, escalationRules: list, teams: list, repeating: bool, frequency: int, delayMin: int, routingKey: string>, integrationType: string, integrationKey: string, integrationUrl: string, autoResolutionTimeout: string, alertGroupingWindow: string, alertCreation: string, status: string, active: bool, alertPriorityRule: string, supportHours: record<id: int>, bidirectional: bool, summaryTemplate: record<textTemplate: string, elements: list>, detailsTemplate: record<textTemplate: string, elements: list>, routingTemplate: record<textTemplate: string, elements: list>, linkTemplates: list<record>, priorityTemplate: record<valueTemplate: record, mappings: list>, severityTemplate: record<valueTemplate: record, mappings: list>, eventFilter: string, alertKeyTemplate: record<textTemplate: string, elements: list>, servicesTemplate: list<record>, eventTypeFilterCreate: string, eventTypeFilterAccept: string, eventTypeFilterResolve: string, autoRaiseAlerts: bool, scoreThreshold: float, severity: int, services: list<record>, setupStatus: string, autoCreateServices: bool, createdAt: string, updatedAt: string>, teams: table<id: int, name: string>, integrationKey: string, integrationUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/heartbeat-monitors" $qp)
  let body = {name: $name, intervalSec: $intervalSec, alertSummary: $alertSummary, alertSource: $alertSource} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the heartbeat monitor with specified id.
#
# GET /heartbeat-monitors/{id}
export def "heartbeat-monitors get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Describes optional properties that should be included in the response. You may declare multiple. (integrationKey (default), integrationUrl, alertSource (default)); alertSource does not work in lists; may be used for POST and PUT as well.
]: nothing -> record<id: int, name: string, state: string, intervalSec: int, alertSummary: string, createdAt: string, updatedAt: string, alertSource: record<id: int, teams: list<record>, name: string, iconUrl: string, lightIconUrl: string, darkIconUrl: string, escalationPolicy: record<id: int, name: string, escalationRules: list, teams: list, repeating: bool, frequency: int, delayMin: int, routingKey: string>, integrationType: string, integrationKey: string, integrationUrl: string, autoResolutionTimeout: string, alertGroupingWindow: string, alertCreation: string, status: string, active: bool, alertPriorityRule: string, supportHours: record<id: int>, bidirectional: bool, summaryTemplate: record<textTemplate: string, elements: list>, detailsTemplate: record<textTemplate: string, elements: list>, routingTemplate: record<textTemplate: string, elements: list>, linkTemplates: list<record>, priorityTemplate: record<valueTemplate: record, mappings: list>, severityTemplate: record<valueTemplate: record, mappings: list>, eventFilter: string, alertKeyTemplate: record<textTemplate: string, elements: list>, servicesTemplate: list<record>, eventTypeFilterCreate: string, eventTypeFilterAccept: string, eventTypeFilterResolve: string, autoRaiseAlerts: bool, scoreThreshold: float, severity: int, services: list<record>, setupStatus: string, autoCreateServices: bool, createdAt: string, updatedAt: string>, teams: table<id: int, name: string>, integrationKey: string, integrationUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/heartbeat-monitors/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing heartbeat monitor.
#
# PUT /heartbeat-monitors/{id}
# --alertSource shape: {id: int}
export def "heartbeat-monitors put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  intervalSec: int # We recommend using an interval between 3 and 5 minutes, while pinging every 60 seconds. Of course if you are tracking use-cases like backup jobs that run once a week, a larger timeout and less pings suffice. (format: int32)
  --alertSummary: string
  --alertSource: record # For POST and PUT requests only the id field is required for sub entities, e.g. status page -> service, alert source -> support hour — shape: {id: int}
]: any -> record<id: int, name: string, state: string, intervalSec: int, alertSummary: string, createdAt: string, updatedAt: string, alertSource: record<id: int, teams: list<record>, name: string, iconUrl: string, lightIconUrl: string, darkIconUrl: string, escalationPolicy: record<id: int, name: string, escalationRules: list, teams: list, repeating: bool, frequency: int, delayMin: int, routingKey: string>, integrationType: string, integrationKey: string, integrationUrl: string, autoResolutionTimeout: string, alertGroupingWindow: string, alertCreation: string, status: string, active: bool, alertPriorityRule: string, supportHours: record<id: int>, bidirectional: bool, summaryTemplate: record<textTemplate: string, elements: list>, detailsTemplate: record<textTemplate: string, elements: list>, routingTemplate: record<textTemplate: string, elements: list>, linkTemplates: list<record>, priorityTemplate: record<valueTemplate: record, mappings: list>, severityTemplate: record<valueTemplate: record, mappings: list>, eventFilter: string, alertKeyTemplate: record<textTemplate: string, elements: list>, servicesTemplate: list<record>, eventTypeFilterCreate: string, eventTypeFilterAccept: string, eventTypeFilterResolve: string, autoRaiseAlerts: bool, scoreThreshold: float, severity: int, services: list<record>, setupStatus: string, autoCreateServices: bool, createdAt: string, updatedAt: string>, teams: table<id: int, name: string>, integrationKey: string, integrationUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/heartbeat-monitors/($id)")
  let body = {name: $name, intervalSec: $intervalSec, alertSummary: $alertSummary, alertSource: $alertSource} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the specified heartbeat monitor.
#
# DELETE /heartbeat-monitors/{id}
export def "heartbeat-monitors delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/heartbeat-monitors/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List support hours.
#
# GET /support-hours
export def "support-hours list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of support hours. (format: int32, default: 50)
]: nothing -> table<id: int, name: string, teams: list<record>, timezone: string, supportDays: record<MONDAY: record, TUESDAY: record, WEDNESDAY: record, THURSDAY: record, FRIDAY: record, SATURDAY: record, SUNDAY: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/support-hours" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new support hour.
#
# POST /support-hours
# --teams item shape: {id?: int, name?: string}
# --supportDays shape: {MONDAY?: record, TUESDAY?: record, WEDNESDAY?: record, THURSDAY?: record, FRIDAY?: record, SATURDAY?: record, SUNDAY?: record}
# --exceptions item shape: {name: string, start: string, end: string, supportStatus: "DURING"|"OUTSIDE"}
export def "support-hours post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int64
  name: string
  --teams: list # item shape: {id?: int, name?: string}
  timezone: string@timezone-completer
  supportDays: record # shape: {MONDAY?: record, TUESDAY?: record, WEDNESDAY?: record, THURSDAY?: record, FRIDAY?: record, SATURDAY?: record, SUNDAY?: record}
  --exceptions: list # item shape: {name: string, start: string, end: string, supportStatus: "DURING"|"OUTSIDE"}
]: any -> record<id: int, name: string, teams: table<id: int, name: string>, timezone: string, supportDays: record<MONDAY: record<start: string, end: string>, TUESDAY: record<start: string, end: string>, WEDNESDAY: record<start: string, end: string>, THURSDAY: record<start: string, end: string>, FRIDAY: record<start: string, end: string>, SATURDAY: record<start: string, end: string>, SUNDAY: record<start: string, end: string>>, exceptions: table<name: string, start: string, end: string, supportStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/support-hours")
  let body = {id: $id, name: $name, teams: $teams, timezone: $timezone, supportDays: $supportDays, exceptions: $exceptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the support hour with specified id.
#
# GET /support-hours/{id}
export def "support-hours get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, teams: table<id: int, name: string>, timezone: string, supportDays: record<MONDAY: record<start: string, end: string>, TUESDAY: record<start: string, end: string>, WEDNESDAY: record<start: string, end: string>, THURSDAY: record<start: string, end: string>, FRIDAY: record<start: string, end: string>, SATURDAY: record<start: string, end: string>, SUNDAY: record<start: string, end: string>>, exceptions: table<name: string, start: string, end: string, supportStatus: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/support-hours/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing support hour.
#
# PUT /support-hours/{id}
# --teams item shape: {id?: int, name?: string}
# --supportDays shape: {MONDAY?: record, TUESDAY?: record, WEDNESDAY?: record, THURSDAY?: record, FRIDAY?: record, SATURDAY?: record, SUNDAY?: record}
# --exceptions item shape: {name: string, start: string, end: string, supportStatus: "DURING"|"OUTSIDE"}
export def "support-hours put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: int # format: int64
  name: string
  --teams: list # item shape: {id?: int, name?: string}
  timezone: string@timezone-completer
  supportDays: record # shape: {MONDAY?: record, TUESDAY?: record, WEDNESDAY?: record, THURSDAY?: record, FRIDAY?: record, SATURDAY?: record, SUNDAY?: record}
  --exceptions: list # item shape: {name: string, start: string, end: string, supportStatus: "DURING"|"OUTSIDE"}
]: any -> record<id: int, name: string, teams: table<id: int, name: string>, timezone: string, supportDays: record<MONDAY: record<start: string, end: string>, TUESDAY: record<start: string, end: string>, WEDNESDAY: record<start: string, end: string>, THURSDAY: record<start: string, end: string>, FRIDAY: record<start: string, end: string>, SATURDAY: record<start: string, end: string>, SUNDAY: record<start: string, end: string>>, exceptions: table<name: string, start: string, end: string, supportStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/support-hours/($id)")
  let body = {id: $body_id, name: $name, teams: $teams, timezone: $timezone, supportDays: $supportDays, exceptions: $exceptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the specified support hour.
#
# DELETE /support-hours/{id}
export def "support-hours delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/support-hours/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List maintenance windows.
#
# GET /maintenance-windows
export def "maintenance-windows list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --state: string@state-completer # Filter maintenance windows by state. `OPEN` includes upcoming and ongoing windows, `CLOSED` includes past windows.
  --services: list # filter by service IDs
  --sources: list # filter by alert source IDs
  --qp-from: string # from date, ISO-UTC e.g. 2021-05-25T21:24:56.771Z (format: date-time)
  --until: string # until date, ISO-UTC e.g. 2021-05-26T21:24:56.771Z (format: date-time)
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of entities. (format: int32, default: 50)
]: nothing -> table<timezone: string, start: string, end: string, summary: string, description: string, alertSources: list<record>, services: list<record>, createdBy: string, notifications: record<atCreation: bool, atStart: bool, atEnd: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "services" $services "multi") (serialize-qp "sources" $sources "multi") (serialize-qp "from" $qp_from "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/maintenance-windows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new maintenance window.
#
# POST /maintenance-windows
# --alertSources item shape: {id?: int, teams?: list, name: string, iconUrl?: string, lightIconUrl?: string, darkIconUrl?: string, escalationPolicy: record, integrationType: "NAGIOS"|"ICINGA"|"EMAIL2"|"SMS"|"API"|"HEARTBEAT2"|"PRTG"|"PINGDOM"|"CLOUDWATCH"|"AWSPHD"|"STACKDRIVER"|"INSTANA"|"ZABBIX"|"SOLARWINDS"|"PROMETHEUS"|"NEWRELIC"|"GRAFANA"|"GITHUB"|"DATADOG"|"UPTIMEROBOT"|"APPDYNAMICS"|"DYNATRACE"|"TOPDESK"|"STATUSCAKE"|"MONITOR"|"TOOL"|"CHECKMK"|"AUTOTASK"|"AWSBUDGET"|"SYSDIG"|"SERVERDENSITY"|"ZAPIER"|"KENTIXAM"|"JIRA"|"CONSUL"|"ZAMMAD"|"SPLUNK"|"SERVICENOW"|"SEARCHGUARD"|"KUBERNETES"|"SIGNALFX"|"AZUREALERTS"|"TERRAFORMCLOUD"|"SENTRY"|"SEMATEXT"|"SUMOLOGIC"|"RAYGUN"|"MXTOOLBOX"|"ESWATCHER"|"AMAZONSNS"|"KAPACITOR"|"CORTEXXSOAR"|"ZENDESK"|"AUVIK"|"SENSU"|"NCENTRAL"|"JUMPCLOUD"|"SALESFORCE"|"GUARDDUTY"|"STATUSHUB"|"IXON"|"APIFORTRESS"|"FRESHSERVICE"|"APPSIGNAL"|"LIGHTSTEP"|"IBMCLOUDFUNCTIONS"|"CROWDSTRIKE"|"HUMIO"|"OHDEAR"|"MONGODBATLAS"|"GITLAB"|"HYPERPING"|"PAPRISMACLOUD"|"SAMSARA"|"PANDORAFMS"|"MSSCOM"|"TWILIO"|"CISCOMERAKI"|"CHECKLY"|"POSTHOG"|"GOOGLESCC"|"SLACK"|"MSTEAMS"|"UPTIMEKUMA"|"TWILIOERRORS"|"PARTICLE"|"CLOUDFLARE"|"TULIP"|"GRAYLOG"|"CATCHPOINT"|"LOKI"|"CORTEX"|"MIMIR"|"HALOPSA"|"INFLUXDB"|"CALLFLOW"|"HALOITSM"|"KIBANA"|"VICTORIAMETRICS"|"HONEYCOMB"|"FOURME"|"KEEP"|"UBIDOTS"|"HETRIXTOOLS"|"POSTMAN"|"CLUSTERCONTROL"|"NETDATA"|"AWX"|"KAFKA"|"MQTT"|"RAPIDSPIKE"|"HONEYBADGER"|"HEALTHCHECKSIO"|"MEZMO"|"SERVERGUARD24"|"CISCOTHOUSANDEYES"|"SITE24X7"|"ITCONDUCTOR"|"SAPFRUN"|"APICA"|"DASH0"|"ROLLBAR"|"GATUS"|"LIBRENMS"|"PANTHER"|"TEAMCITY"|"ALIBABACLOUD"|"FLEETDM"|"CONNECTWISEPSA"|"DEADMANSSNITCH"|"FORTISOAR"|"OPMANAGER"|"CRONITOR"|"DOMOTZ"|"LIVEWATCH"|"AZUREDEVOPS"|"LEVELIO"|"EKARA"|"SYSAID"|"PHAREIO"|"OPSGENIE"|"WHATAP"|"SIGNOZ"|"GOOGLECHAT"|"DOTCOMMONITOR"|"UPTIME"|"HELPSCOUT"|"SCIENCELOGIC"|"PULSETIC"|"WAZUH"|"SEKOIA", integrationKey?: string, autoResolutionTimeout?: string, alertGroupingWindow?: string, alertCreation?: "ONE_ALERT_PER_EMAIL"|"ONE_ALERT_PER_EMAIL_SUBJECT"|"ONE_PENDING_ALERT_ALLOWED"|"ONE_OPEN_ALERT_ALLOWED"|"OPEN_RESOLVE_ON_EXTRACTION"|"ONE_ALERT_GROUPED_PER_WINDOW"|"INTELLIGENT_GROUPING", active?: bool, alertPriorityRule?: "HIGH"|"LOW"|"HIGH_DURING_SUPPORT_HOURS"|"LOW_DURING_SUPPORT_HOURS", supportHours?: record, summaryTemplate?: record, detailsTemplate?: record, routingTemplate?: record, linkTemplates?: list, priorityTemplate?: record, severityTemplate?: record, eventFilter?: string, alertKeyTemplate?: record, servicesTemplate?: list, eventTypeFilterCreate?: string, eventTypeFilterAccept?: string, eventTypeFilterResolve?: string, autoRaiseAlerts?: bool, scoreThreshold?: float, severity?: int, services?: list, setupStatus?: "CREATED"|"CREATED_ADVANCED"|"CREATED_BIDIRECTIONAL"|"FINISHED", autoCreateServices?: bool}
# --services item shape: {id?: float, name?: string, alias?: string, status?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", description?: string, oneOpenIncidentOnly?: bool, showUptimeHistory?: bool, teams?: list}
# --notifications shape: {atCreation?: bool, atStart?: bool, atEnd?: bool}
export def "maintenance-windows post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timezone: string@timezone-completer
  --start: string # format: date-time
  --end: string # format: date-time
  --summary: string
  --description: string
  --alertSources: list # item shape: {id?: int, teams?: list, name: string, iconUrl?: string, lightIconUrl?: string, darkIconUrl?: string, escalationPolicy: record, integrationType: "NAGIOS"|"ICINGA"|"EMAIL2"|"SMS"|"API"|"HEARTBEAT2"|"PRTG"|"PINGDOM"|"CLOUDWATCH"|"AWSPHD"|"STACKDRIVER"|"INSTANA"|"ZABBIX"|"SOLARWINDS"|"PROMETHEUS"|"NEWRELIC"|"GRAFANA"|"GITHUB"|"DATADOG"|"UPTIMEROBOT"|"APPDYNAMICS"|"DYNATRACE"|"TOPDESK"|"STATUSCAKE"|"MONITOR"|"TOOL"|"CHECKMK"|"AUTOTASK"|"AWSBUDGET"|"SYSDIG"|"SERVERDENSITY"|"ZAPIER"|"KENTIXAM"|"JIRA"|"CONSUL"|"ZAMMAD"|"SPLUNK"|"SERVICENOW"|"SEARCHGUARD"|"KUBERNETES"|"SIGNALFX"|"AZUREALERTS"|"TERRAFORMCLOUD"|"SENTRY"|"SEMATEXT"|"SUMOLOGIC"|"RAYGUN"|"MXTOOLBOX"|"ESWATCHER"|"AMAZONSNS"|"KAPACITOR"|"CORTEXXSOAR"|"ZENDESK"|"AUVIK"|"SENSU"|"NCENTRAL"|"JUMPCLOUD"|"SALESFORCE"|"GUARDDUTY"|"STATUSHUB"|"IXON"|"APIFORTRESS"|"FRESHSERVICE"|"APPSIGNAL"|"LIGHTSTEP"|"IBMCLOUDFUNCTIONS"|"CROWDSTRIKE"|"HUMIO"|"OHDEAR"|"MONGODBATLAS"|"GITLAB"|"HYPERPING"|"PAPRISMACLOUD"|"SAMSARA"|"PANDORAFMS"|"MSSCOM"|"TWILIO"|"CISCOMERAKI"|"CHECKLY"|"POSTHOG"|"GOOGLESCC"|"SLACK"|"MSTEAMS"|"UPTIMEKUMA"|"TWILIOERRORS"|"PARTICLE"|"CLOUDFLARE"|"TULIP"|"GRAYLOG"|"CATCHPOINT"|"LOKI"|"CORTEX"|"MIMIR"|"HALOPSA"|"INFLUXDB"|"CALLFLOW"|"HALOITSM"|"KIBANA"|"VICTORIAMETRICS"|"HONEYCOMB"|"FOURME"|"KEEP"|"UBIDOTS"|"HETRIXTOOLS"|"POSTMAN"|"CLUSTERCONTROL"|"NETDATA"|"AWX"|"KAFKA"|"MQTT"|"RAPIDSPIKE"|"HONEYBADGER"|"HEALTHCHECKSIO"|"MEZMO"|"SERVERGUARD24"|"CISCOTHOUSANDEYES"|"SITE24X7"|"ITCONDUCTOR"|"SAPFRUN"|"APICA"|"DASH0"|"ROLLBAR"|"GATUS"|"LIBRENMS"|"PANTHER"|"TEAMCITY"|"ALIBABACLOUD"|"FLEETDM"|"CONNECTWISEPSA"|"DEADMANSSNITCH"|"FORTISOAR"|"OPMANAGER"|"CRONITOR"|"DOMOTZ"|"LIVEWATCH"|"AZUREDEVOPS"|"LEVELIO"|"EKARA"|"SYSAID"|"PHAREIO"|"OPSGENIE"|"WHATAP"|"SIGNOZ"|"GOOGLECHAT"|"DOTCOMMONITOR"|"UPTIME"|"HELPSCOUT"|"SCIENCELOGIC"|"PULSETIC"|"WAZUH"|"SEKOIA", integrationKey?: string, autoResolutionTimeout?: string, alertGroupingWindow?: string, alertCreation?: "ONE_ALERT_PER_EMAIL"|"ONE_ALERT_PER_EMAIL_SUBJECT"|"ONE_PENDING_ALERT_ALLOWED"|"ONE_OPEN_ALERT_ALLOWED"|"OPEN_RESOLVE_ON_EXTRACTION"|"ONE_ALERT_GROUPED_PER_WINDOW"|"INTELLIGENT_GROUPING", active?: bool, alertPriorityRule?: "HIGH"|"LOW"|"HIGH_DURING_SUPPORT_HOURS"|"LOW_DURING_SUPPORT_HOURS", supportHours?: record, summaryTemplate?: record, detailsTemplate?: record, routingTemplate?: record, linkTemplates?: list, priorityTemplate?: record, severityTemplate?: record, eventFilter?: string, alertKeyTemplate?: record, servicesTemplate?: list, eventTypeFilterCreate?: string, eventTypeFilterAccept?: string, eventTypeFilterResolve?: string, autoRaiseAlerts?: bool, scoreThreshold?: float, severity?: int, services?: list, setupStatus?: "CREATED"|"CREATED_ADVANCED"|"CREATED_BIDIRECTIONAL"|"FINISHED", autoCreateServices?: bool}
  --services: list # item shape: {id?: float, name?: string, alias?: string, status?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", description?: string, oneOpenIncidentOnly?: bool, showUptimeHistory?: bool, teams?: list}
  --notifications: record # shape: {atCreation?: bool, atStart?: bool, atEnd?: bool}
]: any -> record<timezone: string, start: string, end: string, summary: string, description: string, alertSources: table<id: int, teams: list, name: string, iconUrl: string, lightIconUrl: string, darkIconUrl: string, escalationPolicy: record, integrationType: string, integrationKey: string, integrationUrl: string, autoResolutionTimeout: string, alertGroupingWindow: string, alertCreation: string, status: string, active: bool, alertPriorityRule: string, supportHours: record, bidirectional: bool, summaryTemplate: record, detailsTemplate: record, routingTemplate: record, linkTemplates: list, priorityTemplate: record, severityTemplate: record, eventFilter: string, alertKeyTemplate: record, servicesTemplate: list, eventTypeFilterCreate: string, eventTypeFilterAccept: string, eventTypeFilterResolve: string, autoRaiseAlerts: bool, scoreThreshold: float, severity: int, services: list, setupStatus: string, autoCreateServices: bool, createdAt: string, updatedAt: string>, services: table<id: float, name: string, alias: string, status: string, description: string, oneOpenIncidentOnly: bool, showUptimeHistory: bool, teams: list>, createdBy: string, notifications: record<atCreation: bool, atStart: bool, atEnd: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/maintenance-windows")
  let body = {timezone: $timezone, start: $start, end: $end, summary: $summary, description: $description, alertSources: $alertSources, services: $services, notifications: $notifications} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the maintenance window with specified id.
#
# GET /maintenance-windows/{id}
export def "maintenance-windows get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<timezone: string, start: string, end: string, summary: string, description: string, alertSources: table<id: int, teams: list, name: string, iconUrl: string, lightIconUrl: string, darkIconUrl: string, escalationPolicy: record, integrationType: string, integrationKey: string, integrationUrl: string, autoResolutionTimeout: string, alertGroupingWindow: string, alertCreation: string, status: string, active: bool, alertPriorityRule: string, supportHours: record, bidirectional: bool, summaryTemplate: record, detailsTemplate: record, routingTemplate: record, linkTemplates: list, priorityTemplate: record, severityTemplate: record, eventFilter: string, alertKeyTemplate: record, servicesTemplate: list, eventTypeFilterCreate: string, eventTypeFilterAccept: string, eventTypeFilterResolve: string, autoRaiseAlerts: bool, scoreThreshold: float, severity: int, services: list, setupStatus: string, autoCreateServices: bool, createdAt: string, updatedAt: string>, services: table<id: float, name: string, alias: string, status: string, description: string, oneOpenIncidentOnly: bool, showUptimeHistory: bool, teams: list>, createdBy: string, notifications: record<atCreation: bool, atStart: bool, atEnd: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/maintenance-windows/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing maintenance window.
#
# PUT /maintenance-windows/{id}
# --alertSources item shape: {id?: int, teams?: list, name: string, iconUrl?: string, lightIconUrl?: string, darkIconUrl?: string, escalationPolicy: record, integrationType: "NAGIOS"|"ICINGA"|"EMAIL2"|"SMS"|"API"|"HEARTBEAT2"|"PRTG"|"PINGDOM"|"CLOUDWATCH"|"AWSPHD"|"STACKDRIVER"|"INSTANA"|"ZABBIX"|"SOLARWINDS"|"PROMETHEUS"|"NEWRELIC"|"GRAFANA"|"GITHUB"|"DATADOG"|"UPTIMEROBOT"|"APPDYNAMICS"|"DYNATRACE"|"TOPDESK"|"STATUSCAKE"|"MONITOR"|"TOOL"|"CHECKMK"|"AUTOTASK"|"AWSBUDGET"|"SYSDIG"|"SERVERDENSITY"|"ZAPIER"|"KENTIXAM"|"JIRA"|"CONSUL"|"ZAMMAD"|"SPLUNK"|"SERVICENOW"|"SEARCHGUARD"|"KUBERNETES"|"SIGNALFX"|"AZUREALERTS"|"TERRAFORMCLOUD"|"SENTRY"|"SEMATEXT"|"SUMOLOGIC"|"RAYGUN"|"MXTOOLBOX"|"ESWATCHER"|"AMAZONSNS"|"KAPACITOR"|"CORTEXXSOAR"|"ZENDESK"|"AUVIK"|"SENSU"|"NCENTRAL"|"JUMPCLOUD"|"SALESFORCE"|"GUARDDUTY"|"STATUSHUB"|"IXON"|"APIFORTRESS"|"FRESHSERVICE"|"APPSIGNAL"|"LIGHTSTEP"|"IBMCLOUDFUNCTIONS"|"CROWDSTRIKE"|"HUMIO"|"OHDEAR"|"MONGODBATLAS"|"GITLAB"|"HYPERPING"|"PAPRISMACLOUD"|"SAMSARA"|"PANDORAFMS"|"MSSCOM"|"TWILIO"|"CISCOMERAKI"|"CHECKLY"|"POSTHOG"|"GOOGLESCC"|"SLACK"|"MSTEAMS"|"UPTIMEKUMA"|"TWILIOERRORS"|"PARTICLE"|"CLOUDFLARE"|"TULIP"|"GRAYLOG"|"CATCHPOINT"|"LOKI"|"CORTEX"|"MIMIR"|"HALOPSA"|"INFLUXDB"|"CALLFLOW"|"HALOITSM"|"KIBANA"|"VICTORIAMETRICS"|"HONEYCOMB"|"FOURME"|"KEEP"|"UBIDOTS"|"HETRIXTOOLS"|"POSTMAN"|"CLUSTERCONTROL"|"NETDATA"|"AWX"|"KAFKA"|"MQTT"|"RAPIDSPIKE"|"HONEYBADGER"|"HEALTHCHECKSIO"|"MEZMO"|"SERVERGUARD24"|"CISCOTHOUSANDEYES"|"SITE24X7"|"ITCONDUCTOR"|"SAPFRUN"|"APICA"|"DASH0"|"ROLLBAR"|"GATUS"|"LIBRENMS"|"PANTHER"|"TEAMCITY"|"ALIBABACLOUD"|"FLEETDM"|"CONNECTWISEPSA"|"DEADMANSSNITCH"|"FORTISOAR"|"OPMANAGER"|"CRONITOR"|"DOMOTZ"|"LIVEWATCH"|"AZUREDEVOPS"|"LEVELIO"|"EKARA"|"SYSAID"|"PHAREIO"|"OPSGENIE"|"WHATAP"|"SIGNOZ"|"GOOGLECHAT"|"DOTCOMMONITOR"|"UPTIME"|"HELPSCOUT"|"SCIENCELOGIC"|"PULSETIC"|"WAZUH"|"SEKOIA", integrationKey?: string, autoResolutionTimeout?: string, alertGroupingWindow?: string, alertCreation?: "ONE_ALERT_PER_EMAIL"|"ONE_ALERT_PER_EMAIL_SUBJECT"|"ONE_PENDING_ALERT_ALLOWED"|"ONE_OPEN_ALERT_ALLOWED"|"OPEN_RESOLVE_ON_EXTRACTION"|"ONE_ALERT_GROUPED_PER_WINDOW"|"INTELLIGENT_GROUPING", active?: bool, alertPriorityRule?: "HIGH"|"LOW"|"HIGH_DURING_SUPPORT_HOURS"|"LOW_DURING_SUPPORT_HOURS", supportHours?: record, summaryTemplate?: record, detailsTemplate?: record, routingTemplate?: record, linkTemplates?: list, priorityTemplate?: record, severityTemplate?: record, eventFilter?: string, alertKeyTemplate?: record, servicesTemplate?: list, eventTypeFilterCreate?: string, eventTypeFilterAccept?: string, eventTypeFilterResolve?: string, autoRaiseAlerts?: bool, scoreThreshold?: float, severity?: int, services?: list, setupStatus?: "CREATED"|"CREATED_ADVANCED"|"CREATED_BIDIRECTIONAL"|"FINISHED", autoCreateServices?: bool}
# --services item shape: {id?: float, name?: string, alias?: string, status?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", description?: string, oneOpenIncidentOnly?: bool, showUptimeHistory?: bool, teams?: list}
# --notifications shape: {atCreation?: bool, atStart?: bool, atEnd?: bool}
export def "maintenance-windows put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timezone: string@timezone-completer
  --start: string # format: date-time
  --end: string # format: date-time
  --summary: string
  --description: string
  --alertSources: list # item shape: {id?: int, teams?: list, name: string, iconUrl?: string, lightIconUrl?: string, darkIconUrl?: string, escalationPolicy: record, integrationType: "NAGIOS"|"ICINGA"|"EMAIL2"|"SMS"|"API"|"HEARTBEAT2"|"PRTG"|"PINGDOM"|"CLOUDWATCH"|"AWSPHD"|"STACKDRIVER"|"INSTANA"|"ZABBIX"|"SOLARWINDS"|"PROMETHEUS"|"NEWRELIC"|"GRAFANA"|"GITHUB"|"DATADOG"|"UPTIMEROBOT"|"APPDYNAMICS"|"DYNATRACE"|"TOPDESK"|"STATUSCAKE"|"MONITOR"|"TOOL"|"CHECKMK"|"AUTOTASK"|"AWSBUDGET"|"SYSDIG"|"SERVERDENSITY"|"ZAPIER"|"KENTIXAM"|"JIRA"|"CONSUL"|"ZAMMAD"|"SPLUNK"|"SERVICENOW"|"SEARCHGUARD"|"KUBERNETES"|"SIGNALFX"|"AZUREALERTS"|"TERRAFORMCLOUD"|"SENTRY"|"SEMATEXT"|"SUMOLOGIC"|"RAYGUN"|"MXTOOLBOX"|"ESWATCHER"|"AMAZONSNS"|"KAPACITOR"|"CORTEXXSOAR"|"ZENDESK"|"AUVIK"|"SENSU"|"NCENTRAL"|"JUMPCLOUD"|"SALESFORCE"|"GUARDDUTY"|"STATUSHUB"|"IXON"|"APIFORTRESS"|"FRESHSERVICE"|"APPSIGNAL"|"LIGHTSTEP"|"IBMCLOUDFUNCTIONS"|"CROWDSTRIKE"|"HUMIO"|"OHDEAR"|"MONGODBATLAS"|"GITLAB"|"HYPERPING"|"PAPRISMACLOUD"|"SAMSARA"|"PANDORAFMS"|"MSSCOM"|"TWILIO"|"CISCOMERAKI"|"CHECKLY"|"POSTHOG"|"GOOGLESCC"|"SLACK"|"MSTEAMS"|"UPTIMEKUMA"|"TWILIOERRORS"|"PARTICLE"|"CLOUDFLARE"|"TULIP"|"GRAYLOG"|"CATCHPOINT"|"LOKI"|"CORTEX"|"MIMIR"|"HALOPSA"|"INFLUXDB"|"CALLFLOW"|"HALOITSM"|"KIBANA"|"VICTORIAMETRICS"|"HONEYCOMB"|"FOURME"|"KEEP"|"UBIDOTS"|"HETRIXTOOLS"|"POSTMAN"|"CLUSTERCONTROL"|"NETDATA"|"AWX"|"KAFKA"|"MQTT"|"RAPIDSPIKE"|"HONEYBADGER"|"HEALTHCHECKSIO"|"MEZMO"|"SERVERGUARD24"|"CISCOTHOUSANDEYES"|"SITE24X7"|"ITCONDUCTOR"|"SAPFRUN"|"APICA"|"DASH0"|"ROLLBAR"|"GATUS"|"LIBRENMS"|"PANTHER"|"TEAMCITY"|"ALIBABACLOUD"|"FLEETDM"|"CONNECTWISEPSA"|"DEADMANSSNITCH"|"FORTISOAR"|"OPMANAGER"|"CRONITOR"|"DOMOTZ"|"LIVEWATCH"|"AZUREDEVOPS"|"LEVELIO"|"EKARA"|"SYSAID"|"PHAREIO"|"OPSGENIE"|"WHATAP"|"SIGNOZ"|"GOOGLECHAT"|"DOTCOMMONITOR"|"UPTIME"|"HELPSCOUT"|"SCIENCELOGIC"|"PULSETIC"|"WAZUH"|"SEKOIA", integrationKey?: string, autoResolutionTimeout?: string, alertGroupingWindow?: string, alertCreation?: "ONE_ALERT_PER_EMAIL"|"ONE_ALERT_PER_EMAIL_SUBJECT"|"ONE_PENDING_ALERT_ALLOWED"|"ONE_OPEN_ALERT_ALLOWED"|"OPEN_RESOLVE_ON_EXTRACTION"|"ONE_ALERT_GROUPED_PER_WINDOW"|"INTELLIGENT_GROUPING", active?: bool, alertPriorityRule?: "HIGH"|"LOW"|"HIGH_DURING_SUPPORT_HOURS"|"LOW_DURING_SUPPORT_HOURS", supportHours?: record, summaryTemplate?: record, detailsTemplate?: record, routingTemplate?: record, linkTemplates?: list, priorityTemplate?: record, severityTemplate?: record, eventFilter?: string, alertKeyTemplate?: record, servicesTemplate?: list, eventTypeFilterCreate?: string, eventTypeFilterAccept?: string, eventTypeFilterResolve?: string, autoRaiseAlerts?: bool, scoreThreshold?: float, severity?: int, services?: list, setupStatus?: "CREATED"|"CREATED_ADVANCED"|"CREATED_BIDIRECTIONAL"|"FINISHED", autoCreateServices?: bool}
  --services: list # item shape: {id?: float, name?: string, alias?: string, status?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", description?: string, oneOpenIncidentOnly?: bool, showUptimeHistory?: bool, teams?: list}
  --notifications: record # shape: {atCreation?: bool, atStart?: bool, atEnd?: bool}
]: any -> record<timezone: string, start: string, end: string, summary: string, description: string, alertSources: table<id: int, teams: list, name: string, iconUrl: string, lightIconUrl: string, darkIconUrl: string, escalationPolicy: record, integrationType: string, integrationKey: string, integrationUrl: string, autoResolutionTimeout: string, alertGroupingWindow: string, alertCreation: string, status: string, active: bool, alertPriorityRule: string, supportHours: record, bidirectional: bool, summaryTemplate: record, detailsTemplate: record, routingTemplate: record, linkTemplates: list, priorityTemplate: record, severityTemplate: record, eventFilter: string, alertKeyTemplate: record, servicesTemplate: list, eventTypeFilterCreate: string, eventTypeFilterAccept: string, eventTypeFilterResolve: string, autoRaiseAlerts: bool, scoreThreshold: float, severity: int, services: list, setupStatus: string, autoCreateServices: bool, createdAt: string, updatedAt: string>, services: table<id: float, name: string, alias: string, status: string, description: string, oneOpenIncidentOnly: bool, showUptimeHistory: bool, teams: list>, createdBy: string, notifications: record<atCreation: bool, atStart: bool, atEnd: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/maintenance-windows/($id)")
  let body = {timezone: $timezone, start: $start, end: $end, summary: $summary, description: $description, alertSources: $alertSources, services: $services, notifications: $notifications} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the specified maintenance window.
#
# DELETE /maintenance-windows/{id}
export def "maintenance-windows delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/maintenance-windows/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List escalation policies.
#
# GET /escalation-policies
export def "escalation-policies list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of escalation policies. (format: int32, default: 50)
]: nothing -> table<id: int, name: string, escalationRules: list<record>, teams: list<record>, repeating: bool, frequency: int, delayMin: int, routingKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/escalation-policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new escalation policy.
#
# POST /escalation-policies
# --escalationRules item shape: {escalationTimeout: int, user?: record, schedule?: record, team?: record, users?: list, schedules?: list, teams?: list}
# --teams item shape: {id?: int, name?: string}
export def "escalation-policies post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int64
  name: string
  escalationRules: list # item shape: {escalationTimeout: int, user?: record, schedule?: record, team?: record, users?: list, schedules?: list, teams?: list}
  --teams: list # item shape: {id?: int, name?: string}
  --repeating: string@bool-completer # default: false
  --frequency: int # format: int32, default: 1
  --delayMin: int # format: int32, default: 0
  --routingKey: string # optional
]: any -> record<id: int, name: string, escalationRules: table<escalationTimeout: int, user: record, schedule: record, team: record, users: list, schedules: list, teams: list>, teams: table<id: int, name: string>, repeating: bool, frequency: int, delayMin: int, routingKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/escalation-policies")
  let body = {id: $id, name: $name, escalationRules: $escalationRules, teams: $teams, repeating: $repeating, frequency: $frequency, delayMin: $delayMin, routingKey: $routingKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resolve an escalation policy by routing key.
#
# GET /escalation-policies/resolve
export def "escalation-policies-resolve get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --routing-key: string # routing key expression used to resolve the escalation policy, including ordered comma-separated keys or the special il:{...} policy reference format.
]: nothing -> record<id: int, name: string, escalationRules: table<escalationTimeout: int, user: record, schedule: record, team: record, users: list, schedules: list, teams: list>, teams: table<id: int, name: string>, repeating: bool, frequency: int, delayMin: int, routingKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "routing-key" $routing_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/escalation-policies/resolve" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get escalation policy with the specified id.
#
# GET /escalation-policies/{id}
export def "escalation-policies get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, escalationRules: table<escalationTimeout: int, user: record, schedule: record, team: record, users: list, schedules: list, teams: list>, teams: table<id: int, name: string>, repeating: bool, frequency: int, delayMin: int, routingKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/escalation-policies/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing escalation policy.
#
# PUT /escalation-policies/{id}
# --escalationRules item shape: {escalationTimeout: int, user?: record, schedule?: record, team?: record, users?: list, schedules?: list, teams?: list}
# --teams item shape: {id?: int, name?: string}
export def "escalation-policies put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: int # format: int64
  name: string
  escalationRules: list # item shape: {escalationTimeout: int, user?: record, schedule?: record, team?: record, users?: list, schedules?: list, teams?: list}
  --teams: list # item shape: {id?: int, name?: string}
  --repeating: string@bool-completer # default: false
  --frequency: int # format: int32, default: 1
  --delayMin: int # format: int32, default: 0
  --routingKey: string # optional
]: any -> record<id: int, name: string, escalationRules: table<escalationTimeout: int, user: record, schedule: record, team: record, users: list, schedules: list, teams: list>, teams: table<id: int, name: string>, repeating: bool, frequency: int, delayMin: int, routingKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/escalation-policies/($id)")
  let body = {id: $body_id, name: $name, escalationRules: $escalationRules, teams: $teams, repeating: $repeating, frequency: $frequency, delayMin: $delayMin, routingKey: $routingKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the specified escalation policy.
#
# DELETE /escalation-policies/{id}
export def "escalation-policies delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/escalation-policies/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace an escalation rule at the specified level.
#
# PUT /escalation-policies/{id}/levels/{level}
# --user shape: {id?: float}
# --schedule shape: {id?: float}
# --team shape: {id?: float}
# --users item shape: {id: int, firstName?: string, lastName?: string}
# --schedules item shape: {id?: int, name?: string, type?: "STATIC"|"RECURRING"}
# --teams item shape: {id?: int, name?: string}
export def "escalation-policies-levels put" [
  id: float
  level: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  escalationTimeout: int
  --user: record # This field (type: User) is deprecated, please use 'users' instead — shape: {id?: float}
  --schedule: record # This field (type: Schedule) is deprecated, please use 'schedules' instead — shape: {id?: float}
  --team: record # This field (type: Team) is deprecated, please use 'teams' instead — shape: {id?: float}
  --users: list # item shape: {id: int, firstName?: string, lastName?: string}
  --schedules: list # item shape: {id?: int, name?: string, type?: "STATIC"|"RECURRING"}
  --teams: list # item shape: {id?: int, name?: string}
]: any -> record<escalationTimeout: int, user: record<id: float>, schedule: record<id: float>, team: record<id: float>, users: table<id: int, firstName: string, lastName: string>, schedules: table<id: int, name: string, type: string>, teams: table<id: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/escalation-policies/($id)/levels/($level)")
  let body = {escalationTimeout: $escalationTimeout, user: $user, schedule: $schedule, team: $team, users: $users, schedules: $schedules, teams: $teams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Ingest a series for a metric
#
# POST /series/{key}
# --series item shape: {timestamp?: float, value: float}
export def "series post" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timestamp: float # The unix epoch second of your time point (format: int64)
  --value: float # Value of your time point (format: double)
  --series: list # item shape: {timestamp?: float, value: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/series/($key)")
  let body = {timestamp: $timestamp, value: $value, series: $series} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Post an event to ilert.
#
# POST /events
# --images item shape: {src?: string, href?: string, alt?: string}
# --links item shape: {href?: string, text?: string}
# --comments item shape: {creator?: string, content?: string}
# --services item shape: {id?: int, alias?: string}
export def "events post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  integrationKey: string
  eventType: string@eventType-completer # the event type
  summary: string # The event summary. Will be used as the alert summary if a new alert will be created.
  --details: string # The event details. Will be used as the alert details if a new alert will be created.
  --alertKey: string # Used to deduplicate events. If an open alert with the key already exists, the event will be appended to the alert's event log. Otherwise a new alert will be created. We will trim this value if necessary. Upper casing is allowed, however comparison is case insensitive.
  --priority: string@priority-completer
  --severity: int # Optional severity in range 1..5. Will overwrite the evaluated severity of the alert source. (format: int32)
  --images: list # item shape: {src?: string, href?: string, alt?: string}
  --links: list # item shape: {href?: string, text?: string}
  --comments: list # item shape: {creator?: string, content?: string}
  --labels: record # Optional key/value labels that are attached to the alert.
  --services: list # Optional list of service refs. Usually pass alias; id is optional for rare edge cases. — item shape: {id?: int, alias?: string}
  --customDetails: record
  --routingKey: string # Optional routing key that overwrites the escalation policy of the alert source for ALERT events. Must map to routingKey of escalation policy
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/events")
  let body = {integrationKey: $integrationKey, eventType: $eventType, summary: $summary, details: $details, alertKey: $alertKey, priority: $priority, severity: $severity, images: $images, links: $links, comments: $comments, labels: $labels, services: $services, customDetails: $customDetails, routingKey: $routingKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Post a deployment event to ilert.
#
# POST /deployment-events
# --links item shape: {href?: string, text?: string}
export def "deployment-events post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  integrationKey: string
  summary: string
  --timestamp: int # format: int64
  --userEmail: string # Optional email used to map the event to a specific user in ilert (format: email)
  --customDetails: record
  --links: list # item shape: {href?: string, text?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deployment-events")
  let body = {integrationKey: $integrationKey, summary: $summary, timestamp: $timestamp, userEmail: $userEmail, customDetails: $customDetails, links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get alert actions.
#
# GET /alert-actions
export def "alert-actions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-source: float # alert source id
  --connector: string # connector id
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of alert actions. (format: int32, default: 100)
]: nothing -> table<id: string, alertSources: list<record>, connectorId: string, connectorType: string, name: string, createdAt: string, updatedAt: string, triggerMode: string, bidirectional: bool, escalationEndedDelaySec: float, notResolvedDelaySec: float, triggerTypes: list<string>, alertFilter: record<operator: string, predicates: list>, conditions: string, params: record, teams: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar") (serialize-qp "connector" $connector "scalar") (serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/alert-actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new alert action.
#
# POST /alert-actions
# --alertSources item shape: {id?: int, teams?: list, name: string, iconUrl?: string, lightIconUrl?: string, darkIconUrl?: string, escalationPolicy: record, integrationType: "NAGIOS"|"ICINGA"|"EMAIL2"|"SMS"|"API"|"HEARTBEAT2"|"PRTG"|"PINGDOM"|"CLOUDWATCH"|"AWSPHD"|"STACKDRIVER"|"INSTANA"|"ZABBIX"|"SOLARWINDS"|"PROMETHEUS"|"NEWRELIC"|"GRAFANA"|"GITHUB"|"DATADOG"|"UPTIMEROBOT"|"APPDYNAMICS"|"DYNATRACE"|"TOPDESK"|"STATUSCAKE"|"MONITOR"|"TOOL"|"CHECKMK"|"AUTOTASK"|"AWSBUDGET"|"SYSDIG"|"SERVERDENSITY"|"ZAPIER"|"KENTIXAM"|"JIRA"|"CONSUL"|"ZAMMAD"|"SPLUNK"|"SERVICENOW"|"SEARCHGUARD"|"KUBERNETES"|"SIGNALFX"|"AZUREALERTS"|"TERRAFORMCLOUD"|"SENTRY"|"SEMATEXT"|"SUMOLOGIC"|"RAYGUN"|"MXTOOLBOX"|"ESWATCHER"|"AMAZONSNS"|"KAPACITOR"|"CORTEXXSOAR"|"ZENDESK"|"AUVIK"|"SENSU"|"NCENTRAL"|"JUMPCLOUD"|"SALESFORCE"|"GUARDDUTY"|"STATUSHUB"|"IXON"|"APIFORTRESS"|"FRESHSERVICE"|"APPSIGNAL"|"LIGHTSTEP"|"IBMCLOUDFUNCTIONS"|"CROWDSTRIKE"|"HUMIO"|"OHDEAR"|"MONGODBATLAS"|"GITLAB"|"HYPERPING"|"PAPRISMACLOUD"|"SAMSARA"|"PANDORAFMS"|"MSSCOM"|"TWILIO"|"CISCOMERAKI"|"CHECKLY"|"POSTHOG"|"GOOGLESCC"|"SLACK"|"MSTEAMS"|"UPTIMEKUMA"|"TWILIOERRORS"|"PARTICLE"|"CLOUDFLARE"|"TULIP"|"GRAYLOG"|"CATCHPOINT"|"LOKI"|"CORTEX"|"MIMIR"|"HALOPSA"|"INFLUXDB"|"CALLFLOW"|"HALOITSM"|"KIBANA"|"VICTORIAMETRICS"|"HONEYCOMB"|"FOURME"|"KEEP"|"UBIDOTS"|"HETRIXTOOLS"|"POSTMAN"|"CLUSTERCONTROL"|"NETDATA"|"AWX"|"KAFKA"|"MQTT"|"RAPIDSPIKE"|"HONEYBADGER"|"HEALTHCHECKSIO"|"MEZMO"|"SERVERGUARD24"|"CISCOTHOUSANDEYES"|"SITE24X7"|"ITCONDUCTOR"|"SAPFRUN"|"APICA"|"DASH0"|"ROLLBAR"|"GATUS"|"LIBRENMS"|"PANTHER"|"TEAMCITY"|"ALIBABACLOUD"|"FLEETDM"|"CONNECTWISEPSA"|"DEADMANSSNITCH"|"FORTISOAR"|"OPMANAGER"|"CRONITOR"|"DOMOTZ"|"LIVEWATCH"|"AZUREDEVOPS"|"LEVELIO"|"EKARA"|"SYSAID"|"PHAREIO"|"OPSGENIE"|"WHATAP"|"SIGNOZ"|"GOOGLECHAT"|"DOTCOMMONITOR"|"UPTIME"|"HELPSCOUT"|"SCIENCELOGIC"|"PULSETIC"|"WAZUH"|"SEKOIA", integrationKey?: string, autoResolutionTimeout?: string, alertGroupingWindow?: string, alertCreation?: "ONE_ALERT_PER_EMAIL"|"ONE_ALERT_PER_EMAIL_SUBJECT"|"ONE_PENDING_ALERT_ALLOWED"|"ONE_OPEN_ALERT_ALLOWED"|"OPEN_RESOLVE_ON_EXTRACTION"|"ONE_ALERT_GROUPED_PER_WINDOW"|"INTELLIGENT_GROUPING", active?: bool, alertPriorityRule?: "HIGH"|"LOW"|"HIGH_DURING_SUPPORT_HOURS"|"LOW_DURING_SUPPORT_HOURS", supportHours?: record, summaryTemplate?: record, detailsTemplate?: record, routingTemplate?: record, linkTemplates?: list, priorityTemplate?: record, severityTemplate?: record, eventFilter?: string, alertKeyTemplate?: record, servicesTemplate?: list, eventTypeFilterCreate?: string, eventTypeFilterAccept?: string, eventTypeFilterResolve?: string, autoRaiseAlerts?: bool, scoreThreshold?: float, severity?: int, services?: list, setupStatus?: "CREATED"|"CREATED_ADVANCED"|"CREATED_BIDIRECTIONAL"|"FINISHED", autoCreateServices?: bool}
# --alertFilter shape: {operator?: "AND"|"OR", predicates?: list}
# --params shape: {tags?: list, priority?: string, site?: string, project?: string, issueType?: string, bodyTemplate?: string, channelId?: string, channelName?: string, teamId?: string, teamName?: string, type?: "chat"|"meeting", callerId?: string, impact?: string, urgency?: string, closeCode?: string, assignmentGroup?: string, ownerGroup?: string, service?: string, serviceOffering?: string, contactType?: string, companyId?: string, queueId?: string, ticketCategory?: string, ticketType?: string, noteType?: string, notePublish?: string, status?: string, teamDomain?: string, webhookUrl?: string, headers?: list, owner?: string, repository?: string, labels?: list, recipients?: list, subject?: string, eventFilter?: string, password?: string, pageId?: string, isAtAll?: bool, atMobiles?: list, url?: string, secret?: string, alertType?: "CREATED"|"ACCEPTED", resolveIncident?: bool, serviceStatus?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", templateId?: int, sendNotification?: bool, serviceIds?: list}
# --teams item shape: {id?: int, name?: string}
export def "alert-actions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string
  --alertSources: list # item shape: {id?: int, teams?: list, name: string, iconUrl?: string, lightIconUrl?: string, darkIconUrl?: string, escalationPolicy: record, integrationType: "NAGIOS"|"ICINGA"|"EMAIL2"|"SMS"|"API"|"HEARTBEAT2"|"PRTG"|"PINGDOM"|"CLOUDWATCH"|"AWSPHD"|"STACKDRIVER"|"INSTANA"|"ZABBIX"|"SOLARWINDS"|"PROMETHEUS"|"NEWRELIC"|"GRAFANA"|"GITHUB"|"DATADOG"|"UPTIMEROBOT"|"APPDYNAMICS"|"DYNATRACE"|"TOPDESK"|"STATUSCAKE"|"MONITOR"|"TOOL"|"CHECKMK"|"AUTOTASK"|"AWSBUDGET"|"SYSDIG"|"SERVERDENSITY"|"ZAPIER"|"KENTIXAM"|"JIRA"|"CONSUL"|"ZAMMAD"|"SPLUNK"|"SERVICENOW"|"SEARCHGUARD"|"KUBERNETES"|"SIGNALFX"|"AZUREALERTS"|"TERRAFORMCLOUD"|"SENTRY"|"SEMATEXT"|"SUMOLOGIC"|"RAYGUN"|"MXTOOLBOX"|"ESWATCHER"|"AMAZONSNS"|"KAPACITOR"|"CORTEXXSOAR"|"ZENDESK"|"AUVIK"|"SENSU"|"NCENTRAL"|"JUMPCLOUD"|"SALESFORCE"|"GUARDDUTY"|"STATUSHUB"|"IXON"|"APIFORTRESS"|"FRESHSERVICE"|"APPSIGNAL"|"LIGHTSTEP"|"IBMCLOUDFUNCTIONS"|"CROWDSTRIKE"|"HUMIO"|"OHDEAR"|"MONGODBATLAS"|"GITLAB"|"HYPERPING"|"PAPRISMACLOUD"|"SAMSARA"|"PANDORAFMS"|"MSSCOM"|"TWILIO"|"CISCOMERAKI"|"CHECKLY"|"POSTHOG"|"GOOGLESCC"|"SLACK"|"MSTEAMS"|"UPTIMEKUMA"|"TWILIOERRORS"|"PARTICLE"|"CLOUDFLARE"|"TULIP"|"GRAYLOG"|"CATCHPOINT"|"LOKI"|"CORTEX"|"MIMIR"|"HALOPSA"|"INFLUXDB"|"CALLFLOW"|"HALOITSM"|"KIBANA"|"VICTORIAMETRICS"|"HONEYCOMB"|"FOURME"|"KEEP"|"UBIDOTS"|"HETRIXTOOLS"|"POSTMAN"|"CLUSTERCONTROL"|"NETDATA"|"AWX"|"KAFKA"|"MQTT"|"RAPIDSPIKE"|"HONEYBADGER"|"HEALTHCHECKSIO"|"MEZMO"|"SERVERGUARD24"|"CISCOTHOUSANDEYES"|"SITE24X7"|"ITCONDUCTOR"|"SAPFRUN"|"APICA"|"DASH0"|"ROLLBAR"|"GATUS"|"LIBRENMS"|"PANTHER"|"TEAMCITY"|"ALIBABACLOUD"|"FLEETDM"|"CONNECTWISEPSA"|"DEADMANSSNITCH"|"FORTISOAR"|"OPMANAGER"|"CRONITOR"|"DOMOTZ"|"LIVEWATCH"|"AZUREDEVOPS"|"LEVELIO"|"EKARA"|"SYSAID"|"PHAREIO"|"OPSGENIE"|"WHATAP"|"SIGNOZ"|"GOOGLECHAT"|"DOTCOMMONITOR"|"UPTIME"|"HELPSCOUT"|"SCIENCELOGIC"|"PULSETIC"|"WAZUH"|"SEKOIA", integrationKey?: string, autoResolutionTimeout?: string, alertGroupingWindow?: string, alertCreation?: "ONE_ALERT_PER_EMAIL"|"ONE_ALERT_PER_EMAIL_SUBJECT"|"ONE_PENDING_ALERT_ALLOWED"|"ONE_OPEN_ALERT_ALLOWED"|"OPEN_RESOLVE_ON_EXTRACTION"|"ONE_ALERT_GROUPED_PER_WINDOW"|"INTELLIGENT_GROUPING", active?: bool, alertPriorityRule?: "HIGH"|"LOW"|"HIGH_DURING_SUPPORT_HOURS"|"LOW_DURING_SUPPORT_HOURS", supportHours?: record, summaryTemplate?: record, detailsTemplate?: record, routingTemplate?: record, linkTemplates?: list, priorityTemplate?: record, severityTemplate?: record, eventFilter?: string, alertKeyTemplate?: record, servicesTemplate?: list, eventTypeFilterCreate?: string, eventTypeFilterAccept?: string, eventTypeFilterResolve?: string, autoRaiseAlerts?: bool, scoreThreshold?: float, severity?: int, services?: list, setupStatus?: "CREATED"|"CREATED_ADVANCED"|"CREATED_BIDIRECTIONAL"|"FINISHED", autoCreateServices?: bool}
  --connectorId: string
  connectorType: string@connectorType-completer
  name: string
  --createdAt: string # format: date-time
  --updatedAt: string # format: date-time
  --triggerMode: string@triggerMode-completer
  --escalationEndedDelaySec: float # May only be used with triggerType 'alert-escalation-ended' selected
  --notResolvedDelaySec: float # May only be used with triggerType 'v-alert-not-resolved' selected
  --triggerTypes: list
  --alertFilter: record # This field is deprecated, use 'conditions' instead. If both are used this field is ignored. — shape: {operator?: "AND"|"OR", predicates?: list}
  --conditions: string # Defines an optional alert filter condition in ICL language. This is a code based implementation, more info on syntax: https://docs.ilert.com/rest-api/icl-ilert-condition-language. For block based configuration please use the web UI. Note: this field is an ?include, it will not appear in lists.
  --params: record # shape: {tags?: list, priority?: string, site?: string, project?: string, issueType?: string, bodyTemplate?: string, channelId?: string, channelName?: string, teamId?: string, teamName?: string, type?: "chat"|"meeting", callerId?: string, impact?: string, urgency?: string, closeCode?: string, assignmentGroup?: string, ownerGroup?: string, service?: string, serviceOffering?: string, contactType?: string, companyId?: string, queueId?: string, ticketCategory?: string, ticketType?: string, noteType?: string, notePublish?: string, status?: string, teamDomain?: string, webhookUrl?: string, headers?: list, owner?: string, repository?: string, labels?: list, recipients?: list, subject?: string, eventFilter?: string, password?: string, pageId?: string, isAtAll?: bool, atMobiles?: list, url?: string, secret?: string, alertType?: "CREATED"|"ACCEPTED", resolveIncident?: bool, serviceStatus?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", templateId?: int, sendNotification?: bool, serviceIds?: list}
  --teams: list # item shape: {id?: int, name?: string}
]: any -> record<id: string, alertSources: table<id: int, teams: list, name: string, iconUrl: string, lightIconUrl: string, darkIconUrl: string, escalationPolicy: record, integrationType: string, integrationKey: string, integrationUrl: string, autoResolutionTimeout: string, alertGroupingWindow: string, alertCreation: string, status: string, active: bool, alertPriorityRule: string, supportHours: record, bidirectional: bool, summaryTemplate: record, detailsTemplate: record, routingTemplate: record, linkTemplates: list, priorityTemplate: record, severityTemplate: record, eventFilter: string, alertKeyTemplate: record, servicesTemplate: list, eventTypeFilterCreate: string, eventTypeFilterAccept: string, eventTypeFilterResolve: string, autoRaiseAlerts: bool, scoreThreshold: float, severity: int, services: list, setupStatus: string, autoCreateServices: bool, createdAt: string, updatedAt: string>, connectorId: string, connectorType: string, name: string, createdAt: string, updatedAt: string, triggerMode: string, bidirectional: bool, escalationEndedDelaySec: float, notResolvedDelaySec: float, triggerTypes: list<string>, alertFilter: record<operator: string, predicates: list<record>>, conditions: string, params: record, teams: table<id: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/alert-actions")
  let body = {id: $id, alertSources: $alertSources, connectorId: $connectorId, connectorType: $connectorType, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, triggerMode: $triggerMode, escalationEndedDelaySec: $escalationEndedDelaySec, notResolvedDelaySec: $notResolvedDelaySec, triggerTypes: $triggerTypes, alertFilter: $alertFilter, conditions: $conditions, params: $params, teams: $teams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific alert action.
#
# GET /alert-actions/{id}
export def "alert-actions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Describes optional properties that should be included in the response. You may declare multiple. (conditions); some may not work in lists; may be used for POST and PUT as well.
]: nothing -> record<id: string, alertSources: table<id: int, teams: list, name: string, iconUrl: string, lightIconUrl: string, darkIconUrl: string, escalationPolicy: record, integrationType: string, integrationKey: string, integrationUrl: string, autoResolutionTimeout: string, alertGroupingWindow: string, alertCreation: string, status: string, active: bool, alertPriorityRule: string, supportHours: record, bidirectional: bool, summaryTemplate: record, detailsTemplate: record, routingTemplate: record, linkTemplates: list, priorityTemplate: record, severityTemplate: record, eventFilter: string, alertKeyTemplate: record, servicesTemplate: list, eventTypeFilterCreate: string, eventTypeFilterAccept: string, eventTypeFilterResolve: string, autoRaiseAlerts: bool, scoreThreshold: float, severity: int, services: list, setupStatus: string, autoCreateServices: bool, createdAt: string, updatedAt: string>, connectorId: string, connectorType: string, name: string, createdAt: string, updatedAt: string, triggerMode: string, bidirectional: bool, escalationEndedDelaySec: float, notResolvedDelaySec: float, triggerTypes: list<string>, alertFilter: record<operator: string, predicates: list<record>>, conditions: string, params: record, teams: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/alert-actions/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the specific alert action. (note: type cannot be changed)
#
# PUT /alert-actions/{id}
# --alertSources item shape: {id?: int, teams?: list, name: string, iconUrl?: string, lightIconUrl?: string, darkIconUrl?: string, escalationPolicy: record, integrationType: "NAGIOS"|"ICINGA"|"EMAIL2"|"SMS"|"API"|"HEARTBEAT2"|"PRTG"|"PINGDOM"|"CLOUDWATCH"|"AWSPHD"|"STACKDRIVER"|"INSTANA"|"ZABBIX"|"SOLARWINDS"|"PROMETHEUS"|"NEWRELIC"|"GRAFANA"|"GITHUB"|"DATADOG"|"UPTIMEROBOT"|"APPDYNAMICS"|"DYNATRACE"|"TOPDESK"|"STATUSCAKE"|"MONITOR"|"TOOL"|"CHECKMK"|"AUTOTASK"|"AWSBUDGET"|"SYSDIG"|"SERVERDENSITY"|"ZAPIER"|"KENTIXAM"|"JIRA"|"CONSUL"|"ZAMMAD"|"SPLUNK"|"SERVICENOW"|"SEARCHGUARD"|"KUBERNETES"|"SIGNALFX"|"AZUREALERTS"|"TERRAFORMCLOUD"|"SENTRY"|"SEMATEXT"|"SUMOLOGIC"|"RAYGUN"|"MXTOOLBOX"|"ESWATCHER"|"AMAZONSNS"|"KAPACITOR"|"CORTEXXSOAR"|"ZENDESK"|"AUVIK"|"SENSU"|"NCENTRAL"|"JUMPCLOUD"|"SALESFORCE"|"GUARDDUTY"|"STATUSHUB"|"IXON"|"APIFORTRESS"|"FRESHSERVICE"|"APPSIGNAL"|"LIGHTSTEP"|"IBMCLOUDFUNCTIONS"|"CROWDSTRIKE"|"HUMIO"|"OHDEAR"|"MONGODBATLAS"|"GITLAB"|"HYPERPING"|"PAPRISMACLOUD"|"SAMSARA"|"PANDORAFMS"|"MSSCOM"|"TWILIO"|"CISCOMERAKI"|"CHECKLY"|"POSTHOG"|"GOOGLESCC"|"SLACK"|"MSTEAMS"|"UPTIMEKUMA"|"TWILIOERRORS"|"PARTICLE"|"CLOUDFLARE"|"TULIP"|"GRAYLOG"|"CATCHPOINT"|"LOKI"|"CORTEX"|"MIMIR"|"HALOPSA"|"INFLUXDB"|"CALLFLOW"|"HALOITSM"|"KIBANA"|"VICTORIAMETRICS"|"HONEYCOMB"|"FOURME"|"KEEP"|"UBIDOTS"|"HETRIXTOOLS"|"POSTMAN"|"CLUSTERCONTROL"|"NETDATA"|"AWX"|"KAFKA"|"MQTT"|"RAPIDSPIKE"|"HONEYBADGER"|"HEALTHCHECKSIO"|"MEZMO"|"SERVERGUARD24"|"CISCOTHOUSANDEYES"|"SITE24X7"|"ITCONDUCTOR"|"SAPFRUN"|"APICA"|"DASH0"|"ROLLBAR"|"GATUS"|"LIBRENMS"|"PANTHER"|"TEAMCITY"|"ALIBABACLOUD"|"FLEETDM"|"CONNECTWISEPSA"|"DEADMANSSNITCH"|"FORTISOAR"|"OPMANAGER"|"CRONITOR"|"DOMOTZ"|"LIVEWATCH"|"AZUREDEVOPS"|"LEVELIO"|"EKARA"|"SYSAID"|"PHAREIO"|"OPSGENIE"|"WHATAP"|"SIGNOZ"|"GOOGLECHAT"|"DOTCOMMONITOR"|"UPTIME"|"HELPSCOUT"|"SCIENCELOGIC"|"PULSETIC"|"WAZUH"|"SEKOIA", integrationKey?: string, autoResolutionTimeout?: string, alertGroupingWindow?: string, alertCreation?: "ONE_ALERT_PER_EMAIL"|"ONE_ALERT_PER_EMAIL_SUBJECT"|"ONE_PENDING_ALERT_ALLOWED"|"ONE_OPEN_ALERT_ALLOWED"|"OPEN_RESOLVE_ON_EXTRACTION"|"ONE_ALERT_GROUPED_PER_WINDOW"|"INTELLIGENT_GROUPING", active?: bool, alertPriorityRule?: "HIGH"|"LOW"|"HIGH_DURING_SUPPORT_HOURS"|"LOW_DURING_SUPPORT_HOURS", supportHours?: record, summaryTemplate?: record, detailsTemplate?: record, routingTemplate?: record, linkTemplates?: list, priorityTemplate?: record, severityTemplate?: record, eventFilter?: string, alertKeyTemplate?: record, servicesTemplate?: list, eventTypeFilterCreate?: string, eventTypeFilterAccept?: string, eventTypeFilterResolve?: string, autoRaiseAlerts?: bool, scoreThreshold?: float, severity?: int, services?: list, setupStatus?: "CREATED"|"CREATED_ADVANCED"|"CREATED_BIDIRECTIONAL"|"FINISHED", autoCreateServices?: bool}
# --alertFilter shape: {operator?: "AND"|"OR", predicates?: list}
# --params shape: {tags?: list, priority?: string, site?: string, project?: string, issueType?: string, bodyTemplate?: string, channelId?: string, channelName?: string, teamId?: string, teamName?: string, type?: "chat"|"meeting", callerId?: string, impact?: string, urgency?: string, closeCode?: string, assignmentGroup?: string, ownerGroup?: string, service?: string, serviceOffering?: string, contactType?: string, companyId?: string, queueId?: string, ticketCategory?: string, ticketType?: string, noteType?: string, notePublish?: string, status?: string, teamDomain?: string, webhookUrl?: string, headers?: list, owner?: string, repository?: string, labels?: list, recipients?: list, subject?: string, eventFilter?: string, password?: string, pageId?: string, isAtAll?: bool, atMobiles?: list, url?: string, secret?: string, alertType?: "CREATED"|"ACCEPTED", resolveIncident?: bool, serviceStatus?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", templateId?: int, sendNotification?: bool, serviceIds?: list}
# --teams item shape: {id?: int, name?: string}
export def "alert-actions put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: string
  --alertSources: list # item shape: {id?: int, teams?: list, name: string, iconUrl?: string, lightIconUrl?: string, darkIconUrl?: string, escalationPolicy: record, integrationType: "NAGIOS"|"ICINGA"|"EMAIL2"|"SMS"|"API"|"HEARTBEAT2"|"PRTG"|"PINGDOM"|"CLOUDWATCH"|"AWSPHD"|"STACKDRIVER"|"INSTANA"|"ZABBIX"|"SOLARWINDS"|"PROMETHEUS"|"NEWRELIC"|"GRAFANA"|"GITHUB"|"DATADOG"|"UPTIMEROBOT"|"APPDYNAMICS"|"DYNATRACE"|"TOPDESK"|"STATUSCAKE"|"MONITOR"|"TOOL"|"CHECKMK"|"AUTOTASK"|"AWSBUDGET"|"SYSDIG"|"SERVERDENSITY"|"ZAPIER"|"KENTIXAM"|"JIRA"|"CONSUL"|"ZAMMAD"|"SPLUNK"|"SERVICENOW"|"SEARCHGUARD"|"KUBERNETES"|"SIGNALFX"|"AZUREALERTS"|"TERRAFORMCLOUD"|"SENTRY"|"SEMATEXT"|"SUMOLOGIC"|"RAYGUN"|"MXTOOLBOX"|"ESWATCHER"|"AMAZONSNS"|"KAPACITOR"|"CORTEXXSOAR"|"ZENDESK"|"AUVIK"|"SENSU"|"NCENTRAL"|"JUMPCLOUD"|"SALESFORCE"|"GUARDDUTY"|"STATUSHUB"|"IXON"|"APIFORTRESS"|"FRESHSERVICE"|"APPSIGNAL"|"LIGHTSTEP"|"IBMCLOUDFUNCTIONS"|"CROWDSTRIKE"|"HUMIO"|"OHDEAR"|"MONGODBATLAS"|"GITLAB"|"HYPERPING"|"PAPRISMACLOUD"|"SAMSARA"|"PANDORAFMS"|"MSSCOM"|"TWILIO"|"CISCOMERAKI"|"CHECKLY"|"POSTHOG"|"GOOGLESCC"|"SLACK"|"MSTEAMS"|"UPTIMEKUMA"|"TWILIOERRORS"|"PARTICLE"|"CLOUDFLARE"|"TULIP"|"GRAYLOG"|"CATCHPOINT"|"LOKI"|"CORTEX"|"MIMIR"|"HALOPSA"|"INFLUXDB"|"CALLFLOW"|"HALOITSM"|"KIBANA"|"VICTORIAMETRICS"|"HONEYCOMB"|"FOURME"|"KEEP"|"UBIDOTS"|"HETRIXTOOLS"|"POSTMAN"|"CLUSTERCONTROL"|"NETDATA"|"AWX"|"KAFKA"|"MQTT"|"RAPIDSPIKE"|"HONEYBADGER"|"HEALTHCHECKSIO"|"MEZMO"|"SERVERGUARD24"|"CISCOTHOUSANDEYES"|"SITE24X7"|"ITCONDUCTOR"|"SAPFRUN"|"APICA"|"DASH0"|"ROLLBAR"|"GATUS"|"LIBRENMS"|"PANTHER"|"TEAMCITY"|"ALIBABACLOUD"|"FLEETDM"|"CONNECTWISEPSA"|"DEADMANSSNITCH"|"FORTISOAR"|"OPMANAGER"|"CRONITOR"|"DOMOTZ"|"LIVEWATCH"|"AZUREDEVOPS"|"LEVELIO"|"EKARA"|"SYSAID"|"PHAREIO"|"OPSGENIE"|"WHATAP"|"SIGNOZ"|"GOOGLECHAT"|"DOTCOMMONITOR"|"UPTIME"|"HELPSCOUT"|"SCIENCELOGIC"|"PULSETIC"|"WAZUH"|"SEKOIA", integrationKey?: string, autoResolutionTimeout?: string, alertGroupingWindow?: string, alertCreation?: "ONE_ALERT_PER_EMAIL"|"ONE_ALERT_PER_EMAIL_SUBJECT"|"ONE_PENDING_ALERT_ALLOWED"|"ONE_OPEN_ALERT_ALLOWED"|"OPEN_RESOLVE_ON_EXTRACTION"|"ONE_ALERT_GROUPED_PER_WINDOW"|"INTELLIGENT_GROUPING", active?: bool, alertPriorityRule?: "HIGH"|"LOW"|"HIGH_DURING_SUPPORT_HOURS"|"LOW_DURING_SUPPORT_HOURS", supportHours?: record, summaryTemplate?: record, detailsTemplate?: record, routingTemplate?: record, linkTemplates?: list, priorityTemplate?: record, severityTemplate?: record, eventFilter?: string, alertKeyTemplate?: record, servicesTemplate?: list, eventTypeFilterCreate?: string, eventTypeFilterAccept?: string, eventTypeFilterResolve?: string, autoRaiseAlerts?: bool, scoreThreshold?: float, severity?: int, services?: list, setupStatus?: "CREATED"|"CREATED_ADVANCED"|"CREATED_BIDIRECTIONAL"|"FINISHED", autoCreateServices?: bool}
  --connectorId: string
  connectorType: string@connectorType-completer
  name: string
  --createdAt: string # format: date-time
  --updatedAt: string # format: date-time
  --triggerMode: string@triggerMode-completer
  --escalationEndedDelaySec: float # May only be used with triggerType 'alert-escalation-ended' selected
  --notResolvedDelaySec: float # May only be used with triggerType 'v-alert-not-resolved' selected
  --triggerTypes: list
  --alertFilter: record # This field is deprecated, use 'conditions' instead. If both are used this field is ignored. — shape: {operator?: "AND"|"OR", predicates?: list}
  --conditions: string # Defines an optional alert filter condition in ICL language. This is a code based implementation, more info on syntax: https://docs.ilert.com/rest-api/icl-ilert-condition-language. For block based configuration please use the web UI. Note: this field is an ?include, it will not appear in lists.
  --params: record # shape: {tags?: list, priority?: string, site?: string, project?: string, issueType?: string, bodyTemplate?: string, channelId?: string, channelName?: string, teamId?: string, teamName?: string, type?: "chat"|"meeting", callerId?: string, impact?: string, urgency?: string, closeCode?: string, assignmentGroup?: string, ownerGroup?: string, service?: string, serviceOffering?: string, contactType?: string, companyId?: string, queueId?: string, ticketCategory?: string, ticketType?: string, noteType?: string, notePublish?: string, status?: string, teamDomain?: string, webhookUrl?: string, headers?: list, owner?: string, repository?: string, labels?: list, recipients?: list, subject?: string, eventFilter?: string, password?: string, pageId?: string, isAtAll?: bool, atMobiles?: list, url?: string, secret?: string, alertType?: "CREATED"|"ACCEPTED", resolveIncident?: bool, serviceStatus?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", templateId?: int, sendNotification?: bool, serviceIds?: list}
  --teams: list # item shape: {id?: int, name?: string}
]: any -> record<id: string, alertSources: table<id: int, teams: list, name: string, iconUrl: string, lightIconUrl: string, darkIconUrl: string, escalationPolicy: record, integrationType: string, integrationKey: string, integrationUrl: string, autoResolutionTimeout: string, alertGroupingWindow: string, alertCreation: string, status: string, active: bool, alertPriorityRule: string, supportHours: record, bidirectional: bool, summaryTemplate: record, detailsTemplate: record, routingTemplate: record, linkTemplates: list, priorityTemplate: record, severityTemplate: record, eventFilter: string, alertKeyTemplate: record, servicesTemplate: list, eventTypeFilterCreate: string, eventTypeFilterAccept: string, eventTypeFilterResolve: string, autoRaiseAlerts: bool, scoreThreshold: float, severity: int, services: list, setupStatus: string, autoCreateServices: bool, createdAt: string, updatedAt: string>, connectorId: string, connectorType: string, name: string, createdAt: string, updatedAt: string, triggerMode: string, bidirectional: bool, escalationEndedDelaySec: float, notResolvedDelaySec: float, triggerTypes: list<string>, alertFilter: record<operator: string, predicates: list<record>>, conditions: string, params: record, teams: table<id: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alert-actions/($id)")
  let body = {id: $body_id, alertSources: $alertSources, connectorId: $connectorId, connectorType: $connectorType, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, triggerMode: $triggerMode, escalationEndedDelaySec: $escalationEndedDelaySec, notResolvedDelaySec: $notResolvedDelaySec, triggerTypes: $triggerTypes, alertFilter: $alertFilter, conditions: $conditions, params: $params, teams: $teams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a specific alert action.
#
# DELETE /alert-actions/{id}
export def "alert-actions delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alert-actions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get connectors.
#
# GET /connectors
export def "connectors list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of entities. (format: int32, default: 50)
]: nothing -> table<id: string, type: string, name: string, createdAt: string, updatedAt: string, params: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/connectors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new connector.
#
# POST /connectors
# --params shape: {apiKey?: string, url?: string, email?: string, password?: string, username?: string, authorization?: string, secret?: string}
export def "connectors post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string
  type: string@type-completer-4
  name: string
  --createdAt: string # format: date-time
  --updatedAt: string # format: date-time
  --params: record # shape: {apiKey?: string, url?: string, email?: string, password?: string, username?: string, authorization?: string, secret?: string}
]: any -> record<id: string, type: string, name: string, createdAt: string, updatedAt: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/connectors")
  let body = {id: $id, type: $type, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific connector.
#
# GET /connectors/{id}
export def "connectors get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, name: string, createdAt: string, updatedAt: string, params: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connectors/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the specific connector. (note: type cannot be changed)
#
# PUT /connectors/{id}
# --params shape: {apiKey?: string, url?: string, email?: string, password?: string, username?: string, authorization?: string, secret?: string}
export def "connectors put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: string
  type: string@type-completer-4
  name: string
  --createdAt: string # format: date-time
  --updatedAt: string # format: date-time
  --params: record # shape: {apiKey?: string, url?: string, email?: string, password?: string, username?: string, authorization?: string, secret?: string}
]: any -> record<id: string, type: string, name: string, createdAt: string, updatedAt: string, params: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connectors/($id)")
  let body = {id: $body_id, type: $type, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a specific connector.
#
# DELETE /connectors/{id}
export def "connectors delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connectors/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get teams.
#
# GET /teams
export def "teams list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of entities. (format: int32, default: 50)
  --members: float # optional, filter teams for specific members (currently only a single occurrence of this param is allowed)
]: nothing -> table<id: int, name: string, visibility: string, members: list<record>, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "members" $members "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new team.
#
# POST /teams
# --members item shape: {user?: record, role?: "STAKEHOLDER"|"RESPONDER"|"USER"|"ADMIN"}
export def "teams post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int64
  --name: string
  --visibility: string@visibility-completer
  --members: list # item shape: {user?: record, role?: "STAKEHOLDER"|"RESPONDER"|"USER"|"ADMIN"}
  --createdAt: string # Date in ISO-8601 (format: date-time)
  --updatedAt: string # Date in ISO-8601 (format: date-time)
]: any -> record<id: int, name: string, visibility: string, members: table<user: record, role: string>, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/teams")
  let body = {id: $id, name: $name, visibility: $visibility, members: $members, createdAt: $createdAt, updatedAt: $updatedAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific team.
#
# GET /teams/{id}
export def "teams get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, visibility: string, members: table<user: record, role: string>, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the specific team
#
# PUT /teams/{id}
# --members item shape: {user?: record, role?: "STAKEHOLDER"|"RESPONDER"|"USER"|"ADMIN"}
export def "teams put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: int # format: int64
  --name: string
  --visibility: string@visibility-completer
  --members: list # item shape: {user?: record, role?: "STAKEHOLDER"|"RESPONDER"|"USER"|"ADMIN"}
  --createdAt: string # Date in ISO-8601 (format: date-time)
  --updatedAt: string # Date in ISO-8601 (format: date-time)
]: any -> record<id: int, name: string, visibility: string, members: table<user: record, role: string>, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)")
  let body = {id: $body_id, name: $name, visibility: $visibility, members: $members, createdAt: $createdAt, updatedAt: $updatedAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a specific team.
#
# DELETE /teams/{id}
export def "teams delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new team member to specific team
#
# POST /teams/{id}/members
# --user shape: {id?: int, firstName: string, lastName: string, email: string, timezone?: "Europe/Berlin"|"America/New_York"|"America/Los_Angeles"|"Asia/Istanbul", position?: string, department?: string, language?: "de"|"en", region?: "DE"|"GB"|"CH"|"CN"|"IN"|"US"|"FR"|"ES"|"CA"|"IE", role?: "STAKEHOLDER"|"GUEST"|"RESPONDER"|"USER"|"ADMIN", shiftColor?: string, mutedUntil?: string, createdAt?: string, updatedAt?: string}
export def "teams-members post" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user: record # shape: {id?: int, firstName: string, lastName: string, email: string, timezone?: "Europe/Berlin"|"America/New_York"|"America/Los_Angeles"|"Asia/Istanbul", position?: string, department?: string, language?: "de"|"en", region?: "DE"|"GB"|"CH"|"CN"|"IN"|"US"|"FR"|"ES"|"CA"|"IE", role?: "STAKEHOLDER"|"GUEST"|"RESPONDER"|"USER"|"ADMIN", shiftColor?: string, mutedUntil?: string, createdAt?: string, updatedAt?: string}
  --role: string@role-completer-1
]: any -> record<user: record<id: int, firstName: string, lastName: string, email: string, timezone: string, position: string, department: string, avatarUrl: string, language: string, region: string, role: string, shiftColor: string, mutedUntil: string, createdAt: string, updatedAt: string>, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)/members")
  let body = {user: $user, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a specific member of a specific team.
#
# DELETE /teams/{id}/members/{id}
export def "teams-members delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)/members/{id}")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List alert metrics for the requested resources
#
# GET /reports/alerts
export def "reports-alerts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --sources: float # alert source ids to filter metrics for
  --policies: float # escalation policy ids to filter metrics for
  --numbers: string # phone numbers of call routing numbers to filter metrics for
  --qp-from: string # date-time ISO-UTC e.g. 2021-05-25T21:24:56.771Z, start of the time range, may not exceed 1 year in total span
  --until: string # date-time ISO-UTC e.g. 2021-05-25T21:24:56.771Z, end of the time range, must be after 'from', must not be in the future
  --timezone: string # Time zone in which the results will be rendered, defaults to tenant's configured default timezone
  --metric: string # Describes the metric that should be fetched choose one of: COUNT, MTTA or MTTR - defaults to COUNT
  --group-by: string # Defines the grouping of metrics, choose one of: DAY, WEEK or MONTH - defaults to WEEK
  --priority: string # Sets the priority filter that should be applied, choose one of: LOW, HIGH or ALL - defaults to ALL
]: nothing -> list<list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sources" $sources "scalar") (serialize-qp "policies" $policies "scalar") (serialize-qp "numbers" $numbers "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "metric" $metric "scalar") (serialize-qp "group-by" $group_by "scalar") (serialize-qp "priority" $priority "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/alerts" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Summarize a list of alert metrics
#
# GET /reports/alerts/summary
export def "reports-alerts-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sources: float # alert source ids to filter metrics for
  --policies: float # escalation policy ids to filter metrics for
  --numbers: string # phone numbers of call routing numbers to filter metrics for
  --qp-from: string # date-time ISO-UTC e.g. 2021-05-25T21:24:56.771Z, start of the time range, may not exceed 1 year in total span
  --until: string # date-time ISO-UTC e.g. 2021-05-25T21:24:56.771Z, end of the time range, must be after 'from', must not be in the future
  --timezone: string # Time zone in which the results will be rendered, defaults to tenant's configured default timezone
  --metric: string # Describes the metric that should be fetched choose one of: COUNT, MTTA or MTTR - defaults to COUNT
  --group-by: string # Defines the grouping of metrics, choose one of: DAY, WEEK or MONTH - defaults to WEEK
  --priority: string # Sets the priority filter that should be applied, choose one of: LOW, HIGH or ALL - defaults to ALL
]: nothing -> table<alertSourceId: float, escalationPolicyId: float, callRoutingNumberPhoneNumber: string, count: float, mtta: float, mttr: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sources" $sources "scalar") (serialize-qp "policies" $policies "scalar") (serialize-qp "numbers" $numbers "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "metric" $metric "scalar") (serialize-qp "group-by" $group_by "scalar") (serialize-qp "priority" $priority "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/alerts/summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List API key usage metrics for the requested resources
#
# GET /reports/api-keys/usage
export def "reports-api-keys-usage get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --scopes: string # scopes of our API resources e.g. alert see https://docs.ilert.com/rest-api/developing-ilert-apps/token-lifetimes-error-codes-app-verification-etc.#ilert-oauth2-scopes
  --qp-from: string # date-time ISO-UTC e.g. 2021-05-25T21:24:56.771Z, start of the time range, may not exceed 1 month (31 days) in total span (use this to paginate)
  --until: string # date-time ISO-UTC e.g. 2021-05-25T21:24:56.771Z, end of the time range, must be after 'from', must not be in the future (use this to paginate)
  --timezone: string # Time zone in which the results will be rendered, defaults to tenant's configured default timezone
]: nothing -> list<list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scopes" $scopes "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "timezone" $timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/api-keys/usage" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get incident templates.
#
# GET /incident-templates
export def "incident-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of entities. (format: int32, default: 50)
]: nothing -> table<id: float, name: string, summary: string, status: string, message: string, sendNotification: bool, teams: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/incident-templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new incident template.
#
# POST /incident-templates
# --teams item shape: {id?: int, name?: string}
export def "incident-templates post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: float
  --name: string
  --summary: string
  --status: string@status-completer # the incident status
  --message: string
  --sendNotification: string@bool-completer
  --teams: list # item shape: {id?: int, name?: string}
]: any -> record<id: float, name: string, summary: string, status: string, message: string, sendNotification: bool, teams: table<id: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/incident-templates")
  let body = {id: $id, name: $name, summary: $summary, status: $status, message: $message, sendNotification: $sendNotification, teams: $teams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific incident template.
#
# GET /incident-templates/{id}
export def "incident-templates get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: float, name: string, summary: string, status: string, message: string, sendNotification: bool, teams: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incident-templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the specific incident template
#
# PUT /incident-templates/{id}
# --teams item shape: {id?: int, name?: string}
export def "incident-templates put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: float
  --name: string
  --summary: string
  --status: string@status-completer # the incident status
  --message: string
  --sendNotification: string@bool-completer
  --teams: list # item shape: {id?: int, name?: string}
]: any -> record<id: float, name: string, summary: string, status: string, message: string, sendNotification: bool, teams: table<id: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incident-templates/($id)")
  let body = {id: $body_id, name: $name, summary: $summary, status: $status, message: $message, sendNotification: $sendNotification, teams: $teams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a specific incident template.
#
# DELETE /incident-templates/{id}
export def "incident-templates delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incident-templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get services.
#
# GET /services
export def "services list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of services. (Note: when using ?include maximum is reduced to 25) (format: int32, default: 10)
  --include: list # Describes optional properties that should be included in the response. You may declare multiple. (subscribed, uptime, incidents)
]: nothing -> table<id: float, name: string, alias: string, status: string, description: string, oneOpenIncidentOnly: bool, showUptimeHistory: bool, teams: list<record>, subscribed: bool, uptime: record<rangeStart: string, rangeEnd: string, outages: list, uptimePercentage: record>, incidents: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new service.
#
# POST /services
# --teams item shape: {id?: int, name?: string}
export def "services post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: float
  --name: string
  --alias: string
  --status: string@status-completer-1 # the service status
  --description: string
  --oneOpenIncidentOnly: string@bool-completer
  --showUptimeHistory: string@bool-completer
  --teams: list # item shape: {id?: int, name?: string}
]: any -> record<id: float, name: string, alias: string, status: string, description: string, oneOpenIncidentOnly: bool, showUptimeHistory: bool, teams: table<id: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/services")
  let body = {id: $id, name: $name, alias: $alias, status: $status, description: $description, oneOpenIncidentOnly: $oneOpenIncidentOnly, showUptimeHistory: $showUptimeHistory, teams: $teams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific service.
#
# GET /services/{id}
export def "services get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Describes optional properties that should be included in the response. You may declare multiple. (subscribed, uptime, incidents)
]: nothing -> record<id: float, name: string, alias: string, status: string, description: string, oneOpenIncidentOnly: bool, showUptimeHistory: bool, teams: table<id: int, name: string>, subscribed: bool, uptime: record<rangeStart: string, rangeEnd: string, outages: list<record>, uptimePercentage: record<uptimePercentage: record>>, incidents: table<id: float, summary: string, status: string, message: string, sendNotification: bool, createdAt: string, updatedAt: string, affectedServices: list, resolvedOn: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/services/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the specific service
#
# PUT /services/{id}
# --teams item shape: {id?: int, name?: string}
export def "services put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: float
  --name: string
  --alias: string
  --status: string@status-completer-1 # the service status
  --description: string
  --oneOpenIncidentOnly: string@bool-completer
  --showUptimeHistory: string@bool-completer
  --teams: list # item shape: {id?: int, name?: string}
]: any -> record<id: float, name: string, alias: string, status: string, description: string, oneOpenIncidentOnly: bool, showUptimeHistory: bool, teams: table<id: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($id)")
  let body = {id: $body_id, name: $name, alias: $alias, status: $status, description: $description, oneOpenIncidentOnly: $oneOpenIncidentOnly, showUptimeHistory: $showUptimeHistory, teams: $teams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a specific service.
#
# DELETE /services/{id}
export def "services delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get incidents.
#
# GET /incidents
export def "incidents list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of incidents. (Note: when using ?include maximum is reduced to 25) (format: int32, default: 10)
  --include: list # Describes optional properties that should be included in the response. You may declare multiple. (subscribed)
  --states: list # state of the alert
  --services: list # service IDs of the incident's affected services
  --qp-from: string # from date, ISO-UTC e.g. 2021-05-25T21:24:56.771Z, based on reportTime (format: date-time)
  --until: string # until date, ISO-UTC e.g. 2021-05-26T21:24:56.771Z, based on reportTime (format: date-time)
]: nothing -> table<id: float, summary: string, status: string, message: string, sendNotification: bool, createdAt: string, updatedAt: string, affectedServices: list<record>, resolvedOn: string, subscribed: bool, affectedTeams: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "include" $include "multi") (serialize-qp "states" $states "multi") (serialize-qp "services" $services "multi") (serialize-qp "from" $qp_from "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/incidents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new incident.
#
# POST /incidents
# --affectedServices item shape: {impact?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", service?: record}
export def "incidents post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: float
  --summary: string
  --status: string@status-completer # the incident status
  --message: string
  --sendNotification: string@bool-completer
  --createdAt: string # May be overwritten during the creation of the incident, otherwise read-only (format: date-time)
  --updatedAt: string # May be overwritten during the creation of the incident, otherwise read-only (format: date-time)
  --affectedServices: list # item shape: {impact?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", service?: record}
]: any -> record<id: float, summary: string, status: string, message: string, sendNotification: bool, createdAt: string, updatedAt: string, affectedServices: table<impact: string, service: record>, resolvedOn: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/incidents")
  let body = {id: $id, summary: $summary, status: $status, message: $message, sendNotification: $sendNotification, createdAt: $createdAt, updatedAt: $updatedAt, affectedServices: $affectedServices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Forecast the affected subscribers and status pages
#
# POST /incidents/publish-info
# --affectedServices item shape: {impact?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", service?: record}
export def "incidents-publish-info post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: float
  --summary: string
  --status: string@status-completer # the incident status
  --message: string
  --sendNotification: string@bool-completer
  --createdAt: string # May be overwritten during the creation of the incident, otherwise read-only (format: date-time)
  --updatedAt: string # May be overwritten during the creation of the incident, otherwise read-only (format: date-time)
  --affectedServices: list # item shape: {impact?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", service?: record}
]: any -> record<statusPagesInfo: record<id: float, label: string>, privateStatusPages: float, publicStatusPages: float, privateSubscribers: float, publicSubscribers: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/incidents/publish-info")
  let body = {id: $id, summary: $summary, status: $status, message: $message, sendNotification: $sendNotification, createdAt: $createdAt, updatedAt: $updatedAt, affectedServices: $affectedServices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific incident.
#
# GET /incidents/{id}
export def "incidents get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Describes optional properties that should be included in the response. You may declare multiple. (subscribed, affectedTeams, history)
]: nothing -> record<id: float, summary: string, status: string, message: string, sendNotification: bool, createdAt: string, updatedAt: string, history: table<id: string, content: string, creator: record, incidentStatus: string, sendNotification: bool, createdAt: string>, affectedServices: table<impact: string, service: record>, resolvedOn: string, subscribed: bool, affectedTeams: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/incidents/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the specific incident.
#
# PUT /incidents/{id}
# --affectedServices item shape: {impact?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", service?: record}
export def "incidents put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # Should be the ETag response header retrieved from GET /incidents/{id} to prevent updating the incident based on outdated information. Will return 412 status code in case of conflict.
  --body-id: float
  --summary: string
  --status: string@status-completer # the incident status
  --message: string
  --sendNotification: string@bool-completer
  --createdAt: string # May be overwritten during the creation of the incident, otherwise read-only (format: date-time)
  --updatedAt: string # May be overwritten during the creation of the incident, otherwise read-only (format: date-time)
  --affectedServices: list # item shape: {impact?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", service?: record}
]: any -> record<id: float, summary: string, status: string, message: string, sendNotification: bool, createdAt: string, updatedAt: string, affectedServices: table<impact: string, service: record>, resolvedOn: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)")
  let body = {id: $body_id, summary: $summary, status: $status, message: $message, sendNotification: $sendNotification, createdAt: $createdAt, updatedAt: $updatedAt, affectedServices: $affectedServices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the subscribers (users and teams) of an incident
#
# GET /incidents/{id}/private-subscribers
export def "incidents-private-subscribers get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: float, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)/private-subscribers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add subscribers (users and teams) to an incident
#
# POST /incidents/{id}/private-subscribers
export def "incidents-private-subscribers post" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)/private-subscribers")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the subscribers (users and teams) of a service
#
# GET /services/{id}/private-subscribers
export def "services-private-subscribers get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: float, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($id)/private-subscribers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set subscribers (users and teams) of a service
#
# PUT /services/{id}/private-subscribers
export def "services-private-subscribers put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($id)/private-subscribers")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get status pages.
#
# GET /status-pages
export def "status-pages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of status pages. (format: int32, default: 25)
  --include: list # Describes optional properties that should be included in the response. You may declare multiple. (subscribed)
]: nothing -> table<id: float, name: string, domain: string, subdomain: string, timezone: string, faviconUrl: string, logoUrl: string, visibility: string, hiddenFromSearch: bool, showSubscribeAction: bool, showIncidentHistoryOption: bool, pageTitle: string, pageDescription: string, logoRedirectUrl: string, activated: bool, status: string, teams: list<record>, services: list<record>, metrics: list<record>, ipWhitelist: list<string>, subscribed: bool, announcement: string, announcementOnPage: bool, announcementInWidget: bool, audienceSpecific: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/status-pages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new status page.
#
# POST /status-pages
# --teams item shape: {id?: int, name?: string}
# --services item shape: {id?: float, name?: string, alias?: string, status?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", description?: string, oneOpenIncidentOnly?: bool, showUptimeHistory?: bool, teams?: list}
# --metrics item shape: {id?: float, name?: string, description?: string, aggregationType?: "AVG"|"SUM"|"MIN"|"MAX"|"LAST", displayType?: "GRAPH"|"SINGLE", interpolateGaps?: bool, lockYAxisMax?: float, lockYAxisMin?: float, mouseOverDecimal?: float, showValuesOnMouseOver?: bool, unitLabel?: string, teams?: list}
# --structure shape: {elements?: list}
export def "status-pages post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: float
  --name: string
  --domain: string
  --subdomain: string
  --timezone: string@timezone-completer
  --faviconUrl: string
  --logoUrl: string
  --visibility: string@visibility-completer
  --hiddenFromSearch: string@bool-completer
  --showSubscribeAction: string@bool-completer
  --showIncidentHistoryOption: string@bool-completer
  --pageTitle: string
  --pageDescription: string
  --pageLayout: string@pageLayout-completer
  --logoRedirectUrl: string
  --activated: string@bool-completer
  --status: string@status-completer-1 # the service status
  --teams: list # item shape: {id?: int, name?: string}
  --services: list # item shape: {id?: float, name?: string, alias?: string, status?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", description?: string, oneOpenIncidentOnly?: bool, showUptimeHistory?: bool, teams?: list}
  --metrics: list # item shape: {id?: float, name?: string, description?: string, aggregationType?: "AVG"|"SUM"|"MIN"|"MAX"|"LAST", displayType?: "GRAPH"|"SINGLE", interpolateGaps?: bool, lockYAxisMax?: float, lockYAxisMin?: float, mouseOverDecimal?: float, showValuesOnMouseOver?: bool, unitLabel?: string, teams?: list}
  --ipWhitelist: list # ipv4 or ipv6 addresses to give access to. Can only be set on 'PRIVATE' status pages
  --structure: record # This field is not available in the list resource. Describes the structure of a status page. Allows for nesting children. It is not required unless groups are used. — shape: {elements?: list}
  --appearance: string@appearance-completer
]: any -> record<id: float, name: string, domain: string, subdomain: string, timezone: string, faviconUrl: string, logoUrl: string, visibility: string, hiddenFromSearch: bool, showSubscribeAction: bool, showIncidentHistoryOption: bool, pageTitle: string, pageDescription: string, pageLayout: string, logoRedirectUrl: string, activated: bool, status: string, teams: table<id: int, name: string>, services: table<id: float, name: string, alias: string, status: string, description: string, oneOpenIncidentOnly: bool, showUptimeHistory: bool, teams: list>, metrics: table<id: float, name: string, description: string, aggregationType: string, displayType: string, interpolateGaps: bool, lockYAxisMax: float, lockYAxisMin: float, mouseOverDecimal: float, showValuesOnMouseOver: bool, unitLabel: string, teams: list>, ipWhitelist: list<string>, structure: record<elements: list<record>>, appearance: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/status-pages")
  let body = {id: $id, name: $name, domain: $domain, subdomain: $subdomain, timezone: $timezone, faviconUrl: $faviconUrl, logoUrl: $logoUrl, visibility: $visibility, hiddenFromSearch: $hiddenFromSearch, showSubscribeAction: $showSubscribeAction, showIncidentHistoryOption: $showIncidentHistoryOption, pageTitle: $pageTitle, pageDescription: $pageDescription, pageLayout: $pageLayout, logoRedirectUrl: $logoRedirectUrl, activated: $activated, status: $status, teams: $teams, services: $services, metrics: $metrics, ipWhitelist: $ipWhitelist, structure: $structure, appearance: $appearance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific status page.
#
# GET /status-pages/{id}
export def "status-pages get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Describes optional properties that should be included in the response. You may declare multiple. (subscribed, uptime, groups, structure). Note: structure is always included by default.
]: nothing -> record<id: float, name: string, domain: string, subdomain: string, timezone: string, faviconUrl: string, logoUrl: string, visibility: string, hiddenFromSearch: bool, showSubscribeAction: bool, showIncidentHistoryOption: bool, pageTitle: string, pageDescription: string, pageLayout: string, logoRedirectUrl: string, activated: bool, status: string, teams: table<id: int, name: string>, services: table<id: float, name: string, status: string, description: string, oneOpenIncidentOnly: bool, showUptimeHistory: bool, teams: list, uptime: record>, metrics: table<id: float, name: string, description: string, aggregationType: string, displayType: string, interpolateGaps: bool, lockYAxisMax: float, lockYAxisMin: float, mouseOverDecimal: float, showValuesOnMouseOver: bool, unitLabel: string, teams: list>, ipWhitelist: list<string>, structure: record<elements: list<record>>, subscribed: bool, groups: table<id: float, name: string>, appearance: string, announcement: string, announcementOnPage: bool, announcementInWidget: bool, audienceSpecific: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/status-pages/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the specific status page
#
# PUT /status-pages/{id}
# --teams item shape: {id?: int, name?: string}
# --services item shape: {id?: float, name?: string, alias?: string, status?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", description?: string, oneOpenIncidentOnly?: bool, showUptimeHistory?: bool, teams?: list}
# --metrics item shape: {id?: float, name?: string, description?: string, aggregationType?: "AVG"|"SUM"|"MIN"|"MAX"|"LAST", displayType?: "GRAPH"|"SINGLE", interpolateGaps?: bool, lockYAxisMax?: float, lockYAxisMin?: float, mouseOverDecimal?: float, showValuesOnMouseOver?: bool, unitLabel?: string, teams?: list}
# --structure shape: {elements?: list}
export def "status-pages put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: float
  --name: string
  --domain: string
  --subdomain: string
  --timezone: string@timezone-completer
  --faviconUrl: string
  --logoUrl: string
  --visibility: string@visibility-completer
  --hiddenFromSearch: string@bool-completer
  --showSubscribeAction: string@bool-completer
  --showIncidentHistoryOption: string@bool-completer
  --pageTitle: string
  --pageDescription: string
  --pageLayout: string@pageLayout-completer
  --logoRedirectUrl: string
  --activated: string@bool-completer
  --status: string@status-completer-1 # the service status
  --teams: list # item shape: {id?: int, name?: string}
  --services: list # item shape: {id?: float, name?: string, alias?: string, status?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", description?: string, oneOpenIncidentOnly?: bool, showUptimeHistory?: bool, teams?: list}
  --metrics: list # item shape: {id?: float, name?: string, description?: string, aggregationType?: "AVG"|"SUM"|"MIN"|"MAX"|"LAST", displayType?: "GRAPH"|"SINGLE", interpolateGaps?: bool, lockYAxisMax?: float, lockYAxisMin?: float, mouseOverDecimal?: float, showValuesOnMouseOver?: bool, unitLabel?: string, teams?: list}
  --ipWhitelist: list # ipv4 or ipv6 addresses to give access to. Can only be set on 'PRIVATE' status pages
  --structure: record # This field is not available in the list resource. Describes the structure of a status page. Allows for nesting children. It is not required unless groups are used. — shape: {elements?: list}
  --appearance: string@appearance-completer
]: any -> record<id: float, name: string, domain: string, subdomain: string, timezone: string, faviconUrl: string, logoUrl: string, visibility: string, hiddenFromSearch: bool, showSubscribeAction: bool, showIncidentHistoryOption: bool, pageTitle: string, pageDescription: string, pageLayout: string, logoRedirectUrl: string, activated: bool, status: string, teams: table<id: int, name: string>, services: table<id: float, name: string, alias: string, status: string, description: string, oneOpenIncidentOnly: bool, showUptimeHistory: bool, teams: list>, metrics: table<id: float, name: string, description: string, aggregationType: string, displayType: string, interpolateGaps: bool, lockYAxisMax: float, lockYAxisMin: float, mouseOverDecimal: float, showValuesOnMouseOver: bool, unitLabel: string, teams: list>, ipWhitelist: list<string>, structure: record<elements: list<record>>, appearance: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status-pages/($id)")
  let body = {id: $body_id, name: $name, domain: $domain, subdomain: $subdomain, timezone: $timezone, faviconUrl: $faviconUrl, logoUrl: $logoUrl, visibility: $visibility, hiddenFromSearch: $hiddenFromSearch, showSubscribeAction: $showSubscribeAction, showIncidentHistoryOption: $showIncidentHistoryOption, pageTitle: $pageTitle, pageDescription: $pageDescription, pageLayout: $pageLayout, logoRedirectUrl: $logoRedirectUrl, activated: $activated, status: $status, teams: $teams, services: $services, metrics: $metrics, ipWhitelist: $ipWhitelist, structure: $structure, appearance: $appearance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a specific status page.
#
# DELETE /status-pages/{id}
export def "status-pages delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status-pages/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the groups of a status page
#
# GET /status-pages/{id}/groups
export def "status-pages-groups list" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of entities. (format: int32, default: 50)
]: nothing -> table<id: float, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/status-pages/($id)/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a group to a status page
#
# POST /status-pages/{id}/groups
export def "status-pages-groups post" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: float
  --name: string
]: any -> record<id: float, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status-pages/($id)/groups")
  let body = {id: $body_id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific group of a status page
#
# GET /status-pages/{id}/groups/{group-id}
export def "status-pages-groups get" [
  id: float
  group_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: float, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status-pages/($id)/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a group of a status page
#
# PUT /status-pages/{id}/groups/{group-id}
export def "status-pages-groups put" [
  id: float
  group_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: float
  --name: string
]: any -> record<id: float, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status-pages/($id)/groups/($group_id)")
  let body = {id: $body_id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove group from a status page
#
# DELETE /status-pages/{id}/groups/{group-id}
export def "status-pages-groups delete" [
  id: float
  group_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status-pages/($id)/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the subscribers (users and teams) of a status page
#
# GET /status-pages/{id}/private-subscribers
export def "status-pages-private-subscribers get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: float, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status-pages/($id)/private-subscribers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set subscribers (users and teams) of a status page
#
# PUT /status-pages/{id}/private-subscribers
export def "status-pages-private-subscribers put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status-pages/($id)/private-subscribers")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add subscriber (user and team) to a status page
#
# POST /status-pages/{id}/private-subscribers
export def "status-pages-private-subscribers post" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: float
  --name: string
  --type: string@type-completer-5
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status-pages/($id)/private-subscribers")
  let body = {id: $body_id, name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove subscriber (user and team) from a status page
#
# DELETE /status-pages/{id}/private-subscribers/{subscriber-id}
export def "status-pages-private-subscribers delete" [
  id: float
  subscriber_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscriber-type: string@subscriber-type-completer # the type of subscriber USER or TEAM
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscriber-type" $subscriber_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/status-pages/($id)/private-subscribers/($subscriber_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the outages (including applied overrides) of a specific service
#
# GET /service-outages
export def "service-outages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --service: float # the id of the service for which the outages should be fetched
  --qp-from: string # from date, ISO-UTC e.g. 2021-05-25T21:24:56.771Z (format: date-time)
  --until: string # until date, ISO-UTC e.g. 2021-05-26T21:24:56.771Z (format: date-time)
  --ignore-overrides: string@bool-completer # if the outages should not take overrides into account, default is false
]: nothing -> table<status: string, from: string, until: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "service" $service "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "ignore-overrides" $ignore_overrides "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/service-outages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the overrides of a specific service
#
# GET /service-outages/overrides
export def "service-outages-overrides list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --service: float # the id of the service for which the overrides should be fetched
  --qp-from: string # from date, ISO-UTC e.g. 2021-05-25T21:24:56.771Z (format: date-time)
  --until: string # until date, ISO-UTC e.g. 2021-05-26T21:24:56.771Z (format: date-time)
]: nothing -> table<id: string, service: record<id: float, name: string, alias: string, status: string, description: string, oneOpenIncidentOnly: bool, showUptimeHistory: bool, teams: list>, status: string, from: string, until: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "service" $service "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/service-outages/overrides" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Override a part of a service's outage history
#
# POST /service-outages/overrides
# --service shape: {id?: float, name?: string, alias?: string, status?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", description?: string, oneOpenIncidentOnly?: bool, showUptimeHistory?: bool, teams?: list}
export def "service-outages-overrides post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string
  --service: record # shape: {id?: float, name?: string, alias?: string, status?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", description?: string, oneOpenIncidentOnly?: bool, showUptimeHistory?: bool, teams?: list}
  --status: string@status-completer-1 # the service status
  --body-from: string # format: date-time
  --until: string # format: date-time
]: any -> record<id: string, service: record<id: float, name: string, alias: string, status: string, description: string, oneOpenIncidentOnly: bool, showUptimeHistory: bool, teams: list<record>>, status: string, from: string, until: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/service-outages/overrides")
  let body = {id: $id, service: $service, status: $status, from: $body_from, until: $until} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the specific service outage override
#
# GET /service-outages/overrides/{id}
export def "service-outages-overrides get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, service: record<id: float, name: string, alias: string, status: string, description: string, oneOpenIncidentOnly: bool, showUptimeHistory: bool, teams: list<record>>, status: string, from: string, until: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/service-outages/overrides/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing service outage override
#
# PUT /service-outages/overrides/{id}
# --service shape: {id?: float, name?: string, alias?: string, status?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", description?: string, oneOpenIncidentOnly?: bool, showUptimeHistory?: bool, teams?: list}
export def "service-outages-overrides put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: string
  --service: record # shape: {id?: float, name?: string, alias?: string, status?: "OPERATIONAL"|"UNDER_MAINTENANCE"|"DEGRADED"|"PARTIAL_OUTAGE"|"MAJOR_OUTAGE", description?: string, oneOpenIncidentOnly?: bool, showUptimeHistory?: bool, teams?: list}
  --status: string@status-completer-1 # the service status
  --body-from: string # format: date-time
  --until: string # format: date-time
]: any -> record<id: string, service: record<id: float, name: string, alias: string, status: string, description: string, oneOpenIncidentOnly: bool, showUptimeHistory: bool, teams: list<record>>, status: string, from: string, until: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/service-outages/overrides/($id)")
  let body = {id: $body_id, service: $service, status: $status, from: $body_from, until: $until} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a service outage override
#
# DELETE /service-outages/overrides/{id}
export def "service-outages-overrides delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/service-outages/overrides/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Metric Data Sources
#
# GET /metric-data-sources
export def "metric-data-sources list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of metric data sources (format: int32, default: 10)
]: nothing -> table<id: float, name: string, type: string, teams: list<record>, metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metric-data-sources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Metric Data Source.
#
# POST /metric-data-sources
# --teams item shape: {id?: int, name?: string}
# --metadata shape: {region?: string, apiKey?: string, applicationKey?: string, url?: string, authType?: "NONE"|"BASIC"|"HEADER", basicUser?: string, basicPass?: string, headerKey?: string, headerValue?: string}
export def "metric-data-sources post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  type: string@type-completer-6
  --teams: list # item shape: {id?: int, name?: string}
  metadata: record # shape: {region?: string, apiKey?: string, applicationKey?: string, url?: string, authType?: "NONE"|"BASIC"|"HEADER", basicUser?: string, basicPass?: string, headerKey?: string, headerValue?: string}
]: any -> record<id: float, name: string, type: string, teams: table<id: int, name: string>, metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metric-data-sources")
  let body = {name: $name, type: $type, teams: $teams, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific Metric Data Source
#
# GET /metric-data-sources/{id}
export def "metric-data-sources get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: float, name: string, type: string, teams: table<id: int, name: string>, metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metric-data-sources/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the specific Metric Data Source
#
# PUT /metric-data-sources/{id}
# --teams item shape: {id?: int, name?: string}
# --metadata shape: {region?: string, apiKey?: string, applicationKey?: string, url?: string, authType?: "NONE"|"BASIC"|"HEADER", basicUser?: string, basicPass?: string, headerKey?: string, headerValue?: string}
export def "metric-data-sources put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  type: string@type-completer-6
  --teams: list # item shape: {id?: int, name?: string}
  metadata: record # shape: {region?: string, apiKey?: string, applicationKey?: string, url?: string, authType?: "NONE"|"BASIC"|"HEADER", basicUser?: string, basicPass?: string, headerKey?: string, headerValue?: string}
]: any -> record<id: float, name: string, type: string, teams: table<id: int, name: string>, metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metric-data-sources/($id)")
  let body = {name: $name, type: $type, teams: $teams, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a specific Metric Data Source
#
# DELETE /metric-data-sources/{id}
export def "metric-data-sources delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metric-data-sources/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get metrics.
#
# GET /metrics
export def "metrics list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of metrics. (Note: when using ?include maximum is reduced to 25) (format: int32, default: 10)
  --include: list # Describes optional properties that should be included in the response. You may declare multiple. (dataSource, integrationKey)
]: nothing -> table<id: float, name: string, description: string, aggregationType: string, displayType: string, interpolateGaps: bool, lockYAxisMax: float, lockYAxisMin: float, mouseOverDecimal: float, showValuesOnMouseOver: bool, teams: list<record>, unitLabel: string, integrationKey: string, dataSource: record<id: float, name: string, type: string, teams: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new metric.
#
# POST /metrics
# --teams item shape: {id?: int, name?: string}
# --metadata shape: {query?: string}
# --dataSource shape: {id?: float}
export def "metrics post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --description: string
  aggregationType: string@aggregationType-completer
  displayType: string@displayType-completer
  --interpolateGaps: string@bool-completer # default: false
  --lockYAxisMax: float # format: double
  --lockYAxisMin: float # format: double
  --mouseOverDecimal: float # format: int32
  --showValuesOnMouseOver: string@bool-completer # default: false
  --teams: list # item shape: {id?: int, name?: string}
  --unitLabel: string
  --metadata: record # Only required if the metric has a dataSource. You may not change this after creation. (default: null) — shape: {query?: string}
  --dataSource: record # shape: {id?: float}
]: any -> record<id: float, name: string, description: string, aggregationType: string, displayType: string, interpolateGaps: bool, lockYAxisMax: float, lockYAxisMin: float, mouseOverDecimal: float, showValuesOnMouseOver: bool, teams: table<id: int, name: string>, unitLabel: string, integrationKey: string, metadata: record, dataSource: record<id: float, name: string, type: string, teams: list<record>, metadata: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics")
  let body = {name: $name, description: $description, aggregationType: $aggregationType, displayType: $displayType, interpolateGaps: $interpolateGaps, lockYAxisMax: $lockYAxisMax, lockYAxisMin: $lockYAxisMin, mouseOverDecimal: $mouseOverDecimal, showValuesOnMouseOver: $showValuesOnMouseOver, teams: $teams, unitLabel: $unitLabel, metadata: $metadata, dataSource: $dataSource} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific Metric
#
# GET /metrics/{id}
export def "metrics get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: float, name: string, description: string, aggregationType: string, displayType: string, interpolateGaps: bool, lockYAxisMax: float, lockYAxisMin: float, mouseOverDecimal: float, showValuesOnMouseOver: bool, teams: table<id: int, name: string>, unitLabel: string, integrationKey: string, metadata: record, dataSource: record<id: float, name: string, type: string, teams: list<record>, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metrics/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the specific Metric
#
# PUT /metrics/{id}
# --teams item shape: {id?: int, name?: string}
# --metadata shape: {query?: string}
# --dataSource shape: {id?: float}
export def "metrics put" [
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
  aggregationType: string@aggregationType-completer
  displayType: string@displayType-completer
  --interpolateGaps: string@bool-completer # default: false
  --lockYAxisMax: float # format: double
  --lockYAxisMin: float # format: double
  --mouseOverDecimal: float # format: int32
  --showValuesOnMouseOver: string@bool-completer # default: false
  --teams: list # item shape: {id?: int, name?: string}
  --unitLabel: string
  --metadata: record # Only required if the metric has a dataSource. You may not change this after creation. (default: null) — shape: {query?: string}
  --dataSource: record # shape: {id?: float}
]: any -> record<id: float, name: string, description: string, aggregationType: string, displayType: string, interpolateGaps: bool, lockYAxisMax: float, lockYAxisMin: float, mouseOverDecimal: float, showValuesOnMouseOver: bool, teams: table<id: int, name: string>, unitLabel: string, integrationKey: string, metadata: record, dataSource: record<id: float, name: string, type: string, teams: list<record>, metadata: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metrics/($id)")
  let body = {name: $name, description: $description, aggregationType: $aggregationType, displayType: $displayType, interpolateGaps: $interpolateGaps, lockYAxisMax: $lockYAxisMax, lockYAxisMin: $lockYAxisMin, mouseOverDecimal: $mouseOverDecimal, showValuesOnMouseOver: $showValuesOnMouseOver, teams: $teams, unitLabel: $unitLabel, metadata: $metadata, dataSource: $dataSource} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the specific Metric
#
# DELETE /metrics/{id}
export def "metrics delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metrics/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get deployment pipelines
#
# GET /deployment-pipelines
export def "deployment-pipelines list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of deployment pipelines (format: int32, default: 50)
]: nothing -> table<id: int, name: string, integrationType: string, integrationKey: string, teams: list<record>, createdAt: string, updatedAt: string, params: record, integrationUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deployment-pipelines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new deployment pipeline.
#
# POST /deployment-pipelines
# --teams item shape: {id?: int, name?: string}
# --params shape: {branchFilters?: list, eventFilters?: list}
export def "deployment-pipelines post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int64
  name: string
  integrationType: string
  --integrationKey: string
  --teams: list # item shape: {id?: int, name?: string}
  --params: record # Dynamic params based on the chosen integration type of the pipeline (default: null) — shape: {branchFilters?: list, eventFilters?: list}
  --integrationUrl: string
]: any -> record<id: int, name: string, integrationType: string, integrationKey: string, teams: table<id: int, name: string>, createdAt: string, updatedAt: string, params: record, integrationUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deployment-pipelines")
  let body = {id: $id, name: $name, integrationType: $integrationType, integrationKey: $integrationKey, teams: $teams, params: $params, integrationUrl: $integrationUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific deployment pipeline
#
# GET /deployment-pipelines/{id}
export def "deployment-pipelines get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, integrationType: string, integrationKey: string, teams: table<id: int, name: string>, createdAt: string, updatedAt: string, params: record, integrationUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployment-pipelines/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the specific deployment pipeline
#
# PUT /deployment-pipelines/{id}
# --teams item shape: {id?: int, name?: string}
# --params shape: {branchFilters?: list, eventFilters?: list}
export def "deployment-pipelines put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: int # format: int64
  name: string
  integrationType: string
  --integrationKey: string
  --teams: list # item shape: {id?: int, name?: string}
  --params: record # Dynamic params based on the chosen integration type of the pipeline (default: null) — shape: {branchFilters?: list, eventFilters?: list}
  --integrationUrl: string
]: any -> record<id: int, name: string, integrationType: string, integrationKey: string, teams: table<id: int, name: string>, createdAt: string, updatedAt: string, params: record, integrationUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployment-pipelines/($id)")
  let body = {id: $body_id, name: $name, integrationType: $integrationType, integrationKey: $integrationKey, teams: $teams, params: $params, integrationUrl: $integrationUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a specific deployment pipeline
#
# DELETE /deployment-pipelines/{id}
export def "deployment-pipelines delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployment-pipelines/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List existing event flows.
#
# GET /event-flows
export def "event-flows list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of entities. (format: int32, default: 50)
]: nothing -> table<id: int, name: string, teams: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/event-flows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new event flow.
#
# POST /event-flows
# --teams item shape: {id?: int, name?: string}
# --root shape: {id?: int, name?: string, nodeType: "ROOT"|"SUPPORT_HOURS"|"ROUTE_EVENT"|"DEFINE_BRANCHES"|"WAIT"|"TRANSFORM", metadata?: any, branches?: list}
export def "event-flows post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int64
  name: string
  --teams: list # item shape: {id?: int, name?: string}
  root: record # shape: {id?: int, name?: string, nodeType: "ROOT"|"SUPPORT_HOURS"|"ROUTE_EVENT"|"DEFINE_BRANCHES"|"WAIT"|"TRANSFORM", metadata?: any, branches?: list}
]: any -> record<id: int, name: string, teams: table<id: int, name: string>, root: record<id: int, name: string, nodeType: string, metadata: any, branches: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/event-flows")
  let body = {id: $id, name: $name, teams: $teams, root: $root} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific event flow.
#
# GET /event-flows/{id}
export def "event-flows get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, teams: table<id: int, name: string>, root: record<id: int, name: string, nodeType: string, metadata: any, branches: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event-flows/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a specific event flow.
#
# PUT /event-flows/{id}
# --teams item shape: {id?: int, name?: string}
# --root shape: {id?: int, name?: string, nodeType: "ROOT"|"SUPPORT_HOURS"|"ROUTE_EVENT"|"DEFINE_BRANCHES"|"WAIT"|"TRANSFORM", metadata?: any, branches?: list}
export def "event-flows put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: int # format: int64
  name: string
  --teams: list # item shape: {id?: int, name?: string}
  root: record # shape: {id?: int, name?: string, nodeType: "ROOT"|"SUPPORT_HOURS"|"ROUTE_EVENT"|"DEFINE_BRANCHES"|"WAIT"|"TRANSFORM", metadata?: any, branches?: list}
]: any -> record<id: int, name: string, teams: table<id: int, name: string>, root: record<id: int, name: string, nodeType: string, metadata: any, branches: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event-flows/($id)")
  let body = {id: $body_id, name: $name, teams: $teams, root: $root} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a specific event flow.
#
# DELETE /event-flows/{id}
export def "event-flows delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event-flows/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List existing call flows.
#
# GET /call-flows
export def "call-flows list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of entities. (format: int32, default: 50)
]: nothing -> table<id: int, name: string, assignedNumber: record<id: int, name: string, phoneNumber: record>, teams: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/call-flows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new call flow.
#
# POST /call-flows
# --assignedNumber shape: {id?: int, name?: string, phoneNumber?: record}
# --teams item shape: {id?: int, name?: string}
# --root shape: {id?: int, name?: string, nodeType: "ROOT"|"IVR_MENU"|"AUDIO_MESSAGE"|"SUPPORT_HOURS"|"ROUTE_CALL"|"PARALLEL_ROUTE_CALL"|"VOICEMAIL"|"PIN_CODE"|"CREATE_ALERT"|"BLOCK_NUMBERS"|"AGENTIC", metadata?: any, branches?: list}
export def "call-flows post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int64
  name: string
  language: string@language-completer
  --assignedNumber: record # shape: {id?: int, name?: string, phoneNumber?: record}
  --teams: list # item shape: {id?: int, name?: string}
  root: record # shape: {id?: int, name?: string, nodeType: "ROOT"|"IVR_MENU"|"AUDIO_MESSAGE"|"SUPPORT_HOURS"|"ROUTE_CALL"|"PARALLEL_ROUTE_CALL"|"VOICEMAIL"|"PIN_CODE"|"CREATE_ALERT"|"BLOCK_NUMBERS"|"AGENTIC", metadata?: any, branches?: list}
]: any -> record<id: int, name: string, language: string, assignedNumber: record<id: int, name: string, phoneNumber: record<regionCode: string, number: string>>, teams: table<id: int, name: string>, root: record<id: int, name: string, nodeType: string, metadata: any, branches: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/call-flows")
  let body = {id: $id, name: $name, language: $language, assignedNumber: $assignedNumber, teams: $teams, root: $root} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific call flow.
#
# GET /call-flows/{id}
export def "call-flows get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, language: string, assignedNumber: record<id: int, name: string, phoneNumber: record<regionCode: string, number: string>>, teams: table<id: int, name: string>, root: record<id: int, name: string, nodeType: string, metadata: any, branches: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/call-flows/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a specific call flow.
#
# PUT /call-flows/{id}
# --assignedNumber shape: {id?: int, name?: string, phoneNumber?: record}
# --teams item shape: {id?: int, name?: string}
# --root shape: {id?: int, name?: string, nodeType: "ROOT"|"IVR_MENU"|"AUDIO_MESSAGE"|"SUPPORT_HOURS"|"ROUTE_CALL"|"PARALLEL_ROUTE_CALL"|"VOICEMAIL"|"PIN_CODE"|"CREATE_ALERT"|"BLOCK_NUMBERS"|"AGENTIC", metadata?: any, branches?: list}
export def "call-flows put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: int # format: int64
  name: string
  language: string@language-completer
  --assignedNumber: record # shape: {id?: int, name?: string, phoneNumber?: record}
  --teams: list # item shape: {id?: int, name?: string}
  root: record # shape: {id?: int, name?: string, nodeType: "ROOT"|"IVR_MENU"|"AUDIO_MESSAGE"|"SUPPORT_HOURS"|"ROUTE_CALL"|"PARALLEL_ROUTE_CALL"|"VOICEMAIL"|"PIN_CODE"|"CREATE_ALERT"|"BLOCK_NUMBERS"|"AGENTIC", metadata?: any, branches?: list}
]: any -> record<id: int, name: string, language: string, assignedNumber: record<id: int, name: string, phoneNumber: record<regionCode: string, number: string>>, teams: table<id: int, name: string>, root: record<id: int, name: string, nodeType: string, metadata: any, branches: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/call-flows/($id)")
  let body = {id: $body_id, name: $name, language: $language, assignedNumber: $assignedNumber, teams: $teams, root: $root} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a specific call flow.
#
# DELETE /call-flows/{id}
export def "call-flows delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/call-flows/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List call flow numbers.
#
# GET /call-flow-numbers
export def "call-flow-numbers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --state: string@state-completer-1 # Filter call flow numbers by availability state. (default: ANY)
  --include: list # Describes optional properties that should be included in the response. You may declare multiple. (assignedTo)
  --start-index: int # an integer specifying the starting point (beginning with 0) when paging through a list of entities (format: int32, default: 0)
  --max-results: int # the maximum number of results when paging through a list of entities. (format: int32, default: 50)
  --qp-query: string # Filter call flow numbers by name.
]: nothing -> table<id: int, name: string, state: string, phoneNumber: record<regionCode: string, number: string>, assignedTo: record<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "include" $include "multi") (serialize-qp "start-index" $start_index "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/call-flow-numbers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific call flow number.
#
# GET /call-flow-numbers/{id}
export def "call-flow-numbers get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, state: string, phoneNumber: record<regionCode: string, number: string>, assignedTo: record<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/call-flow-numbers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
