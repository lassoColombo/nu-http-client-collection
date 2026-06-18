# Auto-generated client for ADHybridHealthService v2014-01-01
# Source: https://api.apis.guru/v2/specs/azure.com/adhybridhealthservice-ADHybridHealthService/2014-01-01/swagger.json
# Auth: --token flag or $env.ADHYBRIDHEALTHSERVICE_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ADHYBRIDHEALTHSERVICE_TOKEN | default "" }
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

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def next-partition-key-completer [] { [" "] }
def next-row-key-completer [] { [" "] }
def server-reported-monitoring-level-completer [] { ["Full" "Off" "Partial"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-ad-hybrid-health-service-addsservices list-adds" } } | get name | first)
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

# Gets the details of Active Directory Domain Service, for a tenant, that are onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices
# operationId: addsServices_list
export def "providers-microsoft-ad-hybrid-health-service-addsservices list-adds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The service property filter to apply.
  --service-type: string # The service type for the services onboarded to Azure Active Directory Connect Health. Depending on whether the service is monitoring, ADFS, Sync or ADDS roles, the service type can either be AdFederationService or AadSyncService or AdDomainService.
  --skip-count: int # The skip count, which specifies the number of elements that can be bypassed from a sequence and then return the remaining elements.
  --take-count: int # The take count , which specifies the number of elements that can be returned from a sequence.
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "serviceType" $service_type "scalar") (serialize-qp "skipCount" $skip_count "scalar") (serialize-qp "takeCount" $take_count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.ADHybridHealthService/addsservices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Onboards a service for a given tenant in Azure Active Directory Connect Health.
#
# POST /providers/Microsoft.ADHybridHealthService/addsservices
# operationId: addsServices_add
export def "providers-microsoft-ad-hybrid-health-service-addsservices create-adds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
  --active-alerts: int # The count of alerts that are currently active for the service.
  --additional-information: string # The additional information related to the service.
  --created-date: string # The date and time, in UTC, when the service was onboarded to Azure Active Directory Connect Health. (format: date-time)
  --custom-notification-emails: list<string> # The list of additional emails that are configured to receive notifications about the service.
  --disabled: oneof<nothing, bool> # Indicates if the service is disabled or not.
  --display-name: string # The display name of the service.
  --health: string # The health of the service.
  --id: string # The id of the service.
  --last-disabled: string # The date and time, in UTC, when the service was last disabled. (format: date-time)
  --last-updated: string # The date or time , in UTC, when the service properties were last updated. (format: date-time)
  --monitoring-configurations-computed: record # The monitoring configuration of the service which determines what activities are monitored by Azure Active Directory Connect Health.
  --monitoring-configurations-customized: record # The customized monitoring configuration of the service which determines what activities are monitored by Azure Active Directory Connect Health.
  --notification-email-enabled: oneof<nothing, bool> # Indicates if email notification is enabled or not.
  --notification-email-enabled-for-global-admins: oneof<nothing, bool> # Indicates if email notification is enabled for global administrators of the tenant.
  --notification-emails: list<string> # The list of emails to whom service notifications will be sent.
  --notification-emails-enabled-for-global-admins: oneof<nothing, bool> # Indicates if email notification is enabled for global administrators of the tenant.
  --original-disabled-state: oneof<nothing, bool> # Gets the original disable state.
  --resolved-alerts: int # The total count of alerts that has been resolved for the service.
  --service-id: string # The id of the service.
  --service-name: string # The name of the service.
  --signature: string # The signature of the service.
  --simple-properties: record # List of service specific configuration properties.
  --tenant-id: string # The id of the tenant to which the service is registered to.
  --type: string # The service type for the services onboarded to Azure Active Directory Connect Health. Depending on whether the service is monitoring, ADFS, Sync or ADDS roles, the service type can either be AdFederationService or AadSyncService or AdDomainService.
]: any -> record<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list<string>, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list<string>, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.ADHybridHealthService/addsservices" $qp)
  let req_body = {"activeAlerts": $active_alerts, "additionalInformation": $additional_information, "createdDate": $created_date, "customNotificationEmails": $custom_notification_emails, "disabled": $disabled, "displayName": $display_name, "health": $health, "id": $id, "lastDisabled": $last_disabled, "lastUpdated": $last_updated, "monitoringConfigurationsComputed": $monitoring_configurations_computed, "monitoringConfigurationsCustomized": $monitoring_configurations_customized, "notificationEmailEnabled": $notification_email_enabled, "notificationEmailEnabledForGlobalAdmins": $notification_email_enabled_for_global_admins, "notificationEmails": $notification_emails, "notificationEmailsEnabledForGlobalAdmins": $notification_emails_enabled_for_global_admins, "originalDisabledState": $original_disabled_state, "resolvedAlerts": $resolved_alerts, "serviceId": $service_id, "serviceName": $service_name, "signature": $signature, "simpleProperties": $simple_properties, "tenantId": $tenant_id, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the details of Active Directory Domain Services for a tenant having Azure AD Premium license and is onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/premiumCheck
# operationId: addsServices_listPremiumServices
export def "providers-microsoft-ad-hybrid-health-service-addsservices-premium-check list-adds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The service property filter to apply.
  --service-type: string # The service type for the services onboarded to Azure Active Directory Connect Health. Depending on whether the service is monitoring, ADFS, Sync or ADDS roles, the service type can either be AdFederationService or AadSyncService or AdDomainService.
  --skip-count: int # The skip count, which specifies the number of elements that can be bypassed from a sequence and then return the remaining elements.
  --take-count: int # The take count , which specifies the number of elements that can be returned from a sequence.
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "serviceType" $service_type "scalar") (serialize-qp "skipCount" $skip_count "scalar") (serialize-qp "takeCount" $take_count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.ADHybridHealthService/addsservices/premiumCheck" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an Active Directory Domain Service which is onboarded to Azure Active Directory Connect Health.
#
# DELETE /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}
# operationId: addsServices_delete
export def "providers-microsoft-ad-hybrid-health-service-addsservices delete-adds" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --confirm: oneof<nothing, bool> # Indicates if the service will be permanently deleted or disabled. True indicates that the service will be permanently deleted and False indicates that the service will be marked disabled and then deleted after 30 days, if it is not re-registered.
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirm" $confirm "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the details of an Active Directory Domain Service for a tenant having Azure AD Premium license and is onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}
# operationId: addsServices_get
export def "providers-microsoft-ad-hybrid-health-service-addsservices get-adds" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list<string>, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list<string>, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an Active Directory Domain Service properties of an onboarded service.
#
# PATCH /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}
# operationId: addsServices_update
export def "providers-microsoft-ad-hybrid-health-service-addsservices update-adds" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
  --active-alerts: int # The count of alerts that are currently active for the service.
  --additional-information: string # The additional information related to the service.
  --created-date: string # The date and time, in UTC, when the service was onboarded to Azure Active Directory Connect Health. (format: date-time)
  --custom-notification-emails: list<string> # The list of additional emails that are configured to receive notifications about the service.
  --disabled: oneof<nothing, bool> # Indicates if the service is disabled or not.
  --display-name: string # The display name of the service.
  --health: string # The health of the service.
  --id: string # The id of the service.
  --last-disabled: string # The date and time, in UTC, when the service was last disabled. (format: date-time)
  --last-updated: string # The date or time , in UTC, when the service properties were last updated. (format: date-time)
  --monitoring-configurations-computed: record # The monitoring configuration of the service which determines what activities are monitored by Azure Active Directory Connect Health.
  --monitoring-configurations-customized: record # The customized monitoring configuration of the service which determines what activities are monitored by Azure Active Directory Connect Health.
  --notification-email-enabled: oneof<nothing, bool> # Indicates if email notification is enabled or not.
  --notification-email-enabled-for-global-admins: oneof<nothing, bool> # Indicates if email notification is enabled for global administrators of the tenant.
  --notification-emails: list<string> # The list of emails to whom service notifications will be sent.
  --notification-emails-enabled-for-global-admins: oneof<nothing, bool> # Indicates if email notification is enabled for global administrators of the tenant.
  --original-disabled-state: oneof<nothing, bool> # Gets the original disable state.
  --resolved-alerts: int # The total count of alerts that has been resolved for the service.
  --service-id: string # The id of the service.
  --body-service-name: string # The name of the service.
  --signature: string # The signature of the service.
  --simple-properties: record # List of service specific configuration properties.
  --tenant-id: string # The id of the tenant to which the service is registered to.
  --type: string # The service type for the services onboarded to Azure Active Directory Connect Health. Depending on whether the service is monitoring, ADFS, Sync or ADDS roles, the service type can either be AdFederationService or AadSyncService or AdDomainService.
]: any -> record<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list<string>, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list<string>, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}") $qp)
  let req_body = {"activeAlerts": $active_alerts, "additionalInformation": $additional_information, "createdDate": $created_date, "customNotificationEmails": $custom_notification_emails, "disabled": $disabled, "displayName": $display_name, "health": $health, "id": $id, "lastDisabled": $last_disabled, "lastUpdated": $last_updated, "monitoringConfigurationsComputed": $monitoring_configurations_computed, "monitoringConfigurationsCustomized": $monitoring_configurations_customized, "notificationEmailEnabled": $notification_email_enabled, "notificationEmailEnabledForGlobalAdmins": $notification_email_enabled_for_global_admins, "notificationEmails": $notification_emails, "notificationEmailsEnabledForGlobalAdmins": $notification_emails_enabled_for_global_admins, "originalDisabledState": $original_disabled_state, "resolvedAlerts": $resolved_alerts, "serviceId": $service_id, "serviceName": $body_service_name, "signature": $signature, "simpleProperties": $simple_properties, "tenantId": $tenant_id, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the details of the servers, for a given Active Directory Domain Service, that are onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/addomainservicemembers
# operationId: adDomainServiceMembers_list
export def "providers-microsoft-ad-hybrid-health-service-addsservices-addomainservicemembers list-domain-members" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The server property filter to apply.
  --is-groupby-site: oneof<nothing, bool> # Indicates if the result should be grouped by site or not.
  --query: string # The custom query.
  --next-partition-key: string@next-partition-key-completer # The next partition key to query for.
  --next-row-key: string@next-row-key-completer # The next row key to query for.
  --take-count: int # The take count , which specifies the number of elements that can be returned from a sequence.
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, addsRoles: list, createdDate: string, dcTypes: list, dimensions: list, disabled: bool, disabledReason: int, domainName: string, gcReachable: bool, installedQfes: list, isAdvertising: bool, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: list, monitoringConfigurationsCustomized: list, osName: string, osVersion: string, pdcReachable: bool, properties: list, recommendedQfes: list, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, siteName: string, status: string, sysvolState: bool, tenantId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "isGroupbySite" $is_groupby_site "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "nextPartitionKey" $next_partition_key "scalar") (serialize-qp "nextRowKey" $next_row_key "scalar") (serialize-qp "takeCount" $take_count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/addomainservicemembers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the details of the Active Directory Domain servers, for a given Active Directory Domain Service, that are onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/addsservicemembers
# operationId: addsServiceMembers_list
export def "providers-microsoft-ad-hybrid-health-service-addsservices-addsservicemembers list-adds-members" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The server property filter to apply.
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, addsRoles: list, createdDate: string, dcTypes: list, dimensions: list, disabled: bool, disabledReason: int, domainName: string, gcReachable: bool, installedQfes: list, isAdvertising: bool, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: list, monitoringConfigurationsCustomized: list, osName: string, osVersion: string, pdcReachable: bool, properties: list, recommendedQfes: list, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, siteName: string, status: string, sysvolState: bool, tenantId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/addsservicemembers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the alerts for a given Active Directory Domain Service.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/alerts
# operationId: alerts_listAddsAlerts
export def "providers-microsoft-ad-hybrid-health-service-addsservices-alerts list-adds" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The alert property filter to apply.
  --state: string # The alert state to query for.
  --qp-from: string # The start date to query for. (format: date-time)
  --qp-to: string # The end date till when to query for. (format: date-time)
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlertProperties: list, additionalInformation: list, alertId: string, createdDate: string, description: string, displayName: string, lastUpdated: string, level: string, monitorRoleType: string, relatedLinks: list, remediation: string, resolvedAlertProperties: list, resolvedDate: string, scope: string, serviceId: string, serviceMemberId: string, shortName: string, state: string, tenantId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/alerts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the service configurations.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/configuration
# operationId: configuration_listAddsConfigurations
export def "providers-microsoft-ad-hybrid-health-service-addsservices-configuration list-adds" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --grouping: string # The grouping for configurations.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "grouping" $grouping "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/configuration") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the dimensions for a given dimension type in a server.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/dimensions/{dimension}
# operationId: dimensions_listAddsDimensions
export def "providers-microsoft-ad-hybrid-health-service-addsservices-dimensions list-adds" [
  service_name: string
  dimension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, displayName: string, health: string, lastUpdated: string, resolvedAlerts: int, signature: string, simpleProperties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), dimension: (encode-path-segment $dimension)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/dimensions/{dimension}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the user preferences for a given feature.
#
# DELETE /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/features/{featureName}/userpreference
# operationId: addsServicesUserPreference_delete
export def "providers-microsoft-ad-hybrid-health-service-addsservices-features-userpreference delete-adds-user-preference" [
  service_name: string
  feature_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), feature_name: (encode-path-segment $feature_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/features/{feature_name}/userpreference") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the user preferences for a given feature.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/features/{featureName}/userpreference
# operationId: addsServicesUserPreference_get
export def "providers-microsoft-ad-hybrid-health-service-addsservices-features-userpreference get-adds-user-preference" [
  service_name: string
  feature_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<metricNames: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), feature_name: (encode-path-segment $feature_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/features/{feature_name}/userpreference") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds the user preferences for a given feature.
#
# POST /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/features/{featureName}/userpreference
# operationId: addsServicesUserPreference_add
export def "providers-microsoft-ad-hybrid-health-service-addsservices-features-userpreference create-adds-user-preference" [
  service_name: string
  feature_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
  --metric-names: list<string> # The name of the metric.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), feature_name: (encode-path-segment $feature_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/features/{feature_name}/userpreference") $qp)
  let req_body = {"metricNames": $metric_names} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the forest summary for a given Active Directory Domain Service, that is onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/forestsummary
# operationId: addsServices_getForestSummary
export def "providers-microsoft-ad-hybrid-health-service-addsservices-forestsummary get-adds-forest-summary" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<domainCount: int, domains: list<string>, forestName: string, monitoredDcCount: int, siteCount: int, sites: list<string>, totalDcCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/forestsummary") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the service related metrics information.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/metricmetadata
# operationId: addsServices_listMetricMetadata
export def "providers-microsoft-ad-hybrid-health-service-addsservices-metricmetadata list-adds-metric-metadata" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The metric metadata property filter to apply.
  --perf-counter: oneof<nothing, bool> # Indicates if only performance counter metrics are requested.
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<displayName: string, groupings: list, isDefault: bool, isDevOps: bool, isPerfCounter: bool, kind: string, maxValue: int, metricName: string, metricsProcessorClassName: string, minValue: int, valueKind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "perfCounter" $perf_counter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/metricmetadata") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the service related metric information.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/metricmetadata/{metricName}
# operationId: addsServices_getMetricMetadata
export def "providers-microsoft-ad-hybrid-health-service-addsservices-metricmetadata get-adds-metric-metadata" [
  service_name: string
  metric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<displayName: string, groupings: table<displayName: string, invisibleForUi: bool, key: string>, isDefault: bool, isDevOps: bool, isPerfCounter: bool, kind: string, maxValue: int, metricName: string, metricsProcessorClassName: string, minValue: int, valueKind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), metric_name: (encode-path-segment $metric_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/metricmetadata/{metric_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the service related metrics for a given metric and group combination.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/metricmetadata/{metricName}/groups/{groupName}
# operationId: addsServices_getMetricMetadataForGroup
export def "providers-microsoft-ad-hybrid-health-service-addsservices-metricmetadata-groups get-adds-metric-metadata" [
  service_name: string
  metric_name: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-key: string # The group key
  --from-date: string # The start date. (format: date-time)
  --to-date: string # The end date. (format: date-time)
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<sets: table<setName: string, values: list>, timeStamps: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupKey" $group_key "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), metric_name: (encode-path-segment $metric_name), group_name: (encode-path-segment $group_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/metricmetadata/{metric_name}/groups/{group_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the server related metrics for a given metric and group combination.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/metrics/{metricName}/groups/{groupName}
# operationId: addsService_getMetrics
export def "providers-microsoft-ad-hybrid-health-service-addsservices-metrics-groups get-adds" [
  service_name: string
  metric_name: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-key: string # The group key
  --from-date: string # The start date. (format: date-time)
  --to-date: string # The end date. (format: date-time)
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<sets: table<setName: string, values: list>, timeStamps: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupKey" $group_key "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), metric_name: (encode-path-segment $metric_name), group_name: (encode-path-segment $group_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/metrics/{metric_name}/groups/{group_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the average of the metric values for a given metric and group combination.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/metrics/{metricName}/groups/{groupName}/average
# operationId: addsServices_listMetricsAverage
export def "providers-microsoft-ad-hybrid-health-service-addsservices-metrics-groups-average list-adds" [
  service_name: string
  metric_name: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), metric_name: (encode-path-segment $metric_name), group_name: (encode-path-segment $group_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/metrics/{metric_name}/groups/{group_name}/average") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the sum of the metric values for a given metric and group combination.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/metrics/{metricName}/groups/{groupName}/sum
# operationId: addsServices_listMetricsSum
export def "providers-microsoft-ad-hybrid-health-service-addsservices-metrics-groups-sum list-adds" [
  service_name: string
  metric_name: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), metric_name: (encode-path-segment $metric_name), group_name: (encode-path-segment $group_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/metrics/{metric_name}/groups/{group_name}/sum") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets complete domain controller list along with replication details for a given Active Directory Domain Service, that is onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/replicationdetails
# operationId: addsServices_listReplicationDetails
export def "providers-microsoft-ad-hybrid-health-service-addsservices-replicationdetails list-adds-replication-details" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The server property filter to apply.
  --with-details: oneof<nothing, bool> # Indicates if InboundReplicationNeighbor details are required or not.
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<domain: string, inboundNeighborCollection: list, lastAttemptedSync: string, lastSuccessfulSync: string, site: string, status: int, targetServer: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "withDetails" $with_details "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/replicationdetails") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Replication status for a given Active Directory Domain Service, that is onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/replicationstatus
# operationId: addsServicesReplicationStatus_get
export def "providers-microsoft-ad-hybrid-health-service-addsservices-replicationstatus get-adds-replication-status" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<errorDcCount: int, forestName: string, totalDcCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/replicationstatus") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets complete domain controller list along with replication details for a given Active Directory Domain Service, that is onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/replicationsummary
# operationId: addsServices_listReplicationSummary
export def "providers-microsoft-ad-hybrid-health-service-addsservices-replicationsummary list-adds-replication-summary" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The server property filter to apply.
  --is-groupby-site: oneof<nothing, bool> # Indicates if the result should be grouped by site or not.
  --query: string # The custom query.
  --next-partition-key: string@next-partition-key-completer # The next partition key to query for.
  --next-row-key: string@next-row-key-completer # The next row key to query for.
  --take-count: int # The take count , which specifies the number of elements that can be returned from a sequence.
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<value: table<domain: string, inboundNeighborCollection: list, lastAttemptedSync: string, lastSuccessfulSync: string, site: string, status: int, targetServer: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "isGroupbySite" $is_groupby_site "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "nextPartitionKey" $next_partition_key "scalar") (serialize-qp "nextRowKey" $next_row_key "scalar") (serialize-qp "takeCount" $take_count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/replicationsummary") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the details of the servers, for a given Active Directory Domain Controller service, that are onboarded to Azure Active Directory Connect Health Service.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/servicemembers
# operationId: addsServicesServiceMembers_list
export def "providers-microsoft-ad-hybrid-health-service-addsservices-servicemembers list-adds-members" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The server property filter to apply.
  --dimension-type: string # The server specific dimension.
  --dimension-signature: string # The value of the dimension.
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, createdDate: string, dimensions: record, disabled: bool, disabledReason: int, installedQfes: record, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, osName: string, osVersion: string, properties: record, recommendedQfes: record, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, status: string, tenantId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "dimensionType" $dimension_type "scalar") (serialize-qp "dimensionSignature" $dimension_signature "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/servicemembers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Onboards a server, for a given Active Directory Domain Controller service, to Azure Active Directory Connect Health Service.
#
# POST /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/servicemembers
# operationId: addsServicesServiceMembers_add
export def "providers-microsoft-ad-hybrid-health-service-addsservices-servicemembers create-adds-members" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
  --active-alerts: int # The total number of alerts that are currently active for the server.
  --additional-information: string # The additional information, if any, for the server.
  --created-date: string # The date time , in UTC, when the server was onboarded to Azure Active Directory Connect Health. (format: date-time)
  --dimensions: record # The server specific configuration related dimensions.
  --disabled: oneof<nothing, bool> # Indicates if the server is disabled or not.
  --disabled-reason: int # The reason for disabling the server.
  --installed-qfes: record # The list of installed QFEs for the server.
  --last-disabled: string # The date and time , in UTC, when the server was last disabled. (format: date-time)
  --last-reboot: string # The date and time, in UTC, when the server was last rebooted. (format: date-time)
  --last-server-reported-monitoring-level-change: string # The date and time, in UTC, when the server's data monitoring configuration was last changed. (format: date-time)
  --last-updated: string # The date and time, in UTC, when the server properties were last updated. (format: date-time)
  --machine-id: string # The id of the machine.
  --machine-name: string # The name of the server.
  --monitoring-configurations-computed: record # The monitoring configuration of the server which determines what activities are monitored by Azure Active Directory Connect Health.
  --monitoring-configurations-customized: record # The customized monitoring configuration of the server which determines what activities are monitored by Azure Active Directory Connect Health.
  --os-name: string # The name of the operating system installed in the machine.
  --os-version: string # The version of the operating system installed in the machine.
  --properties: record # Server specific properties.
  --recommended-qfes: record # The list of recommended hotfixes for the server.
  --resolved-alerts: int # The total count of alerts that are resolved for this server.
  --role: string # The service role that is being monitored in the server.
  --server-reported-monitoring-level: string@server-reported-monitoring-level-completer # The monitoring level reported by the server.
  --service-id: string # The service id to whom this server belongs.
  --service-member-id: string # The id of the server.
  --status: string # The health status of the server.
  --tenant-id: string # The tenant id to whom this server belongs.
]: any -> record<activeAlerts: int, additionalInformation: string, createdDate: string, dimensions: record, disabled: bool, disabledReason: int, installedQfes: record, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, osName: string, osVersion: string, properties: record, recommendedQfes: record, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, status: string, tenantId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/servicemembers") $qp)
  let req_body = {"activeAlerts": $active_alerts, "additionalInformation": $additional_information, "createdDate": $created_date, "dimensions": $dimensions, "disabled": $disabled, "disabledReason": $disabled_reason, "installedQfes": $installed_qfes, "lastDisabled": $last_disabled, "lastReboot": $last_reboot, "lastServerReportedMonitoringLevelChange": $last_server_reported_monitoring_level_change, "lastUpdated": $last_updated, "machineId": $machine_id, "machineName": $machine_name, "monitoringConfigurationsComputed": $monitoring_configurations_computed, "monitoringConfigurationsCustomized": $monitoring_configurations_customized, "osName": $os_name, "osVersion": $os_version, "properties": $properties, "recommendedQfes": $recommended_qfes, "resolvedAlerts": $resolved_alerts, "role": $role, "serverReportedMonitoringLevel": $server_reported_monitoring_level, "serviceId": $service_id, "serviceMemberId": $service_member_id, "status": $status, "tenantId": $tenant_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a Active Directory Domain Controller server that has been onboarded to Azure Active Directory Connect Health Service.
#
# DELETE /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/servicemembers/{serviceMemberId}
# operationId: addsServiceMembers_delete
export def "providers-microsoft-ad-hybrid-health-service-addsservices-servicemembers delete-adds-members" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --confirm: oneof<nothing, bool> # Indicates if the server will be permanently deleted or disabled. True indicates that the server will be permanently deleted and False indicates that the server will be marked disabled and then deleted after 30 days, if it is not re-registered.
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirm" $confirm "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), service_member_id: (encode-path-segment $service_member_id)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/servicemembers/{service_member_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the details of a server, for a given Active Directory Domain Controller service, that are onboarded to Azure Active Directory Connect Health Service.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/servicemembers/{serviceMemberId}
# operationId: addsServiceMembers_get
export def "providers-microsoft-ad-hybrid-health-service-addsservices-servicemembers get-adds-members" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<activeAlerts: int, additionalInformation: string, createdDate: string, dimensions: record, disabled: bool, disabledReason: int, installedQfes: record, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, osName: string, osVersion: string, properties: record, recommendedQfes: record, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, status: string, tenantId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), service_member_id: (encode-path-segment $service_member_id)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/servicemembers/{service_member_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the details of an alert for a given Active Directory Domain Controller service and server combination.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/servicemembers/{serviceMemberId}/alerts
# operationId: addsServices_listServerAlerts
export def "providers-microsoft-ad-hybrid-health-service-addsservices-servicemembers-alerts list-adds-server" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The alert property filter to apply.
  --state: string # The alert state to query for.
  --qp-from: string # The start date to query for. (format: date-time)
  --qp-to: string # The end date till when to query for. (format: date-time)
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlertProperties: list, additionalInformation: list, alertId: string, createdDate: string, description: string, displayName: string, lastUpdated: string, level: string, monitorRoleType: string, relatedLinks: list, remediation: string, resolvedAlertProperties: list, resolvedDate: string, scope: string, serviceId: string, serviceMemberId: string, shortName: string, state: string, tenantId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), service_member_id: (encode-path-segment $service_member_id)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/servicemembers/{service_member_id}/alerts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the credentials of the server which is needed by the agent to connect to Azure Active Directory Connect Health Service.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/servicemembers/{serviceMemberId}/credentials
# operationId: addsServiceMembers_listCredentials
export def "providers-microsoft-ad-hybrid-health-service-addsservices-servicemembers-credentials list-adds-members" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The property filter to apply.
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<value: table<credentialData: list, identifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), service_member_id: (encode-path-segment $service_member_id)} | format pattern "/providers/Microsoft.ADHybridHealthService/addsservices/{service_name}/servicemembers/{service_member_id}/credentials") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the details of a tenant onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/configuration
# operationId: configuration_get
export def "providers-microsoft-ad-hybrid-health-service-configuration get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<aadLicense: string, aadPremium: bool, agentAutoUpdate: bool, alertSuppressionTimeInMins: int, consentedToMicrosoftDevOps: bool, countryLetterCode: string, createdDate: string, devOpsTtl: string, disabled: bool, disabledReason: int, globalAdminsEmail: list<string>, initialDomain: string, lastDisabled: string, lastVerified: string, onboarded: bool, onboardingAllowed: bool, pksCertificate: record, privatePreviewTenant: bool, tenantId: string, tenantInQuarantine: bool, tenantName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.ADHybridHealthService/configuration" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates tenant properties for tenants onboarded to Azure Active Directory Connect Health.
#
# PATCH /providers/Microsoft.ADHybridHealthService/configuration
# operationId: configuration_update
export def "providers-microsoft-ad-hybrid-health-service-configuration update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
  --aad-license: string # The Azure Active Directory license of the tenant.
  --aad-premium: oneof<nothing, bool> # Indicate if the tenant has Azure Active Directory Premium license or not.
  --agent-auto-update: oneof<nothing, bool> # Indicates if the tenant is configured to automatically receive updates for Azure Active Directory Connect Health client side features.
  --alert-suppression-time-in-mins: int # The time in minutes after which an alert will be auto-suppressed.
  --consented-to-microsoft-dev-ops: oneof<nothing, bool> # Indicates if the tenant data can be seen by Microsoft through Azure portal.
  --country-letter-code: string # The country letter code of the tenant.
  --created-date: string # The date, in UTC, when the tenant was onboarded to Azure Active Directory Connect Health. (format: date-time)
  --dev-ops-ttl: string # The date and time, in UTC, till when the tenant data can be seen by Microsoft through Azure portal. (format: date-time)
  --disabled: oneof<nothing, bool> # Indicates if the tenant is disabled in Azure Active Directory Connect Health.
  --disabled-reason: int # The reason due to which the tenant was disabled in Azure Active Directory Connect Health.
  --global-admins-email: list<string> # The list of global administrators for the tenant.
  --initial-domain: string # The initial domain of the tenant.
  --last-disabled: string # The date and time, in UTC, when the tenant was last disabled in Azure Active Directory Connect Health. (format: date-time)
  --last-verified: string # The date and time, in UTC, when the tenant onboarding status in Azure Active Directory Connect Health was last verified. (format: date-time)
  --onboarded: oneof<nothing, bool> # Indicates if the tenant is already onboarded to Azure Active Directory Connect Health.
  --onboarding-allowed: oneof<nothing, bool> # Indicates if the tenant is allowed to onboard to Azure Active Directory Connect Health.
  --pks-certificate: record # The certificate associated with the tenant to onboard data to Azure Active Directory Connect Health.
  --private-preview-tenant: oneof<nothing, bool> # Indicates if the tenant has signed up for private preview of Azure Active Directory Connect Health features.
  --tenant-id: string # The Id of the tenant.
  --tenant-in-quarantine: oneof<nothing, bool> # Indicates if data collection for this tenant is disabled or not.
  --tenant-name: string # The name of the tenant.
]: any -> record<aadLicense: string, aadPremium: bool, agentAutoUpdate: bool, alertSuppressionTimeInMins: int, consentedToMicrosoftDevOps: bool, countryLetterCode: string, createdDate: string, devOpsTtl: string, disabled: bool, disabledReason: int, globalAdminsEmail: list<string>, initialDomain: string, lastDisabled: string, lastVerified: string, onboarded: bool, onboardingAllowed: bool, pksCertificate: record, privatePreviewTenant: bool, tenantId: string, tenantInQuarantine: bool, tenantName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.ADHybridHealthService/configuration" $qp)
  let req_body = {"aadLicense": $aad_license, "aadPremium": $aad_premium, "agentAutoUpdate": $agent_auto_update, "alertSuppressionTimeInMins": $alert_suppression_time_in_mins, "consentedToMicrosoftDevOps": $consented_to_microsoft_dev_ops, "countryLetterCode": $country_letter_code, "createdDate": $created_date, "devOpsTtl": $dev_ops_ttl, "disabled": $disabled, "disabledReason": $disabled_reason, "globalAdminsEmail": $global_admins_email, "initialDomain": $initial_domain, "lastDisabled": $last_disabled, "lastVerified": $last_verified, "onboarded": $onboarded, "onboardingAllowed": $onboarding_allowed, "pksCertificate": $pks_certificate, "privatePreviewTenant": $private_preview_tenant, "tenantId": $tenant_id, "tenantInQuarantine": $tenant_in_quarantine, "tenantName": $tenant_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Onboards a tenant in Azure Active Directory Connect Health.
#
# POST /providers/Microsoft.ADHybridHealthService/configuration
# operationId: configuration_add
export def "providers-microsoft-ad-hybrid-health-service-configuration create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<aadLicense: string, aadPremium: bool, agentAutoUpdate: bool, alertSuppressionTimeInMins: int, consentedToMicrosoftDevOps: bool, countryLetterCode: string, createdDate: string, devOpsTtl: string, disabled: bool, disabledReason: int, globalAdminsEmail: list<string>, initialDomain: string, lastDisabled: string, lastVerified: string, onboarded: bool, onboardingAllowed: bool, pksCertificate: record, privatePreviewTenant: bool, tenantId: string, tenantInQuarantine: bool, tenantName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.ADHybridHealthService/configuration" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the available Azure Data Factory API operations.
#
# GET /providers/Microsoft.ADHybridHealthService/operations
# operationId: operations_list
export def "providers-microsoft-ad-hybrid-health-service-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<display: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.ADHybridHealthService/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Checks if the user is enabled for Dev Ops access.
#
# GET /providers/Microsoft.ADHybridHealthService/reports/DevOps/IsDevOps
# operationId: reports_getDevOps
export def "providers-microsoft-ad-hybrid-health-service-reports-dev-ops-is-dev-ops get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<value: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.ADHybridHealthService/reports/DevOps/IsDevOps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the connector details for a service.
#
# GET /providers/Microsoft.ADHybridHealthService/service/{serviceName}/servicemembers/{serviceMemberId}/connectors
# operationId: serviceMembers_listConnectors
export def "providers-microsoft-ad-hybrid-health-service-service-servicemembers-connectors list-members" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<value: table<attributesIncluded: list, classesIncluded: list, connectorId: string, description: string, id: string, name: string, partitions: list, passwordHashSyncConfiguration: record, passwordManagementSettings: record, runProfiles: list, schemaXml: string, timeCreated: string, timeLastModified: string, type: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), service_member_id: (encode-path-segment $service_member_id)} | format pattern "/providers/Microsoft.ADHybridHealthService/service/{service_name}/servicemembers/{service_member_id}/connectors") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the details of services, for a tenant, that are onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/services
# operationId: services_list
export def "providers-microsoft-ad-hybrid-health-service-services list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The service property filter to apply.
  --service-type: string # The service type for the services onboarded to Azure Active Directory Connect Health. Depending on whether the service is monitoring, ADFS, Sync or ADDS roles, the service type can either be AdFederationService or AadSyncService or AdDomainService.
  --skip-count: int # The skip count, which specifies the number of elements that can be bypassed from a sequence and then return the remaining elements.
  --take-count: int # The take count , which specifies the number of elements that can be returned from a sequence.
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "serviceType" $service_type "scalar") (serialize-qp "skipCount" $skip_count "scalar") (serialize-qp "takeCount" $take_count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.ADHybridHealthService/services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Onboards a service for a given tenant in Azure Active Directory Connect Health.
#
# POST /providers/Microsoft.ADHybridHealthService/services
# operationId: services_add
export def "providers-microsoft-ad-hybrid-health-service-services create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
  --active-alerts: int # The count of alerts that are currently active for the service.
  --additional-information: string # The additional information related to the service.
  --created-date: string # The date and time, in UTC, when the service was onboarded to Azure Active Directory Connect Health. (format: date-time)
  --custom-notification-emails: list<string> # The list of additional emails that are configured to receive notifications about the service.
  --disabled: oneof<nothing, bool> # Indicates if the service is disabled or not.
  --display-name: string # The display name of the service.
  --health: string # The health of the service.
  --id: string # The id of the service.
  --last-disabled: string # The date and time, in UTC, when the service was last disabled. (format: date-time)
  --last-updated: string # The date or time , in UTC, when the service properties were last updated. (format: date-time)
  --monitoring-configurations-computed: record # The monitoring configuration of the service which determines what activities are monitored by Azure Active Directory Connect Health.
  --monitoring-configurations-customized: record # The customized monitoring configuration of the service which determines what activities are monitored by Azure Active Directory Connect Health.
  --notification-email-enabled: oneof<nothing, bool> # Indicates if email notification is enabled or not.
  --notification-email-enabled-for-global-admins: oneof<nothing, bool> # Indicates if email notification is enabled for global administrators of the tenant.
  --notification-emails: list<string> # The list of emails to whom service notifications will be sent.
  --notification-emails-enabled-for-global-admins: oneof<nothing, bool> # Indicates if email notification is enabled for global administrators of the tenant.
  --original-disabled-state: oneof<nothing, bool> # Gets the original disable state.
  --resolved-alerts: int # The total count of alerts that has been resolved for the service.
  --service-id: string # The id of the service.
  --service-name: string # The name of the service.
  --signature: string # The signature of the service.
  --simple-properties: record # List of service specific configuration properties.
  --tenant-id: string # The id of the tenant to which the service is registered to.
  --type: string # The service type for the services onboarded to Azure Active Directory Connect Health. Depending on whether the service is monitoring, ADFS, Sync or ADDS roles, the service type can either be AdFederationService or AadSyncService or AdDomainService.
]: any -> record<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list<string>, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list<string>, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.ADHybridHealthService/services" $qp)
  let req_body = {"activeAlerts": $active_alerts, "additionalInformation": $additional_information, "createdDate": $created_date, "customNotificationEmails": $custom_notification_emails, "disabled": $disabled, "displayName": $display_name, "health": $health, "id": $id, "lastDisabled": $last_disabled, "lastUpdated": $last_updated, "monitoringConfigurationsComputed": $monitoring_configurations_computed, "monitoringConfigurationsCustomized": $monitoring_configurations_customized, "notificationEmailEnabled": $notification_email_enabled, "notificationEmailEnabledForGlobalAdmins": $notification_email_enabled_for_global_admins, "notificationEmails": $notification_emails, "notificationEmailsEnabledForGlobalAdmins": $notification_emails_enabled_for_global_admins, "originalDisabledState": $original_disabled_state, "resolvedAlerts": $resolved_alerts, "serviceId": $service_id, "serviceName": $service_name, "signature": $signature, "simpleProperties": $simple_properties, "tenantId": $tenant_id, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the details of services for a tenant having Azure AD Premium license and is onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/services/premiumCheck
# operationId: services_listPremium
export def "providers-microsoft-ad-hybrid-health-service-services-premium-check list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The service property filter to apply.
  --service-type: string # The service type for the services onboarded to Azure Active Directory Connect Health. Depending on whether the service is monitoring, ADFS, Sync or ADDS roles, the service type can either be AdFederationService or AadSyncService or AdDomainService.
  --skip-count: int # The skip count, which specifies the number of elements that can be bypassed from a sequence and then return the remaining elements.
  --take-count: int # The take count , which specifies the number of elements that can be returned from a sequence.
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "serviceType" $service_type "scalar") (serialize-qp "skipCount" $skip_count "scalar") (serialize-qp "takeCount" $take_count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.ADHybridHealthService/services/premiumCheck" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a service which is onboarded to Azure Active Directory Connect Health.
#
# DELETE /providers/Microsoft.ADHybridHealthService/services/{serviceName}
# operationId: services_delete
export def "providers-microsoft-ad-hybrid-health-service-services delete" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --confirm: oneof<nothing, bool> # Indicates if the service will be permanently deleted or disabled. True indicates that the service will be permanently deleted and False indicates that the service will be marked disabled and then deleted after 30 days, if it is not re-registered.
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirm" $confirm "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the details of a service for a tenant having Azure AD Premium license and is onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}
# operationId: services_get
export def "providers-microsoft-ad-hybrid-health-service-services get" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list<string>, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list<string>, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the service properties of an onboarded service.
#
# PATCH /providers/Microsoft.ADHybridHealthService/services/{serviceName}
# operationId: services_update
export def "providers-microsoft-ad-hybrid-health-service-services update" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
  --active-alerts: int # The count of alerts that are currently active for the service.
  --additional-information: string # The additional information related to the service.
  --created-date: string # The date and time, in UTC, when the service was onboarded to Azure Active Directory Connect Health. (format: date-time)
  --custom-notification-emails: list<string> # The list of additional emails that are configured to receive notifications about the service.
  --disabled: oneof<nothing, bool> # Indicates if the service is disabled or not.
  --display-name: string # The display name of the service.
  --health: string # The health of the service.
  --id: string # The id of the service.
  --last-disabled: string # The date and time, in UTC, when the service was last disabled. (format: date-time)
  --last-updated: string # The date or time , in UTC, when the service properties were last updated. (format: date-time)
  --monitoring-configurations-computed: record # The monitoring configuration of the service which determines what activities are monitored by Azure Active Directory Connect Health.
  --monitoring-configurations-customized: record # The customized monitoring configuration of the service which determines what activities are monitored by Azure Active Directory Connect Health.
  --notification-email-enabled: oneof<nothing, bool> # Indicates if email notification is enabled or not.
  --notification-email-enabled-for-global-admins: oneof<nothing, bool> # Indicates if email notification is enabled for global administrators of the tenant.
  --notification-emails: list<string> # The list of emails to whom service notifications will be sent.
  --notification-emails-enabled-for-global-admins: oneof<nothing, bool> # Indicates if email notification is enabled for global administrators of the tenant.
  --original-disabled-state: oneof<nothing, bool> # Gets the original disable state.
  --resolved-alerts: int # The total count of alerts that has been resolved for the service.
  --service-id: string # The id of the service.
  --body-service-name: string # The name of the service.
  --signature: string # The signature of the service.
  --simple-properties: record # List of service specific configuration properties.
  --tenant-id: string # The id of the tenant to which the service is registered to.
  --type: string # The service type for the services onboarded to Azure Active Directory Connect Health. Depending on whether the service is monitoring, ADFS, Sync or ADDS roles, the service type can either be AdFederationService or AadSyncService or AdDomainService.
]: any -> record<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list<string>, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list<string>, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}") $qp)
  let req_body = {"activeAlerts": $active_alerts, "additionalInformation": $additional_information, "createdDate": $created_date, "customNotificationEmails": $custom_notification_emails, "disabled": $disabled, "displayName": $display_name, "health": $health, "id": $id, "lastDisabled": $last_disabled, "lastUpdated": $last_updated, "monitoringConfigurationsComputed": $monitoring_configurations_computed, "monitoringConfigurationsCustomized": $monitoring_configurations_customized, "notificationEmailEnabled": $notification_email_enabled, "notificationEmailEnabledForGlobalAdmins": $notification_email_enabled_for_global_admins, "notificationEmails": $notification_emails, "notificationEmailsEnabledForGlobalAdmins": $notification_emails_enabled_for_global_admins, "originalDisabledState": $original_disabled_state, "resolvedAlerts": $resolved_alerts, "serviceId": $service_id, "serviceName": $body_service_name, "signature": $signature, "simpleProperties": $simple_properties, "tenantId": $tenant_id, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Checks if the tenant, to which a service is registered, is whitelisted to use a feature.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/TenantWhitelisting/{featureName}
# operationId: services_getTenantWhitelisting
export def "providers-microsoft-ad-hybrid-health-service-services-tenant-whitelisting get" [
  service_name: string
  feature_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<value: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), feature_name: (encode-path-segment $feature_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/TenantWhitelisting/{feature_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the alerts for a given service.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/alerts
# operationId: services_listAlerts
export def "providers-microsoft-ad-hybrid-health-service-services-alerts list" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The alert property filter to apply.
  --state: string # The alert state to query for.
  --qp-from: string # The start date to query for. (format: date-time)
  --qp-to: string # The end date till when to query for. (format: date-time)
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlertProperties: list, additionalInformation: list, alertId: string, createdDate: string, description: string, displayName: string, lastUpdated: string, level: string, monitorRoleType: string, relatedLinks: list, remediation: string, resolvedAlertProperties: list, resolvedDate: string, scope: string, serviceId: string, serviceMemberId: string, shortName: string, state: string, tenantId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/alerts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Checks if the service has all the pre-requisites met to use a feature.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/checkServiceFeatureAvailibility/{featureName}
# operationId: services_getFeatureAvailibility
export def "providers-microsoft-ad-hybrid-health-service-services-check-service-feature-availibility get" [
  service_name: string
  feature_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<value: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), feature_name: (encode-path-segment $feature_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/checkServiceFeatureAvailibility/{feature_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the count of latest AAD export errors.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/exporterrors/counts
# operationId: services_listExportErrors
export def "providers-microsoft-ad-hybrid-health-service-services-exporterrors-counts list-export-errors" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<value: table<count: int, errorBucket: string, truncated: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/exporterrors/counts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the categorized export errors.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/exporterrors/listV2
# operationId: services_listExportErrorsV2
export def "providers-microsoft-ad-hybrid-health-service-services-exporterrors-list-v2 export-errors" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --error-bucket: string # The error category to query for.
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<value: table<attributeName: string, attributeValue: string, createdDate: string, csObjectId: string, dn: string, existingObject: record, exportErrorStatus: int, id: string, incomingObject: record, incomingObjectDisplayName: string, incomingObjectType: string, mergedEntityId: string, modifiedOrRemovedAttributeValue: string, runStepResultId: string, samAccountName: string, serverErrorDetail: string, serviceId: string, serviceMemberId: string, timeFirstOccurred: string, timeOccurred: string, type: string, userPrincipalName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "errorBucket" $error_bucket "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/exporterrors/listV2") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the export status.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/exportstatus
# operationId: services_listExportStatus
export def "providers-microsoft-ad-hybrid-health-service-services-exportstatus list-export-status" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<endTime: string, runStepResultId: string, serviceId: string, serviceMemberId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/exportstatus") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds an alert feedback submitted by customer.
#
# POST /providers/Microsoft.ADHybridHealthService/services/{serviceName}/feedbacktype/alerts/feedback
# operationId: services_addAlertFeedback
export def "providers-microsoft-ad-hybrid-health-service-services-feedbacktype-alerts-feedback create" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
  --comment: string # Additional comments related to the alert.
  --consented-to-share: oneof<nothing, bool> # Indicates if the alert feedback can be shared from product team.
  --created-date: string # The date and time,in UTC,when the alert was created. (format: date-time)
  --feedback: string # The feedback for the alert which indicates if the customer likes or dislikes the alert.
  --level: string # The alert level which indicates the severity of the alert.
  --service-member-id: string # The server Id of the alert.
  --short-name: string # The alert short name.
  --state: string # The alert state which can be either active or resolved with multiple resolution types.
]: any -> record<comment: string, consentedToShare: bool, createdDate: string, feedback: string, level: string, serviceMemberId: string, shortName: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/feedbacktype/alerts/feedback") $qp)
  let req_body = {"comment": $comment, "consentedToShare": $consented_to_share, "createdDate": $created_date, "feedback": $feedback, "level": $level, "serviceMemberId": $service_member_id, "shortName": $short_name, "state": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of all alert feedback for a given tenant and alert type.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/feedbacktype/alerts/{shortName}/alertfeedback
# operationId: services_listAlertFeedback
export def "providers-microsoft-ad-hybrid-health-service-services-feedbacktype-alerts-alertfeedback list-feedback" [
  service_name: string
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<value: table<comment: string, consentedToShare: bool, createdDate: string, feedback: string, level: string, serviceMemberId: string, shortName: string, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), short_name: (encode-path-segment $short_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/feedbacktype/alerts/{short_name}/alertfeedback") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the service related metrics information.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/metricmetadata
# operationId: services_listMetricMetadata
export def "providers-microsoft-ad-hybrid-health-service-services-metricmetadata list-metric-metadata" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The metric metadata property filter to apply.
  --perf-counter: oneof<nothing, bool> # Indicates if only performance counter metrics are requested.
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<displayName: string, groupings: list, isDefault: bool, isDevOps: bool, isPerfCounter: bool, kind: string, maxValue: int, metricName: string, metricsProcessorClassName: string, minValue: int, valueKind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "perfCounter" $perf_counter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/metricmetadata") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the service related metrics information.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/metricmetadata/{metricName}
# operationId: services_getMetricMetadata
export def "providers-microsoft-ad-hybrid-health-service-services-metricmetadata get-metric-metadata" [
  service_name: string
  metric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<displayName: string, groupings: table<displayName: string, invisibleForUi: bool, key: string>, isDefault: bool, isDevOps: bool, isPerfCounter: bool, kind: string, maxValue: int, metricName: string, metricsProcessorClassName: string, minValue: int, valueKind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), metric_name: (encode-path-segment $metric_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/metricmetadata/{metric_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the service related metrics for a given metric and group combination.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/metricmetadata/{metricName}/groups/{groupName}
# operationId: services_getMetricMetadataForGroup
export def "providers-microsoft-ad-hybrid-health-service-services-metricmetadata-groups get-metric-metadata" [
  service_name: string
  metric_name: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-key: string # The group key
  --from-date: string # The start date. (format: date-time)
  --to-date: string # The end date. (format: date-time)
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<sets: table<setName: string, values: list>, timeStamps: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupKey" $group_key "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), metric_name: (encode-path-segment $metric_name), group_name: (encode-path-segment $group_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/metricmetadata/{metric_name}/groups/{group_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the server related metrics for a given metric and group combination.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/metrics/{metricName}/groups/{groupName}
# operationId: service_getMetrics
export def "providers-microsoft-ad-hybrid-health-service-services-metrics-groups get" [
  service_name: string
  metric_name: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-key: string # The group key
  --from-date: string # The start date. (format: date-time)
  --to-date: string # The end date. (format: date-time)
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<sets: table<setName: string, values: list>, timeStamps: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupKey" $group_key "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), metric_name: (encode-path-segment $metric_name), group_name: (encode-path-segment $group_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/metrics/{metric_name}/groups/{group_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the average of the metric values for a given metric and group combination.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/metrics/{metricName}/groups/{groupName}/average
# operationId: services_listMetricsAverage
export def "providers-microsoft-ad-hybrid-health-service-services-metrics-groups-average list" [
  service_name: string
  metric_name: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), metric_name: (encode-path-segment $metric_name), group_name: (encode-path-segment $group_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/metrics/{metric_name}/groups/{group_name}/average") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the sum of the metric values for a given metric and group combination.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/metrics/{metricName}/groups/{groupName}/sum
# operationId: services_listMetricsSum
export def "providers-microsoft-ad-hybrid-health-service-services-metrics-groups-sum list" [
  service_name: string
  metric_name: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), metric_name: (encode-path-segment $metric_name), group_name: (encode-path-segment $group_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/metrics/{metric_name}/groups/{group_name}/sum") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the service level monitoring configuration.
#
# PATCH /providers/Microsoft.ADHybridHealthService/services/{serviceName}/monitoringconfiguration
# operationId: services_updateMonitoringConfiguration
export def "providers-microsoft-ad-hybrid-health-service-services-monitoringconfiguration update-monitoring-configuration" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
  --key: string # The key for the property.
  --value: string # The value for the key.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/monitoringconfiguration") $qp)
  let req_body = {"key": $key, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the service level monitoring configurations.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/monitoringconfigurations
# operationId: services_listMonitoringConfigurations
export def "providers-microsoft-ad-hybrid-health-service-services-monitoringconfigurations list-monitoring-configurations" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<value: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/monitoringconfigurations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the bad password login attempt report for an user
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/reports/badpassword/details/user
# operationId: services_listUserBadPasswordReport
export def "providers-microsoft-ad-hybrid-health-service-services-reports-badpassword-details-user list-bad-password" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data-source: string # The source of data, if its test data or customer data.
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<value: table<ipAddress: string, lastUpdated: string, totalErrorAttempts: int, uniqueIpAddresses: string, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataSource" $data_source "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/reports/badpassword/details/user") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all Risky IP report URIs for the last 7 days.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/reports/riskyIp/blobUris
# operationId: services_listAllRiskyIpDownloadReport
export def "providers-microsoft-ad-hybrid-health-service-services-reports-risky-ip-blob-uris list-list-download" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<value: table<blobCreateDateTime: string, jobCompletionTime: string, resultSasUri: string, serviceId: string, status: string, tenantId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/reports/riskyIp/blobUris") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initiate the generation of a new Risky IP report. Returns the URI for the new one.
#
# POST /providers/Microsoft.ADHybridHealthService/services/{serviceName}/reports/riskyIp/generateBlobUri
# operationId: services_listCurrentRiskyIpDownloadReport
export def "providers-microsoft-ad-hybrid-health-service-services-reports-risky-ip-generate-blob-uri list-get-download" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<value: table<blobCreateDateTime: string, jobCompletionTime: string, resultSasUri: string, serviceId: string, status: string, tenantId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/reports/riskyIp/generateBlobUri") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the details of the servers, for a given service, that are onboarded to Azure Active Directory Connect Health Service.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers
# operationId: serviceMembers_list
export def "providers-microsoft-ad-hybrid-health-service-services-servicemembers list-members" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The server property filter to apply.
  --dimension-type: string # The server specific dimension.
  --dimension-signature: string # The value of the dimension.
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, createdDate: string, dimensions: record, disabled: bool, disabledReason: int, installedQfes: record, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, osName: string, osVersion: string, properties: record, recommendedQfes: record, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, status: string, tenantId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "dimensionType" $dimension_type "scalar") (serialize-qp "dimensionSignature" $dimension_signature "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/servicemembers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Onboards a server, for a given service, to Azure Active Directory Connect Health Service.
#
# POST /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers
# operationId: serviceMembers_add
export def "providers-microsoft-ad-hybrid-health-service-services-servicemembers create-members" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
  --active-alerts: int # The total number of alerts that are currently active for the server.
  --additional-information: string # The additional information, if any, for the server.
  --created-date: string # The date time , in UTC, when the server was onboarded to Azure Active Directory Connect Health. (format: date-time)
  --dimensions: record # The server specific configuration related dimensions.
  --disabled: oneof<nothing, bool> # Indicates if the server is disabled or not.
  --disabled-reason: int # The reason for disabling the server.
  --installed-qfes: record # The list of installed QFEs for the server.
  --last-disabled: string # The date and time , in UTC, when the server was last disabled. (format: date-time)
  --last-reboot: string # The date and time, in UTC, when the server was last rebooted. (format: date-time)
  --last-server-reported-monitoring-level-change: string # The date and time, in UTC, when the server's data monitoring configuration was last changed. (format: date-time)
  --last-updated: string # The date and time, in UTC, when the server properties were last updated. (format: date-time)
  --machine-id: string # The id of the machine.
  --machine-name: string # The name of the server.
  --monitoring-configurations-computed: record # The monitoring configuration of the server which determines what activities are monitored by Azure Active Directory Connect Health.
  --monitoring-configurations-customized: record # The customized monitoring configuration of the server which determines what activities are monitored by Azure Active Directory Connect Health.
  --os-name: string # The name of the operating system installed in the machine.
  --os-version: string # The version of the operating system installed in the machine.
  --properties: record # Server specific properties.
  --recommended-qfes: record # The list of recommended hotfixes for the server.
  --resolved-alerts: int # The total count of alerts that are resolved for this server.
  --role: string # The service role that is being monitored in the server.
  --server-reported-monitoring-level: string@server-reported-monitoring-level-completer # The monitoring level reported by the server.
  --service-id: string # The service id to whom this server belongs.
  --service-member-id: string # The id of the server.
  --status: string # The health status of the server.
  --tenant-id: string # The tenant id to whom this server belongs.
]: any -> record<activeAlerts: int, additionalInformation: string, createdDate: string, dimensions: record, disabled: bool, disabledReason: int, installedQfes: record, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, osName: string, osVersion: string, properties: record, recommendedQfes: record, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, status: string, tenantId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/servicemembers") $qp)
  let req_body = {"activeAlerts": $active_alerts, "additionalInformation": $additional_information, "createdDate": $created_date, "dimensions": $dimensions, "disabled": $disabled, "disabledReason": $disabled_reason, "installedQfes": $installed_qfes, "lastDisabled": $last_disabled, "lastReboot": $last_reboot, "lastServerReportedMonitoringLevelChange": $last_server_reported_monitoring_level_change, "lastUpdated": $last_updated, "machineId": $machine_id, "machineName": $machine_name, "monitoringConfigurationsComputed": $monitoring_configurations_computed, "monitoringConfigurationsCustomized": $monitoring_configurations_customized, "osName": $os_name, "osVersion": $os_version, "properties": $properties, "recommendedQfes": $recommended_qfes, "resolvedAlerts": $resolved_alerts, "role": $role, "serverReportedMonitoringLevel": $server_reported_monitoring_level, "serviceId": $service_id, "serviceMemberId": $service_member_id, "status": $status, "tenantId": $tenant_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a server that has been onboarded to Azure Active Directory Connect Health Service.
#
# DELETE /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}
# operationId: serviceMembers_delete
export def "providers-microsoft-ad-hybrid-health-service-services-servicemembers delete-members" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --confirm: oneof<nothing, bool> # Indicates if the server will be permanently deleted or disabled. True indicates that the server will be permanently deleted and False indicates that the server will be marked disabled and then deleted after 30 days, if it is not re-registered.
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirm" $confirm "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), service_member_id: (encode-path-segment $service_member_id)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/servicemembers/{service_member_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the details of a server, for a given service, that are onboarded to Azure Active Directory Connect Health Service.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}
# operationId: serviceMembers_get
export def "providers-microsoft-ad-hybrid-health-service-services-servicemembers get-members" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<activeAlerts: int, additionalInformation: string, createdDate: string, dimensions: record, disabled: bool, disabledReason: int, installedQfes: record, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, osName: string, osVersion: string, properties: record, recommendedQfes: record, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, status: string, tenantId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), service_member_id: (encode-path-segment $service_member_id)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/servicemembers/{service_member_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the details of an alert for a given service and server combination.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/alerts
# operationId: serviceMembers_listAlerts
export def "providers-microsoft-ad-hybrid-health-service-services-servicemembers-alerts list-members" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The alert property filter to apply.
  --state: string # The alert state to query for.
  --qp-from: string # The start date to query for. (format: date-time)
  --qp-to: string # The end date till when to query for. (format: date-time)
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlertProperties: list, additionalInformation: list, alertId: string, createdDate: string, description: string, displayName: string, lastUpdated: string, level: string, monitorRoleType: string, relatedLinks: list, remediation: string, resolvedAlertProperties: list, resolvedDate: string, scope: string, serviceId: string, serviceMemberId: string, shortName: string, state: string, tenantId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), service_member_id: (encode-path-segment $service_member_id)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/servicemembers/{service_member_id}/alerts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the credentials of the server which is needed by the agent to connect to Azure Active Directory Connect Health Service.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/credentials
# operationId: serviceMembers_listCredentials
export def "providers-microsoft-ad-hybrid-health-service-services-servicemembers-credentials list-members" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The property filter to apply.
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<value: table<credentialData: list, identifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), service_member_id: (encode-path-segment $service_member_id)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/servicemembers/{service_member_id}/credentials") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the data uploaded by the server to Azure Active Directory Connect Health Service.
#
# DELETE /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/data
# operationId: serviceMembers_deleteData
export def "providers-microsoft-ad-hybrid-health-service-services-servicemembers-data delete-members" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), service_member_id: (encode-path-segment $service_member_id)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/servicemembers/{service_member_id}/data") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the last time when the server uploaded data to Azure Active Directory Connect Health Service.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/datafreshness
# operationId: serviceMembers_listDataFreshness
export def "providers-microsoft-ad-hybrid-health-service-services-servicemembers-datafreshness list-members-data-freshness" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<value: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), service_member_id: (encode-path-segment $service_member_id)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/servicemembers/{service_member_id}/datafreshness") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the export status.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/exportstatus
# operationId: serviceMembers_listExportStatus
export def "providers-microsoft-ad-hybrid-health-service-services-servicemembers-exportstatus list-members-export-status" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<continuationToken: string, nextLink: string, totalCount: int, value: table<endTime: string, runStepResultId: string, serviceId: string, serviceMemberId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), service_member_id: (encode-path-segment $service_member_id)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/servicemembers/{service_member_id}/exportstatus") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the global configuration.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/globalconfiguration
# operationId: serviceMembers_listGlobalConfiguration
export def "providers-microsoft-ad-hybrid-health-service-services-servicemembers-globalconfiguration list-members-global-configuration" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<value: table<featureSet: list, numSavedPwdEvent: int, passwordSyncEnabled: bool, schemaXml: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), service_member_id: (encode-path-segment $service_member_id)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/servicemembers/{service_member_id}/globalconfiguration") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of connectors and run profile names.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/metrics/{metricName}
# operationId: serviceMembers_getConnectorMetadata
export def "providers-microsoft-ad-hybrid-health-service-services-servicemembers-metrics get-members-connector-metadata" [
  service_name: string
  service_member_id: string
  metric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<connectors: table<connectorDisplayName: string, connectorId: string>, runProfileNames: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), service_member_id: (encode-path-segment $service_member_id), metric_name: (encode-path-segment $metric_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/servicemembers/{service_member_id}/metrics/{metric_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the server related metrics for a given metric and group combination.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/metrics/{metricName}/groups/{groupName}
# operationId: serviceMembers_getMetrics
export def "providers-microsoft-ad-hybrid-health-service-services-servicemembers-metrics-groups get-members" [
  service_name: string
  service_member_id: string
  metric_name: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-key: string # The group key
  --from-date: string # The start date. (format: date-time)
  --to-date: string # The end date. (format: date-time)
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<sets: table<setName: string, values: list>, timeStamps: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupKey" $group_key "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), service_member_id: (encode-path-segment $service_member_id), metric_name: (encode-path-segment $metric_name), group_name: (encode-path-segment $group_name)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/servicemembers/{service_member_id}/metrics/{metric_name}/groups/{group_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the service configuration.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/serviceconfiguration
# operationId: serviceMembers_getServiceConfiguration
export def "providers-microsoft-ad-hybrid-health-service-services-servicemembers-serviceconfiguration get-members-configuration" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request.
]: nothing -> record<serviceAccount: string, serviceType: int, sqlDatabaseName: string, sqlDatabaseSize: int, sqlEdition: string, sqlInstance: string, sqlServer: string, sqlVersion: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), service_member_id: (encode-path-segment $service_member_id)} | format pattern "/providers/Microsoft.ADHybridHealthService/services/{service_name}/servicemembers/{service_member_id}/serviceconfiguration") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
