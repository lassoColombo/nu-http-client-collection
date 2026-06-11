# Auto-generated client for Opsgenie REST API v2.0.0
# Source: https://raw.githubusercontent.com/opsgenie/opsgenie-oas/master/swagger.json
# Auth: --token flag or $env.OPSGENIE_REST_API_TOKEN

const BASE_URL = "https://api.opsgenie.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPSGENIE_REST_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://api.opsgenie.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def searchIdentifierType-completer [] { ["id" "name"] }
def sort-completer [] { ["acknowledged" "alias" "count" "createdAt" "integration.name" "integration.type" "isSeen" "lastOccurredAt" "message" "owner" "report.ackTime" "report.acknowledgedBy" "report.closeTime" "report.closedBy" "snoozed" "snoozedUntil" "source" "status" "tinyId" "updatedAt"] }
def order-completer [] { ["asc" "desc"] }
def priority-completer [] { ["P1" "P2" "P3" "P4" "P5"] }
def identifierType-completer [] { ["alias" "id" "tiny"] }
def direction-completer [] { ["next" "prev"] }
def alertIdentifierType-completer [] { ["alias" "id" "tiny"] }
def identifierType-completer-1 [] { ["id" "name"] }
def type-completer [] { ["API" "Airbrake" "AlertLogic" "AlertSite" "AmazonCloudTrail" "AmazonEc2AutoScaling" "AmazonRds" "AmazonRoute53HealthCheck" "AmazonSecurityHub" "AmazonSes" "AmazonSns" "AmazonSnsOutgoing" "Apica" "Apimetrics" "AppDynamics" "AppOptics" "AppSignal" "AppSignalV2" "Atatus" "AtlassianBambooEmail" "AutoTaskEmail" "AutotaskAEMEmail" "Azure" "AzureAutoScale" "AzureOMS" "AzureResourceHealth" "AzureServiceHealth" "BMCFootPrintsV11" "BMCFootPrintsV12" "BMCRemedy" "BMCRemedyForce" "BMCRemedyOnDemand" "BigPanda" "Bitbucket" "BlueMatador" "Boundary" "Campfire" "Catchpoint" "CheckMK" "Cherwell" "CircleCi" "Circonus" "CloudMonix" "CloudSploit" "CloudWatch" "CloudWatchEvents" "Codeship" "Compose" "ConnectWise" "ConnectWiseAutomate" "ConnectWiseManage" "ConnectWiseManageV2" "Consul" "CopperEgg" "Crashlytics" "DNSCheck" "Datadog" "DataloopIO" "Desk" "Detectify" "DripStat" "DynatraceAppMon" "DynatraceV2" "ESWatcher" "Email" "Errorception" "EvidentIO" "Flock" "Flowdock" "FlowdockV2" "Freshdesk" "Freshservice" "GhostInspector" "GitHub" "GitLab" "GoogleStackdriver" "Grafana" "GrafanaV2" "Graylog" "HPServiceManager" "Heartbeat" "HipChat" "HipChatAddOn" "HipChatV2" "Honeybadger" "HostedGraphite" "Humio" "Icinga" "Icinga2" "IncomingCall" "Instana" "Jenkins" "Jira" "JiraServiceDesk" "Kapacitor" "Kayako" "Kore" "LabTechEmail" "Librato" "LibreNMS" "Lightstep" "Logentries" "Loggly" "LogicMonitor" "Logstash" "LogzIO" "Looker" "Loom" "MSTeams" "MSTeamsV2" "Magentrix" "ManageEngine" "Marid" "Mattermost" "MongoDBCloud" "Monitis" "MonitisEmail" "Moxtra" "Nagios" "NagiosV2" "NagiosXI" "NagiosXIV2" "Netuitive" "NeustarEmail" "NewRelic" "NewRelicV2" "NodePing" "OEC" "OEM" "OEMEmail" "OP5" "Observium" "ObserviumV2" "OpsDash" "OpsGenie" "Opsview" "PagerDutyCompatibility" "Panopta" "Papertrail" "Pingdom" "PingdomV2" "PingdomWebhook" "Pingometer" "Planio" "Prometheus" "Prtg" "Rackspace" "Raygun" "RedGateSqlMonitorEmail" "Riemann" "Rigor" "RingCentralEmail" "RingCentralGlip" "Rollbar" "Runscope" "Ruxit" "SCOM" "SalesForceServiceCloud" "SaltStack" "Scalyr" "Scout" "SematextSpm" "Sensu" "Sentry" "ServerDensity" "ServerGuard24" "ServiceNow" "ServiceNowV2" "ServiceNowV3" "SignalFXV2" "SignalSciences" "Signalfx" "Site24x7" "Slack" "SlackApp" "Soasta" "SolarWindsWebHelpDesk" "Solarwinds" "SolarwindsMSPNCentral" "Splunk" "SplunkITSI" "StackStorm" "Stackdriver" "StatusCake" "StatusHub" "StatusIO" "StatusPageIO" "Statusy" "StruxureWare" "SumoLogic" "SysdigCloud" "ThousandEyes" "ThreatStack" "Thundra" "Tideways" "Trace" "TrackIt" "TravisCI" "Twilio" "UpdownIO" "UptimeRobot" "UptimeRobotEmail" "UptimeWebhook" "UptrendsEmail" "VCSA" "VCenter" "VividCortex" "Wavefront" "Webhook" "WhatsUpGold" "Workato" "XLRelease" "Xmpp" "Zabbix" "Zapier" "Zendesk" "Zenoss" "ZyrionEmail"] }
def type-completer-1 [] { ["API" "Airbrake" "AlertLogic" "AlertSite" "AmazonCloudTrail" "AmazonEc2AutoScaling" "AmazonRds" "AmazonRoute53HealthCheck" "AmazonSecurityHub" "AmazonSes" "AmazonSns" "AmazonSnsOutgoing" "Apica" "Apimetrics" "AppDynamics" "AppOptics" "AppSignal" "AppSignalV2" "Atatus" "AtlassianBambooEmail" "AutoTaskEmail" "AutotaskAEMEmail" "Azure" "AzureAutoScale" "AzureOMS" "AzureResourceHealth" "AzureServiceHealth" "BMCFootPrintsV11" "BMCFootPrintsV12" "BMCRemedy" "BMCRemedyForce" "BMCRemedyOnDemand" "BigPanda" "Bitbucket" "BlueMatador" "Boundary" "Campfire" "Catchpoint" "CheckMK" "Cherwell" "CircleCi" "Circonus" "CloudMonix" "CloudSploit" "CloudWatch" "CloudWatchEvents" "Codeship" "Compose" "ConnectWise" "ConnectWiseAutomate" "ConnectWiseManage" "ConnectWiseManageV2" "Consul" "CopperEgg" "Crashlytics" "DNSCheck" "Datadog" "DataloopIO" "Desk" "Detectify" "DripStat" "DynatraceAppMon" "DynatraceV2" "ESWatcher" "Email" "Errorception" "EvidentIO" "Flock" "Flowdock" "FlowdockV2" "Freshdesk" "Freshservice" "GhostInspector" "GitHub" "GitLab" "GoogleStackdriver" "Grafana" "GrafanaV2" "Graylog" "HPServiceManager" "Heartbeat" "HipChat" "HipChatAddOn" "HipChatV2" "Honeybadger" "HostedGraphite" "Humio" "Icinga" "Icinga2" "IncomingCall" "Instana" "Jenkins" "Jira" "JiraServiceDesk" "Kapacitor" "Kayako" "Kore" "LabTechEmail" "Librato" "LibreNMS" "Lightstep" "Logentries" "Loggly" "LogicMonitor" "Logstash" "LogzIO" "Looker" "Loom" "MSTeams" "MSTeamsV2" "Magentrix" "ManageEngine" "Marid" "Mattermost" "MongoDBCloud" "Monitis" "MonitisEmail" "Moxtra" "Nagios" "NagiosV2" "NagiosXI" "NagiosXIV2" "Netuitive" "NeustarEmail" "NewRelic" "NewRelicSyntheticsEmail" "NewRelicV2" "NodePing" "OEC" "OEM" "OEMEmail" "OP5" "Observium" "ObserviumV2" "OpsDash" "OpsGenie" "Opsview" "PagerDutyCompatibility" "Panopta" "Papertrail" "Pingdom" "PingdomV2" "PingdomWebhook" "Pingometer" "Planio" "Prometheus" "Prtg" "Rackspace" "Raygun" "RedGateSqlMonitorEmail" "Riemann" "Rigor" "RingCentralEmail" "RingCentralGlip" "Rollbar" "Runscope" "Ruxit" "SCOM" "SalesForceServiceCloud" "SaltStack" "Scalyr" "Scout" "SematextSpm" "Sensu" "Sentry" "ServerDensity" "ServerGuard24" "ServiceNow" "ServiceNowV2" "ServiceNowV3" "SignalFXV2" "SignalSciences" "Signalfx" "Site24x7" "Slack" "SlackApp" "Soasta" "SolarWindsWebHelpDesk" "Solarwinds" "SolarwindsMSPNCentral" "Splunk" "SplunkITSI" "StackStorm" "Stackdriver" "StatusCake" "StatusHub" "StatusIO" "StatusPageIO" "Statusy" "StruxureWare" "SumoLogic" "SysdigCloud" "ThousandEyes" "ThreatStack" "Thundra" "Tideways" "Trace" "TrackIt" "TravisCI" "Twilio" "UpdownIO" "UptimeRobot" "UptimeRobotEmail" "UptimeWebhook" "UptrendsEmail" "VCSA" "VCenter" "VividCortex" "Wavefront" "Webhook" "WhatsUpGold" "Workato" "XLRelease" "Xmpp" "Zabbix" "Zapier" "Zendesk" "Zenoss" "ZyrionEmail"] }
def type-completer-2 [] { ["acknowledge" "addNote" "close" "create" "ignore"] }
def intervalUnit-completer [] { ["days" "hours" "minutes"] }
def alertPriority-completer [] { ["P1" "P2" "P3" "P4" "P5"] }
def type-completer-3 [] { ["auto-close" "auto-restart-notifications" "modify" "notification-deduplication" "notification-delay" "notification-renotify" "notification-suppress"] }
def type-completer-4 [] { ["all" "non-expired" "past"] }
def method-completer [] { ["email" "mobile" "sms" "voice"] }
def actionType-completer [] { ["acknowledged-alert" "add-note" "assigned-alert" "closed-alert" "create-alert" "incoming-call-routing" "renotified-alert" "schedule-end" "schedule-start"] }
def teamIdentifierType-completer [] { ["id" "name"] }
def intervalUnit-completer-1 [] { ["days" "months" "weeks"] }
def scheduleIdentifierType-completer [] { ["id" "name"] }
def type-completer-5 [] { ["daily" "hourly" "weekly"] }
def identifierType-completer-2 [] { ["alias" "id"] }
def type-completer-6 [] { ["alert" "notification"] }
def identifierType-completer-3 [] { ["id" "tiny"] }
def sort-completer-1 [] { ["createdAt" "isSeen" "message" "owner" "status" "tinyId"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "alerts-requests get" } } | get name | first)
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

# Get Request Status of Alert
#
# GET /v2/alerts/requests/{requestId}
# Docs: https://www.opsgenie.com/docs/alert-api#section-get-request-status — For more information
# operationId: getRequestStatus
export def "alerts-requests get" [
  requestId: string
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
  let full_url = (build-url $base $"/v2/alerts/requests/($requestId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Alerts
#
# GET /v2/alerts
# Docs: https://www.opsgenie.com/docs/alert-api#section-list-alerts — For more information
# operationId: listAlerts
export def "alerts listAlerts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Search query to apply while filtering the alerts
  --searchIdentifier: string # Identifier of the saved search query to apply while filtering the alerts
  --searchIdentifierType: string@searchIdentifierType-completer # Identifier type of the saved search query. Possible values are 'id', or 'name' (default: id)
  --offset: int # Start index of the result set (to apply pagination). Minimum value (and also default value) is 0 (format: int32)
  --limit: int # Maximum number of items to provide in the result. Must be a positive integer value. Default value is 20 and maximum value is 100 (format: int32)
  --qp-sort: string@sort-completer # Name of the field that result set will be sorted by (default: createdAt)
  --order: string@order-completer # Sorting order of the result set (default: desc)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "searchIdentifier" $searchIdentifier "scalar") (serialize-qp "searchIdentifierType" $searchIdentifierType "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/alerts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Alert
#
# POST /v2/alerts
# Docs: https://www.opsgenie.com/docs/alert-api#section-create-alert — For more information
# operationId: createAlert
# --responders item shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string}
# --visibleTo item shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string}
export def "alerts createAlert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user: string # Display name of the request owner
  --note: string # Additional note that will be added while creating the alert
  --body-source: string # Source field of the alert. Default value is IP address of the incoming request
  message: string # Message of the alert
  --alias: string # Client-defined identifier of the alert, that is also the key element of alert deduplication.
  --description: string # Description field of the alert that is generally used to provide a detailed information about the alert.
  --responders: list # Responders that the alert will be routed to send notifications — item shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string}
  --visibleTo: list # Teams and users that the alert will become visible to without sending any notification — item shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string}
  --actions: list # Custom actions that will be available for the alert
  --tags: list # Tags of the alert
  --details: record # Map of key-value pairs to use as custom properties of the alert
  --entity: string # Entity field of the alert that is generally used to specify which domain alert is related to
  --priority: string@priority-completer # Priority level of the alert
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/alerts")
  let body = {user: $user, note: $note, source: $body_source, message: $message, alias: $alias, description: $description, responders: $responders, visibleTo: $visibleTo, actions: $actions, tags: $tags, details: $details, entity: $entity, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Alert
#
# GET /v2/alerts/{identifier}
# Docs: https://www.opsgenie.com/docs/alert-api#section-get-alert — For more information
# operationId: getAlert
export def "alerts get" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Alert
#
# DELETE /v2/alerts/{identifier}
# Docs: https://www.opsgenie.com/docs/alert-api#section-delete-alert — For more information
# operationId: deleteAlert
export def "alerts delete" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
  --user: string # Display name of the request owner
  --qp-source: string # Display name of the request source
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Acknowledge Alert
#
# POST /v2/alerts/{identifier}/acknowledge
# Docs: https://www.opsgenie.com/docs/alert-api#section-acknowledge-alert — For more information
# operationId: acknowledgeAlert
export def "alerts-acknowledge acknowledgeAlert" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
  --user: string # Display name of the request owner
  --note: string # Additional note that will be added while creating the alert
  --body-source: string # Source field of the alert. Default value is IP address of the incoming request
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/acknowledge" $qp)
  let body = {user: $user, note: $note, source: $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# UnAcknowledge Alert
#
# POST /v2/alerts/{identifier}/unacknowledge
# Docs: https://www.opsgenie.com/docs/alert-api#section-unacknowledge-alert — For more information
# operationId: unAcknowledgeAlert
export def "alerts-unacknowledge unAcknowledgeAlert" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
  --user: string # Display name of the request owner
  --note: string # Additional note that will be added while creating the alert
  --body-source: string # Source field of the alert. Default value is IP address of the incoming request
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/unacknowledge" $qp)
  let body = {user: $user, note: $note, source: $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Close Alert
#
# POST /v2/alerts/{identifier}/close
# Docs: https://www.opsgenie.com/docs/alert-api#section-close-alert — For more information
# operationId: closeAlert
export def "alerts-close closeAlert" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
  --user: string # Display name of the request owner
  --note: string # Additional note that will be added while creating the alert
  --body-source: string # Source field of the alert. Default value is IP address of the incoming request
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/close" $qp)
  let body = {user: $user, note: $note, source: $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Snooze Alert
#
# POST /v2/alerts/{identifier}/snooze
# Docs: https://www.opsgenie.com/docs/alert-api#section-snooze-alert — For more information
# operationId: snoozeAlert
export def "alerts-snooze snoozeAlert" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
  --user: string # Display name of the request owner
  --note: string # Additional note that will be added while creating the alert
  --body-source: string # Source field of the alert. Default value is IP address of the incoming request
  endTime: string # Date and time that snooze will lose effect (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/snooze" $qp)
  let body = {user: $user, note: $note, source: $body_source, endTime: $endTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Escalate Alert
#
# POST /v2/alerts/{identifier}/escalate
# Docs: https://www.opsgenie.com/docs/alert-api#section-escalate-alert-to-next — For more information
# operationId: escalateAlert
export def "alerts-escalate escalateAlert" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
  --user: string # Display name of the request owner
  --note: string # Additional note that will be added while creating the alert
  --body-source: string # Source field of the alert. Default value is IP address of the incoming request
  escalation: any # Escalation recipient
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/escalate" $qp)
  let body = {user: $user, note: $note, source: $body_source, escalation: $escalation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign Alert
#
# POST /v2/alerts/{identifier}/assign
# Docs: https://www.opsgenie.com/docs/alert-api#section-assign-alert — For more information
# operationId: assignAlert
export def "alerts-assign assignAlert" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
  --user: string # Display name of the request owner
  --note: string # Additional note that will be added while creating the alert
  --body-source: string # Source field of the alert. Default value is IP address of the incoming request
  owner: any # User recipient
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/assign" $qp)
  let body = {user: $user, note: $note, source: $body_source, owner: $owner} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Responder
#
# POST /v2/alerts/{identifier}/responders
# Docs: https://www.opsgenie.com/docs/alert-api#section-add-responder-to-alert — For more information
# operationId: addResponder
# --responder shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string}
export def "alerts-responders addResponder" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
  --user: string # Display name of the request owner
  --note: string # Additional note that will be added while creating the alert
  --body-source: string # Source field of the alert. Default value is IP address of the incoming request
  responder: record # shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/responders" $qp)
  let body = {user: $user, note: $note, source: $body_source, responder: $responder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Team
#
# POST /v2/alerts/{identifier}/teams
# Docs: https://www.opsgenie.com/docs/alert-api#section-add-team-to-alert — For more information
# operationId: addTeam
export def "alerts-teams addTeam" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
  --user: string # Display name of the request owner
  --note: string # Additional note that will be added while creating the alert
  --body-source: string # Source field of the alert. Default value is IP address of the incoming request
  team: any # Team recipient
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/teams" $qp)
  let body = {user: $user, note: $note, source: $body_source, team: $team} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Custom Alert Action
#
# POST /v2/alerts/{identifier}/actions/{actionName}
# Docs: https://www.opsgenie.com/docs/alert-api#section-execute-custom-action — For more information
# operationId: executeCustomAlertAction
export def "alerts-actions executeCustomAlertAction" [
  identifier: string
  actionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
  --user: string # Display name of the request owner
  --note: string # Additional note that will be added while creating the alert
  --body-source: string # Source field of the alert. Default value is IP address of the incoming request
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/actions/($actionName)" $qp)
  let body = {user: $user, note: $note, source: $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Alert Recipients
#
# GET /v2/alerts/{identifier}/recipients
# Docs: https://www.opsgenie.com/docs/alert-api#section-list-alert-recipients — For more information
# operationId: listRecipients
export def "alerts-recipients listRecipients" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/recipients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Alert Logs
#
# GET /v2/alerts/{identifier}/logs
# Docs: https://www.opsgenie.com/docs/alert-api#section-list-alert-logs — For more information
# operationId: listLogs
export def "alerts-logs listLogs" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
  --offset: string # Starting value of the offset property
  --direction: string@direction-completer # Page direction to apply for the given offset with 'next' and 'prev' (default: next)
  --limit: int # Maximum number of items to provide in the result. Must be a positive integer value. Default value is 20 and maximum value is 100 (format: int32)
  --order: string@order-completer # Sorting order of the result set (default: desc)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Alert Attachments
#
# GET /v2/alerts/{identifier}/attachments
# Docs: https://www.opsgenie.com/docs/alert-api#section-list-alert-attachments — For more information
# operationId: listAttachments
export def "alerts-attachments listAttachments" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alertIdentifierType: string@alertIdentifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alertIdentifierType" $alertIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/attachments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Alert Attachment
#
# POST /v2/alerts/{identifier}/attachments
# Docs: https://www.opsgenie.com/docs/alert-api#section-create-alert-attachment — For more information
# operationId: addAttachment
export def "alerts-attachments addAttachment" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alertIdentifierType: string@alertIdentifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
  file: path # Attachment file to be uploaded
  --user: string # Display name of the request owner
  --indexFile: string # Name of html file which will be shown when attachment clicked on UI
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alertIdentifierType" $alertIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/attachments" $qp)
  let body = {file: $file, user: $user, indexFile: $indexFile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($file | is-not-empty) { $body | upsert file (open -r $file) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get Alert Attachment
#
# GET /v2/alerts/{identifier}/attachments/{attachmentId}
# Docs: https://www.opsgenie.com/docs/alert-api#section-get-alert-attachment — For more information
# operationId: getAttachment
export def "alerts-attachments get" [
  identifier: string
  attachmentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alertIdentifierType: string@alertIdentifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alertIdentifierType" $alertIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/attachments/($attachmentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove Alert Attachment
#
# DELETE /v2/alerts/{identifier}/attachments/{attachmentId}
# Docs: https://www.opsgenie.com/docs/alert-api#section-delete-alert-attachment — For more information
# operationId: removeAttachment
export def "alerts-attachments removeAttachment" [
  identifier: string
  attachmentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alertIdentifierType: string@alertIdentifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
  --user: string # Display name of the request owner
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alertIdentifierType" $alertIdentifierType "scalar") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/attachments/($attachmentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Tags
#
# POST /v2/alerts/{identifier}/tags
# Docs: https://www.opsgenie.com/docs/alert-api#section-add-tags-to-alert — For more information
# operationId: addTags
export def "alerts-tags addTags" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
  --user: string # Display name of the request owner
  --note: string # Additional note that will be added while creating the alert
  --body-source: string # Source field of the alert. Default value is IP address of the incoming request
  tags: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/tags" $qp)
  let body = {user: $user, note: $note, source: $body_source, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Tags
#
# DELETE /v2/alerts/{identifier}/tags
# Docs: https://www.opsgenie.com/docs/alert-api#section-remove-tags-from-alert — For more information
# operationId: removeTags
export def "alerts-tags removeTags" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
  --user: string # Display name of the request owner
  --note: string # Additional alert note to add
  --qp-source: string # Display name of the request source
  --tags: list # Tags field of the given alert as comma seperated values (e.g. 'tag1, tag2')
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "note" $note "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "tags" $tags "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Details
#
# POST /v2/alerts/{identifier}/details
# Docs: https://www.opsgenie.com/docs/alert-api#section-add-details-custom-properties-to-alert — For more information
# operationId: addDetails
export def "alerts-details addDetails" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
  --user: string # Display name of the request owner
  --note: string # Additional note that will be added while creating the alert
  --body-source: string # Source field of the alert. Default value is IP address of the incoming request
  details: record # Key-value pairs to add as custom property into alert.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/details" $qp)
  let body = {user: $user, note: $note, source: $body_source, details: $details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Details
#
# DELETE /v2/alerts/{identifier}/details
# Docs: https://www.opsgenie.com/docs/alert-api#section-remove-details-custom-properties-from-alert — For more information
# operationId: removeDetails
export def "alerts-details removeDetails" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
  --user: string # Display name of the request owner
  --note: string # Additional alert note to add
  --qp-source: string # Display name of the request source
  --keys: list # Comma separated list of keys to remove from the custom properties of the alert (e.g. 'key1,key2')
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "note" $note "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "keys" $keys "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Alert Notes
#
# GET /v2/alerts/{identifier}/notes
# Docs: https://www.opsgenie.com/docs/alert-api#section-list-alert-notes — For more information
# operationId: listNotes
export def "alerts-notes listNotes" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
  --offset: string # Starting value of the offset property
  --direction: string@direction-completer # Page direction to apply for the given offset with 'next' and 'prev' (default: next)
  --limit: int # Maximum number of items to provide in the result. Must be a positive integer value. Default value is 20 and maximum value is 100 (format: int32)
  --order: string@order-completer # Sorting order of the result set (default: desc)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Note
#
# POST /v2/alerts/{identifier}/notes
# Docs: https://www.opsgenie.com/docs/alert-api#section-add-note-to-alert — For more information
# operationId: addNote
export def "alerts-notes addNote" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
  --user: string # Display name of the request owner
  note: string # Additional note that will be added while creating the alert
  --body-source: string # Source field of the alert. Default value is IP address of the incoming request
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/notes" $qp)
  let body = {user: $user, note: $note, source: $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists Saved Searches
#
# GET /v2/alerts/saved-searches
# Docs: https://www.opsgenie.com/docs/alert-api#section-list-saved-searches — For more information
# operationId: listSavedSearches
export def "alerts-saved-searches listSavedSearches" [
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
  let full_url = (build-url $base "/v2/alerts/saved-searches")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Saved Search
#
# POST /v2/alerts/saved-searches
# Docs: https://www.opsgenie.com/docs/alert-api#section-create-a-saved-search — For more information
# operationId: createSavedSearches
# --teams item shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string, name?: string}
export def "alerts-saved-searches createSavedSearches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --description: string
  --body-query: string
  owner: any # User recipient
  --teams: list # Teams that the alert will be routed to send notifications — item shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string, name?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/alerts/saved-searches")
  let body = {name: $name, description: $description, query: $body_query, owner: $owner, teams: $teams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Saved Search
#
# GET /v2/alerts/saved-searches/{identifier}
# Docs: https://www.opsgenie.com/docs/alert-api#section-get-saved-search — For more information
# operationId: getSavedSearch
export def "alerts-saved-searches get" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-1 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', or 'name' (default: id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/saved-searches/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Saved Search
#
# DELETE /v2/alerts/saved-searches/{identifier}
# operationId: deleteSavedSearch
export def "alerts-saved-searches delete" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-1 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', or 'name' (default: id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/saved-searches/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Saved Search
#
# PATCH /v2/alerts/saved-searches/{identifier}
# Docs: https://docs.opsgenie.com/docs/alert-api-continued#section-update-saved-search — For more information
# operationId: updateSavedSearch
# --teams item shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string, name?: string}
export def "alerts-saved-searches updateSavedSearch" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-1 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', or 'name' (default: id)
  name: string
  --description: string
  --body-query: string
  owner: any # User recipient
  --teams: list # Teams that the alert will be routed to send notifications — item shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string, name?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/saved-searches/($identifier)" $qp)
  let body = {name: $name, description: $description, query: $body_query, owner: $owner, teams: $teams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Count Alerts
#
# GET /v2/alerts/count
# Docs: https://docs.opsgenie.com/docs/alert-api#section-count-alerts — For more information
# operationId: countAlerts
export def "alerts-count countAlerts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Search query to apply while filtering the alerts
  --searchIdentifier: string # Identifier of the saved search query to apply while filtering the alerts
  --searchIdentifierType: string@searchIdentifierType-completer # Identifier type of the saved search query. Possible values are id and name. Default value is id. If searchIdentifier is not provided, this value is ignored. (default: id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "searchIdentifier" $searchIdentifier "scalar") (serialize-qp "searchIdentifierType" $searchIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/alerts/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Alert Message
#
# PUT /v2/alerts/{identifier}/message
# Docs: https://docs.opsgenie.com/docs/alert-api-continued#section-update-alert-message — For more information
# operationId: updateAlertMessage
export def "alerts-message updateAlertMessage" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
  message: string # Message of the alert
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/message" $qp)
  let body = {message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Alert Description
#
# PUT /v2/alerts/{identifier}/description
# Docs: https://docs.opsgenie.com/docs/alert-api-continued#section-update-alert-description — For more information
# operationId: updateAlertDescription
export def "alerts-description updateAlertDescription" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
  description: string # Description of the alert
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/description" $qp)
  let body = {description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Alert Priority
#
# PUT /v2/alerts/{identifier}/priority
# Docs: https://docs.opsgenie.com/docs/alert-api-continued#section-update-alert-priority — For more information
# operationId: updateAlertPriority
export def "alerts-priority updateAlertPriority" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id', 'alias' or 'tiny' (default: id)
  priority: string@priority-completer # Priority level of the alert
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/alerts/($identifier)/priority" $qp)
  let body = {priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Integrations
#
# GET /v2/integrations
# Docs: https://www.opsgenie.com/docs/integration-api#section-list-integrations — For more information
# operationId: listIntegrations
export def "integrations listIntegrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string # Type of the integration (For instance, "API" for API Integration). If type parameter is given, the result will be filtered by type
  --teamId: string # The ID of the team. If the team ID parameter is given, the result will be filtered by teamId
  --teamName: string # The name of the team. If the team name parameter is given, the result will be filtered by teamName
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "teamName" $teamName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/integrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Integration
#
# POST /v2/integrations
# Discriminator (request): type
# Docs: https://www.opsgenie.com/docs/integration-api#section-create-api-based-integration — For more information
# operationId: createIntegration
# --ownerTeam shape: {id?: string, name?: string}
export def "integrations createIntegration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer # Type of the integration. (For instance, "API" for API Integration)
  --id: string
  name: string # Name of the integration. Name must be unique for each integration
  --enabled: string@bool-completer # This parameter is for specifying whether the integration will be enabled or not
  --ownerTeam: record # shape: {id?: string, name?: string}
  --isGlobal: string@bool-completer # nullable
  --readOnly: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/integrations")
  let body = {type: $type, id: $id, name: $name, enabled: $enabled, ownerTeam: $ownerTeam, isGlobal: $isGlobal, _readOnly: $readOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Integration
#
# GET /v2/integrations/{id}
# Docs: https://www.opsgenie.com/docs/integration-api#section-get-integration — For more information
# operationId: getIntegration
export def "integrations get" [
  id: string
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
  let full_url = (build-url $base $"/v2/integrations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Integration
#
# PUT /v2/integrations/{id}
# Discriminator (request): type
# Docs: https://www.opsgenie.com/docs/integration-api#section-update-integration — For more information
# operationId: updateIntegration
# --ownerTeam shape: {id?: string, name?: string}
export def "integrations updateIntegration" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer # Type of the integration. (For instance, "API" for API Integration)
  --body-id: string
  name: string # Name of the integration. Name must be unique for each integration
  --enabled: string@bool-completer # This parameter is for specifying whether the integration will be enabled or not
  --ownerTeam: record # shape: {id?: string, name?: string}
  --isGlobal: string@bool-completer # nullable
  --readOnly: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/integrations/($id)")
  let body = {type: $type, id: $body_id, name: $name, enabled: $enabled, ownerTeam: $ownerTeam, isGlobal: $isGlobal, _readOnly: $readOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Integration
#
# DELETE /v2/integrations/{id}
# Docs: https://www.opsgenie.com/docs/integration-api#section-delete-integration — For more information
# operationId: deleteIntegration
export def "integrations delete" [
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
  let full_url = (build-url $base $"/v2/integrations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable Integration
#
# POST /v2/integrations/{id}/enable
# Docs: https://www.opsgenie.com/docs/integration-api#section-enable-integration — For more information
# operationId: enableIntegration
export def "integrations-enable enableIntegration" [
  id: string
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
  let full_url = (build-url $base $"/v2/integrations/($id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable Integration
#
# POST /v2/integrations/{id}/disable
# Docs: https://www.opsgenie.com/docs/integration-api#section-disable-integration — For more information
# operationId: disableIntegration
export def "integrations-disable disableIntegration" [
  id: string
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
  let full_url = (build-url $base $"/v2/integrations/($id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Authenticate Integration
#
# POST /v2/integrations/authenticate
# Docs: https://www.opsgenie.com/docs/integration-api#section-authenticate-integration — For more information
# operationId: authenticateIntegration
export def "integrations-authenticate authenticateIntegration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/integrations/authenticate")
  let body = {type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Integration Actions
#
# GET /v2/integrations/{id}/actions
# Docs: https://www.opsgenie.com/docs/integration-api#section-get-integration-actions — For more information
# operationId: listIntegrationActions
export def "integrations-actions listIntegrationActions" [
  id: string
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
  let full_url = (build-url $base $"/v2/integrations/($id)/actions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Integration Actions
#
# PUT /v2/integrations/{id}/actions
# Docs: https://www.opsgenie.com/docs/integration-api#section-update-all-integration-actions — For more information
# operationId: updateIntegrationActions
# --_parent shape: {id?: string, name?: string, enabled?: bool, type?: string, teamId?: string}
# --ignore item shape: {name: string, order?: int, filter: record, type: "acknowledge"|"addNote"|"close"|"create"|"ignore"}
# --create item shape: {source?: string, message?: string, description?: string, entity?: string, priority?: "P1"|"P2"|"P3"|"P4"|"P5", customPriority?: string, appendAttachments?: bool, alertActions?: list, ignoreAlertActionsFromPayload?: bool, recipients?: list, responders?: list, ignoreRecipientsFromPayload?: bool, ignoreTeamsFromPayload?: bool, tags?: list, ignoreTagsFromPayload?: bool, extraProperties?: record, ignoreExtraPropertiesFromPayload?: bool, ignoreRespondersFromPayload?: bool}
export def "integrations-actions updateIntegrationActions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parent: record # shape: {id?: string, name?: string, enabled?: bool, type?: string, teamId?: string}
  --ignore: list # item shape: {name: string, order?: int, filter: record, type: "acknowledge"|"addNote"|"close"|"create"|"ignore"}
  --create: list # item shape: {source?: string, message?: string, description?: string, entity?: string, priority?: "P1"|"P2"|"P3"|"P4"|"P5", customPriority?: string, appendAttachments?: bool, alertActions?: list, ignoreAlertActionsFromPayload?: bool, recipients?: list, responders?: list, ignoreRecipientsFromPayload?: bool, ignoreTeamsFromPayload?: bool, tags?: list, ignoreTagsFromPayload?: bool, extraProperties?: record, ignoreExtraPropertiesFromPayload?: bool, ignoreRespondersFromPayload?: bool}
  --close: list
  --acknowledge: list
  --addNote: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/integrations/($id)/actions")
  let body = {_parent: $parent, ignore: $ignore, create: $create, close: $close, acknowledge: $acknowledge, addNote: $addNote} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Integration Action
#
# POST /v2/integrations/{id}/actions
# Discriminator (request): type
# Docs: https://www.opsgenie.com/docs/integration-api#section-create-a-new-integration-action — For more information
# operationId: createIntegrationAction
# --filter shape: {conditionMatchType?: "match-all"|"match-any-condition"|"match-all-conditions", conditions?: list}
export def "integrations-actions createIntegrationAction" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --order: int # format: int32
  filter: record # shape: {conditionMatchType?: "match-all"|"match-any-condition"|"match-all-conditions", conditions?: list}
  type: string@type-completer-2
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/integrations/($id)/actions")
  let body = {name: $name, order: $order, filter: $filter, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Ping Heartbeat
#
# GET /v2/heartbeats/{name}/ping
# Docs: https://www.opsgenie.com/docs/heartbeat-api#section-ping-heartbeat-request — For more information
# operationId: ping
export def "heartbeats-ping ping" [
  name: string
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
  let full_url = (build-url $base $"/v2/heartbeats/($name)/ping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Heartbeats
#
# GET /v2/heartbeats
# Docs: https://docs.opsgenie.com/docs/heartbeat-api#section-list-heartbeats — For more information
# operationId: listHeartBeats
export def "heartbeats listHeartBeats" [
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
  let full_url = (build-url $base "/v2/heartbeats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Heartbeat
#
# POST /v2/heartbeats
# Docs: https://www.opsgenie.com/docs/heartbeat-api#section-add-heartbeat-request — For more information
# operationId: createHeartbeat
# --ownerTeam shape: {name?: string, id?: string}
export def "heartbeats createHeartbeat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the heartbeat
  --description: string # An optional description of the heartbeat
  interval: int # Specifies how often a heartbeat message should be expected (format: int32)
  intervalUnit: string@intervalUnit-completer # Interval specified as 'minutes', 'hours' or 'days'
  --enabled: string@bool-completer # Enable/disable heartbeat monitoring
  --ownerTeam: record # Owner team of the heartbeat, consisting id and/or name of the owner team — shape: {name?: string, id?: string}
  --alertMessage: string # Specifies the alert message for heartbeat expiration alert. If this is not provided, default alert message is 'HeartbeatName is expired'
  --alertTags: list # Specifies the alert tags for heartbeat expiration alert
  --alertPriority: string@alertPriority-completer # Specifies the alert priority for heartbeat expiration alert. If this is not provided, default priority is P3
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/heartbeats")
  let body = {name: $name, description: $description, interval: $interval, intervalUnit: $intervalUnit, enabled: $enabled, ownerTeam: $ownerTeam, alertMessage: $alertMessage, alertTags: $alertTags, alertPriority: $alertPriority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Heartbeat
#
# GET /v2/heartbeats/{name}
# Docs: https://www.opsgenie.com/docs/heartbeat-api#section-get-heartbeat-request — For more information
# operationId: getHeartbeat
export def "heartbeats get" [
  name: string
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
  let full_url = (build-url $base $"/v2/heartbeats/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Heartbeat (Partial)
#
# PATCH /v2/heartbeats/{name}
# Docs: https://www.opsgenie.com/docs/heartbeat-api#section-update-heartbeat-request-partial — For more information
# operationId: updateHeartbeat
export def "heartbeats updateHeartbeat" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # An optional description of the heartbeat
  --interval: int # Specifies how often a heartbeat message should be expected (format: int32)
  --intervalUnit: string@intervalUnit-completer # Interval specified as 'minutes', 'hours' or 'days'
  --enabled: string@bool-completer # Enable/disable heartbeat monitoring
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/heartbeats/($name)")
  let body = {description: $description, interval: $interval, intervalUnit: $intervalUnit, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Heartbeat
#
# DELETE /v2/heartbeats/{name}
# Docs: https://www.opsgenie.com/docs/heartbeat-api#section-delete-heartbeat-request — For more information
# operationId: deleteHeartbeat
export def "heartbeats delete" [
  name: string
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
  let full_url = (build-url $base $"/v2/heartbeats/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable Heartbeat
#
# POST /v2/heartbeats/{name}/enable
# Docs: https://www.opsgenie.com/docs/heartbeat-api#section-enable-heartbeat-request — For more information
# operationId: enableHeartbeat
export def "heartbeats-enable enableHeartbeat" [
  name: string
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
  let full_url = (build-url $base $"/v2/heartbeats/($name)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable Heartbeat
#
# POST /v2/heartbeats/{name}/disable
# Docs: https://www.opsgenie.com/docs/heartbeat-api#section-disable-heartbeat-request — For more information
# operationId: disableHeartbeat
export def "heartbeats-disable disableHeartbeat" [
  name: string
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
  let full_url = (build-url $base $"/v2/heartbeats/($name)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Alert Policies
#
# GET /v1/policies
# Docs: https://www.opsgenie.com/docs/policy-api#section-list-policies — For more information
# operationId: listAlertPolicies
export def "policies listAlertPolicies" [
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
  let full_url = (build-url $base "/v1/policies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Alert Policy
#
# POST /v1/policies
# Discriminator (request): type
# Docs: https://www.opsgenie.com/docs/policy-api#section-create-policy — For more information
# operationId: createAlertPolicy
# --filter shape: {type: "match-all"|"match-any-condition"|"match-all-conditions"}
# --timeRestrictions shape: {type: "weekday-and-time-of-day"|"time-of-day"}
export def "policies createAlertPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string
  --name: string # Name of the policy
  --policyDescription: string # Description of the policy
  --filter: record # Defines the conditions that will be checked before applying rules and type of the operations that will be applied on conditions — shape: {type: "match-all"|"match-any-condition"|"match-all-conditions"}
  --timeRestrictions: record # shape: {type: "weekday-and-time-of-day"|"time-of-day"}
  --enabled: string@bool-completer # Activity status of the alert policy
  type: string@type-completer-3 # Type of the policy
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/policies")
  let body = {id: $id, name: $name, policyDescription: $policyDescription, filter: $filter, timeRestrictions: $timeRestrictions, enabled: $enabled, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Alert Policy
#
# GET /v1/policies/{policyId}
# Docs: https://www.opsgenie.com/docs/policy-api#section-get-policy — For more information
# operationId: getAlertPolicy
export def "policies get-by-policyId" [
  policyId: string
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
  let full_url = (build-url $base $"/v1/policies/($policyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Alert Policy
#
# PUT /v1/policies/{policyId}
# Discriminator (request): type
# Docs: https://www.opsgenie.com/docs/policy-api#section-update-policy — For more information
# operationId: updateAlertPolicy
# --filter shape: {type: "match-all"|"match-any-condition"|"match-all-conditions"}
# --timeRestrictions shape: {type: "weekday-and-time-of-day"|"time-of-day"}
export def "policies updateAlertPolicy" [
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string
  --name: string # Name of the policy
  --policyDescription: string # Description of the policy
  --filter: record # Defines the conditions that will be checked before applying rules and type of the operations that will be applied on conditions — shape: {type: "match-all"|"match-any-condition"|"match-all-conditions"}
  --timeRestrictions: record # shape: {type: "weekday-and-time-of-day"|"time-of-day"}
  --enabled: string@bool-completer # Activity status of the alert policy
  type: string@type-completer-3 # Type of the policy
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/policies/($policyId)")
  let body = {id: $id, name: $name, policyDescription: $policyDescription, filter: $filter, timeRestrictions: $timeRestrictions, enabled: $enabled, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Alert Policy
#
# DELETE /v1/policies/{policyId}
# Docs: https://www.opsgenie.com/docs/policy-api#section-delete-policy — For more information
# operationId: deleteAlertPolicy
export def "policies delete-by-policyId" [
  policyId: string
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
  let full_url = (build-url $base $"/v1/policies/($policyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable Alert Policy
#
# POST /v1/policies/{policyId}/enable
# Docs: https://www.opsgenie.com/docs/policy-api#section-enable-policy — For more information
# operationId: enableAlertPolicy
export def "policies-enable enableAlertPolicy" [
  policyId: string
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
  let full_url = (build-url $base $"/v1/policies/($policyId)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable Alert Policy
#
# POST /v1/policies/{policyId}/disable
# Docs: https://www.opsgenie.com/docs/policy-api#section-disable-policy — For more information
# operationId: disableAlertPolicy
export def "policies-disable disableAlertPolicy" [
  policyId: string
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
  let full_url = (build-url $base $"/v1/policies/($policyId)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change Alert Policy Order
#
# POST /v1/policies/{policyId}/change-order
# Docs: https://www.opsgenie.com/docs/policy-api#section-change-policy-order — For more information
# operationId: changeAlertPolicyOrder
export def "policies-change-order changeAlertPolicyOrder" [
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  targetIndex: int # Order of the target policy will be changed to this value. Larger values than policy count will put the target policy to last place (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/policies/($policyId)/change-order")
  let body = {targetIndex: $targetIndex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Maintenance
#
# POST /v1/maintenance
# Docs: https://www.opsgenie.com/docs/maintenance-api#section-create-maintenance — For more information
# operationId: createMaintenance
# --time shape: {type: "for-5-minutes"|"for-30-minutes"|"for-1-hour"|"indefinitely"|"schedule", startDate?: string, endDate?: string}
# --rules item shape: {state?: "enabled"|"disabled", entity: record}
export def "maintenance createMaintenance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description for the maintenance
  time: record # shape: {type: "for-5-minutes"|"for-30-minutes"|"for-1-hour"|"indefinitely"|"schedule", startDate?: string, endDate?: string}
  rules: list # Rules of maintenance, which takes a list of rule objects and defines the maintenance rules over integrations and policies. — item shape: {state?: "enabled"|"disabled", entity: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/maintenance")
  let body = {description: $description, time: $time, rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Maintenance
#
# GET /v1/maintenance
# Docs: https://www.opsgenie.com/docs/maintenance-api#section-list-maintenance — For more information
# operationId: listMaintenance
export def "maintenance listMaintenance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4 # Type of the maintenance list to be searched (default: [all])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/maintenance" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Maintenance
#
# GET /v1/maintenance/{id}
# Docs: https://www.opsgenie.com/docs/maintenance-api#section-get-maintenance — For more information
# operationId: getMaintenance
export def "maintenance get" [
  id: string
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
  let full_url = (build-url $base $"/v1/maintenance/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Maintenance
#
# PUT /v1/maintenance/{id}
# Docs: https://www.opsgenie.com/docs/maintenance-api#section-update-maintenance — For more information
# operationId: updateMaintenance
# --time shape: {type: "for-5-minutes"|"for-30-minutes"|"for-1-hour"|"indefinitely"|"schedule", startDate?: string, endDate?: string}
# --rules item shape: {state?: "enabled"|"disabled", entity: record}
export def "maintenance updateMaintenance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description for the maintenance
  time: record # shape: {type: "for-5-minutes"|"for-30-minutes"|"for-1-hour"|"indefinitely"|"schedule", startDate?: string, endDate?: string}
  rules: list # Rules of maintenance, which takes a list of rule objects and defines the maintenance rules over integrations and policies. — item shape: {state?: "enabled"|"disabled", entity: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/maintenance/($id)")
  let body = {description: $description, time: $time, rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Maintenance
#
# DELETE /v1/maintenance/{id}
# Docs: https://www.opsgenie.com/docs/maintenance-api#section-delete-maintenance — For more information
# operationId: deleteMaintenance
export def "maintenance delete" [
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
  let full_url = (build-url $base $"/v1/maintenance/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel Maintenance
#
# POST /v1/maintenance/{id}/cancel
# Docs: https://www.opsgenie.com/docs/maintenance-api#section-cancel-maintenance — For more information
# operationId: cancelMaintenance
export def "maintenance-cancel cancelMaintenance" [
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
  let full_url = (build-url $base $"/v1/maintenance/($id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Account Info
#
# GET /v2/account
# Docs: https://www.opsgenie.com/docs/account-api#section-get-account-info — For more information
# operationId: getInfo
export def "account get" [
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
  let full_url = (build-url $base "/v2/account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create User
#
# POST /v2/users
# Docs: https://www.opsgenie.com/docs/user-api#section-create-user — For more information
# operationId: createUser
# --role shape: {id?: string, name?: string}
# --userAddress shape: {country?: string, state?: string, city?: string, line?: string, zipCode?: string}
export def "users createUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  username: string # E-mail address of the user (format: email)
  fullName: string # Name of the user
  role: record # shape: {id?: string, name?: string}
  --skypeUsername: string # Skype username of the user
  --timeZone: string # Timezone of the user. If not set, timezone of the customer will be used instead.
  --locale: string # Location information of the user. If not set, locale of the customer will be used instead.
  --userAddress: record # shape: {country?: string, state?: string, city?: string, line?: string, zipCode?: string}
  --tags: list # List of labels attached to the user. You can label users to differentiate them from the rest. For example, you can add ITManager tag to differentiate people with this role from others.
  --details: record # Set of user defined properties.
  --invitationDisabled: string@bool-completer # Invitation email will not be sent if set to true. Default value is false
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/users")
  let body = {username: $username, fullName: $fullName, role: $role, skypeUsername: $skypeUsername, timeZone: $timeZone, locale: $locale, userAddress: $userAddress, tags: $tags, details: $details, invitationDisabled: $invitationDisabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List users
#
# GET /v2/users
# Docs: https://www.opsgenie.com/docs/user-api#section-list-user — For more information
# operationId: listUsers
export def "users listUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of users to retrieve (format: int32, default: 100)
  --offset: int # Number of users to skip from start (format: int32, default: 0)
  --sortField: string # Field to use in sorting. Should be one of 'username', 'fullName' and 'insertedAt'
  --order: string@order-completer # Direction of sorting. Should be one of 'asc' or 'desc' (default: asc)
  --qp-query: string # Field:value combinations with most of user fields to make more advanced searches. Possible fields are username, fullName, blocked, verified, role, locale, timeZone, userAddress and createdAt
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sortField" $sortField "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get User
#
# GET /v2/users/{identifier}
# Docs: https://www.opsgenie.com/docs/user-api#section-get-user — For more information
# operationId: getUser
export def "users get" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: list # Comma separated list of strings to create a more detailed response. The only expandable field for user api is 'contact'
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/users/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update User (Partial)
#
# PATCH /v2/users/{identifier}
# Docs: https://www.opsgenie.com/docs/user-api#section-update-user-partial — For more information
# operationId: updateUser
# --role shape: {id?: string, name?: string}
# --userAddress shape: {country?: string, state?: string, city?: string, line?: string, zipCode?: string}
export def "users updateUser" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --username: string # E-mail address of the user (format: email)
  --fullName: string # Name of the user
  --role: record # shape: {id?: string, name?: string}
  --skypeUsername: string # Skype username of the user
  --timeZone: string # Timezone of the user. If not set, timezone of the customer will be used instead.
  --locale: string # Location information of the user. If not set, locale of the customer will be used instead.
  --userAddress: record # shape: {country?: string, state?: string, city?: string, line?: string, zipCode?: string}
  --tags: list # List of labels attached to the user. You can label users to differentiate them from the rest. For example, you can add ITManager tag to differentiate people with this role from others.
  --details: record # Set of user defined properties.
  --invitationDisabled: string@bool-completer # Invitation email will not be sent if set to true. Default value is false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($identifier)")
  let body = {username: $username, fullName: $fullName, role: $role, skypeUsername: $skypeUsername, timeZone: $timeZone, locale: $locale, userAddress: $userAddress, tags: $tags, details: $details, invitationDisabled: $invitationDisabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete User
#
# DELETE /v2/users/{identifier}
# Docs: https://www.opsgenie.com/docs/user-api#section-delete-user — For more information
# operationId: deleteUser
export def "users delete" [
  identifier: string
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
  let full_url = (build-url $base $"/v2/users/($identifier)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User Teams
#
# GET /v2/users/{identifier}/teams
# Docs: https://www.opsgenie.com/docs/user-api#section-list-user-teams — For more information
# operationId: listUserTeams
export def "users-teams listUserTeams" [
  identifier: string
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
  let full_url = (build-url $base $"/v2/users/($identifier)/teams")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User Forwarding Rules
#
# GET /v2/users/{identifier}/forwarding-rules
# Docs: https://www.opsgenie.com/docs/user-api#section-list-user-forwarding-rules — For more information
# operationId: listUserForwardingRules
export def "users-forwarding-rules listUserForwardingRules" [
  identifier: string
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
  let full_url = (build-url $base $"/v2/users/($identifier)/forwarding-rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User Escalations
#
# GET /v2/users/{identifier}/escalations
# Docs: https://www.opsgenie.com/docs/user-api#section-list-user-escalations — For more information
# operationId: listUserEscalations
export def "users-escalations listUserEscalations" [
  identifier: string
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
  let full_url = (build-url $base $"/v2/users/($identifier)/escalations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User Schedules
#
# GET /v2/users/{identifier}/schedules
# Docs: https://www.opsgenie.com/docs/user-api#section-list-user-schedules — For more information
# operationId: listUserSchedules
export def "users-schedules listUserSchedules" [
  identifier: string
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
  let full_url = (build-url $base $"/v2/users/($identifier)/schedules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Contact
#
# POST /v2/users/{identifier}/contacts
# Docs: https://www.opsgenie.com/docs/contact-api#section-create-contact — For more information
# operationId: createContact
export def "users-contacts createContact" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  method: string@method-completer # Contact method of user
  --body-to: string # Address of contact method
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($identifier)/contacts")
  let body = {method: $method, to: $body_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Contacts
#
# GET /v2/users/{identifier}/contacts
# Docs: https://www.opsgenie.com/docs/contact-api#section-list-contacts — For more information
# operationId: listContacts
export def "users-contacts listContacts" [
  identifier: string
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
  let full_url = (build-url $base $"/v2/users/($identifier)/contacts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Contact (Partial)
#
# PATCH /v2/users/{identifier}/contacts/{contactId}
# Docs: https://www.opsgenie.com/docs/contact-api#section-update-contact-partial — For more information
# operationId: updateContact
export def "users-contacts updateContact" [
  identifier: string
  contactId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-to: string # Address of contact method
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($identifier)/contacts/($contactId)")
  let body = {to: $body_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Contact
#
# GET /v2/users/{identifier}/contacts/{contactId}
# Docs: https://www.opsgenie.com/docs/contact-api#section-get-contact — For more information
# operationId: getContact
export def "users-contacts get" [
  identifier: string
  contactId: string
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
  let full_url = (build-url $base $"/v2/users/($identifier)/contacts/($contactId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Contact
#
# DELETE /v2/users/{identifier}/contacts/{contactId}
# Docs: https://www.opsgenie.com/docs/contact-api#section-delete-contact — For more information
# operationId: deleteContact
export def "users-contacts delete" [
  identifier: string
  contactId: string
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
  let full_url = (build-url $base $"/v2/users/($identifier)/contacts/($contactId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable Contact
#
# POST /v2/users/{identifier}/contacts/{contactId}/enable
# Docs: https://www.opsgenie.com/docs/contact-api#section-enable-contact — For more information
# operationId: enableContact
export def "users-contacts-enable enableContact" [
  identifier: string
  contactId: string
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
  let full_url = (build-url $base $"/v2/users/($identifier)/contacts/($contactId)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable Contact
#
# POST /v2/users/{identifier}/contacts/{contactId}/disable
# Docs: https://www.opsgenie.com/docs/contact-api#section-disable-contact — For more information
# operationId: disableContact
export def "users-contacts-disable disableContact" [
  identifier: string
  contactId: string
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
  let full_url = (build-url $base $"/v2/users/($identifier)/contacts/($contactId)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Notification Rules
#
# GET /v2/users/{identifier}/notification-rules
# Docs: https://www.opsgenie.com/docs/notification-rule-api#section-list-notification-rule — For more information
# operationId: listNotificationRules
export def "users-notification-rules listNotificationRules" [
  identifier: string
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
  let full_url = (build-url $base $"/v2/users/($identifier)/notification-rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Notification Rule
#
# POST /v2/users/{identifier}/notification-rules
# Docs: https://www.opsgenie.com/docs/notification-rule-api#section-create-notification-rule — For more information
# operationId: createNotificationRule
# --criteria shape: {type: "match-all"|"match-any-condition"|"match-all-conditions"}
# --timeRestriction shape: {type: "weekday-and-time-of-day"|"time-of-day"}
# --schedules item shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string, name?: string}
# --steps item shape: {contact: record, sendAfter?: record, enabled: bool}
# --repeat shape: {loopAfter?: int, enabled?: bool}
export def "users-notification-rules createNotificationRule" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the notification rule
  actionType: string@actionType-completer # Type of the action that notification rule will have
  --criteria: record # Defines the conditions that will be checked before applying rules and type of the operations that will be applied on conditions — shape: {type: "match-all"|"match-any-condition"|"match-all-conditions"}
  --notificationTime: list # List of Time Periods that notification for schedule start/end will be sent
  --timeRestriction: record # shape: {type: "weekday-and-time-of-day"|"time-of-day"}
  --schedules: list # List of schedules that notification rule will be applied when on call of that schedule starts/ends. This field is valid for Schedule Start/End rules — item shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string, name?: string}
  --order: int # The order of the notification rule within the notification rules with the same action type (format: int32)
  --steps: list # List of steps that will be added to notification rule — item shape: {contact: record, sendAfter?: record, enabled: bool}
  --repeat: record # The amount of time in minutes that notification steps will be repeatedly apply — shape: {loopAfter?: int, enabled?: bool}
  --enabled: string@bool-completer # Defines if notification rule will be enabled or not when it is created
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($identifier)/notification-rules")
  let body = {name: $name, actionType: $actionType, criteria: $criteria, notificationTime: $notificationTime, timeRestriction: $timeRestriction, schedules: $schedules, order: $order, steps: $steps, repeat: $repeat, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Notification Rule
#
# GET /v2/users/{identifier}/notification-rules/{ruleId}
# Docs: https://www.opsgenie.com/docs/notification-rule-api#section-get-notification-rule — For more information
# operationId: getNotificationRule
export def "users-notification-rules get" [
  identifier: string
  ruleId: string
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
  let full_url = (build-url $base $"/v2/users/($identifier)/notification-rules/($ruleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Notification Rule
#
# DELETE /v2/users/{identifier}/notification-rules/{ruleId}
# Docs: https://www.opsgenie.com/docs/notification-rule-api#section-delete-notification-rule — For more information
# operationId: deleteNotificationRule
export def "users-notification-rules delete" [
  identifier: string
  ruleId: string
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
  let full_url = (build-url $base $"/v2/users/($identifier)/notification-rules/($ruleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Notification Rule (Partial)
#
# PATCH /v2/users/{identifier}/notification-rules/{ruleId}
# Docs: https://www.opsgenie.com/docs/notification-rule-api#section-update-notification-rule-partial — For more information
# operationId: updateNotificationRule
# --criteria shape: {type: "match-all"|"match-any-condition"|"match-all-conditions"}
# --timeRestriction shape: {type: "weekday-and-time-of-day"|"time-of-day"}
# --schedules item shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string, name?: string}
# --steps item shape: {contact: record, sendAfter?: record, enabled: bool}
# --repeat shape: {loopAfter?: int, enabled?: bool}
export def "users-notification-rules updateNotificationRule" [
  identifier: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the notification rule
  --criteria: record # Defines the conditions that will be checked before applying rules and type of the operations that will be applied on conditions — shape: {type: "match-all"|"match-any-condition"|"match-all-conditions"}
  --notificationTime: list # List of Time Periods that notification for schedule start/end will be sent
  --timeRestriction: record # shape: {type: "weekday-and-time-of-day"|"time-of-day"}
  --schedules: list # List of schedules that notification rule will be applied when on call of that schedule starts/ends. This field is valid for Schedule Start/End rules — item shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string, name?: string}
  --steps: list # List of steps that will be added to notification rule — item shape: {contact: record, sendAfter?: record, enabled: bool}
  --repeat: record # The amount of time in minutes that notification steps will be repeatedly apply — shape: {loopAfter?: int, enabled?: bool}
  --order: int # The order of the notification rule within the notification rules with the same action type (format: int32)
  --enabled: string@bool-completer # Defines if notification rule will be enabled or not when it is created
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($identifier)/notification-rules/($ruleId)")
  let body = {name: $name, criteria: $criteria, notificationTime: $notificationTime, timeRestriction: $timeRestriction, schedules: $schedules, steps: $steps, repeat: $repeat, order: $order, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enable Notification Rule
#
# POST /v2/users/{identifier}/notification-rules/{ruleId}/enable
# Docs: https://www.opsgenie.com/docs/notification-rule-api#section-enable-notification-rule — For more information
# operationId: enableNotificationRule
export def "users-notification-rules-enable enableNotificationRule" [
  identifier: string
  ruleId: string
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
  let full_url = (build-url $base $"/v2/users/($identifier)/notification-rules/($ruleId)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable Notification Rule
#
# POST /v2/users/{identifier}/notification-rules/{ruleId}/disable
# Docs: https://www.opsgenie.com/docs/notification-rule-api#section-disable-notification-rule — For more information
# operationId: disableNotificationRule
export def "users-notification-rules-disable disableNotificationRule" [
  identifier: string
  ruleId: string
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
  let full_url = (build-url $base $"/v2/users/($identifier)/notification-rules/($ruleId)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change order of Notification Rule
#
# POST /v2/users/{identifier}/notification-rules/{ruleId}/change-order
# operationId: changeNotificationRuleOrder
export def "users-notification-rules-change-order changeNotificationRuleOrder" [
  identifier: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($identifier)/notification-rules/($ruleId)/change-order")
  let body = {order: $order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Notification Rule Steps
#
# GET /v2/users/{identifier}/notification-rules/{ruleId}/steps
# Docs: https://www.opsgenie.com/docs/notification-rule-step-api#section-list-notification-rule-step — For more information
# operationId: listNotificationRuleSteps
export def "users-notification-rules-steps listNotificationRuleSteps" [
  identifier: string
  ruleId: string
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
  let full_url = (build-url $base $"/v2/users/($identifier)/notification-rules/($ruleId)/steps")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Notification Rule Step
#
# POST /v2/users/{identifier}/notification-rules/{ruleId}/steps
# Docs: https://www.opsgenie.com/docs/notification-rule-step-api#section-create-notification-rule-step — For more information
# operationId: createNotificationRuleStep
# --contact shape: {method: "email"|"sms"|"voice"|"mobile", to: string}
# --sendAfter shape: {timeAmount: int, timeUnit?: "days"|"hours"|"minutes"|"seconds"|"miliseconds"|"micros"|"nanos"}
export def "users-notification-rules-steps createNotificationRuleStep" [
  identifier: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  contact: record # shape: {method: "email"|"sms"|"voice"|"mobile", to: string}
  --sendAfter: record # shape: {timeAmount: int, timeUnit?: "days"|"hours"|"minutes"|"seconds"|"miliseconds"|"micros"|"nanos"}
  --enabled: string@bool-completer # Specifies whether given step will be enabled or not when it is created.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($identifier)/notification-rules/($ruleId)/steps")
  let body = {contact: $contact, sendAfter: $sendAfter, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Notification Rule Step
#
# GET /v2/users/{identifier}/notification-rules/{ruleId}/steps/{id}
# Docs: https://www.opsgenie.com/docs/notification-rule-step-api#section-get-notification-rule-step — For more information
# operationId: getNotificationRuleStep
export def "users-notification-rules-steps get" [
  identifier: string
  ruleId: string
  id: string
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
  let full_url = (build-url $base $"/v2/users/($identifier)/notification-rules/($ruleId)/steps/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Notification Rule Step
#
# DELETE /v2/users/{identifier}/notification-rules/{ruleId}/steps/{id}
# Docs: https://www.opsgenie.com/docs/notification-rule-step-api#section-delete-notification-rule-step — For more information
# operationId: deleteNotificationRuleStep
export def "users-notification-rules-steps delete" [
  identifier: string
  ruleId: string
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
  let full_url = (build-url $base $"/v2/users/($identifier)/notification-rules/($ruleId)/steps/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Notification Rule Step (Partial)
#
# PATCH /v2/users/{identifier}/notification-rules/{ruleId}/steps/{id}
# Docs: https://www.opsgenie.com/docs/notification-rule-step-api#section-update-notification-rule-step-partial — For more information
# operationId: updateNotificationRuleStep
# --contact shape: {method: "email"|"sms"|"voice"|"mobile", to: string}
# --sendAfter shape: {timeAmount: int, timeUnit?: "days"|"hours"|"minutes"|"seconds"|"miliseconds"|"micros"|"nanos"}
export def "users-notification-rules-steps updateNotificationRuleStep" [
  identifier: string
  ruleId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contact: record # shape: {method: "email"|"sms"|"voice"|"mobile", to: string}
  --sendAfter: record # shape: {timeAmount: int, timeUnit?: "days"|"hours"|"minutes"|"seconds"|"miliseconds"|"micros"|"nanos"}
  --enabled: string@bool-completer # Specifies whether given step will be enabled or not when it is updated.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($identifier)/notification-rules/($ruleId)/steps/($id)")
  let body = {contact: $contact, sendAfter: $sendAfter, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disable Notification Rule Step
#
# POST /v2/users/{identifier}/notification-rules/{ruleId}/steps/{id}/disable
# Docs: https://www.opsgenie.com/docs/notification-rule-step-api#section-disable-notification-rule-step — For more information
# operationId: disableNotificationRuleStep
export def "users-notification-rules-steps-disable disableNotificationRuleStep" [
  identifier: string
  ruleId: string
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
  let full_url = (build-url $base $"/v2/users/($identifier)/notification-rules/($ruleId)/steps/($id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable Notification Rule Step
#
# POST /v2/users/{identifier}/notification-rules/{ruleId}/steps/{id}/enable
# Docs: https://www.opsgenie.com/docs/notification-rule-step-api#section-enable-notification-rule-step — For more information
# operationId: enableNotificationRuleStep
export def "users-notification-rules-steps-enable enableNotificationRuleStep" [
  identifier: string
  ruleId: string
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
  let full_url = (build-url $base $"/v2/users/($identifier)/notification-rules/($ruleId)/steps/($id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Team
#
# POST /v2/teams
# Docs: https://www.opsgenie.com/docs/team-api#section-create-team — For more information
# operationId: createTeam
# --members item shape: {user?: record, role?: string}
export def "teams createTeam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the team
  --description: string # The description of team
  --members: list # The users which will be added to team, and optionally their roles. — item shape: {user?: record, role?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/teams")
  let body = {name: $name, description: $description, members: $members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Teams
#
# GET /v2/teams
# Docs: https://www.opsgenie.com/docs/team-api#section-list-teams — For more information
# operationId: listTeams
export def "teams listTeams" [
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
  let full_url = (build-url $base "/v2/teams")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Team
#
# GET /v2/teams/{identifier}
# Docs: https://www.opsgenie.com/docs/team-api#section-get-team — For more information
# operationId: getTeam
export def "teams get" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-1 # Type of the identifier. Possible values are 'id' and 'name'. Default value is 'id' (default: id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/teams/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Team
#
# DELETE /v2/teams/{identifier}
# Docs: https://www.opsgenie.com/docs/team-api#section-delete-team — For more information
# operationId: deleteTeam
export def "teams delete" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-1 # Type of the identifier. Possible values are 'id' and 'name'. Default value is 'id' (default: id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/teams/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Team (Partial)
#
# PATCH /v2/teams/{identifier}
# Docs: https://www.opsgenie.com/docs/team-api#section-update-team-partial — For more information
# operationId: updateTeam
# --members item shape: {user?: record, role?: string}
export def "teams updateTeam" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the team
  --description: string # The description of team
  --members: list # item shape: {user?: record, role?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/teams/($identifier)")
  let body = {name: $name, description: $description, members: $members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Team Logs
#
# GET /v2/teams/{identifier}/logs
# Docs: https://www.opsgenie.com/docs/team-api#section-list-team-logs — For more information
# operationId: listTeamLogs
export def "teams-logs listTeamLogs" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-1 # Type of the identifier. Possible values are 'id' and 'name'. Default value is 'id' (default: id)
  --limit: int # Maximum number of items to provide in the result. Must be a positive integer value. (format: int32)
  --order: string@order-completer # Sorting order of the result set (default: desc)
  --offset: string # Key which will be used in pagination
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/teams/($identifier)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Team Member
#
# POST /v2/teams/{identifier}/members
# Docs: https://www.opsgenie.com/docs/team-member-api#section-add-team-member — For more information
# operationId: addTeamMember
# --user shape: {id?: string, username?: string}
export def "teams-members addTeamMember" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamIdentifierType: string@teamIdentifierType-completer # Type of the identifier. Possible values are 'id' and 'name'. Default value is 'id' (default: id)
  user: record # shape: {id?: string, username?: string}
  --role: string # Member role of the user, consisting 'user', 'admin' or a custom team role. Default value is 'user' (default: user)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamIdentifierType" $teamIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/teams/($identifier)/members" $qp)
  let body = {user: $user, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Team Member
#
# DELETE /v2/teams/{identifier}/members/{memberIdentifier}
# Docs: https://www.opsgenie.com/docs/team-member-api#section-remove-team-member — For more information
# operationId: deleteTeamMember
export def "teams-members delete" [
  identifier: string
  memberIdentifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamIdentifierType: string@teamIdentifierType-completer # Type of the identifier. Possible values are 'id' and 'name'. Default value is 'id' (default: id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamIdentifierType" $teamIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/teams/($identifier)/members/($memberIdentifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Team Roles
#
# GET /v2/teams/{identifier}/roles
# Docs: https://www.opsgenie.com/docs/team-role-api#section-list-team-roles — For more information
# operationId: listTeamRoles
export def "teams-roles listTeamRoles" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamIdentifierType: string@teamIdentifierType-completer # Type of the identifier. Possible values are 'id' and 'name'. Default value is 'id' (default: id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamIdentifierType" $teamIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/teams/($identifier)/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Team Role
#
# POST /v2/teams/{identifier}/roles
# Docs: https://www.opsgenie.com/docs/team-role-api#section-create-team-role — For more information
# operationId: createTeamRole
# --rights item shape: {right: string, granted?: bool}
export def "teams-roles createTeamRole" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamIdentifierType: string@teamIdentifierType-completer # Type of the identifier. Possible values are 'id' and 'name'. Default value is 'id' (default: id)
  name: string # Name of the team role
  rights: list # List of team role rights. — item shape: {right: string, granted?: bool}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamIdentifierType" $teamIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/teams/($identifier)/roles" $qp)
  let body = {name: $name, rights: $rights} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Team Role
#
# GET /v2/teams/{identifier}/roles/{teamRoleIdentifier}
# Docs: https://www.opsgenie.com/docs/team-role-api#section-get-team-role — For more information
# operationId: getTeamRole
export def "teams-roles get" [
  identifier: string
  teamRoleIdentifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamIdentifierType: string@teamIdentifierType-completer # Type of the identifier. Possible values are 'id' and 'name'. Default value is 'id' (default: id)
  --identifierType: string@identifierType-completer-1 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamIdentifierType" $teamIdentifierType "scalar") (serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/teams/($identifier)/roles/($teamRoleIdentifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Team Role
#
# DELETE /v2/teams/{identifier}/roles/{teamRoleIdentifier}
# Docs: https://www.opsgenie.com/docs/team-role-api#section-delete-team-role — For more information
# operationId: deleteTeamRole
export def "teams-roles delete" [
  identifier: string
  teamRoleIdentifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamIdentifierType: string@teamIdentifierType-completer # Type of the identifier. Possible values are 'id' and 'name'. Default value is 'id' (default: id)
  --identifierType: string@identifierType-completer-1 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamIdentifierType" $teamIdentifierType "scalar") (serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/teams/($identifier)/roles/($teamRoleIdentifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Team Role (Partial)
#
# PATCH /v2/teams/{identifier}/roles/{teamRoleIdentifier}
# Docs: https://www.opsgenie.com/docs/team-role-api#section-update-team-rolepartial — For more information
# operationId: updateTeamRole
# --rights item shape: {right: string, granted?: bool}
export def "teams-roles updateTeamRole" [
  identifier: string
  teamRoleIdentifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamIdentifierType: string@teamIdentifierType-completer # Type of the identifier. Possible values are 'id' and 'name'. Default value is 'id' (default: id)
  --identifierType: string@identifierType-completer-1 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
  --name: string # Name of the team role
  --rights: list # List of team role rights. — item shape: {right: string, granted?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamIdentifierType" $teamIdentifierType "scalar") (serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/teams/($identifier)/roles/($teamRoleIdentifier)" $qp)
  let body = {name: $name, rights: $rights} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Team Routing Rule
#
# POST /v2/teams/{identifier}/routing-rules
# Docs: https://www.opsgenie.com/docs//team-routing-rule-api#section-create-team-routing-rule — For more information
# operationId: createTeamRoutingRule
# --criteria shape: {type: "match-all"|"match-any-condition"|"match-all-conditions"}
# --timeRestriction shape: {type: "weekday-and-time-of-day"|"time-of-day"}
# --notify shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string}
export def "teams-routing-rules createTeamRoutingRule" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamIdentifierType: string@teamIdentifierType-completer # Type of the identifier. Possible values are 'id' and 'name'. Default value is 'id' (default: id)
  --name: string # Name of the team routing rule
  --order: int # Order of team routing rule within the rules. order value is actually the index of the team routing rule. (format: int32)
  --criteria: record # Defines the conditions that will be checked before applying rules and type of the operations that will be applied on conditions — shape: {type: "match-all"|"match-any-condition"|"match-all-conditions"}
  --timeRestriction: record # shape: {type: "weekday-and-time-of-day"|"time-of-day"}
  notify: record # shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string}
  --timezone: string # Timezone of team routing rule. If timezone field is not given, account timezone is used as default.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamIdentifierType" $teamIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/teams/($identifier)/routing-rules" $qp)
  let body = {name: $name, order: $order, criteria: $criteria, timeRestriction: $timeRestriction, notify: $notify, timezone: $timezone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Team Routing Rules
#
# GET /v2/teams/{identifier}/routing-rules
# Docs: https://www.opsgenie.com/docs/team-routing-rule-api#section-list-team-routing-rules — For more information
# operationId: listTeamRoutingRules
export def "teams-routing-rules listTeamRoutingRules" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamIdentifierType: string@teamIdentifierType-completer # Type of the identifier. Possible values are 'id' and 'name'. Default value is 'id' (default: id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamIdentifierType" $teamIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/teams/($identifier)/routing-rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Team Routing Rule
#
# GET /v2/teams/{identifier}/routing-rules/{id}
# Docs: https://www.opsgenie.com/docs/team-routing-rule-api#section-get-team-routing-rule — For more information
# operationId: getTeamRoutingRule
export def "teams-routing-rules get" [
  identifier: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamIdentifierType: string@teamIdentifierType-completer # Type of the identifier. Possible values are 'id' and 'name'. Default value is 'id' (default: id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamIdentifierType" $teamIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/teams/($identifier)/routing-rules/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Team Routing Rule (Partial)
#
# PATCH /v2/teams/{identifier}/routing-rules/{id}
# Docs: https://www.opsgenie.com/docs/team-routing-rule-api#section-update-team-routing-rule-partial — For more information
# operationId: updateTeamRoutingRule
# --criteria shape: {type: "match-all"|"match-any-condition"|"match-all-conditions"}
# --timeRestriction shape: {type: "weekday-and-time-of-day"|"time-of-day"}
# --notify shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string}
export def "teams-routing-rules updateTeamRoutingRule" [
  identifier: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamIdentifierType: string@teamIdentifierType-completer # Type of the identifier. Possible values are 'id' and 'name'. Default value is 'id' (default: id)
  --name: string # Name of the team routing rule
  --criteria: record # Defines the conditions that will be checked before applying rules and type of the operations that will be applied on conditions — shape: {type: "match-all"|"match-any-condition"|"match-all-conditions"}
  --timeRestriction: record # shape: {type: "weekday-and-time-of-day"|"time-of-day"}
  --notify: record # shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string}
  --timezone: string # Timezone of team routing rule. If timezone field is not given, account timezone is used as default.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamIdentifierType" $teamIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/teams/($identifier)/routing-rules/($id)" $qp)
  let body = {name: $name, criteria: $criteria, timeRestriction: $timeRestriction, notify: $notify, timezone: $timezone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Team Routing Rule
#
# DELETE /v2/teams/{identifier}/routing-rules/{id}
# Docs: https://www.opsgenie.com/docs/team-routing-rule-api#section-delete-team-routing-rule — For more information
# operationId: deleteTeamRoutingRule
export def "teams-routing-rules delete" [
  identifier: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamIdentifierType: string@teamIdentifierType-completer # Type of the identifier. Possible values are 'id' and 'name'. Default value is 'id' (default: id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamIdentifierType" $teamIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/teams/($identifier)/routing-rules/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change Team Routing Rule Order
#
# POST /v2/teams/{identifier}/routing-rules/{id}/change-order
# Docs: https://www.opsgenie.com/docs/team-routing-rule-api#section-change-team-routing-rule-order — For more information
# operationId: changeTeamRoutingRuleOrder
export def "teams-routing-rules-change-order changeTeamRoutingRuleOrder" [
  identifier: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamIdentifierType: string@teamIdentifierType-completer # Type of the identifier. Possible values are 'id' and 'name'. Default value is 'id' (default: id)
  --order: int # Order of team routing rule within the rules. order value is actually the index of the team routing rule. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamIdentifierType" $teamIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/teams/($identifier)/routing-rules/($id)/change-order" $qp)
  let body = {order: $order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Schedules
#
# GET /v2/schedules
# Docs: https://www.opsgenie.com/docs/schedule-api#section-list-schedules — For more information
# operationId: listSchedules
export def "schedules listSchedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: list # Returns more detailed response with expanding it. Possible value is 'rotation' which is also returned with expandable field of response
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Schedule
#
# POST /v2/schedules
# Docs: https://www.opsgenie.com/docs/schedule-api#section-create-schedule — For more information
# operationId: createSchedule
# --ownerTeam shape: {id?: string, name?: string}
# --rotations item shape: {name?: string, startDate: string, endDate?: string, type: "daily"|"weekly"|"hourly", length?: int, participants: list, timeRestriction?: record}
export def "schedules createSchedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the schedule
  --description: string # The description of schedule
  --timezone: string # Timezone of schedule
  --enabled: string@bool-completer # Enable/disable state of schedule (nullable)
  --ownerTeam: record # shape: {id?: string, name?: string}
  --rotations: list # item shape: {name?: string, startDate: string, endDate?: string, type: "daily"|"weekly"|"hourly", length?: int, participants: list, timeRestriction?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/schedules")
  let body = {name: $name, description: $description, timezone: $timezone, enabled: $enabled, ownerTeam: $ownerTeam, rotations: $rotations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Schedule
#
# GET /v2/schedules/{identifier}
# Docs: https://www.opsgenie.com/docs/schedule-api#section-get-schedule — For more information
# operationId: getSchedule
export def "schedules get" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-1 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/schedules/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Schedule (Partial)
#
# PATCH /v2/schedules/{identifier}
# Docs: https://www.opsgenie.com/docs/schedule-api#section-update-schedule-partial — For more information
# operationId: updateSchedule
# --ownerTeam shape: {id?: string, name?: string}
# --rotations item shape: {name?: string, startDate: string, endDate?: string, type: "daily"|"weekly"|"hourly", length?: int, participants: list, timeRestriction?: record}
export def "schedules updateSchedule" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-1 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
  --name: string # Name of the schedule
  --description: string # The description of schedule
  --timezone: string # Timezone of schedule
  --enabled: string@bool-completer # Enable/disable state of schedule (nullable)
  --ownerTeam: record # shape: {id?: string, name?: string}
  --rotations: list # item shape: {name?: string, startDate: string, endDate?: string, type: "daily"|"weekly"|"hourly", length?: int, participants: list, timeRestriction?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/schedules/($identifier)" $qp)
  let body = {name: $name, description: $description, timezone: $timezone, enabled: $enabled, ownerTeam: $ownerTeam, rotations: $rotations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Schedule
#
# DELETE /v2/schedules/{identifier}
# Docs: https://www.opsgenie.com/docs/schedule-api#section-delete-schedule — For more information
# operationId: deleteSchedule
export def "schedules delete" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-1 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/schedules/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Schedule Timeline
#
# GET /v2/schedules/{identifier}/timeline
# Docs: https://www.opsgenie.com/docs/schedule-api#section-get-schedule-timeline — For more information
# operationId: getScheduleTimeline
export def "schedules-timeline get" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-1 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
  --expand: list # Returns more detailed response with expanding it. Possible values are 'base', 'forwarding', and 'override' which is also returned with expandable field of response
  --interval: int # Length of time as integer in intervalUnits to retrieve the timeline. Default value is 1 (format: int32, default: 1)
  --intervalUnit: string@intervalUnit-completer-1 # Unit of the time to retrieve the timeline. Available values are 'days', 'weeks' and 'months'. Default value is 'weeks'
  --date: string # Time to return future date on-call participants. Default date is the moment of the time that request is received (format: date-time)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "expand" $expand "csv") (serialize-qp "interval" $interval "scalar") (serialize-qp "intervalUnit" $intervalUnit "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/schedules/($identifier)/timeline" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export Schedule
#
# GET /v2/schedules/{identifier}.ics
# Docs: https://www.opsgenie.com/docs/schedule-api#section-export-schedule — For more information
# operationId: exportSchedule
export def "schedules exportSchedule" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-1 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/schedules/($identifier).ics" $qp)
  let accept_val = "text/calendar"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Schedule Rotation
#
# POST /v2/schedules/{identifier}/rotations
# Docs: https://www.opsgenie.com/docs/schedule-rotation-api#section-create-schedule-rotation — For more information
# operationId: createScheduleRotation
# --participants item shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string}
# --timeRestriction shape: {type: "weekday-and-time-of-day"|"time-of-day"}
export def "schedules-rotations createScheduleRotation" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scheduleIdentifierType: string@scheduleIdentifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
  --name: string # Name of rotation
  startDate: string # Defines a date time as an override start. Minutes may take 0 or 30 as value. Otherwise they will be converted to nearest 0 or 30 automatically (format: date-time)
  --endDate: string # Defines a date time as an override end. Minutes may take 0 or 30 as value. Otherwise they will be converted to nearest 0 or 30 automatically (format: date-time)
  type: string@type-completer-5 # Type of rotation. May be one of 'daily', 'weekly' and 'hourly'
  --length: int # Length of the rotation with default value 1 (format: int32)
  participants: list # List of escalations, teams, users or the reserved word none which will be used in schedule. Each of them can be used multiple times and will be rotated in the order they given. — item shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string}
  --timeRestriction: record # shape: {type: "weekday-and-time-of-day"|"time-of-day"}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scheduleIdentifierType" $scheduleIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/schedules/($identifier)/rotations" $qp)
  let body = {name: $name, startDate: $startDate, endDate: $endDate, type: $type, length: $length, participants: $participants, timeRestriction: $timeRestriction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Schedule Rotations
#
# GET /v2/schedules/{identifier}/rotations
# Docs: https://www.opsgenie.com/docs/schedule-rotation-api#section-list-schedule-rotations — For more information
# operationId: listScheduleRotations
export def "schedules-rotations listScheduleRotations" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scheduleIdentifierType: string@scheduleIdentifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scheduleIdentifierType" $scheduleIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/schedules/($identifier)/rotations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Schedule Rotation
#
# GET /v2/schedules/{identifier}/rotations/{id}
# Docs: https://www.opsgenie.com/docs/schedule-rotation-api#section-get-schedule-rotation — For more information
# operationId: getScheduleRotation
export def "schedules-rotations get" [
  identifier: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scheduleIdentifierType: string@scheduleIdentifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scheduleIdentifierType" $scheduleIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/schedules/($identifier)/rotations/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Schedule Rotation (Partial)
#
# PATCH /v2/schedules/{identifier}/rotations/{id}
# Docs: https://www.opsgenie.com/docs/schedule-rotation-api#section-update-schedule-rotation-partial — For more information
# operationId: updateScheduleRotation
# --participants item shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string}
# --timeRestriction shape: {type: "weekday-and-time-of-day"|"time-of-day"}
export def "schedules-rotations updateScheduleRotation" [
  identifier: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scheduleIdentifierType: string@scheduleIdentifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
  --name: string # Name of rotation
  --startDate: string # Defines a date time as an override start. Minutes may take 0 or 30 as value. Otherwise they will be converted to nearest 0 or 30 automatically (format: date-time)
  --endDate: string # Defines a date time as an override end. Minutes may take 0 or 30 as value. Otherwise they will be converted to nearest 0 or 30 automatically (format: date-time)
  --type: string@type-completer-5 # Type of rotation. May be one of 'daily', 'weekly' and 'hourly'
  --length: int # Length of the rotation with default value 1 (format: int32)
  --participants: list # List of escalations, teams, users or the reserved word none which will be used in schedule. Each of them can be used multiple times and will be rotated in the order they given. — item shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string}
  --timeRestriction: record # shape: {type: "weekday-and-time-of-day"|"time-of-day"}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scheduleIdentifierType" $scheduleIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/schedules/($identifier)/rotations/($id)" $qp)
  let body = {name: $name, startDate: $startDate, endDate: $endDate, type: $type, length: $length, participants: $participants, timeRestriction: $timeRestriction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Schedule Rotation
#
# DELETE /v2/schedules/{identifier}/rotations/{id}
# Docs: https://www.opsgenie.com/docs/schedule-rotation-api#section-delete-schedule-rotation — For more information
# operationId: deleteScheduleRotation
export def "schedules-rotations delete" [
  identifier: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scheduleIdentifierType: string@scheduleIdentifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scheduleIdentifierType" $scheduleIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/schedules/($identifier)/rotations/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Schedule Override
#
# POST /v2/schedules/{identifier}/overrides
# Docs: https://www.opsgenie.com/docs/schedule-override-api#section-create-schedule-override — For more information
# operationId: createScheduleOverride
# --user shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string}
# --rotations item shape: {id?: string, name?: string}
export def "schedules-overrides createScheduleOverride" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scheduleIdentifierType: string@scheduleIdentifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
  --alias: string # A user defined identifier for the override
  user: record # shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string}
  startDate: string # Time for override starting (format: date-time)
  endDate: string # Time for override ending (format: date-time)
  --rotations: list # Identifier (id or name) of rotations that override will apply. When it's set, only specified schedule rotations will be overridden — item shape: {id?: string, name?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scheduleIdentifierType" $scheduleIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/schedules/($identifier)/overrides" $qp)
  let body = {alias: $alias, user: $user, startDate: $startDate, endDate: $endDate, rotations: $rotations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Schedule Overrides
#
# GET /v2/schedules/{identifier}/overrides
# Docs: https://www.opsgenie.com/docs/schedule-override-api#section-list-schedule-overrides — For more information
# operationId: listScheduleOverride
export def "schedules-overrides listScheduleOverride" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scheduleIdentifierType: string@scheduleIdentifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scheduleIdentifierType" $scheduleIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/schedules/($identifier)/overrides" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Schedule Override
#
# GET /v2/schedules/{identifier}/overrides/{alias}
# Docs: https://www.opsgenie.com/docs/schedule-override-api#section-get-schedule-override — For more information
# operationId: getScheduleOverride
export def "schedules-overrides get" [
  identifier: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scheduleIdentifierType: string@scheduleIdentifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scheduleIdentifierType" $scheduleIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/schedules/($identifier)/overrides/($alias)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Schedule Override
#
# PUT /v2/schedules/{identifier}/overrides/{alias}
# Docs: https://www.opsgenie.com/docs/schedule-override-api#section-update-schedule-override — For more information
# operationId: updateScheduleOverride
# --user shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string}
# --rotations item shape: {id?: string, name?: string}
export def "schedules-overrides updateScheduleOverride" [
  identifier: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scheduleIdentifierType: string@scheduleIdentifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
  user: record # shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string}
  startDate: string # Time for override starting (format: date-time)
  endDate: string # Time for override ending (format: date-time)
  --rotations: list # Identifier (id or name) of rotations that override will apply. When it's set, only specified schedule rotations will be overridden — item shape: {id?: string, name?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scheduleIdentifierType" $scheduleIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/schedules/($identifier)/overrides/($alias)" $qp)
  let body = {user: $user, startDate: $startDate, endDate: $endDate, rotations: $rotations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Schedule Override
#
# DELETE /v2/schedules/{identifier}/overrides/{alias}
# Docs: https://www.opsgenie.com/docs/schedule-override-api#section-delete-schedule-override — For more information
# operationId: deleteScheduleOverride
export def "schedules-overrides delete" [
  identifier: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scheduleIdentifierType: string@scheduleIdentifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scheduleIdentifierType" $scheduleIdentifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/schedules/($identifier)/overrides/($alias)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List On Calls
#
# GET /v2/schedules/on-calls
# Docs: https://www.opsgenie.com/docs/who-is-on-call-api#section-list-on-calls — For more information
# operationId: listOnCalls
export def "schedules-on-calls listOnCalls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --flat: string@bool-completer # Retrieves user names of all on call participants if enabled
  --date: string # Starting date of the timeline (format: date-time)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "flat" $flat "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/schedules/on-calls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get On Calls
#
# GET /v2/schedules/{identifier}/on-calls
# Docs: https://www.opsgenie.com/docs/who-is-on-call-api#section-get-on-calls — For more information
# operationId: getOnCalls
export def "schedules-on-calls get" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scheduleIdentifierType: string@scheduleIdentifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
  --flat: string@bool-completer # Retrieves user names of all on call participants if enabled
  --date: string # Starting date of the timeline (format: date-time)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scheduleIdentifierType" $scheduleIdentifierType "scalar") (serialize-qp "flat" $flat "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/schedules/($identifier)/on-calls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Next On Calls
#
# GET /v2/schedules/{identifier}/next-on-calls
# Docs: https://www.opsgenie.com/docs/who-is-on-call-api#section-get-next-on-calls — For more information
# operationId: getNextOnCalls
export def "schedules-next-on-calls get" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scheduleIdentifierType: string@scheduleIdentifierType-completer # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
  --flat: string@bool-completer # Retrieves user names of all on call participants if enabled
  --date: string # Starting date of the timeline (format: date-time)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scheduleIdentifierType" $scheduleIdentifierType "scalar") (serialize-qp "flat" $flat "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/schedules/($identifier)/next-on-calls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export On-Call User
#
# GET /v2/schedules/on-calls/{identifier}.ics
# Docs: https://www.opsgenie.com/docs/who-is-on-call-api#section-export-on-call-user — For more information
# operationId: exportOnCallUser
export def "schedules-on-calls exportOnCallUser" [
  identifier: string
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
  let full_url = (build-url $base $"/v2/schedules/on-calls/($identifier).ics")
  let accept_val = "text/calendar"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Escalations
#
# GET /v2/escalations
# Docs: https://www.opsgenie.com/docs/escalation-api#section-list-escalations — For more information
# operationId: listEscalations
export def "escalations listEscalations" [
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
  let full_url = (build-url $base "/v2/escalations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Escalation
#
# POST /v2/escalations
# Docs: https://www.opsgenie.com/docs/escalation-api#section-create-escalation — For more information
# operationId: createEscalation
# --rules item shape: {condition: "if-not-acked"|"if-not-closed", notifyType: "default"|"next"|"previous"|"users"|"admins"|"all", delay: record, recipient: record}
# --ownerTeam shape: {id?: string, name?: string}
# --repeat shape: {waitInterval?: int, count?: int, resetRecipientStates?: bool, closeAlertAfterAll?: bool}
export def "escalations createEscalation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the escalation
  --description: string # Description of the escalation
  rules: list # List of escalation rules. — item shape: {condition: "if-not-acked"|"if-not-closed", notifyType: "default"|"next"|"previous"|"users"|"admins"|"all", delay: record, recipient: record}
  --ownerTeam: record # shape: {id?: string, name?: string}
  --repeat: record # shape: {waitInterval?: int, count?: int, resetRecipientStates?: bool, closeAlertAfterAll?: bool}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/escalations")
  let body = {name: $name, description: $description, rules: $rules, ownerTeam: $ownerTeam, repeat: $repeat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Escalation
#
# GET /v2/escalations/{identifier}
# Docs: https://www.opsgenie.com/docs/escalation-api#section-get-escalation — For more information
# operationId: getEscalation
export def "escalations get" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-1 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/escalations/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Escalation
#
# DELETE /v2/escalations/{identifier}
# Docs: https://www.opsgenie.com/docs/escalation-api#section-delete-escalation — For more information
# operationId: deleteEscalation
export def "escalations delete" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-1 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/escalations/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Escalation (Partial)
#
# PATCH /v2/escalations/{identifier}
# Docs: https://www.opsgenie.com/docs/escalation-api#section-update-escalation-partial — For more information
# operationId: updateEscalation
# --rules item shape: {condition: "if-not-acked"|"if-not-closed", notifyType: "default"|"next"|"previous"|"users"|"admins"|"all", delay: record, recipient: record}
# --ownerTeam shape: {id?: string, name?: string}
# --repeat shape: {waitInterval?: int, count?: int, resetRecipientStates?: bool, closeAlertAfterAll?: bool}
export def "escalations updateEscalation" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-1 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
  --name: string # Name of the escalation
  --description: string # Description of the escalation
  --rules: list # List of escalation rules. — item shape: {condition: "if-not-acked"|"if-not-closed", notifyType: "default"|"next"|"previous"|"users"|"admins"|"all", delay: record, recipient: record}
  --ownerTeam: record # shape: {id?: string, name?: string}
  --repeat: record # shape: {waitInterval?: int, count?: int, resetRecipientStates?: bool, closeAlertAfterAll?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/escalations/($identifier)" $qp)
  let body = {name: $name, description: $description, rules: $rules, ownerTeam: $ownerTeam, repeat: $repeat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Forwarding Rules
#
# GET /v2/forwarding-rules
# Docs: https://www.opsgenie.com/docs/forwarding-rule-api#section-list-forwarding-rules — For more information
# operationId: listForwardingRules
export def "forwarding-rules listForwardingRules" [
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
  let full_url = (build-url $base "/v2/forwarding-rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Forwarding Rule
#
# POST /v2/forwarding-rules
# Docs: https://www.opsgenie.com/docs/forwarding-rule-api#section-create-forwarding-rule — For more information
# operationId: createForwardingRule
# --fromUser shape: {id?: string, username?: string}
# --toUser shape: {id?: string, username?: string}
export def "forwarding-rules createForwardingRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  fromUser: record # shape: {id?: string, username?: string}
  toUser: record # shape: {id?: string, username?: string}
  startDate: string # The date and time for forwarding will start (format: date-time)
  endDate: string # The date and time for forwarding will end (format: date-time)
  --alias: string # A user defined identifier for the forwarding rule.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/forwarding-rules")
  let body = {fromUser: $fromUser, toUser: $toUser, startDate: $startDate, endDate: $endDate, alias: $alias} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Forwarding Rule
#
# GET /v2/forwarding-rules/{identifier}
# Docs: https://www.opsgenie.com/docs/forwarding-rule-api#section-get-forwarding-rule — For more information
# operationId: getForwardingRule
export def "forwarding-rules get" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-2 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'alias' (default: id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/forwarding-rules/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Forwarding Rule
#
# DELETE /v2/forwarding-rules/{identifier}
# Docs: https://www.opsgenie.com/docs/forwarding-rule-api#section-delete-forwarding-rule — For more information
# operationId: deleteForwardingRule
export def "forwarding-rules delete" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-2 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'alias' (default: id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/forwarding-rules/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Forwarding Rule
#
# PUT /v2/forwarding-rules/{identifier}
# Docs: https://www.opsgenie.com/docs/forwarding-rule-api#section-update-forwarding-rule — For more information
# operationId: updateForwardingRule
# --fromUser shape: {id?: string, username?: string}
# --toUser shape: {id?: string, username?: string}
export def "forwarding-rules updateForwardingRule" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-2 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'alias' (default: id)
  fromUser: record # shape: {id?: string, username?: string}
  toUser: record # shape: {id?: string, username?: string}
  startDate: string # The date and time for forwarding will start (format: date-time)
  endDate: string # The date and time for forwarding will end (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/forwarding-rules/($identifier)" $qp)
  let body = {fromUser: $fromUser, toUser: $toUser, startDate: $startDate, endDate: $endDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Custom User Roles
#
# GET /v2/roles
# Docs: https://docs.opsgenie.com/docs/users-and-user-roles#section-custom-roles — For more information
# operationId: listCustomUserRoles
export def "roles listCustomUserRoles" [
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
  let full_url = (build-url $base "/v2/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Custom User Role
#
# POST /v2/roles
# Docs: https://docs.opsgenie.com/docs/users-and-user-roles#section-custom-roles — For more information
# operationId: createCustomUserRole
export def "roles createCustomUserRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of custom user role
  --extendedRole: string # Custom role. Must not be one of the defined values (i.e. "user", "observer", "stakeholder")
  --grantedRights: list # Rights granted to the custom user role.
  --disallowedRights: list # Rights disallowed for the custom user role.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/roles")
  let body = {name: $name, extendedRole: $extendedRole, grantedRights: $grantedRights, disallowedRights: $disallowedRights} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Custom User Role
#
# GET /v2/roles/{identifier}
# Docs: https://docs.opsgenie.com/docs/users-and-user-roles#section-custom-roles — For more information
# operationId: getCustomUserRole
export def "roles get" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-1 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/roles/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Custom User Role
#
# DELETE /v2/roles/{identifier}
# Docs: https://docs.opsgenie.com/docs/users-and-user-roles#section-custom-roles — For more information
# operationId: deleteCustomUserRole
export def "roles delete" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-1 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/roles/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Custom User Role
#
# PUT /v2/roles/{identifier}
# Docs: https://docs.opsgenie.com/docs/users-and-user-roles#section-custom-roles — For more information
# operationId: updateCustomUserRole
export def "roles updateCustomUserRole" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-1 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'name' (default: id)
  --name: string # Name of custom user role
  --extendedRole: string # Custom role. Must not be one of the defined values (i.e. "user", "observer", "stakeholder")
  --grantedRights: list # Rights granted to the custom user role.
  --disallowedRights: list # Rights disallowed for the custom user role.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/roles/($identifier)" $qp)
  let body = {name: $name, extendedRole: $extendedRole, grantedRights: $grantedRights, disallowedRights: $disallowedRights} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Policy
#
# POST /v2/policies
# Discriminator (request): type
# Docs: https://docs.opsgenie.com/docs/alert-and-notification-policy-api#section-create-policy — For more information
# operationId: createPolicy
# --filter shape: {type: "match-all"|"match-any-condition"|"match-all-conditions"}
# --timeRestrictions shape: {type: "weekday-and-time-of-day"|"time-of-day"}
export def "policies createPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # TeamId of policy created if it belongs to a team
  --id: string
  --name: string # Name of the policy
  --policyDescription: string # Description of the policy
  --teamId: string # TeamId of the policy
  --filter: record # Defines the conditions that will be checked before applying rules and type of the operations that will be applied on conditions — shape: {type: "match-all"|"match-any-condition"|"match-all-conditions"}
  --timeRestrictions: record # shape: {type: "weekday-and-time-of-day"|"time-of-day"}
  --enabled: string@bool-completer # Activity status of the alert policy
  type: string@type-completer-6 # Type of the policy
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/policies" $qp)
  let body = {id: $id, name: $name, policyDescription: $policyDescription, teamId: $teamId, filter: $filter, timeRestrictions: $timeRestrictions, enabled: $enabled, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Alert Policies
#
# GET /v2/policies/alert
# Docs: https://docs.opsgenie.com/docs/alert-and-notification-policy-api#section-list-alert-policies — For more information
# operationId: listAlertPolicies
export def "policies-alert listAlertPolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # TeamId of policy created if it belongs to a team
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/policies/alert" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Notification Policies
#
# GET /v2/policies/notification
# Docs: https://docs.opsgenie.com/docs/alert-and-notification-policy-api#section-list-notification-policies — For more information
# operationId: listNotificationPolicies
export def "policies-notification listNotificationPolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # TeamId of policy created if it belongs to a team
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/policies/notification" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Policy
#
# DELETE /v2/policies/{policyId}
# Docs: https://docs.opsgenie.com/docs/alert-and-notification-policy-api#section-delete-policy — For more information
# operationId: deletePolicy
export def "policies delete-by-policyId-1" [
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # TeamId of policy created if it belongs to a team
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/policies/($policyId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Policy
#
# GET /v2/policies/{policyId}
# Docs: https://docs.opsgenie.com/docs/alert-and-notification-policy-api#section-get-policy — For more information
# operationId: getPolicy
export def "policies get-by-policyId-1" [
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # TeamId of policy created if it belongs to a team
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/policies/($policyId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Policy
#
# PUT /v2/policies/{policyId}
# Discriminator (request): type
# Docs: https://docs.opsgenie.com/docs/alert-and-notification-policy-api#section-update-policy — For more information
# operationId: updatePolicy
# --filter shape: {type: "match-all"|"match-any-condition"|"match-all-conditions"}
# --timeRestrictions shape: {type: "weekday-and-time-of-day"|"time-of-day"}
export def "policies updatePolicy" [
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # TeamId of policy created if it belongs to a team
  --id: string
  --name: string # Name of the policy
  --policyDescription: string # Description of the policy
  --teamId: string # TeamId of the policy
  --filter: record # Defines the conditions that will be checked before applying rules and type of the operations that will be applied on conditions — shape: {type: "match-all"|"match-any-condition"|"match-all-conditions"}
  --timeRestrictions: record # shape: {type: "weekday-and-time-of-day"|"time-of-day"}
  --enabled: string@bool-completer # Activity status of the alert policy
  type: string@type-completer-6 # Type of the policy
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/policies/($policyId)" $qp)
  let body = {id: $id, name: $name, policyDescription: $policyDescription, teamId: $teamId, filter: $filter, timeRestrictions: $timeRestrictions, enabled: $enabled, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enable Policy
#
# POST /v2/policies/{policyId}/enable
# Docs: https://docs.opsgenie.com/docs/alert-and-notification-policy-api#section-enable-policy — For more information
# operationId: enablePolicy
export def "policies-enable enablePolicy" [
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # TeamId of policy created if it belongs to a team
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/policies/($policyId)/enable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable Policy
#
# POST /v2/policies/{policyId}/disable
# Docs: https://docs.opsgenie.com/docs/alert-and-notification-policy-api#section-disable-policy — For more information
# operationId: disablePolicy
export def "policies-disable disablePolicy" [
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # TeamId of policy created if it belongs to a team
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/policies/($policyId)/disable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change Policy Order
#
# POST /v2/policies/{policyId}/change-order
# Docs: https://docs.opsgenie.com/docs/alert-and-notification-policy-api#section-change-policy-order — For more information
# operationId: changePolicyOrder
export def "policies-change-order changePolicyOrder" [
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # TeamId of policy created if it belongs to a team
  targetIndex: int # Order of the target policy will be changed to this value. Larger values than policy count will put the target policy to last place (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/policies/($policyId)/change-order" $qp)
  let body = {targetIndex: $targetIndex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Request Status of Incident
#
# GET /v1/incidents/requests/{requestId}
# Docs: https://docs.opsgenie.com/docs/incident-api#section-get-request-status — For more information
# operationId: getIncidentRequestStatus
export def "incidents-requests get" [
  requestId: string
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
  let full_url = (build-url $base $"/v1/incidents/requests/($requestId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Incident
#
# POST /v1/incidents/create
# Docs: https://docs.opsgenie.com/docs/incident-api#section-create-incident — For more information
# operationId: createIncident
# --responders item shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string}
export def "incidents-create createIncident" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  message: string # Message of the incident
  --description: string # Description field of the incident that is generally used to provide a detailed information about the incident.
  --responders: list # Responders that the incident will be routed to send notifications — item shape: {type: "all"|"none"|"user"|"escalation"|"schedule"|"team"|"group", id?: string}
  --tags: list # Tags of the incident.
  --details: record # Map of key-value pairs to use as custom properties of the incident
  --priority: string@priority-completer # Priority level of the incident
  --note: string # Additional note that will be added while creating the incident
  serviceId: string # Service on which incident will be created.
  --statusPageEntry: record # Status page entry fields. If this field is leaved blank, message and description of incident will be used for title and detail respectively.
  --notifyStakeholders: string@bool-completer # Indicate whether stakeholders are notified or not. Default value is false.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/incidents/create")
  let body = {message: $message, description: $description, responders: $responders, tags: $tags, details: $details, priority: $priority, note: $note, serviceId: $serviceId, statusPageEntry: $statusPageEntry, notifyStakeholders: $notifyStakeholders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Incident
#
# GET /v1/incidents/{identifier}
# Docs: https://docs.opsgenie.com/docs/incident-api#section-get-incident — For more information
# operationId: getIncident
export def "incidents get" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-3 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'tiny. Default is id' (default: id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/incidents/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Incident
#
# DELETE /v1/incidents/{identifier}
# Docs: https://docs.opsgenie.com/docs/incident-api#section-delete-incident — For more information
# operationId: deleteIncident
export def "incidents delete" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-3 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'tiny. Default is id' (default: id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/incidents/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List incidents
#
# GET /v1/incidents/
# Docs: https://docs.opsgenie.com/docs/incident-api#section-list-incidents — For more information
# operationId: ListIncidents
export def "incidents ListIncidents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Search query to apply while filtering the incidents.
  --offset: int # Start index of the result set (to apply pagination). Minimum value (and also default value) is 0. (format: int32)
  --limit: int # Maximum number of items to provide in the result. Must be a positive integer value. Default value is 20 and maximum value is 100 (format: int32)
  --qp-sort: string@sort-completer-1 # Name of the field that result set will be sorted by (default: createdAt)
  --order: string@order-completer # Sorting order of the result set (default: desc)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/incidents/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Close Incident
#
# POST /v1/incidents/{identifier}/close
# Docs: https://docs.opsgenie.com/docs/incident-api#section-close-incident — For more information
# operationId: closeIncident
export def "incidents-close closeIncident" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-3 # Type of the identifier that is provided as an in-line parameter. Possible values are 'id' or 'tiny. Default is id' (default: id)
  --note: string # Additional note that will be included with the incident
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/incidents/($identifier)/close" $qp)
  let body = {note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
