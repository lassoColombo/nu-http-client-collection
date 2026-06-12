# Auto-generated client for Akamai: Application Security API vv1
# Source: https://raw.githubusercontent.com/akamai/akamai-apis/main/apis/appsec/v1/openapi.json
# Auth: --token flag or $env.AKAMAI_APPLICATION_SECURITY_API_TOKEN

const BASE_URL = "https://{hostname}/appsec/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AKAMAI_APPLICATION_SECURITY_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://{hostname}/appsec/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def action-completer [] { ["ACTIVATE" "DEACTIVATE"] }
def network-completer [] { ["PRODUCTION" "STAGING"] }
def reason-completer [] { ["FALSE_POSITIVE" "NOT_ELIGIBLE"] }
def operation-completer [] { ["AND" "OR"] }
def action-completer-1 [] { ["subscribe" "unsubscribe"] }
def cookieDomain-completer [] { ["automatic" "fqdn" "legacy" "psl"] }
def action-completer-2 [] { ["REMOVE"] }
def conditionOperator-completer [] { ["AND" "OR"] }
def requestBodyInspectionLimitInKB-completer [] { ["16" "32" "8" "default"] }
def sensitivity-completer [] { ["CONSERVATIVE" "MODERATE" "STRICT"] }
def defaultFile-completer [] { ["BASE_MATCH" "NO_MATCH" "RECURSIVE_MATCH"] }
def type-completer [] { ["api" "website"] }
def type-completer-1 [] { ["API" "WEBSITE"] }
def mode-completer [] { ["append" "remove" "replace"] }
def counterType-completer [] { ["per_edge" "region_aggregated"] }
def matchType-completer [] { ["api" "path"] }
def pathMatchType-completer [] { ["AllRequests" "Custom" "RequestDisabled" "TopLevel"] }
def penaltyBoxDuration-completer [] { ["FOUR_HOURS" "ONE_HOUR" "SIX_HOURS" "TEN_MINUTES" "THIRTY_MINUTES" "TWELVE_HOURS" "TWENTY_FOUR_HOURS"] }
def requestType-completer [] { ["ClientRequest" "ClientResponse" "ForwardRequest" "ForwardResponse"] }
def type-completer-2 [] { ["BOTMAN" "WAF"] }
def action-completer-3 [] { ["APPLY" "DISCARD"] }
def context-completer [] { ["DOSATCK" "SCANTL" "WEBATCK" "WEBSCRP"] }
def sharedIpHandling-completer [] { ["BOTH" "NON_SHARED" "SHARED_ONLY"] }
def challengeType-completer [] { ["AKAMAI_MOBILE_CRYPTO" "AKAMAI_WEB_CRYPTO" "GOOGLE_RECAPTCHA"] }
def action-completer-4 [] { ["alert" "deny" "none"] }
def eval-completer [] { ["COMPLETE" "RESTART" "START" "STOP" "UPDATE"] }
def mode-completer-1 [] { ["ASE_AUTO" "ASE_MANUAL"] }
def block-completer [] { ["blockAllTrafficExceptAllowedIPs" "blockSpecificIPGeo"] }
def unscannedAction-completer [] { ["alert" "deny" "none"] }
def mode-completer-2 [] { ["AAG" "ASE_AUTO" "ASE_MANUAL" "KRS"] }
def type-completer-3 [] { ["ACTIVE" "ALL" "EVALUATION"] }
def action-completer-5 [] { ["ACCEPT" "DECLINE" "RESET"] }
def action-completer-6 [] { ["abort" "alert"] }
def threatIntel-completer [] { ["off" "on"] }
def protectionType-completer [] { ["MULTIPLE" "SINGLE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "activations post-activations" } } | get name | first)
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

# Activate a configuration version
#
# POST /activations
# Docs: https://techdocs.akamai.com/application-security/reference/post-activations — See documentation for this operation in Akamai's Application Security API
# operationId: post-activations
# --acknowledgedInvalidHostsByConfig item shape: {configId: int, invalidHosts: list}
# --activationConfigs item shape: {configId: int, configVersion: int}
export def "activations post-activations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --acknowledgedInvalidHosts: list # The list of invalid hostnames in the security configuration to activate. In some cases, you may want to activate a security configuration with hostnames that WAF can't protect (for example, hostnames not managed as Akamai properties, or managed under a different contract than the configuration). By default, the existence of invalid hostnames blocks activation with a warning. The warning includes the names of the invalid hostnames. If you want to activate a configuration with invalid hostnames, enter the hostnames in this array. This field is now deprecated. Use `acknowledgedInvalidHostsByConfig` instead.
  --acknowledgedInvalidHostsByConfig: list # The list of invalid hostnames per security configuration to activate. In some cases, you may want to activate a security configuration with hostnames that WAF can't protect (for example, hostnames not managed as Akamai properties, or managed under a different contract than the configuration). By default, the existence of invalid hostnames blocks activation with a warning. The warning includes the names of the invalid hostnames. If you want to activate a configuration with invalid hostnames, enter the hostnames and the configuration ID in this array. — item shape: {configId: int, invalidHosts: list}
  action: string@action-completer # The action to take, either `ACTIVATE` or `DEACTIVATE`.
  activationConfigs: list # Specifies the security configuration and version to activate or deactivate. — item shape: {configId: int, configVersion: int}
  network: string@network-completer # The target Akamai activation environment, either `STAGING` or `PRODUCTION`.
  note: string # The notes you entered for the activation.
  notificationEmails: list # The email addresses to notify when the activation happens.
]: any -> record<action: string, activationConfigs: table<configId: int, configName: string, configVersion: int, previousConfigVersion: int>, activationId: int, completionDate: string, createDate: string, createdBy: string, dispatchCount: int, estimate: string, network: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activations" $qp)
  let body = {acknowledgedInvalidHosts: $acknowledgedInvalidHosts, acknowledgedInvalidHostsByConfig: $acknowledgedInvalidHostsByConfig, action: $action, activationConfigs: $activationConfigs, network: $network, note: $note, notificationEmails: $notificationEmails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an activation request status
#
# GET /activations/status/{statusId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-activations-status — See documentation for this operation in Akamai's Application Security API
# operationId: get-activations-status
export def "activations-status get-activations-status" [
  statusId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<createDate: string, statusId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/activations/status/($statusId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get activation status
#
# GET /activations/{activationId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-activation — See documentation for this operation in Akamai's Application Security API
# operationId: get-activation
export def "activations get-activation" [
  activationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<action: string, activationConfigs: table<configId: int, configName: string, configVersion: int, previousConfigVersion: int>, activationId: int, completionDate: string, createDate: string, createdBy: string, dispatchCount: int, estimate: string, network: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/activations/($activationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List discovered APIs
#
# GET /api-discovery
# Docs: https://techdocs.akamai.com/application-security/reference/get-api-list — See documentation for this operation in Akamai's Application Security API
# operationId: get-api-list
export def "api-discovery get-api-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeHidden: oneof<nothing, bool> # If `true`, includes all discovered APIs including ones you have hidden. By default, `false` returns only the visible APIs. (default: false, e.g. true)
  --search: string # Filter results by hostname or basepath. You can also match on substrings. (e.g. www.example.com)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<apis: table<basePath: string, encodedBasePath: string, encodedHost: string, host: string, lastModified: string, type: string, visibility: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeHidden" $includeHidden "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api-discovery" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a discovered API
#
# GET /api-discovery/host/{hostname}/basepath/{basePath}
# Docs: https://techdocs.akamai.com/application-security/reference/get-api-details — See documentation for this operation in Akamai's Application Security API
# operationId: get-api-details
export def "api-discovery-host-basepath get-api-details" [
  hostname: string
  basePath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeHidden: oneof<nothing, bool> # If `true`, includes all discovered APIs including ones you have hidden. By default, `false` returns only the visible APIs. (default: false, e.g. true)
  --search: string # Filter results by name, description, or ID. You can match on substrings. (e.g. SQL Injection)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<apiEndpointIds: list<int>, basePath: string, discoveryType: string, enrichment: record<options: int, browsers: int, clientErrors: int, clientReputation: float, dateFirstSeen: string, dateLastModified: string, dateLastSeen: string, deletes: int, dosAttackers: float, formats: list<string>, gets: int, hostSamples: list<string>, mobiles: int, newlyDiscovered: bool, paths: list<record>, posts: int, puts: int, redirects: int, requests: int, requestsBadReputation: float, requestsLastDay: int, scanningTools: float, serverErrors: int, successes: int, totalDailyRequests: list<record>, totalErrors: int, trend: string, webAttackers: float, webScrapers: float>, host: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeHidden" $includeHidden "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api-discovery/host/($hostname)/basepath/($basePath)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify an API's visibility
#
# PUT /api-discovery/host/{hostname}/basepath/{basePath}
# Docs: https://techdocs.akamai.com/application-security/reference/put-api-visibility — See documentation for this operation in Akamai's Application Security API
# operationId: put-api-visibility
export def "api-discovery-host-basepath put-api-visibility" [
  hostname: string
  basePath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --hidden: oneof<nothing, bool> # Describes an API's visibility status.
  --reason: string@reason-completer # The reason you've decided to hide the API from the API list. Use `NOT_ELIGIBLE` if you want to hide it for now and choose what to do with the API at a later time. Use `FALSE_POSITIVE` for APIs you feel are incorrectly included in the data.
]: any -> record<hidden: bool, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api-discovery/host/($hostname)/basepath/($basePath)" $qp)
  let body = {hidden: $hidden, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create an endpoint or resource
#
# POST /api-discovery/host/{hostname}/basepath/{basePath}/endpoints
# Docs: https://techdocs.akamai.com/application-security/reference/post-api-endpoint-resource — See documentation for this operation in Akamai's Application Security API
# operationId: post-api-endpoint-resource
export def "api-discovery-host-basepath-endpoints post-api-endpoint-resource" [
  hostname: string
  basePath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --apiEndpointId: int # A unique identifier for an API endpoint. You need this when adding a resource to an existing endpoint.
  --apiName: string # The name for this API endpoint. You need this to register an endpoint.
  --contractId: string # A unique identifier for a contract. You need this when registering a new endpoint.
  --groupId: int # A unique identifier for a group. You need this when registering a new endpoint.
  --version: int # The version number. You need this when adding a resource to an existing endpoint. When a version is read-only, the version is cloned and updates are included in the newly cloned version.
]: any -> record<akamaiSecurityRestrictions: record<ALLOW_UNDEFINED_RESPONSE_BODY_PARAMS: int, ALLOW_UNDEFINED_RESPONSE_HEADER_PARAMS: int, MAX_BODY_SIZE: int, MAX_DOC_DEPTH: int, MAX_ELEMENT_NAME_LENGTH: int, MAX_INTEGER_VALUE: int, MAX_JSONXML_ELEMENT: int, MAX_STRING_LENGTH: int, POSITIVE_SECURITY_ENABLED: int>, apiCategoryIds: list<int>, apiEndPointHosts: list<string>, apiEndPointId: int, apiEndPointLocked: bool, apiEndPointName: string, apiEndPointScheme: string, apiEndPointVersion: int, apiResources: table<apiResourceClonedFromId: int, apiResourceId: int, apiResourceLogicId: int, apiResourceMethodNameLists: list, apiResourceMethods: list, apiResourceName: string, createDate: string, createdBy: string, description: string, link: string, lockVersion: int, private: bool, resourcePath: string, updateDate: string, updatedBy: string>, apiVersionInfo: record<location: string, parameterName: string, value: string>, availableActions: list<string>, basePath: string, caseSensitive: bool, clonedFromVersion: int, consumeType: string, contractId: string, createDate: string, createdBy: string, description: string, endpointHidden: bool, groupId: int, isGraphQL: bool, lockVersion: int, positiveConstrainsEnabled: bool, productionStatus: string, productionVersion: record, protectedByApiKey: bool, securityScheme: record<securitySchemeDetail: record<apiKeyLocation: string, apiKeyName: string>, securitySchemeType: string>, source: record, stagingStatus: string, stagingVersion: record, updateDate: string, updatedBy: string, versionHidden: bool, versionNumber: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api-discovery/host/($hostname)/basepath/($basePath)/endpoints" $qp)
  let body = {apiEndpointId: $apiEndpointId, apiName: $apiName, contractId: $contractId, groupId: $groupId, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List discovered API endpoints
#
# GET /api-discovery/host/{hostname}/basepath/{basePath}/endpoints
# Docs: https://techdocs.akamai.com/application-security/reference/get-discovered-api-endpoints — See documentation for this operation in Akamai's Application Security API
# operationId: get-discovered-api-endpoints
export def "api-discovery-host-basepath-endpoints get-discovered-api-endpoints" [
  hostname: string
  basePath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<apis: table<apiEndPointId: int, apiEndPointName: string, latest: record, production: record, staging: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api-discovery/host/($hostname)/basepath/($basePath)/endpoints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a configuration
#
# POST /configs
# Docs: https://techdocs.akamai.com/application-security/reference/post-config — See documentation for this operation in Akamai's Application Security API
# operationId: post-config
# --createFrom shape: {configId: int, version: int}
export def "configs post-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --configId: int # Uniquely identifies the security configuration.
  --contractId: string # Contract ID.
  --createFrom: record # Contains details about a source configuration and version for cloning a new security configuration. — shape: {configId: int, version: int}
  description: string # Describes the security configuration.
  --groupId: int # Group ID.
  hostnames: list # List of hostnames to be added to the configuration.
  name: string # The name you assigned to the security configuration.
  --version: int # The configuration version of the security configuration.
]: any -> record<configId: int, contractId: string, createFrom: record<configId: int, version: int>, description: string, groupId: int, hostnames: list<string>, name: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/configs" $qp)
  let body = {configId: $configId, contractId: $contractId, createFrom: $createFrom, description: $description, groupId: $groupId, hostnames: $hostnames, name: $name, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List configurations
#
# GET /configs
# Docs: https://techdocs.akamai.com/application-security/reference/get-configs — See documentation for this operation in Akamai's Application Security API
# operationId: get-configs
export def "configs get-configs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<configurations: table<description: string, id: int, latestVersion: int, name: string, productionHostnames: list, productionVersion: int, stagingVersion: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/configs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a security configuration
#
# GET /configs/{configId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-config — See documentation for this operation in Akamai's Application Security API
# operationId: get-config
export def "configs get-config" [
  configId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeHostnames: oneof<nothing, bool> # If `true`, include the list of hostnames protected by this security configuration in the production network.  If `false`, exclude the list of hostnames protected by this security configuration in the production network. (default: false, e.g. false)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<description: string, id: int, latestVersion: int, name: string, productionHostnames: list<string>, productionVersion: int, stagingVersion: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeHostnames" $includeHostnames "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rename a security configuration
#
# PUT /configs/{configId}
# Docs: https://techdocs.akamai.com/application-security/reference/put-config — See documentation for this operation in Akamai's Application Security API
# operationId: put-config
export def "configs put-config" [
  configId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --description: string # Describes the security configuration.
  name: string # The name you assigned to the security configuration.
]: any -> record<description: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)" $qp)
  let body = {description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a configuration
#
# DELETE /configs/{configId}
# Docs: https://techdocs.akamai.com/application-security/reference/delete-config — See documentation for this operation in Akamai's Application Security API
# operationId: delete-config
export def "configs delete-config" [
  configId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List activation history
#
# GET /configs/{configId}/activations
# Docs: https://techdocs.akamai.com/application-security/reference/get-activation-history — See documentation for this operation in Akamai's Application Security API
# operationId: get-activation-history
export def "configs-activations get-activation-history" [
  configId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<activationHistory: table<activatedBy: string, activationDate: string, activationId: int, network: string, notes: string, status: string, version: int>, configId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/activations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a custom rule
#
# POST /configs/{configId}/custom-rules
# Docs: https://techdocs.akamai.com/application-security/reference/post-config-custom-rules — See documentation for this operation in Akamai's Application Security API
# operationId: post-config-custom-rules
# --conditions item shape: {name?: any, nameCase?: bool, nameWildcard?: bool, positiveMatch: bool, type: "cookieMatch"|"extensionMatch"|"filenameMatch"|"ipMatch"|"pathMatch"|"requestHeaderMatch"|"requestMethodMatch"|"requestProtocolVersionMatch"|"uriQueryMatch"|"headerOrderMatch"|"argsPostMatch"|"argsPostNamesMatch"|"clientCertPresentMatch"|"clientCertValidMatch"|"clientTlsFingerprintMatch"|"hostMatch"|"ipAddressMatch"|"geoMatch"|"asNumberMatch"|"clientListMatch", useXForwardForHeaders?: bool, value?: string, valueCase?: bool, valueExactMatch?: bool, valueIgnoreSegment?: bool, valueNormalize?: bool, valueRecursive?: bool, valueWildcard?: bool}
# --effectiveTimePeriod shape: {endDate: string, startDate: string, status?: "active"|"inactive"|"expiring"|"expired"}
# --loggingOptions item shape: {id: "CLIENT_TLS_FINGERPRINT_MATCH"|"HEADER_ORDER_MATCH"|"REQUEST_HEADER_MATCH"|"COOKIE_MATCH"|"URI_QUERY_MATCH"|"ARGS_POST_MATCH", name?: string, value?: string}
export def "configs-custom-rules post-config-custom-rules" [
  configId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --conditions: list # Contains the details about the condition that triggers the custom rule. — item shape: {name?: any, nameCase?: bool, nameWildcard?: bool, positiveMatch: bool, type: "cookieMatch"|"extensionMatch"|"filenameMatch"|"ipMatch"|"pathMatch"|"requestHeaderMatch"|"requestMethodMatch"|"requestProtocolVersionMatch"|"uriQueryMatch"|"headerOrderMatch"|"argsPostMatch"|"argsPostNamesMatch"|"clientCertPresentMatch"|"clientCertValidMatch"|"clientTlsFingerprintMatch"|"hostMatch"|"ipAddressMatch"|"geoMatch"|"asNumberMatch"|"clientListMatch", useXForwardForHeaders?: bool, value?: string, valueCase?: bool, valueExactMatch?: bool, valueIgnoreSegment?: bool, valueNormalize?: bool, valueRecursive?: bool, valueWildcard?: bool}
  --description: string # The custom rule description.
  --effectiveTimePeriod: record # The time period during which the custom rule is active. — shape: {endDate: string, startDate: string, status?: "active"|"inactive"|"expiring"|"expired"}
  --id: int # Uniquely identifies the rule.
  --inspectRequest: oneof<nothing, bool> # Whether to inspect the HTTP request for unstructured custom rules.
  --inspectResponse: oneof<nothing, bool> # Whether to inspect the HTTP response for unstructured custom rules.
  --loggingOptions: list # The specific conditions to be logged. — item shape: {id: "CLIENT_TLS_FINGERPRINT_MATCH"|"HEADER_ORDER_MATCH"|"REQUEST_HEADER_MATCH"|"COOKIE_MATCH"|"URI_QUERY_MATCH"|"ARGS_POST_MATCH", name?: string, value?: string}
  --metadata: string # The metadata you provided for unstructured custom rules.
  name: string # The custom rule name.
  operation: string@operation-completer # Specify `AND` logic to require all conditions, or `OR` logic to require at least one condition to match.
  --ruleActivated: oneof<nothing, bool> # Whether the rule is active in the configuration.
  --samplingRate: int # The portion of traffic to sample, expressed as a percent.
  --stagingOnly: oneof<nothing, bool> # Whether to show traffic from only the staging network, or all traffic. The default setting is `false` and only shows in the response when `true`. (default: false)
  --structured: oneof<nothing, bool> # Whether you created the rule with the structured custom rule builder or free-form XML. This needs to be `true`.
  --tag: list # The list of labels you assigned to the custom rule.
  --version: int # The custom rule version.
]: any -> record<conditions: table<name: any, nameCase: bool, nameWildcard: bool, positiveMatch: bool, type: string, useXForwardForHeaders: bool, value: string, valueCase: bool, valueExactMatch: bool, valueIgnoreSegment: bool, valueNormalize: bool, valueRecursive: bool, valueWildcard: bool>, description: string, effectiveTimePeriod: record<endDate: string, startDate: string, status: string>, id: int, inspectRequest: bool, inspectResponse: bool, loggingOptions: table<id: string, name: string, value: string>, metadata: string, name: string, operation: string, ruleActivated: bool, samplingRate: int, stagingOnly: bool, structured: bool, tag: list<string>, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/custom-rules" $qp)
  let body = {conditions: $conditions, description: $description, effectiveTimePeriod: $effectiveTimePeriod, id: $id, inspectRequest: $inspectRequest, inspectResponse: $inspectResponse, loggingOptions: $loggingOptions, metadata: $metadata, name: $name, operation: $operation, ruleActivated: $ruleActivated, samplingRate: $samplingRate, stagingOnly: $stagingOnly, structured: $structured, tag: $tag, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List custom rules
#
# GET /configs/{configId}/custom-rules
# Docs: https://techdocs.akamai.com/application-security/reference/get-configs-custom-rules — See documentation for this operation in Akamai's Application Security API
# operationId: get-configs-custom-rules
export def "configs-custom-rules get-configs-custom-rules" [
  configId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<customRules: table<effectiveTimePeriod: record, id: int, link: string, name: string, samplingRate: int, status: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/custom-rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a custom rule
#
# GET /configs/{configId}/custom-rules/{ruleId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-config-custom-rule — See documentation for this operation in Akamai's Application Security API
# operationId: get-config-custom-rule
export def "configs-custom-rules get-config-custom-rule" [
  ruleId: int
  configId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<conditions: table<name: any, nameCase: bool, nameWildcard: bool, positiveMatch: bool, type: string, useXForwardForHeaders: bool, value: string, valueCase: bool, valueExactMatch: bool, valueIgnoreSegment: bool, valueNormalize: bool, valueRecursive: bool, valueWildcard: bool>, description: string, effectiveTimePeriod: record<endDate: string, startDate: string, status: string>, id: int, inspectRequest: bool, inspectResponse: bool, loggingOptions: table<id: string, name: string, value: string>, metadata: string, name: string, operation: string, ruleActivated: bool, samplingRate: int, stagingOnly: bool, structured: bool, tag: list<string>, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/custom-rules/($ruleId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a custom rule
#
# PUT /configs/{configId}/custom-rules/{ruleId}
# Docs: https://techdocs.akamai.com/application-security/reference/put-config-custom-rule — See documentation for this operation in Akamai's Application Security API
# operationId: put-config-custom-rule
# --conditions item shape: {name?: any, nameCase?: bool, nameWildcard?: bool, positiveMatch: bool, type: "cookieMatch"|"extensionMatch"|"filenameMatch"|"ipMatch"|"pathMatch"|"requestHeaderMatch"|"requestMethodMatch"|"requestProtocolVersionMatch"|"uriQueryMatch"|"headerOrderMatch"|"argsPostMatch"|"argsPostNamesMatch"|"clientCertPresentMatch"|"clientCertValidMatch"|"clientTlsFingerprintMatch"|"hostMatch"|"ipAddressMatch"|"geoMatch"|"asNumberMatch"|"clientListMatch", useXForwardForHeaders?: bool, value?: string, valueCase?: bool, valueExactMatch?: bool, valueIgnoreSegment?: bool, valueNormalize?: bool, valueRecursive?: bool, valueWildcard?: bool}
# --effectiveTimePeriod shape: {endDate: string, startDate: string, status?: "active"|"inactive"|"expiring"|"expired"}
# --loggingOptions item shape: {id: "CLIENT_TLS_FINGERPRINT_MATCH"|"HEADER_ORDER_MATCH"|"REQUEST_HEADER_MATCH"|"COOKIE_MATCH"|"URI_QUERY_MATCH"|"ARGS_POST_MATCH", name?: string, value?: string}
export def "configs-custom-rules put-config-custom-rule" [
  ruleId: int
  configId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --conditions: list # Contains the details about the condition that triggers the custom rule. — item shape: {name?: any, nameCase?: bool, nameWildcard?: bool, positiveMatch: bool, type: "cookieMatch"|"extensionMatch"|"filenameMatch"|"ipMatch"|"pathMatch"|"requestHeaderMatch"|"requestMethodMatch"|"requestProtocolVersionMatch"|"uriQueryMatch"|"headerOrderMatch"|"argsPostMatch"|"argsPostNamesMatch"|"clientCertPresentMatch"|"clientCertValidMatch"|"clientTlsFingerprintMatch"|"hostMatch"|"ipAddressMatch"|"geoMatch"|"asNumberMatch"|"clientListMatch", useXForwardForHeaders?: bool, value?: string, valueCase?: bool, valueExactMatch?: bool, valueIgnoreSegment?: bool, valueNormalize?: bool, valueRecursive?: bool, valueWildcard?: bool}
  --description: string # The custom rule description.
  --effectiveTimePeriod: record # The time period during which the custom rule is active. — shape: {endDate: string, startDate: string, status?: "active"|"inactive"|"expiring"|"expired"}
  --id: int # Uniquely identifies the rule.
  --inspectRequest: oneof<nothing, bool> # Whether to inspect the HTTP request for unstructured custom rules.
  --inspectResponse: oneof<nothing, bool> # Whether to inspect the HTTP response for unstructured custom rules.
  --loggingOptions: list # The specific conditions to be logged. — item shape: {id: "CLIENT_TLS_FINGERPRINT_MATCH"|"HEADER_ORDER_MATCH"|"REQUEST_HEADER_MATCH"|"COOKIE_MATCH"|"URI_QUERY_MATCH"|"ARGS_POST_MATCH", name?: string, value?: string}
  --metadata: string # The metadata you provided for unstructured custom rules.
  name: string # The custom rule name.
  operation: string@operation-completer # Specify `AND` logic to require all conditions, or `OR` logic to require at least one condition to match.
  --ruleActivated: oneof<nothing, bool> # Whether the rule is active in the configuration.
  --samplingRate: int # The portion of traffic to sample, expressed as a percent.
  --stagingOnly: oneof<nothing, bool> # Whether to show traffic from only the staging network, or all traffic. The default setting is `false` and only shows in the response when `true`. (default: false)
  --structured: oneof<nothing, bool> # Whether you created the rule with the structured custom rule builder or free-form XML. This needs to be `true`.
  --tag: list # The list of labels you assigned to the custom rule.
  --version: int # The custom rule version.
]: any -> record<conditions: table<name: any, nameCase: bool, nameWildcard: bool, positiveMatch: bool, type: string, useXForwardForHeaders: bool, value: string, valueCase: bool, valueExactMatch: bool, valueIgnoreSegment: bool, valueNormalize: bool, valueRecursive: bool, valueWildcard: bool>, description: string, effectiveTimePeriod: record<endDate: string, startDate: string, status: string>, id: int, inspectRequest: bool, inspectResponse: bool, loggingOptions: table<id: string, name: string, value: string>, metadata: string, name: string, operation: string, ruleActivated: bool, samplingRate: int, stagingOnly: bool, structured: bool, tag: list<string>, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/custom-rules/($ruleId)" $qp)
  let body = {conditions: $conditions, description: $description, effectiveTimePeriod: $effectiveTimePeriod, id: $id, inspectRequest: $inspectRequest, inspectResponse: $inspectResponse, loggingOptions: $loggingOptions, metadata: $metadata, name: $name, operation: $operation, ruleActivated: $ruleActivated, samplingRate: $samplingRate, stagingOnly: $stagingOnly, structured: $structured, tag: $tag, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a custom rule
#
# DELETE /configs/{configId}/custom-rules/{ruleId}
# Docs: https://techdocs.akamai.com/application-security/reference/delete-config-custom-rule — See documentation for this operation in Akamai's Application Security API
# operationId: delete-config-custom-rule
export def "configs-custom-rules delete-config-custom-rule" [
  ruleId: int
  configId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/custom-rules/($ruleId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List failover hostnames
#
# GET /configs/{configId}/failover-hostnames
# Docs: https://techdocs.akamai.com/application-security/reference/get-failover-hostnames — See documentation for this operation in Akamai's Application Security API
# operationId: get-failover-hostnames
export def "configs-failover-hostnames get-failover-hostnames" [
  configId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<hostnameList: table<hostname: string>, mode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/failover-hostnames" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe or unsubscribe to recommendation emails
#
# POST /configs/{configId}/notification/subscription/{feature}
# Docs: https://techdocs.akamai.com/application-security/reference/post-subscription-feature — See documentation for this operation in Akamai's Application Security API
# operationId: post-subscription-feature
export def "configs-notification-subscription post-subscription-feature" [
  feature: string
  configId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  action: string@action-completer-1 # Use `subscribe` to add user emails to the subscription. Use `unsubscribe` to remove them from the subscription.
  emails: list # The user emails to add to or remove from subscription.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/notification/subscription/($feature)" $qp)
  let body = {action: $action, emails: $emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List subscribers
#
# GET /configs/{configId}/notification/subscription/{feature}
# Docs: https://techdocs.akamai.com/application-security/reference/get-subscription-feature — See documentation for this operation in Akamai's Application Security API
# operationId: get-subscription-feature
export def "configs-notification-subscription get-subscription-feature" [
  feature: string
  configId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<emails: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/notification/subscription/($feature)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clone a configuration version
#
# POST /configs/{configId}/versions
# Docs: https://techdocs.akamai.com/application-security/reference/post-config-versions — See documentation for this operation in Akamai's Application Security API
# operationId: post-config-versions
export def "configs-versions post-config-versions" [
  configId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  createFromVersion: int # The configuration version to clone from.
  --ruleUpdate: oneof<nothing, bool> # Specifies whether the application rules should be migrated to the latest version.
]: any -> record<basedOn: int, configId: int, configName: string, createDate: string, createdBy: string, production: record<action: string, status: string, time: string>, staging: record<action: string, status: string, time: string>, version: int, versionNotes: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions" $qp)
  let body = {createFromVersion: $createFromVersion, ruleUpdate: $ruleUpdate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List configuration versions
#
# GET /configs/{configId}/versions
# Docs: https://techdocs.akamai.com/application-security/reference/get-config-versions — See documentation for this operation in Akamai's Application Security API
# operationId: get-config-versions
export def "configs-versions get-config-versions" [
  configId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The index of the result page. If the value is `-1`, then pagination is ignored.  The default value is `1`. (default: 1, e.g. 2)
  --pageSize: int # The number of items on each result page. The default value is `25`. (default: 25, e.g. 10)
  --detail: oneof<nothing, bool> # When `true`, the results contain detailed information on versions. With the default `false`, the results contain summary information on versions. (default: false, e.g. true)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<configId: int, configName: string, lastCreatedVersion: int, page: int, pageSize: int, productionActiveVersion: int, productionExpediteRequestId: int, stagingActiveVersion: int, stagingExpediteRequestId: int, totalSize: int, versionList: table<basedOn: int, createDate: string, createdBy: string, production: record, staging: record, version: int, versionNotes: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "detail" $detail "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Compare two versions
#
# POST /configs/{configId}/versions/diff
# Docs: https://techdocs.akamai.com/application-security/reference/post-config-versions-diff — See documentation for this operation in Akamai's Application Security API
# operationId: post-config-versions-diff
export def "configs-versions-diff post-config-versions-diff" [
  configId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --body-from: int # The configuration version number to compare against.
  --outcomes: list # Show either `MODIFIED` or `UNMODIFIED` data, or both. When empty, only `MODIFIED` values are returned. (default: [MODIFIED])
  --body-to: int # The configuration version number you're comparing to the version in `from`.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/diff" $qp)
  let body = {from: $body_from, outcomes: $outcomes, to: $body_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get configuration version details
#
# GET /configs/{configId}/versions/{versionNumber}
# Docs: https://techdocs.akamai.com/application-security/reference/get-version-number — See documentation for this operation in Akamai's Application Security API
# operationId: get-version-number
export def "configs-versions get-version-number" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<basedOn: int, configId: int, configName: string, createDate: string, createdBy: string, production: record<action: string, status: string, time: string>, staging: record<action: string, status: string, time: string>, version: int, versionNotes: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a configuration version
#
# DELETE /configs/{configId}/versions/{versionNumber}
# Docs: https://techdocs.akamai.com/application-security/reference/delete-version-number — See documentation for this operation in Akamai's Application Security API
# operationId: delete-version-number
export def "configs-versions delete-version-number" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get cookie settings
#
# GET /configs/{configId}/versions/{versionNumber}/advanced-settings/cookie-settings
# Docs: https://techdocs.akamai.com/application-security/reference/get-advanced-settings-cookie-settings — See documentation for this operation in Akamai's Application Security API
# operationId: get-advanced-settings-cookie-settings
export def "configs-versions-advanced-settings-cookie-settings get-advanced-settings-cookie-settings" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<cookieDomain: string, useAllSecureTraffic: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/advanced-settings/cookie-settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify cookie settings
#
# PUT /configs/{configId}/versions/{versionNumber}/advanced-settings/cookie-settings
# Docs: https://techdocs.akamai.com/application-security/reference/put-advanced-settings-cookie-settings — See documentation for this operation in Akamai's Application Security API
# operationId: put-advanced-settings-cookie-settings
export def "configs-versions-advanced-settings-cookie-settings put-advanced-settings-cookie-settings" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --cookieDomain: string@cookieDomain-completer # Choose the type of domain. The default recommended type is `automatic`. Otherwise, choose `fqdn` to use the current Fully Qualified Domain name, `legacy` to use the original way in which the domain was selected, or `psl` to use the public suffix list to identify a private domain.
  --useAllSecureTraffic: oneof<nothing, bool> # If all of your traffic uses HTTPS, specify `true`. This option sets the Secure flag on all security product cookies, which are then only included with HTTPS traffic. It also adds `SameSite=None` to most bot management cookies, ensuring that recent browser versions submit the cookies with protected requests. The `SameSite=None` cookie setting is necessary for site architectures that involve cross-domain form submission or inclusion of cross-domain iframes.
]: any -> record<cookieDomain: string, useAllSecureTraffic: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/advanced-settings/cookie-settings" $qp)
  let body = {cookieDomain: $cookieDomain, useAllSecureTraffic: $useAllSecureTraffic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get evasive path match settings for a configuration
#
# GET /configs/{configId}/versions/{versionNumber}/advanced-settings/evasive-path-match
# Docs: https://techdocs.akamai.com/application-security/reference/get-evasive-path-match-per-config — See documentation for this operation in Akamai's Application Security API
# operationId: get-evasive-path-match-per-config
export def "configs-versions-advanced-settings-evasive-path-match get-evasive-path-match-per-config" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<enablePathMatch: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/advanced-settings/evasive-path-match" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify evasive path match settings for a configuration
#
# PUT /configs/{configId}/versions/{versionNumber}/advanced-settings/evasive-path-match
# Docs: https://techdocs.akamai.com/application-security/reference/put-evasive-path-match-per-config — See documentation for this operation in Akamai's Application Security API
# operationId: put-evasive-path-match-per-config
export def "configs-versions-advanced-settings-evasive-path-match put-evasive-path-match-per-config" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --enablePathMatch: oneof<nothing, bool> # When enabled, evaluates requests with the following list of characters removed ` & ! $ ' ( ) + , [ ] * @ ^ \ "` and `.` only when it appears as a trailing character at the end of the URL.
]: any -> record<enablePathMatch: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/advanced-settings/evasive-path-match" $qp)
  let body = {enablePathMatch: $enablePathMatch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get JA4 client TLS fingerprint settings
#
# GET /configs/{configId}/versions/{versionNumber}/advanced-settings/ja4-fingerprint
# Docs: https://techdocs.akamai.com/application-security/reference/get-ja4-fingerprint-settings — See documentation for this operation in Akamai's Application Security API
# operationId: get-ja4-fingerprint-settings
export def "configs-versions-advanced-settings-ja4-fingerprint get-ja4-fingerprint-settings" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<headerNames: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/advanced-settings/ja4-fingerprint" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify JA4 client TLS fingerprint settings
#
# PUT /configs/{configId}/versions/{versionNumber}/advanced-settings/ja4-fingerprint
# Docs: https://techdocs.akamai.com/application-security/reference/put-ja4-fingerprint-settings — See documentation for this operation in Akamai's Application Security API
# operationId: put-ja4-fingerprint-settings
export def "configs-versions-advanced-settings-ja4-fingerprint put-ja4-fingerprint-settings" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --headerNames: list # The header name where you add the JA4 client TLS fingerprint details. (nullable)
]: any -> record<headerNames: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/advanced-settings/ja4-fingerprint" $qp)
  let body = {headerNames: $headerNames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the HTTP header log settings for a configuration
#
# GET /configs/{configId}/versions/{versionNumber}/advanced-settings/logging
# Docs: https://techdocs.akamai.com/application-security/reference/get-advanced-settings-logging — See documentation for this operation in Akamai's Application Security API
# operationId: get-advanced-settings-logging
export def "configs-versions-advanced-settings-logging get-advanced-settings-logging" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<allowSampling: bool, cookies: record<type: string, values: list<string>>, customHeaders: record<type: string, values: list<string>>, standardHeaders: record<type: string, values: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/advanced-settings/logging" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify HTTP header log settings for a configuration
#
# PUT /configs/{configId}/versions/{versionNumber}/advanced-settings/logging
# Docs: https://techdocs.akamai.com/application-security/reference/put-advanced-settings-logging — See documentation for this operation in Akamai's Application Security API
# operationId: put-advanced-settings-logging
# --cookies shape: {type: "all"|"none"|"exclude"|"only", values?: list}
# --customHeaders shape: {type: "all"|"none"|"exclude"|"only", values?: list}
# --standardHeaders shape: {type: "all"|"none"|"exclude"|"only", values?: list}
export def "configs-versions-advanced-settings-logging put-advanced-settings-logging" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --allowSampling: oneof<nothing, bool> # Whether to enable HTTP Header logging.
  --cookies: record # Settings for cookie headers. — shape: {type: "all"|"none"|"exclude"|"only", values?: list}
  --customHeaders: record # Settings for custom headers. — shape: {type: "all"|"none"|"exclude"|"only", values?: list}
  --standardHeaders: record # Settings for standard headers. — shape: {type: "all"|"none"|"exclude"|"only", values?: list}
]: any -> record<allowSampling: bool, cookies: record<type: string, values: list<string>>, customHeaders: record<type: string, values: list<string>>, standardHeaders: record<type: string, values: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/advanced-settings/logging" $qp)
  let body = {allowSampling: $allowSampling, cookies: $cookies, customHeaders: $customHeaders, standardHeaders: $standardHeaders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the attack payload log settings for a configuration
#
# GET /configs/{configId}/versions/{versionNumber}/advanced-settings/logging/attack-payload
# Docs: https://techdocs.akamai.com/application-security/reference/get-advanced-settings-attack-payload-logging — See documentation for this operation in Akamai's Application Security API
# operationId: get-advanced-settings-attack-payload-logging
export def "configs-versions-advanced-settings-logging-attack-payload get-advanced-settings-attack-payload-logging" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<enabled: bool, requestBody: record<type: string>, responseBody: record<type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/advanced-settings/logging/attack-payload" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify attack payload log settings for a configuration
#
# PUT /configs/{configId}/versions/{versionNumber}/advanced-settings/logging/attack-payload
# Docs: https://techdocs.akamai.com/application-security/reference/put-advanced-settings-attack-payload-logging — See documentation for this operation in Akamai's Application Security API
# operationId: put-advanced-settings-attack-payload-logging
# --requestBody shape: {type: "ATTACK_PAYLOAD"|"NONE"}
# --responseBody shape: {type: "ATTACK_PAYLOAD"|"NONE"}
export def "configs-versions-advanced-settings-logging-attack-payload put-advanced-settings-attack-payload-logging" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --enabled: oneof<nothing, bool> # Whether attack payload logging is enabled.
  requestBody: record # Settings for request body. — shape: {type: "ATTACK_PAYLOAD"|"NONE"}
  responseBody: record # Settings for response body. — shape: {type: "ATTACK_PAYLOAD"|"NONE"}
]: any -> record<enabled: bool, requestBody: record<type: string>, responseBody: record<type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/advanced-settings/logging/attack-payload" $qp)
  let body = {enabled: $enabled, requestBody: $requestBody, responseBody: $responseBody} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get PII learning settings for a configuration
#
# GET /configs/{configId}/versions/{versionNumber}/advanced-settings/pii-learning
# Docs: https://techdocs.akamai.com/application-security/reference/get-advanced-settings-pii-learning — See documentation for this operation in Akamai's Application Security API
# operationId: get-advanced-settings-pii-learning
export def "configs-versions-advanced-settings-pii-learning get-advanced-settings-pii-learning" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<enablePiiLearning: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/advanced-settings/pii-learning" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable PII learning settings for a configuration
#
# PUT /configs/{configId}/versions/{versionNumber}/advanced-settings/pii-learning
# Docs: https://techdocs.akamai.com/application-security/reference/put-advanced-settings-pii-learning — See documentation for this operation in Akamai's Application Security API
# operationId: put-advanced-settings-pii-learning
export def "configs-versions-advanced-settings-pii-learning put-advanced-settings-pii-learning" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --enablePiiLearning: oneof<nothing, bool> # Enables PII learning.
]: any -> record<enablePiiLearning: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/advanced-settings/pii-learning" $qp)
  let body = {enablePiiLearning: $enablePiiLearning} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Pragma settings for a configuration
#
# GET /configs/{configId}/versions/{versionNumber}/advanced-settings/pragma-header
# Docs: https://techdocs.akamai.com/application-security/reference/get-advanced-settings-pragma-header — See documentation for this operation in Akamai's Application Security API
# operationId: get-advanced-settings-pragma-header
export def "configs-versions-advanced-settings-pragma-header get-advanced-settings-pragma-header" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<action: string, conditionOperator: string, excludeCondition: table<header: string, name: string, positiveMatch: bool, type: string, useHeaders: bool, value: list, valueCase: bool, valueWildcard: bool>, override: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/advanced-settings/pragma-header" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify Pragma settings for a configuration
#
# PUT /configs/{configId}/versions/{versionNumber}/advanced-settings/pragma-header
# Docs: https://techdocs.akamai.com/application-security/reference/put-advanced-settings-pragma-header — See documentation for this operation in Akamai's Application Security API
# operationId: put-advanced-settings-pragma-header
# --excludeCondition item shape: {header?: string, name?: string, positiveMatch: bool, type: "requestHeaderValueMatch"|"ipMatch"|"networkList"|"queryParamNameValueMatch", useHeaders?: bool, value: list, valueCase?: bool, valueWildcard?: bool}
export def "configs-versions-advanced-settings-pragma-header put-advanced-settings-pragma-header" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  action: string@action-completer-2 # The action to perform when a user passes a `Pragma` header. The only action currently supported is `REMOVE`.
  --conditionOperator: string@conditionOperator-completer # Use `OR` to match any condition, or `AND` to match on all conditions.
  --excludeCondition: list # The conditions to exclude from the default `remove` action. Any condition you set in this object appears in the `Pragma` header debug response object. — item shape: {header?: string, name?: string, positiveMatch: bool, type: "requestHeaderValueMatch"|"ipMatch"|"networkList"|"queryParamNameValueMatch", useHeaders?: bool, value: list, valueCase?: bool, valueWildcard?: bool}
  --override: oneof<nothing, bool> # Whether `Pragma` header override is enabled or disabled.
]: any -> record<action: string, conditionOperator: string, excludeCondition: table<header: string, name: string, positiveMatch: bool, type: string, useHeaders: bool, value: list, valueCase: bool, valueWildcard: bool>, override: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/advanced-settings/pragma-header" $qp)
  let body = {action: $action, conditionOperator: $conditionOperator, excludeCondition: $excludeCondition, override: $override} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get prefetch requests
#
# GET /configs/{configId}/versions/{versionNumber}/advanced-settings/prefetch
# Docs: https://techdocs.akamai.com/application-security/reference/get-advanced-settings-prefetch — See documentation for this operation in Akamai's Application Security API
# operationId: get-advanced-settings-prefetch
export def "configs-versions-advanced-settings-prefetch get-advanced-settings-prefetch" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<allExtensions: bool, enableAppLayer: bool, enableRateControls: bool, extensions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/advanced-settings/prefetch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify prefetch requests
#
# PUT /configs/{configId}/versions/{versionNumber}/advanced-settings/prefetch
# Docs: https://techdocs.akamai.com/application-security/reference/put-advanced-settings-prefetch — See documentation for this operation in Akamai's Application Security API
# operationId: put-advanced-settings-prefetch
export def "configs-versions-advanced-settings-prefetch put-advanced-settings-prefetch" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --allExtensions: oneof<nothing, bool> # Whether to enable prefetch requests for all extensions.
  --enableAppLayer: oneof<nothing, bool> # Whether to enable Prefetch Requests.
  --enableRateControls: oneof<nothing, bool> # Whether to enable Prefetch Requests for rate controls.
  --extensions: list # List of extensions.
]: any -> record<allExtensions: bool, enableAppLayer: bool, enableRateControls: bool, extensions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/advanced-settings/prefetch" $qp)
  let body = {allExtensions: $allExtensions, enableAppLayer: $enableAppLayer, enableRateControls: $enableRateControls, extensions: $extensions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get request body size settings for a configuration
#
# GET /configs/{configId}/versions/{versionNumber}/advanced-settings/request-body
# Docs: https://techdocs.akamai.com/application-security/reference/get-advanced-settings-request-body — See documentation for this operation in Akamai's Application Security API
# operationId: get-advanced-settings-request-body
export def "configs-versions-advanced-settings-request-body get-advanced-settings-request-body" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<requestBodyInspectionLimitInKB: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/advanced-settings/request-body" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify request body inspection limit settings for a configuration
#
# PUT /configs/{configId}/versions/{versionNumber}/advanced-settings/request-body
# Docs: https://techdocs.akamai.com/application-security/reference/put-advanced-settings-request-body — See documentation for this operation in Akamai's Application Security API
# operationId: put-advanced-settings-request-body
export def "configs-versions-advanced-settings-request-body put-advanced-settings-request-body" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --requestBodyInspectionLimitInKB: string@requestBodyInspectionLimitInKB-completer # Request body size in KB, either `8`, `16`, or `32` as string-formatted integers, or `default` to use Akamai's best practice value.
]: any -> record<requestBodyInspectionLimitInKB: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/advanced-settings/request-body" $qp)
  let body = {requestBodyInspectionLimitInKB: $requestBodyInspectionLimitInKB} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a Behavioral DDoS profile
#
# POST /configs/{configId}/versions/{versionNumber}/behavioral-ddos
# Docs: https://techdocs.akamai.com/application-security/reference/post-behavioral-ddos-profile — See documentation for this operation in Akamai's Application Security API
# operationId: post-behavioral-ddos-profile
# --bypassCondition shape: {atomicConditions?: list}
# --exceptions item shape: {hosts: list, paths: list}
# --sensitivityOverrides item shape: {host: string, path: string, sensitivity: "CONSERVATIVE"|"MODERATE"|"STRICT"}
# --suspend shape: {fromDate: string, hostnames: list, toDate: string}
export def "configs-versions-behavioral-ddos post-behavioral-ddos-profile" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --bypassCondition: record # Exempts specific clients from being processed by the Behavioral DDoS profile. — shape: {atomicConditions?: list}
  --body-configId: int # Uniquely identifies the security configuration. (format: int64)
  --configVersion: int # The security configuration version.
  --description: string # A description of the profile.
  --exceptions: list # The hostname and path pairs excluded from Behavioral DDoS mitigation actions. — item shape: {hosts: list, paths: list}
  hostnames: list # The hostnames that you want to be protected by the Behavioral DDoS profile.
  name: string # The profile's unique name.
  sensitivity: string@sensitivity-completer # Sensitivity level, specify `CONSERVATIVE` to provide tolerance for more substantial traffic deviations, `MODERATE` to provide tolerance for traffic fluctuations, or `STRICT` for high-security environments, where minor deviations in traffic might signal a potential DDoS attack.
  --sensitivityOverrides: list # Sensitivity overrides for one or more hostname and path pairs. — item shape: {host: string, path: string, sensitivity: "CONSERVATIVE"|"MODERATE"|"STRICT"}
  --suspend: record # Temporarily disable mitigation for a specific hostname, with the flexibility to choose the duration of its suspension. — shape: {fromDate: string, hostnames: list, toDate: string}
]: any -> record<bypassCondition: record<atomicConditions: list<any>>, configId: int, configVersion: int, createDate: string, createdBy: string, description: string, exceptions: table<hosts: list, paths: list>, hostnames: list<string>, name: string, profileId: int, sensitivity: string, sensitivityOverrides: table<host: string, path: string, sensitivity: string>, suspend: record<fromDate: string, hostnames: list<string>, toDate: string>, updateDate: string, updatedBy: string, used: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/behavioral-ddos" $qp)
  let body = {bypassCondition: $bypassCondition, configId: $body_configId, configVersion: $configVersion, description: $description, exceptions: $exceptions, hostnames: $hostnames, name: $name, sensitivity: $sensitivity, sensitivityOverrides: $sensitivityOverrides, suspend: $suspend} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Behavioral DDoS profiles
#
# GET /configs/{configId}/versions/{versionNumber}/behavioral-ddos
# Docs: https://techdocs.akamai.com/application-security/reference/get-behavioral-ddos-profiles — See documentation for this operation in Akamai's Application Security API
# operationId: get-behavioral-ddos-profiles
export def "configs-versions-behavioral-ddos get-behavioral-ddos-profiles" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<behavioralDdosProfiles: table<bypassCondition: record, configId: int, configVersion: int, createDate: string, createdBy: string, description: string, exceptions: list, hostnames: list, name: string, profileId: int, sensitivity: string, sensitivityOverrides: list, suspend: record, updateDate: string, updatedBy: string, used: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/behavioral-ddos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Behavioral DDoS profile
#
# GET /configs/{configId}/versions/{versionNumber}/behavioral-ddos/{profileId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-behavioral-ddos-profile — See documentation for this operation in Akamai's Application Security API
# operationId: get-behavioral-ddos-profile
export def "configs-versions-behavioral-ddos get-behavioral-ddos-profile" [
  configId: int
  versionNumber: int
  profileId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<bypassCondition: record<atomicConditions: list<any>>, configId: int, configVersion: int, createDate: string, createdBy: string, description: string, exceptions: table<hosts: list, paths: list>, hostnames: list<string>, name: string, profileId: int, sensitivity: string, sensitivityOverrides: table<host: string, path: string, sensitivity: string>, suspend: record<fromDate: string, hostnames: list<string>, toDate: string>, updateDate: string, updatedBy: string, used: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/behavioral-ddos/($profileId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Behavioral DDoS profile
#
# PUT /configs/{configId}/versions/{versionNumber}/behavioral-ddos/{profileId}
# Docs: https://techdocs.akamai.com/application-security/reference/put-behavioral-ddos-profile — See documentation for this operation in Akamai's Application Security API
# operationId: put-behavioral-ddos-profile
# --bypassCondition shape: {atomicConditions?: list}
# --exceptions item shape: {hosts: list, paths: list}
# --sensitivityOverrides item shape: {host: string, path: string, sensitivity: "CONSERVATIVE"|"MODERATE"|"STRICT"}
# --suspend shape: {fromDate: string, hostnames: list, toDate: string}
export def "configs-versions-behavioral-ddos put-behavioral-ddos-profile" [
  configId: int
  versionNumber: int
  profileId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --bypassCondition: record # Exempts specific clients from being processed by the Behavioral DDoS profile. — shape: {atomicConditions?: list}
  --body-configId: int # Uniquely identifies the security configuration. (format: int64)
  --configVersion: int # The security configuration version.
  --description: string # A description of the profile.
  --exceptions: list # The hostname and path pairs excluded from Behavioral DDoS mitigation actions. — item shape: {hosts: list, paths: list}
  hostnames: list # The hostnames that you want to be protected by the Behavioral DDoS profile.
  name: string # The profile's unique name.
  sensitivity: string@sensitivity-completer # Sensitivity level, specify `CONSERVATIVE` to provide tolerance for more substantial traffic deviations, `MODERATE` to provide tolerance for traffic fluctuations, or `STRICT` for high-security environments, where minor deviations in traffic might signal a potential DDoS attack.
  --sensitivityOverrides: list # Sensitivity overrides for one or more hostname and path pairs. — item shape: {host: string, path: string, sensitivity: "CONSERVATIVE"|"MODERATE"|"STRICT"}
  --suspend: record # Temporarily disable mitigation for a specific hostname, with the flexibility to choose the duration of its suspension. — shape: {fromDate: string, hostnames: list, toDate: string}
]: any -> record<bypassCondition: record<atomicConditions: list<any>>, configId: int, configVersion: int, createDate: string, createdBy: string, description: string, exceptions: table<hosts: list, paths: list>, hostnames: list<string>, name: string, profileId: int, sensitivity: string, sensitivityOverrides: table<host: string, path: string, sensitivity: string>, suspend: record<fromDate: string, hostnames: list<string>, toDate: string>, updateDate: string, updatedBy: string, used: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/behavioral-ddos/($profileId)" $qp)
  let body = {bypassCondition: $bypassCondition, configId: $body_configId, configVersion: $configVersion, description: $description, exceptions: $exceptions, hostnames: $hostnames, name: $name, sensitivity: $sensitivity, sensitivityOverrides: $sensitivityOverrides, suspend: $suspend} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a Behavioral DDoS profile
#
# DELETE /configs/{configId}/versions/{versionNumber}/behavioral-ddos/{profileId}
# Docs: https://techdocs.akamai.com/application-security/reference/delete-behavioral-ddos-profile — See documentation for this operation in Akamai's Application Security API
# operationId: delete-behavioral-ddos-profile
export def "configs-versions-behavioral-ddos delete-behavioral-ddos-profile" [
  configId: int
  versionNumber: int
  profileId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/behavioral-ddos/($profileId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bypass network lists settings
#
# GET /configs/{configId}/versions/{versionNumber}/bypass-network-lists
# Docs: https://techdocs.akamai.com/application-security/reference/get-bypass-network-lists — See documentation for this operation in Akamai's Application Security API
# operationId: get-bypass-network-lists
export def "configs-versions-bypass-network-lists get-bypass-network-lists" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<networkLists: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/bypass-network-lists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the bypass network lists settings
#
# PUT /configs/{configId}/versions/{versionNumber}/bypass-network-lists
# Docs: https://techdocs.akamai.com/application-security/reference/put-bypass-network-lists — See documentation for this operation in Akamai's Application Security API
# operationId: put-bypass-network-lists
export def "configs-versions-bypass-network-lists put-bypass-network-lists" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  networkLists: list # Contains a list of network list IDs.
]: any -> record<networkLists: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/bypass-network-lists" $qp)
  let body = {networkLists: $networkLists} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a custom deny action
#
# POST /configs/{configId}/versions/{versionNumber}/custom-deny
# Docs: https://techdocs.akamai.com/application-security/reference/post-custom-deny — See documentation for this operation in Akamai's Application Security API
# operationId: post-custom-deny
# --parameters item shape: {displayName?: string, name: "response_status_code"|"prevent_browser_cache"|"response_content_type"|"response_body_content"|"response_header_name"|"response_header_value"|"custom_deny_hostname"|"custom_deny_path"|"include_true_ip"|"include_reference_id", value: string}
export def "configs-versions-custom-deny post-custom-deny" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --description: string # Describes the custom deny action.
  name: string # The name you assigned to the custom deny action.
  parameters: list # Describes the custom deny parameters. — item shape: {displayName?: string, name: "response_status_code"|"prevent_browser_cache"|"response_content_type"|"response_body_content"|"response_header_name"|"response_header_value"|"custom_deny_hostname"|"custom_deny_path"|"include_true_ip"|"include_reference_id", value: string}
]: any -> record<description: string, id: string, name: string, parameters: table<displayName: string, name: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/custom-deny" $qp)
  let body = {description: $description, name: $name, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List custom deny actions
#
# GET /configs/{configId}/versions/{versionNumber}/custom-deny
# Docs: https://techdocs.akamai.com/application-security/reference/get-custom-deny-actions — See documentation for this operation in Akamai's Application Security API
# operationId: get-custom-deny-actions
export def "configs-versions-custom-deny get-custom-deny-actions" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter results by name, description, or ID. You can match on substrings. (e.g. SQL Injection)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<customDenyList: table<description: string, id: string, name: string, parameters: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/custom-deny" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a custom deny action
#
# GET /configs/{configId}/versions/{versionNumber}/custom-deny/{customDenyId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-custom-deny-action — See documentation for this operation in Akamai's Application Security API
# operationId: get-custom-deny-action
export def "configs-versions-custom-deny get-custom-deny-action" [
  configId: int
  versionNumber: int
  customDenyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<description: string, id: string, name: string, parameters: table<displayName: string, name: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/custom-deny/($customDenyId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a custom deny action
#
# PUT /configs/{configId}/versions/{versionNumber}/custom-deny/{customDenyId}
# Docs: https://techdocs.akamai.com/application-security/reference/put-custom-deny — See documentation for this operation in Akamai's Application Security API
# operationId: put-custom-deny
# --parameters item shape: {displayName?: string, name: "response_status_code"|"prevent_browser_cache"|"response_content_type"|"response_body_content"|"response_header_name"|"response_header_value"|"custom_deny_hostname"|"custom_deny_path"|"include_true_ip"|"include_reference_id", value: string}
export def "configs-versions-custom-deny put-custom-deny" [
  configId: int
  versionNumber: int
  customDenyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --description: string # Describes the custom deny action.
  name: string # The name you assigned to the custom deny action.
  parameters: list # Describes the custom deny parameters. — item shape: {displayName?: string, name: "response_status_code"|"prevent_browser_cache"|"response_content_type"|"response_body_content"|"response_header_name"|"response_header_value"|"custom_deny_hostname"|"custom_deny_path"|"include_true_ip"|"include_reference_id", value: string}
]: any -> record<description: string, id: string, name: string, parameters: table<displayName: string, name: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/custom-deny/($customDenyId)" $qp)
  let body = {description: $description, name: $name, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a custom deny action
#
# DELETE /configs/{configId}/versions/{versionNumber}/custom-deny/{customDenyId}
# Docs: https://techdocs.akamai.com/application-security/reference/delete-custom-deny — See documentation for this operation in Akamai's Application Security API
# operationId: delete-custom-deny
export def "configs-versions-custom-deny delete-custom-deny" [
  configId: int
  versionNumber: int
  customDenyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/custom-deny/($customDenyId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List custom rules usage by security policies
#
# POST /configs/{configId}/versions/{versionNumber}/custom-rules/usage
# Docs: https://techdocs.akamai.com/application-security/reference/post-config-custom-rules-usage — See documentation for this operation in Akamai's Application Security API
# operationId: post-config-custom-rules-usage
export def "configs-versions-custom-rules-usage post-config-custom-rules-usage" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  ruleIds: list # A list of the custom rule IDs.
]: any -> record<rules: table<policies: list, ruleId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/custom-rules/usage" $qp)
  let body = {ruleIds: $ruleIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Asynchronously export a configuration version
#
# POST /configs/{configId}/versions/{versionNumber}/export
# Docs: https://techdocs.akamai.com/application-security/reference/post-export-config-version-async-task — See documentation for this operation in Akamai's Application Security API
# operationId: post-export-config-version-async-task
export def "configs-versions-export post-export-config-version-async-task" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<createdBy: string, createdDate: string, expiresDate: string, exportId: string, exportStatus: string, message: string, resultLink: string, retryAfter: int, statusLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get asynchronous export results
#
# GET /configs/{configId}/versions/{versionNumber}/export/{exportId}/result
# Docs: https://techdocs.akamai.com/application-security/reference/get-export-config-version-async-result — See documentation for this operation in Akamai's Application Security API
# operationId: get-export-config-version-async-result
export def "configs-versions-export-result get-export-config-version-async-result" [
  configId: int
  versionNumber: int
  exportId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<advancedOptions: record<asePenaltyBox: record<akamaiManagedExclusions: record, blockDuration: int, clientIdentifiers: list, qualificationExclusions: record, requestCount: int>, ja4Fingerprint: record<headerNames: list>, logging: record<allowSampling: bool, cookies: record, customHeaders: record, standardHeaders: record>, pragmaHeader: record<action: string, conditionOperator: string, excludeCondition: list, override: bool>, prefetch: record<allExtensions: bool, enableAppLayer: bool, enableRateControls: bool, extensions: list>, requestBody: record<requestBodyInspectionLimitInKB: string>>, basedOn: int, configId: int, configName: string, createDate: string, createdBy: string, customDenyList: table<customDenyList: list>, customRules: table<conditions: list, description: string, id: int, inspectRequest: bool, inspectResponse: bool, loggingOptions: list, metadata: string, name: string, operation: string, ruleActivated: bool, stagingOnly: bool, structured: bool, tag: list, version: int>, errorHosts: table<hostname: string, reason: string, reasonCode: int>, evaluating: record<securityPolicies: list<record>>, malwarePolicies: table<allowListId: string, blockListId: string, contentTypes: list, description: string, hostnames: list, id: int, logFilename: bool, name: string, paths: list>, matchTargets: record<apiTargets: list<record>, websiteTargets: list<record>>, production: record<action: string, status: string, time: string>, ratePolicies: table<additionalMatchOptions: list, apiSelectors: list, averageThreshold: int, bodyParameters: list, burstThreshold: int, burstWindow: int, clientIdentifier: string, clientIdentifiers: list, condition: record, counterType: string, createDate: string, description: string, evaluation: record, fileExtensions: record, hostnames: list, hosts: record, id: int, matchType: string, name: string, path: record, pathMatchType: string, pathUriPositiveMatch: bool, penaltyBoxDuration: string, queryParameters: list, requestType: string, sameActionOnIpv6: bool, type: string, updateDate: string, useXForwardForHeaders: bool, used: bool>, reputationProfiles: table<condition: record, context: string, contextReadable: string, description: string, enabled: bool, id: int, name: string, threshold: float>, rulesets: table<attackGroups: list, id: int, releaseDate: string, rules: list, rulesetVersionId: int, type: string>, securityPolicies: table<apiRequestConstraints: record, clientReputation: record, customRuleActions: list, evaluationPenaltyBox: record, hasRatePolicyWithApiKey: bool, id: string, ipGeoFirewall: record, loggingOverrides: record, malwarePolicyActions: list, name: string, penaltyBox: record, pragmaHeader: record, rapidRules: record, ratePolicyActions: list, requestBody: record, securityControls: record, slowPost: record, webApplicationFirewall: record>, selectableHosts: list<string>, selectedHosts: list<string>, siem: record<enableForAllPolicies: bool, enableSiem: bool, enabledBotmanSiemEvents: bool, exceptions: list<record>, firewallPolicyIds: list<string>, siemDefinitionId: int>, staging: record<action: string, status: string, time: string>, version: int, versionNotes: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/export/($exportId)/result" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get asynchronous export status
#
# GET /configs/{configId}/versions/{versionNumber}/export/{exportId}/status
# Docs: https://techdocs.akamai.com/application-security/reference/get-export-config-version-async-task-status — See documentation for this operation in Akamai's Application Security API
# operationId: get-export-config-version-async-task-status
export def "configs-versions-export-status get-export-config-version-async-task-status" [
  configId: int
  versionNumber: int
  exportId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<createdBy: string, createdDate: string, expiresDate: string, exportId: string, exportStatus: string, message: string, resultLink: string, retryAfter: int, statusLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/export/($exportId)/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the hostname coverage match targets
#
# GET /configs/{configId}/versions/{versionNumber}/hostname-coverage/match-targets
# Docs: https://techdocs.akamai.com/application-security/reference/get-coverage-match-targets — See documentation for this operation in Akamai's Application Security API
# operationId: get-coverage-match-targets
export def "configs-versions-hostname-coverage-match-targets get-coverage-match-targets" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hostname: string # Get results by hostname. (e.g. www.example.com)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<matchTargets: record<apiTargets: list<record>, websiteTargets: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hostname" $hostname "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/hostname-coverage/match-targets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List hostname overlaps
#
# GET /configs/{configId}/versions/{versionNumber}/hostname-coverage/overlapping
# Docs: https://techdocs.akamai.com/application-security/reference/get-hostname-coverage-overlapping — See documentation for this operation in Akamai's Application Security API
# operationId: get-hostname-coverage-overlapping
export def "configs-versions-hostname-coverage-overlapping get-hostname-coverage-overlapping" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hostname: string # Get results by hostname. (e.g. www.example.com)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<overLappingList: table<configId: int, configName: string, configVersion: int, contractId: string, contractName: string, versionTags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hostname" $hostname "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/hostname-coverage/overlapping" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a malware policy
#
# POST /configs/{configId}/versions/{versionNumber}/malware-policies
# Docs: https://techdocs.akamai.com/application-security/reference/post-malware-policies — See documentation for this operation in Akamai's Application Security API
# operationId: post-malware-policies
# --contentTypes item shape: {encodedContentAttributes?: list, name: string}
export def "configs-versions-malware-policies post-malware-policies" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --allowListId: string # The ID of a client list containing file hashes of specific files to allow.
  --blockListId: string # The ID of a client list containing file hashes of specific files to block.
  --contentTypes: list # The content types and encodings to match. — item shape: {encodedContentAttributes?: list, name: string}
  --description: string # Descriptive text you provide about a policy.
  hostnames: list # The hostnames to match. This is where you want the malware detections to focus.
  --logFilename: oneof<nothing, bool> # Whether to log the name of the file that triggered an `alert` or `deny` action. (default: false)
  name: string # The name you assign to a malware policy.
  paths: list # The paths to match. You can use the `?` and `*` wildcards anywhere in a path.
]: any -> record<allowListId: string, blockListId: string, contentTypes: table<encodedContentAttributes: list, name: string>, description: string, hostnames: list<string>, id: int, logFilename: bool, name: string, paths: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/malware-policies" $qp)
  let body = {allowListId: $allowListId, blockListId: $blockListId, contentTypes: $contentTypes, description: $description, hostnames: $hostnames, logFilename: $logFilename, name: $name, paths: $paths} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List malware policies
#
# GET /configs/{configId}/versions/{versionNumber}/malware-policies
# Docs: https://techdocs.akamai.com/application-security/reference/get-malware-policies — See documentation for this operation in Akamai's Application Security API
# operationId: get-malware-policies
export def "configs-versions-malware-policies get-malware-policies" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<malwarePolicies: table<allowListId: string, blockListId: string, contentTypes: list, description: string, hostnames: list, id: int, logFilename: bool, name: string, paths: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/malware-policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List supported malware policy content types
#
# GET /configs/{configId}/versions/{versionNumber}/malware-policies/content-types
# Docs: https://techdocs.akamai.com/application-security/reference/get-malware-policy-content-types — See documentation for this operation in Akamai's Application Security API
# operationId: get-malware-policy-content-types
export def "configs-versions-malware-policies-content-types get-malware-policy-content-types" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<malwareContentTypes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/malware-policies/content-types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a malware policy
#
# GET /configs/{configId}/versions/{versionNumber}/malware-policies/{malwarePolicyId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-malware-policy — See documentation for this operation in Akamai's Application Security API
# operationId: get-malware-policy
export def "configs-versions-malware-policies get-malware-policy" [
  configId: int
  versionNumber: int
  malwarePolicyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<allowListId: string, blockListId: string, contentTypes: table<encodedContentAttributes: list, name: string>, description: string, hostnames: list<string>, id: int, logFilename: bool, name: string, paths: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/malware-policies/($malwarePolicyId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a malware policy
#
# PUT /configs/{configId}/versions/{versionNumber}/malware-policies/{malwarePolicyId}
# Docs: https://techdocs.akamai.com/application-security/reference/put-malware-policy — See documentation for this operation in Akamai's Application Security API
# operationId: put-malware-policy
# --contentTypes item shape: {encodedContentAttributes?: list, name: string}
export def "configs-versions-malware-policies put-malware-policy" [
  configId: int
  versionNumber: int
  malwarePolicyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --allowListId: string # The ID of a client list containing file hashes of specific files to allow.
  --blockListId: string # The ID of a client list containing file hashes of specific files to block.
  --contentTypes: list # The content types and encodings to match. — item shape: {encodedContentAttributes?: list, name: string}
  --description: string # Descriptive text you provide about a policy.
  hostnames: list # The hostnames to match. This is where you want the malware detections to focus.
  --logFilename: oneof<nothing, bool> # Whether to log the name of the file that triggered an `alert` or `deny` action. (default: false)
  name: string # The name you assign to a malware policy.
  paths: list # The paths to match. You can use the `?` and `*` wildcards anywhere in a path.
]: any -> record<allowListId: string, blockListId: string, contentTypes: table<encodedContentAttributes: list, name: string>, description: string, hostnames: list<string>, id: int, logFilename: bool, name: string, paths: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/malware-policies/($malwarePolicyId)" $qp)
  let body = {allowListId: $allowListId, blockListId: $blockListId, contentTypes: $contentTypes, description: $description, hostnames: $hostnames, logFilename: $logFilename, name: $name, paths: $paths} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a malware policy
#
# DELETE /configs/{configId}/versions/{versionNumber}/malware-policies/{malwarePolicyId}
# Docs: https://techdocs.akamai.com/application-security/reference/delete-malware-policy — See documentation for this operation in Akamai's Application Security API
# operationId: delete-malware-policy
export def "configs-versions-malware-policies delete-malware-policy" [
  configId: int
  versionNumber: int
  malwarePolicyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/malware-policies/($malwarePolicyId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a match target
#
# POST /configs/{configId}/versions/{versionNumber}/match-targets
# Docs: https://techdocs.akamai.com/application-security/reference/post-match-targets — See documentation for this operation in Akamai's Application Security API
# operationId: post-match-targets
# --apis item shape: {id: int, name?: string}
# --bypassNetworkLists item shape: {id: string, name?: string}
# --effectiveSecurityControls shape: {applyApiConstraints: bool, applyApplicationLayerControls: bool, applyBotmanControls: bool, applyNetworkLayerControls: bool, applyRateControls: bool, applyReputationControls: bool, applySlowPostControls: bool}
# --securityPolicy shape: {policyId: string}
# --validations shape: {errors: list, notices: list, warnings: list}
export def "configs-versions-match-targets post-match-targets" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --apis: list # Contains a list of objects containing an API endpoint ID and name. This field applies only to API match targets. — item shape: {id: int, name?: string}
  --bypassNetworkLists: list # The list of network list identifiers and names. — item shape: {id: string, name?: string}
  --body-configId: int # Uniquely identifies the security configuration.
  --configVersion: int # The version of security configuration.
  --defaultFile: string@defaultFile-completer # Describes the rule to match on paths. Either `NO_MATCH` to not match on the default file, `BASE_MATCH` to match only requests for top-level hostnames ending in a trailing slash, or `RECURSIVE_MATCH` to match all requests for paths that end in a trailing slash. (default: NO_MATCH)
  --fileExtensions: list # Contains a list of file extensions.
  --filePaths: list # Contains a list of file paths.
  --hostnames: list # Contains a list of hostnames to protect.
  --isNegativeFileExtensionMatch: oneof<nothing, bool> # Describes whether the match target applies when a match is found in the specified `fileExtensions` or when a match isn't found.
  --isNegativePathMatch: oneof<nothing, bool> # Describes whether the match target applies when a match is found in the specified paths or when a match isn't found.
  securityPolicy: record # The security policy associated with the match target. — shape: {policyId: string}
  --sequence: int # The position in the sequence of match targets.
  --targetId: int # Uniquely identifies the match target.
  type: string@type-completer # Describes the type of match target, either `website` or `api`.
]: any -> record<apis: table<id: int, name: string>, bypassNetworkLists: table<id: string, name: string>, configId: int, configVersion: int, defaultFile: string, effectiveSecurityControls: record<applyApiConstraints: bool, applyApplicationLayerControls: bool, applyBotmanControls: bool, applyNetworkLayerControls: bool, applyRateControls: bool, applyReputationControls: bool, applySlowPostControls: bool>, fileExtensions: list<string>, filePaths: list<string>, hostnames: list<string>, isNegativeFileExtensionMatch: bool, isNegativePathMatch: bool, securityPolicy: record<policyId: string>, sequence: int, targetId: int, type: string, validations: record<errors: list<record>, notices: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/match-targets" $qp)
  let body = {apis: $apis, bypassNetworkLists: $bypassNetworkLists, configId: $body_configId, configVersion: $configVersion, defaultFile: $defaultFile, fileExtensions: $fileExtensions, filePaths: $filePaths, hostnames: $hostnames, isNegativeFileExtensionMatch: $isNegativeFileExtensionMatch, isNegativePathMatch: $isNegativePathMatch, securityPolicy: $securityPolicy, sequence: $sequence, targetId: $targetId, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List match targets
#
# GET /configs/{configId}/versions/{versionNumber}/match-targets
# Docs: https://techdocs.akamai.com/application-security/reference/get-match-targets — See documentation for this operation in Akamai's Application Security API
# operationId: get-match-targets
export def "configs-versions-match-targets get-match-targets" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --policyId: string # Specifies the security policy to filter match targets. (e.g. abc_123456)
  --includeChildObjectName: oneof<nothing, bool> # Specify whether to return the object name in the payload, true` by default. (default: true, e.g. false)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<matchTargets: record<apiTargets: list<record>, websiteTargets: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policyId" $policyId "scalar") (serialize-qp "includeChildObjectName" $includeChildObjectName "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/match-targets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify match target order
#
# PUT /configs/{configId}/versions/{versionNumber}/match-targets/sequence
# Docs: https://techdocs.akamai.com/application-security/reference/put-match-targets-sequence — See documentation for this operation in Akamai's Application Security API
# operationId: put-match-targets-sequence
# --targetSequence item shape: {sequence: int, targetId: int}
export def "configs-versions-match-targets-sequence put-match-targets-sequence" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  targetSequence: list # Contains the ID and sequence of a match target. — item shape: {sequence: int, targetId: int}
  type: string@type-completer-1 # Describes the type of match target, either `WEBSITE` or `API`.
]: any -> record<targetSequence: table<sequence: int, targetId: int>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/match-targets/sequence" $qp)
  let body = {targetSequence: $targetSequence, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a match target
#
# GET /configs/{configId}/versions/{versionNumber}/match-targets/{targetId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-match-target — See documentation for this operation in Akamai's Application Security API
# operationId: get-match-target
export def "configs-versions-match-targets get-match-target" [
  configId: int
  versionNumber: int
  targetId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeChildObjectName: oneof<nothing, bool> # Specify whether to return the object name in the payload, true` by default. (default: true, e.g. false)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<apis: table<id: int, name: string>, bypassNetworkLists: table<id: string, name: string>, configId: int, configVersion: int, defaultFile: string, effectiveSecurityControls: record<applyApiConstraints: bool, applyApplicationLayerControls: bool, applyBotmanControls: bool, applyNetworkLayerControls: bool, applyRateControls: bool, applyReputationControls: bool, applySlowPostControls: bool>, fileExtensions: list<string>, filePaths: list<string>, hostnames: list<string>, isNegativeFileExtensionMatch: bool, isNegativePathMatch: bool, securityPolicy: record<policyId: string>, sequence: int, targetId: int, type: string, validations: record<errors: list<record>, notices: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeChildObjectName" $includeChildObjectName "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/match-targets/($targetId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a match target
#
# PUT /configs/{configId}/versions/{versionNumber}/match-targets/{targetId}
# Docs: https://techdocs.akamai.com/application-security/reference/put-match-target — See documentation for this operation in Akamai's Application Security API
# operationId: put-match-target
# --apis item shape: {id: int, name?: string}
# --bypassNetworkLists item shape: {id: string, name?: string}
# --effectiveSecurityControls shape: {applyApiConstraints: bool, applyApplicationLayerControls: bool, applyBotmanControls: bool, applyNetworkLayerControls: bool, applyRateControls: bool, applyReputationControls: bool, applySlowPostControls: bool}
# --securityPolicy shape: {policyId: string}
# --validations shape: {errors: list, notices: list, warnings: list}
export def "configs-versions-match-targets put-match-target" [
  configId: int
  versionNumber: int
  targetId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --apis: list # Contains a list of objects containing an API endpoint ID and name. This field applies only to API match targets. — item shape: {id: int, name?: string}
  --bypassNetworkLists: list # The list of network list identifiers and names. — item shape: {id: string, name?: string}
  --body-configId: int # Uniquely identifies the security configuration.
  --configVersion: int # The version of security configuration.
  --defaultFile: string@defaultFile-completer # Describes the rule to match on paths. Either `NO_MATCH` to not match on the default file, `BASE_MATCH` to match only requests for top-level hostnames ending in a trailing slash, or `RECURSIVE_MATCH` to match all requests for paths that end in a trailing slash. (default: NO_MATCH)
  --fileExtensions: list # Contains a list of file extensions.
  --filePaths: list # Contains a list of file paths.
  --hostnames: list # Contains a list of hostnames to protect.
  --isNegativeFileExtensionMatch: oneof<nothing, bool> # Describes whether the match target applies when a match is found in the specified `fileExtensions` or when a match isn't found.
  --isNegativePathMatch: oneof<nothing, bool> # Describes whether the match target applies when a match is found in the specified paths or when a match isn't found.
  securityPolicy: record # The security policy associated with the match target. — shape: {policyId: string}
  --sequence: int # The position in the sequence of match targets.
  --body-targetId: int # Uniquely identifies the match target.
  type: string@type-completer # Describes the type of match target, either `website` or `api`.
]: any -> record<apis: table<id: int, name: string>, bypassNetworkLists: table<id: string, name: string>, configId: int, configVersion: int, defaultFile: string, effectiveSecurityControls: record<applyApiConstraints: bool, applyApplicationLayerControls: bool, applyBotmanControls: bool, applyNetworkLayerControls: bool, applyRateControls: bool, applyReputationControls: bool, applySlowPostControls: bool>, fileExtensions: list<string>, filePaths: list<string>, hostnames: list<string>, isNegativeFileExtensionMatch: bool, isNegativePathMatch: bool, securityPolicy: record<policyId: string>, sequence: int, targetId: int, type: string, validations: record<errors: list<record>, notices: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/match-targets/($targetId)" $qp)
  let body = {apis: $apis, bypassNetworkLists: $bypassNetworkLists, configId: $body_configId, configVersion: $configVersion, defaultFile: $defaultFile, fileExtensions: $fileExtensions, filePaths: $filePaths, hostnames: $hostnames, isNegativeFileExtensionMatch: $isNegativeFileExtensionMatch, isNegativePathMatch: $isNegativePathMatch, securityPolicy: $securityPolicy, sequence: $sequence, targetId: $body_targetId, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a match target
#
# DELETE /configs/{configId}/versions/{versionNumber}/match-targets/{targetId}
# Docs: https://techdocs.akamai.com/application-security/reference/delete-match-target — See documentation for this operation in Akamai's Application Security API
# operationId: delete-match-target
export def "configs-versions-match-targets delete-match-target" [
  configId: int
  versionNumber: int
  targetId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/match-targets/($targetId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Protect evaluation hostnames
#
# PUT /configs/{configId}/versions/{versionNumber}/protect-eval-hostnames
# Docs: https://techdocs.akamai.com/application-security/reference/put-protect-eval-hostnames — See documentation for this operation in Akamai's Application Security API
# operationId: put-protect-eval-hostnames
export def "configs-versions-protect-eval-hostnames put-protect-eval-hostnames" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  hostnames: list # Contains a list of hostnames.
  --mode: string@mode-completer # The type of update you want to make to the evaluation hostname list. You can `append` additional hostnames, `remove` hostnames from the list, or `replace` the existing list with the hostnames you pass in your request.
]: any -> record<hostnames: list<string>, mode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/protect-eval-hostnames" $qp)
  let body = {hostnames: $hostnames, mode: $mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a rate policy
#
# POST /configs/{configId}/versions/{versionNumber}/rate-policies
# Docs: https://techdocs.akamai.com/application-security/reference/post-rate-policies — See documentation for this operation in Akamai's Application Security API
# operationId: post-rate-policies
# --additionalMatchOptions item shape: {positiveMatch: bool, type: "IpAddressCondition"|"NetworkListCondition"|"RequestHeaderCondition"|"RequestMethodCondition"|"ResponseHeaderCondition"|"ResponseStatusCondition"|"UserAgentCondition"|"AsNumberCondition", values: list}
# --apiSelectors item shape: {apiDefinitionId: int, definedResources?: bool, resourceIds?: list, undefinedResources?: bool}
# --bodyParameters item shape: {name: string, positiveMatch: bool, valueInRange?: bool, values: list}
# --condition shape: {atomicConditions?: list, positiveMatch?: bool}
# --evaluation shape: {averageThreshold: int, burstThreshold: int, counterType?: "per_edge"|"region_aggregated"}
# --fileExtensions shape: {positiveMatch: bool, values: list}
# --hosts shape: {positiveMatch: bool, values: list}
# --path shape: {positiveMatch: bool, values: list}
# --queryParameters item shape: {name: string, positiveMatch: bool, valueInRange?: bool, values: list}
export def "configs-versions-rate-policies post-rate-policies" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --additionalMatchOptions: list # The list of additional match conditions. — item shape: {positiveMatch: bool, type: "IpAddressCondition"|"NetworkListCondition"|"RequestHeaderCondition"|"RequestMethodCondition"|"ResponseHeaderCondition"|"ResponseStatusCondition"|"UserAgentCondition"|"AsNumberCondition", values: list}
  --apiSelectors: list # The API endpoints to match in incoming requests. This only applies to the `api` `matchType`. — item shape: {apiDefinitionId: int, definedResources?: bool, resourceIds?: list, undefinedResources?: bool}
  averageThreshold: int # The allowed hits per second during any two-minute interval.
  --bodyParameters: list # The list of body parameters to match on. — item shape: {name: string, positiveMatch: bool, valueInRange?: bool, values: list}
  burstThreshold: int # The allowed hits per second during any five-second interval.
  --burstWindow: int # The time span for the `burstThreshold` interval. For existing rate policies, analyze your traffic in Alert mode before you reduce the measure window from 5 seconds. [Learn more about thresholds here](https://techdocs.akamai.com/kona-site-defender/docs/rate-thresholds).
  clientIdentifier: string # __Deprecated__ The client identifier you want to use to identify and track request senders. The value is required only for WAF type, and `api-key` is supported only for API match criteria. Using `ip-useragent` is typically more specific than using `ip` alone when trying to identify a client. Tracking by `cookie:value` applies to requests per individual session, even if the IP address changes. This field will be removed in future releases. Use `clientIdentifiers` instead. (DEPRECATED)
  --clientIdentifiers: list # Client identifiers to track request senders. The value is required only for WAF type, and `api-key` is supported only for API match criteria. Using `ip-useragent` is typically more specific than using `ip` alone when trying to identify a client. Tracking by `cookie:value` applies to requests per individual session, even if the IP address changes. Specify `request-header:value` to track by a named request header, like `User-Agent`. Use `query-string:value` to track by a specific named query parameter. The `tls-fingerprint` identifier is available for traffic transmitted using secure transport (HTTPS).
  --condition: record # Contains information about the criteria that trigger the rate policy. — shape: {atomicConditions?: list, positiveMatch?: bool}
  --counterType: string@counterType-completer # The rate policy counter type. Either `per_edge` for rate limiting to work per edge node, or `region_aggregated` for rate limiting to work using aggregated rate accounting across multiple edge nodes. (default: per_edge)
  --description: string # Descriptive text you provide about a policy.
  --evaluation: record # Contains details about rate policy evaluation. — shape: {averageThreshold: int, burstThreshold: int, counterType?: "per_edge"|"region_aggregated"}
  --fileExtensions: record # Contains the file extension match criteria. — shape: {positiveMatch: bool, values: list}
  --hostnames: list # __Deprecated__. The hostnames to match. This array is deprecated. Use the `hosts` object instead.
  --hosts: record # The hostnames to match, and whether to trigger on a match or absence of match. — shape: {positiveMatch: bool, values: list}
  matchType: string@matchType-completer # The match type in a rate policy. Either `path` to match website paths or `api` to match API paths.
  name: string # The name you assign to a rate policy.
  --path: record # Contains details about the path match criteria. — shape: {positiveMatch: bool, values: list}
  pathMatchType: string@pathMatchType-completer # The type of paths to match in incoming requests. Either `AllRequests` to match an empty path or any path that ends in a trailing slash (`/`), `TopLevel` to match top-level hostnames only, or `Custom` to match a specific path or path component. This applies only when the corresponding `matchType` member is `path`. Specify `RequestDisabled` to bypass matching on a path.
  --pathUriPositiveMatch: oneof<nothing, bool> # Whether the condition should trigger on a match (`true`) or a lack of match (`false`).
  --penaltyBoxDuration: string@penaltyBoxDuration-completer # The duration of the penalty box. Either `TEN_MINUTES`, `THIRTY_MINUTES`, `ONE_HOUR`, `FOUR_HOURS`, `SIX_HOURS`, `TWELVE_HOURS`, or `TWENTY_FOUR_HOURS`. Only applicable when the `counterType` is `region_aggregated`. (default: TEN_MINUTES)
  --queryParameters: list # The list of query parameter objects to match on. — item shape: {name: string, positiveMatch: bool, valueInRange?: bool, values: list}
  requestType: string@requestType-completer # The type of requests to count towards the rate policy's thresholds. Either `ClientRequest` to count client requests to edge servers, `ClientResponse` to count edge responses to the client, `ForwardResponse` to count origin responses to the client, or `ForwardRequest` to count edge requests to your origin.
  --sameActionOnIpv6: oneof<nothing, bool> # Whether to apply the same action to the IPv6 traffic as to the IPv4 traffic.
  type: string@type-completer-2 # The rate policy type. Either `WAF` for Web Application Firewall, or `BOTMAN` for Bot Manager.
  --useXForwardForHeaders: oneof<nothing, bool> # Whether to check the contents of the `X-Forwarded-For` header in incoming requests.
]: any -> record<additionalMatchOptions: table<positiveMatch: bool, type: string, values: list>, apiSelectors: table<apiDefinitionId: int, definedResources: bool, resourceIds: list, undefinedResources: bool>, averageThreshold: int, bodyParameters: table<name: string, positiveMatch: bool, valueInRange: bool, values: list>, burstThreshold: int, burstWindow: int, clientIdentifier: string, clientIdentifiers: list<string>, condition: record<atomicConditions: list<any>, positiveMatch: bool>, counterType: string, createDate: string, description: string, evaluation: record<averageThreshold: int, burstThreshold: int, burstWindow: int, counterType: string, endDate: string, evaluationId: int, evaluationStatus: string, startDate: string, version: int>, fileExtensions: record<positiveMatch: bool, values: list<string>>, hostnames: list<string>, hosts: record<positiveMatch: bool, values: list<string>>, id: int, matchType: string, name: string, path: record<positiveMatch: bool, values: list<string>>, pathMatchType: string, pathUriPositiveMatch: bool, penaltyBoxDuration: string, queryParameters: table<name: string, positiveMatch: bool, valueInRange: bool, values: list>, requestType: string, sameActionOnIpv6: bool, type: string, updateDate: string, useXForwardForHeaders: bool, used: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/rate-policies" $qp)
  let body = {additionalMatchOptions: $additionalMatchOptions, apiSelectors: $apiSelectors, averageThreshold: $averageThreshold, bodyParameters: $bodyParameters, burstThreshold: $burstThreshold, burstWindow: $burstWindow, clientIdentifier: $clientIdentifier, clientIdentifiers: $clientIdentifiers, condition: $condition, counterType: $counterType, description: $description, evaluation: $evaluation, fileExtensions: $fileExtensions, hostnames: $hostnames, hosts: $hosts, matchType: $matchType, name: $name, path: $path, pathMatchType: $pathMatchType, pathUriPositiveMatch: $pathUriPositiveMatch, penaltyBoxDuration: $penaltyBoxDuration, queryParameters: $queryParameters, requestType: $requestType, sameActionOnIpv6: $sameActionOnIpv6, type: $type, useXForwardForHeaders: $useXForwardForHeaders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List rate policies
#
# GET /configs/{configId}/versions/{versionNumber}/rate-policies
# Docs: https://techdocs.akamai.com/application-security/reference/get-rate-policies — See documentation for this operation in Akamai's Application Security API
# operationId: get-rate-policies
export def "configs-versions-rate-policies get-rate-policies" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<ratePolicies: table<additionalMatchOptions: list, apiSelectors: list, averageThreshold: int, bodyParameters: list, burstThreshold: int, burstWindow: int, clientIdentifier: string, clientIdentifiers: list, condition: record, counterType: string, createDate: string, description: string, evaluation: record, fileExtensions: record, hostnames: list, hosts: record, id: int, matchType: string, name: string, path: record, pathMatchType: string, pathUriPositiveMatch: bool, penaltyBoxDuration: string, queryParameters: list, requestType: string, sameActionOnIpv6: bool, type: string, updateDate: string, useXForwardForHeaders: bool, used: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/rate-policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a rate policy
#
# GET /configs/{configId}/versions/{versionNumber}/rate-policies/{ratePolicyId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-rate-policy — See documentation for this operation in Akamai's Application Security API
# operationId: get-rate-policy
export def "configs-versions-rate-policies get-rate-policy" [
  configId: int
  versionNumber: int
  ratePolicyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<additionalMatchOptions: table<positiveMatch: bool, type: string, values: list>, apiSelectors: table<apiDefinitionId: int, definedResources: bool, resourceIds: list, undefinedResources: bool>, averageThreshold: int, bodyParameters: table<name: string, positiveMatch: bool, valueInRange: bool, values: list>, burstThreshold: int, burstWindow: int, clientIdentifier: string, clientIdentifiers: list<string>, condition: record<atomicConditions: list<any>, positiveMatch: bool>, counterType: string, createDate: string, description: string, evaluation: record<averageThreshold: int, burstThreshold: int, burstWindow: int, counterType: string, endDate: string, evaluationId: int, evaluationStatus: string, startDate: string, version: int>, fileExtensions: record<positiveMatch: bool, values: list<string>>, hostnames: list<string>, hosts: record<positiveMatch: bool, values: list<string>>, id: int, matchType: string, name: string, path: record<positiveMatch: bool, values: list<string>>, pathMatchType: string, pathUriPositiveMatch: bool, penaltyBoxDuration: string, queryParameters: table<name: string, positiveMatch: bool, valueInRange: bool, values: list>, requestType: string, sameActionOnIpv6: bool, type: string, updateDate: string, useXForwardForHeaders: bool, used: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/rate-policies/($ratePolicyId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a rate policy
#
# PUT /configs/{configId}/versions/{versionNumber}/rate-policies/{ratePolicyId}
# Docs: https://techdocs.akamai.com/application-security/reference/put-rate-policy — See documentation for this operation in Akamai's Application Security API
# operationId: put-rate-policy
# --additionalMatchOptions item shape: {positiveMatch: bool, type: "IpAddressCondition"|"NetworkListCondition"|"RequestHeaderCondition"|"RequestMethodCondition"|"ResponseHeaderCondition"|"ResponseStatusCondition"|"UserAgentCondition"|"AsNumberCondition", values: list}
# --apiSelectors item shape: {apiDefinitionId: int, definedResources?: bool, resourceIds?: list, undefinedResources?: bool}
# --bodyParameters item shape: {name: string, positiveMatch: bool, valueInRange?: bool, values: list}
# --condition shape: {atomicConditions?: list, positiveMatch?: bool}
# --evaluation shape: {averageThreshold: int, burstThreshold: int, counterType?: "per_edge"|"region_aggregated"}
# --fileExtensions shape: {positiveMatch: bool, values: list}
# --hosts shape: {positiveMatch: bool, values: list}
# --path shape: {positiveMatch: bool, values: list}
# --queryParameters item shape: {name: string, positiveMatch: bool, valueInRange?: bool, values: list}
export def "configs-versions-rate-policies put-rate-policy" [
  configId: int
  versionNumber: int
  ratePolicyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --additionalMatchOptions: list # The list of additional match conditions. — item shape: {positiveMatch: bool, type: "IpAddressCondition"|"NetworkListCondition"|"RequestHeaderCondition"|"RequestMethodCondition"|"ResponseHeaderCondition"|"ResponseStatusCondition"|"UserAgentCondition"|"AsNumberCondition", values: list}
  --apiSelectors: list # The API endpoints to match in incoming requests. This only applies to the `api` `matchType`. — item shape: {apiDefinitionId: int, definedResources?: bool, resourceIds?: list, undefinedResources?: bool}
  averageThreshold: int # The allowed hits per second during any two-minute interval.
  --bodyParameters: list # The list of body parameters to match on. — item shape: {name: string, positiveMatch: bool, valueInRange?: bool, values: list}
  burstThreshold: int # The allowed hits per second during any five-second interval.
  --burstWindow: int # The time span for the `burstThreshold` interval. For existing rate policies, analyze your traffic in Alert mode before you reduce the measure window from 5 seconds. [Learn more about thresholds here](https://techdocs.akamai.com/kona-site-defender/docs/rate-thresholds).
  clientIdentifier: string # __Deprecated__ The client identifier you want to use to identify and track request senders. The value is required only for WAF type, and `api-key` is supported only for API match criteria. Using `ip-useragent` is typically more specific than using `ip` alone when trying to identify a client. Tracking by `cookie:value` applies to requests per individual session, even if the IP address changes. This field will be removed in future releases. Use `clientIdentifiers` instead. (DEPRECATED)
  --clientIdentifiers: list # Client identifiers to track request senders. The value is required only for WAF type, and `api-key` is supported only for API match criteria. Using `ip-useragent` is typically more specific than using `ip` alone when trying to identify a client. Tracking by `cookie:value` applies to requests per individual session, even if the IP address changes. Specify `request-header:value` to track by a named request header, like `User-Agent`. Use `query-string:value` to track by a specific named query parameter. The `tls-fingerprint` identifier is available for traffic transmitted using secure transport (HTTPS).
  --condition: record # Contains information about the criteria that trigger the rate policy. — shape: {atomicConditions?: list, positiveMatch?: bool}
  --counterType: string@counterType-completer # The rate policy counter type. Either `per_edge` for rate limiting to work per edge node, or `region_aggregated` for rate limiting to work using aggregated rate accounting across multiple edge nodes. (default: per_edge)
  --description: string # Descriptive text you provide about a policy.
  --evaluation: record # Contains details about rate policy evaluation. — shape: {averageThreshold: int, burstThreshold: int, counterType?: "per_edge"|"region_aggregated"}
  --fileExtensions: record # Contains the file extension match criteria. — shape: {positiveMatch: bool, values: list}
  --hostnames: list # __Deprecated__. The hostnames to match. This array is deprecated. Use the `hosts` object instead.
  --hosts: record # The hostnames to match, and whether to trigger on a match or absence of match. — shape: {positiveMatch: bool, values: list}
  matchType: string@matchType-completer # The match type in a rate policy. Either `path` to match website paths or `api` to match API paths.
  name: string # The name you assign to a rate policy.
  --path: record # Contains details about the path match criteria. — shape: {positiveMatch: bool, values: list}
  pathMatchType: string@pathMatchType-completer # The type of paths to match in incoming requests. Either `AllRequests` to match an empty path or any path that ends in a trailing slash (`/`), `TopLevel` to match top-level hostnames only, or `Custom` to match a specific path or path component. This applies only when the corresponding `matchType` member is `path`. Specify `RequestDisabled` to bypass matching on a path.
  --pathUriPositiveMatch: oneof<nothing, bool> # Whether the condition should trigger on a match (`true`) or a lack of match (`false`).
  --penaltyBoxDuration: string@penaltyBoxDuration-completer # The duration of the penalty box. Either `TEN_MINUTES`, `THIRTY_MINUTES`, `ONE_HOUR`, `FOUR_HOURS`, `SIX_HOURS`, `TWELVE_HOURS`, or `TWENTY_FOUR_HOURS`. Only applicable when the `counterType` is `region_aggregated`. (default: TEN_MINUTES)
  --queryParameters: list # The list of query parameter objects to match on. — item shape: {name: string, positiveMatch: bool, valueInRange?: bool, values: list}
  requestType: string@requestType-completer # The type of requests to count towards the rate policy's thresholds. Either `ClientRequest` to count client requests to edge servers, `ClientResponse` to count edge responses to the client, `ForwardResponse` to count origin responses to the client, or `ForwardRequest` to count edge requests to your origin.
  --sameActionOnIpv6: oneof<nothing, bool> # Whether to apply the same action to the IPv6 traffic as to the IPv4 traffic.
  type: string@type-completer-2 # The rate policy type. Either `WAF` for Web Application Firewall, or `BOTMAN` for Bot Manager.
  --useXForwardForHeaders: oneof<nothing, bool> # Whether to check the contents of the `X-Forwarded-For` header in incoming requests.
]: any -> record<additionalMatchOptions: table<positiveMatch: bool, type: string, values: list>, apiSelectors: table<apiDefinitionId: int, definedResources: bool, resourceIds: list, undefinedResources: bool>, averageThreshold: int, bodyParameters: table<name: string, positiveMatch: bool, valueInRange: bool, values: list>, burstThreshold: int, burstWindow: int, clientIdentifier: string, clientIdentifiers: list<string>, condition: record<atomicConditions: list<any>, positiveMatch: bool>, counterType: string, createDate: string, description: string, evaluation: record<averageThreshold: int, burstThreshold: int, burstWindow: int, counterType: string, endDate: string, evaluationId: int, evaluationStatus: string, startDate: string, version: int>, fileExtensions: record<positiveMatch: bool, values: list<string>>, hostnames: list<string>, hosts: record<positiveMatch: bool, values: list<string>>, id: int, matchType: string, name: string, path: record<positiveMatch: bool, values: list<string>>, pathMatchType: string, pathUriPositiveMatch: bool, penaltyBoxDuration: string, queryParameters: table<name: string, positiveMatch: bool, valueInRange: bool, values: list>, requestType: string, sameActionOnIpv6: bool, type: string, updateDate: string, useXForwardForHeaders: bool, used: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/rate-policies/($ratePolicyId)" $qp)
  let body = {additionalMatchOptions: $additionalMatchOptions, apiSelectors: $apiSelectors, averageThreshold: $averageThreshold, bodyParameters: $bodyParameters, burstThreshold: $burstThreshold, burstWindow: $burstWindow, clientIdentifier: $clientIdentifier, clientIdentifiers: $clientIdentifiers, condition: $condition, counterType: $counterType, description: $description, evaluation: $evaluation, fileExtensions: $fileExtensions, hostnames: $hostnames, hosts: $hosts, matchType: $matchType, name: $name, path: $path, pathMatchType: $pathMatchType, pathUriPositiveMatch: $pathUriPositiveMatch, penaltyBoxDuration: $penaltyBoxDuration, queryParameters: $queryParameters, requestType: $requestType, sameActionOnIpv6: $sameActionOnIpv6, type: $type, useXForwardForHeaders: $useXForwardForHeaders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a rate policy
#
# DELETE /configs/{configId}/versions/{versionNumber}/rate-policies/{ratePolicyId}
# Docs: https://techdocs.akamai.com/application-security/reference/delete-rate-policy — See documentation for this operation in Akamai's Application Security API
# operationId: delete-rate-policy
export def "configs-versions-rate-policies delete-rate-policy" [
  configId: int
  versionNumber: int
  ratePolicyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/rate-policies/($ratePolicyId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a rate policy evaluation
#
# PUT /configs/{configId}/versions/{versionNumber}/rate-policies/{ratePolicyId}/evaluation
# Docs: https://techdocs.akamai.com/application-security/reference/put-rate-policy-evaluation — See documentation for this operation in Akamai's Application Security API
# operationId: put-rate-policy-evaluation
export def "configs-versions-rate-policies-evaluation put-rate-policy-evaluation" [
  configId: int
  versionNumber: int
  ratePolicyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  action: string@action-completer-3 # Specifies the action to perform on a rate policy evaluation, either `APPLY` or `DISCARD`.
]: any -> record<additionalMatchOptions: table<positiveMatch: bool, type: string, values: list>, apiSelectors: table<apiDefinitionId: int, definedResources: bool, resourceIds: list, undefinedResources: bool>, averageThreshold: int, bodyParameters: table<name: string, positiveMatch: bool, valueInRange: bool, values: list>, burstThreshold: int, burstWindow: int, clientIdentifier: string, clientIdentifiers: list<string>, condition: record<atomicConditions: list<any>, positiveMatch: bool>, counterType: string, createDate: string, description: string, evaluation: record<averageThreshold: int, burstThreshold: int, burstWindow: int, counterType: string, endDate: string, evaluationId: int, evaluationStatus: string, startDate: string, version: int>, fileExtensions: record<positiveMatch: bool, values: list<string>>, hostnames: list<string>, hosts: record<positiveMatch: bool, values: list<string>>, id: int, matchType: string, name: string, path: record<positiveMatch: bool, values: list<string>>, pathMatchType: string, pathUriPositiveMatch: bool, penaltyBoxDuration: string, queryParameters: table<name: string, positiveMatch: bool, valueInRange: bool, values: list>, requestType: string, sameActionOnIpv6: bool, type: string, updateDate: string, useXForwardForHeaders: bool, used: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/rate-policies/($ratePolicyId)/evaluation" $qp)
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a reputation profile
#
# POST /configs/{configId}/versions/{versionNumber}/reputation-profiles
# Docs: https://techdocs.akamai.com/application-security/reference/post-reputation-profiles — See documentation for this operation in Akamai's Application Security API
# operationId: post-reputation-profiles
# --condition shape: {atomicConditions?: list, positiveMatch?: bool}
export def "configs-versions-reputation-profiles post-reputation-profiles" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --condition: record # Contains information about the criteria that trigger the reputation profile. — shape: {atomicConditions?: list, positiveMatch?: bool}
  context: string@context-completer # Identifies the reputation category. Web scrapers (`WEBSCRP`) crawl sites and collect data like hotel rates, product prices, store locations, and more. DoS attackers (`DOSATCK`) are web clients or botnets that use automated tools to launch volumetric Denial of Service (DoS) attacks. Web attackers (`WEBATCK`) target websites and web apps with techniques like SQL injection, remote file inclusion, or cross-site scripting. Scanning tools (`SCANTL`) probe web apps for vulnerabilities during an attack's reconnaissance phase.
  --description: string # Describes the reputation profile.
  name: string # The name you assigned to the reputation profile.
  sharedIpHandling: string@sharedIpHandling-completer # Identifies the IP sharing. Either `NON_SHARED`, `SHARED_ONLY`, `BOTH`.
  threshold: float # The threshold when the profile to triggers.
]: any -> record<condition: record<atomicConditions: list<record>, positiveMatch: bool>, context: string, contextReadable: string, description: string, enabled: bool, id: int, name: string, sharedIpHandling: string, threshold: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/reputation-profiles" $qp)
  let body = {condition: $condition, context: $context, description: $description, name: $name, sharedIpHandling: $sharedIpHandling, threshold: $threshold} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List reputation profiles
#
# GET /configs/{configId}/versions/{versionNumber}/reputation-profiles
# Docs: https://techdocs.akamai.com/application-security/reference/get-reputation-profiles — See documentation for this operation in Akamai's Application Security API
# operationId: get-reputation-profiles
export def "configs-versions-reputation-profiles get-reputation-profiles" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<reputationProfiles: table<condition: record, context: string, contextReadable: string, description: string, enabled: bool, id: int, name: string, sharedIpHandling: string, threshold: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/reputation-profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a reputation profile
#
# GET /configs/{configId}/versions/{versionNumber}/reputation-profiles/{reputationProfileId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-reputation-profile — See documentation for this operation in Akamai's Application Security API
# operationId: get-reputation-profile
export def "configs-versions-reputation-profiles get-reputation-profile" [
  configId: int
  versionNumber: int
  reputationProfileId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<condition: record<atomicConditions: list<record>, positiveMatch: bool>, context: string, contextReadable: string, description: string, enabled: bool, id: int, name: string, sharedIpHandling: string, threshold: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/reputation-profiles/($reputationProfileId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a reputation profile
#
# PUT /configs/{configId}/versions/{versionNumber}/reputation-profiles/{reputationProfileId}
# Docs: https://techdocs.akamai.com/application-security/reference/put-reputation-profile — See documentation for this operation in Akamai's Application Security API
# operationId: put-reputation-profile
# --condition shape: {atomicConditions?: list, positiveMatch?: bool}
export def "configs-versions-reputation-profiles put-reputation-profile" [
  configId: int
  versionNumber: int
  reputationProfileId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --condition: record # Contains information about the criteria that trigger the reputation profile. — shape: {atomicConditions?: list, positiveMatch?: bool}
  context: string@context-completer # Identifies the reputation category. Web scrapers (`WEBSCRP`) crawl sites and collect data like hotel rates, product prices, store locations, and more. DoS attackers (`DOSATCK`) are web clients or botnets that use automated tools to launch volumetric Denial of Service (DoS) attacks. Web attackers (`WEBATCK`) target websites and web apps with techniques like SQL injection, remote file inclusion, or cross-site scripting. Scanning tools (`SCANTL`) probe web apps for vulnerabilities during an attack's reconnaissance phase.
  --description: string # Describes the reputation profile.
  name: string # The name you assigned to the reputation profile.
  sharedIpHandling: string@sharedIpHandling-completer # Identifies the IP sharing. Either `NON_SHARED`, `SHARED_ONLY`, `BOTH`.
  threshold: float # The threshold when the profile to triggers.
]: any -> record<condition: record<atomicConditions: list<record>, positiveMatch: bool>, context: string, contextReadable: string, description: string, enabled: bool, id: int, name: string, sharedIpHandling: string, threshold: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/reputation-profiles/($reputationProfileId)" $qp)
  let body = {condition: $condition, context: $context, description: $description, name: $name, sharedIpHandling: $sharedIpHandling, threshold: $threshold} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a reputation profile
#
# DELETE /configs/{configId}/versions/{versionNumber}/reputation-profiles/{reputationProfileId}
# Docs: https://techdocs.akamai.com/application-security/reference/delete-reputation-profile — See documentation for this operation in Akamai's Application Security API
# operationId: delete-reputation-profile
export def "configs-versions-reputation-profiles delete-reputation-profile" [
  configId: int
  versionNumber: int
  reputationProfileId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/reputation-profiles/($reputationProfileId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a challenge action
#
# POST /configs/{configId}/versions/{versionNumber}/response-actions/challenge-actions
# Docs: https://techdocs.akamai.com/application-security/reference/post-challenge-action — See documentation for this operation in Akamai's Application Security API
# operationId: post-challenge-action
export def "configs-versions-response-actions-challenge-actions post-challenge-action" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  actionName: string # The action's unique name.
  --allowFullCpuUtilization: oneof<nothing, bool> # Set to `true` to let the client use 100 percent CPU to resolve the challenge. If more humans than bots see this challenge, set to `false`. (nullable)
  challengeIntervalInSeconds: int # Time between challenges. Set according to how long users interact with the resource you're protecting. A short period interrupts users more often.
  challengeType: string@challengeType-completer # Specify the type of challenge. Choose `GOOGLE_RECAPTCHA` to make users solve a CAPTCHA puzzle. You can also choose `AKAMAI_WEB_CRYPTO` or `AKAMAI_MOBILE_CRYPTO` to make web requesting clients or mobile requesting clients solve a proof-of-work cryptographic challenge.
  --cryptoChallengeDurationInSeconds: int # Specify how many seconds the client machine should spend on the challenge. The longer the duration, the more difficult the challenge. (nullable)
  --customBrandingLegacyCssUrl: string # The CSS page containing your custom spinner. Specify the page's fully qualified URL or root-relative path, like `http://example.com/pages/sample.html` or `/pages/sample.html`. (nullable)
  --customBrandingLegacyMessageUrl: string # The web page containing the static HTML snippet with your custom message. Specify the page's fully qualified URL or root-relative path, like `http://example.com/pages/sample.html` or `/pages/sample.html`. (nullable)
  --customBrandingUrl: string # The web page containing the static HTML snippet with your custom logo. Specify the page's fully qualified URL or root-relative path, like `http://example.com/pages/sample.html` or `/pages/sample.html`. (nullable)
  --description: string # An optional description of the action. (nullable)
  --googleReCaptchaSecretKey: string # If the `challengeType` is `GOOGLE_RECAPTCHA`, specify the Google reCAPTCHA secret key. The secret key authorizes communication between your site and the reCAPTCHA server. (nullable)
  --googleReCaptchaSiteKey: string # If the `challengeType` is `GOOGLE_RECAPTCHA`, specify the Google reCAPTCHA site key. The site key invokes the reCAPTCHA service on your site or application. (nullable)
]: any -> record<actionId: string, actionName: string, allowFullCpuUtilization: bool, challengeIntervalInSeconds: int, challengeType: string, cryptoChallengeDurationInSeconds: int, customBrandingLegacyCssUrl: string, customBrandingLegacyMessageUrl: string, customBrandingUrl: string, description: string, googleReCaptchaSecretKey: string, googleReCaptchaSiteKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/response-actions/challenge-actions" $qp)
  let body = {actionName: $actionName, allowFullCpuUtilization: $allowFullCpuUtilization, challengeIntervalInSeconds: $challengeIntervalInSeconds, challengeType: $challengeType, cryptoChallengeDurationInSeconds: $cryptoChallengeDurationInSeconds, customBrandingLegacyCssUrl: $customBrandingLegacyCssUrl, customBrandingLegacyMessageUrl: $customBrandingLegacyMessageUrl, customBrandingUrl: $customBrandingUrl, description: $description, googleReCaptchaSecretKey: $googleReCaptchaSecretKey, googleReCaptchaSiteKey: $googleReCaptchaSiteKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List challenge actions
#
# GET /configs/{configId}/versions/{versionNumber}/response-actions/challenge-actions
# Docs: https://techdocs.akamai.com/application-security/reference/get-challenge-actions — See documentation for this operation in Akamai's Application Security API
# operationId: get-challenge-actions
export def "configs-versions-response-actions-challenge-actions get-challenge-actions" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<challengeActions: table<actionId: string, actionName: string, allowFullCpuUtilization: bool, challengeIntervalInSeconds: int, challengeType: string, cryptoChallengeDurationInSeconds: int, customBrandingLegacyCssUrl: string, customBrandingLegacyMessageUrl: string, customBrandingUrl: string, description: string, googleReCaptchaSecretKey: string, googleReCaptchaSiteKey: string>, validation: record<errors: list<record>, notices: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/response-actions/challenge-actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a challenge action
#
# GET /configs/{configId}/versions/{versionNumber}/response-actions/challenge-actions/{actionId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-challenge-action — See documentation for this operation in Akamai's Application Security API
# operationId: get-challenge-action
export def "configs-versions-response-actions-challenge-actions get-challenge-action" [
  configId: int
  versionNumber: int
  actionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<actionId: string, actionName: string, allowFullCpuUtilization: bool, challengeIntervalInSeconds: int, challengeType: string, cryptoChallengeDurationInSeconds: int, customBrandingLegacyCssUrl: string, customBrandingLegacyMessageUrl: string, customBrandingUrl: string, description: string, googleReCaptchaSecretKey: string, googleReCaptchaSiteKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/response-actions/challenge-actions/($actionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a challenge action
#
# PUT /configs/{configId}/versions/{versionNumber}/response-actions/challenge-actions/{actionId}
# Docs: https://techdocs.akamai.com/application-security/reference/put-challenge-action — See documentation for this operation in Akamai's Application Security API
# operationId: put-challenge-action
export def "configs-versions-response-actions-challenge-actions put-challenge-action" [
  configId: int
  versionNumber: int
  actionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  actionName: string # The action's unique name.
  --allowFullCpuUtilization: oneof<nothing, bool> # Set to `true` to let the client use 100 percent CPU to resolve the challenge. If more humans than bots see this challenge, set to `false`. (nullable)
  challengeIntervalInSeconds: int # Time between challenges. Set according to how long users interact with the resource you're protecting. A short period interrupts users more often.
  challengeType: string@challengeType-completer # Specify the type of challenge. Choose `GOOGLE_RECAPTCHA` to make users solve a CAPTCHA puzzle. You can also choose `AKAMAI_WEB_CRYPTO` or `AKAMAI_MOBILE_CRYPTO` to make web requesting clients or mobile requesting clients solve a proof-of-work cryptographic challenge.
  --cryptoChallengeDurationInSeconds: int # Specify how many seconds the client machine should spend on the challenge. The longer the duration, the more difficult the challenge. (nullable)
  --customBrandingLegacyCssUrl: string # The CSS page containing your custom spinner. Specify the page's fully qualified URL or root-relative path, like `http://example.com/pages/sample.html` or `/pages/sample.html`. (nullable)
  --customBrandingLegacyMessageUrl: string # The web page containing the static HTML snippet with your custom message. Specify the page's fully qualified URL or root-relative path, like `http://example.com/pages/sample.html` or `/pages/sample.html`. (nullable)
  --customBrandingUrl: string # The web page containing the static HTML snippet with your custom logo. Specify the page's fully qualified URL or root-relative path, like `http://example.com/pages/sample.html` or `/pages/sample.html`. (nullable)
  --description: string # An optional description of the action. (nullable)
  --googleReCaptchaSecretKey: string # If the `challengeType` is `GOOGLE_RECAPTCHA`, specify the Google reCAPTCHA secret key. The secret key authorizes communication between your site and the reCAPTCHA server. (nullable)
  --googleReCaptchaSiteKey: string # If the `challengeType` is `GOOGLE_RECAPTCHA`, specify the Google reCAPTCHA site key. The site key invokes the reCAPTCHA service on your site or application. (nullable)
]: any -> record<actionId: string, actionName: string, allowFullCpuUtilization: bool, challengeIntervalInSeconds: int, challengeType: string, cryptoChallengeDurationInSeconds: int, customBrandingLegacyCssUrl: string, customBrandingLegacyMessageUrl: string, customBrandingUrl: string, description: string, googleReCaptchaSecretKey: string, googleReCaptchaSiteKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/response-actions/challenge-actions/($actionId)" $qp)
  let body = {actionName: $actionName, allowFullCpuUtilization: $allowFullCpuUtilization, challengeIntervalInSeconds: $challengeIntervalInSeconds, challengeType: $challengeType, cryptoChallengeDurationInSeconds: $cryptoChallengeDurationInSeconds, customBrandingLegacyCssUrl: $customBrandingLegacyCssUrl, customBrandingLegacyMessageUrl: $customBrandingLegacyMessageUrl, customBrandingUrl: $customBrandingUrl, description: $description, googleReCaptchaSecretKey: $googleReCaptchaSecretKey, googleReCaptchaSiteKey: $googleReCaptchaSiteKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a challenge action
#
# DELETE /configs/{configId}/versions/{versionNumber}/response-actions/challenge-actions/{actionId}
# Docs: https://techdocs.akamai.com/application-security/reference/delete-challenge-action — See documentation for this operation in Akamai's Application Security API
# operationId: delete-challenge-action
export def "configs-versions-response-actions-challenge-actions delete-challenge-action" [
  configId: int
  versionNumber: int
  actionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/response-actions/challenge-actions/($actionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Google reCAPTCHA secret key
#
# PUT /configs/{configId}/versions/{versionNumber}/response-actions/challenge-actions/{actionId}/google-recaptcha-secret-key
# Docs: https://techdocs.akamai.com/application-security/reference/put-google-recaptcha-secret-key — See documentation for this operation in Akamai's Application Security API
# operationId: put-google-recaptcha-secret-key
export def "configs-versions-response-actions-challenge-actions-google-recaptcha-secret-key put-google-recaptcha-secret-key" [
  configId: int
  versionNumber: int
  actionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  googleReCaptchaSecretKey: string # The Google reCAPTCHA secret key.
]: any -> record<googleReCaptchaSecretKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/response-actions/challenge-actions/($actionId)/google-recaptcha-secret-key" $qp)
  let body = {googleReCaptchaSecretKey: $googleReCaptchaSecretKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Clone or create a security policy
#
# POST /configs/{configId}/versions/{versionNumber}/security-policies
# Docs: https://techdocs.akamai.com/application-security/reference/post-policy — See documentation for this operation in Akamai's Application Security API
# operationId: post-policy
export def "configs-versions-security-policies post-policy" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --createFromSecurityPolicy: string # The unique identifier (`policyId`) of the source policy to create the new policy from. (e.g. 1_35752)
  --defaultSettings: string # The default settings on the policy, `true` by default.
  --policyName: string # The name of the security policy. If not provided, the system generates a name automatically with the pattern  `clone from <createFromSecurityPolicy>`.
  --policyPrefix: string # The four-character alphanumeric string prefix for the `policyId`. If not provided, the prefix is autogenerated.
  --body-source: string # The source for the new the policy. If not provided, the source is blank. Other values are 'default' or the source security policy ID. (nullable)
]: any -> record<configId: int, hasRatePolicyWithApiKey: bool, policyId: string, policyName: string, policySecurityControls: record<applyApiConstraints: bool, applyApplicationLayerControls: bool, applyBotmanControls: bool, applyNetworkLayerControls: bool, applyRateControls: bool, applyReputationControls: bool, applySlowPostControls: bool>, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies" $qp)
  let body = {createFromSecurityPolicy: $createFromSecurityPolicy, defaultSettings: $defaultSettings, policyName: $policyName, policyPrefix: $policyPrefix, source: $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List security policies
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies
# Docs: https://techdocs.akamai.com/application-security/reference/get-policies — See documentation for this operation in Akamai's Application Security API
# operationId: get-policies
export def "configs-versions-security-policies get-policies" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notMatched: oneof<nothing, bool> # If `true`, returns all security policies in the configuration version that don't have a match target.  If `false`, returns all security policies in the configuration version. (e.g. true)
  --detail: oneof<nothing, bool> # When `true`, the results contain detailed information on versions. With the default `false`, the results contain summary information on versions. (default: false, e.g. true)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<configId: int, policies: table<configId: int, hasRatePolicyWithApiKey: bool, policyId: string, policyName: string, policySecurityControls: record, version: int>, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notMatched" $notMatched "scalar") (serialize-qp "detail" $detail "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a security policy
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-policy — See documentation for this operation in Akamai's Application Security API
# operationId: get-policy
export def "configs-versions-security-policies get-policy" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<configId: int, hasRatePolicyWithApiKey: bool, policyId: string, policyName: string, policySecurityControls: record<applyApiConstraints: bool, applyApplicationLayerControls: bool, applyBotmanControls: bool, applyNetworkLayerControls: bool, applyRateControls: bool, applyReputationControls: bool, applySlowPostControls: bool>, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a security policy
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}
# Docs: https://techdocs.akamai.com/application-security/reference/put-policy — See documentation for this operation in Akamai's Application Security API
# operationId: put-policy
export def "configs-versions-security-policies put-policy" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  policyName: string # The name of the security policy.
]: any -> record<policyName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)" $qp)
  let body = {policyName: $policyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a security policy
#
# DELETE /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}
# Docs: https://techdocs.akamai.com/application-security/reference/delete-policy — See documentation for this operation in Akamai's Application Security API
# operationId: delete-policy
export def "configs-versions-security-policies delete-policy" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get evasive path match settings
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/advanced-settings/evasive-path-match
# Docs: https://techdocs.akamai.com/application-security/reference/get-evasive-path-match — See documentation for this operation in Akamai's Application Security API
# operationId: get-evasive-path-match
export def "configs-versions-security-policies-advanced-settings-evasive-path-match get-evasive-path-match" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<enablePathMatch: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/advanced-settings/evasive-path-match" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify evasive path match settings
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/advanced-settings/evasive-path-match
# Docs: https://techdocs.akamai.com/application-security/reference/put-evasive-path-match — See documentation for this operation in Akamai's Application Security API
# operationId: put-evasive-path-match
export def "configs-versions-security-policies-advanced-settings-evasive-path-match put-evasive-path-match" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --enablePathMatch: oneof<nothing, bool> # When enabled, evaluates requests with the following list of characters removed ` & ! $ ' ( ) + , [ ] * @ ^ \ "` and `.` only when it appears as a trailing character at the end of the URL.
]: any -> record<enablePathMatch: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/advanced-settings/evasive-path-match" $qp)
  let body = {enablePathMatch: $enablePathMatch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get HTTP header log settings
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/advanced-settings/logging
# Docs: https://techdocs.akamai.com/application-security/reference/get-policies-logging — See documentation for this operation in Akamai's Application Security API
# operationId: get-policies-logging
export def "configs-versions-security-policies-advanced-settings-logging get-policies-logging" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<allowSampling: bool, cookies: record<type: string, values: list<string>>, customHeaders: record<type: string, values: list<string>>, override: bool, standardHeaders: record<type: string, values: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/advanced-settings/logging" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify HTTP header log settings
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/advanced-settings/logging
# Docs: https://techdocs.akamai.com/application-security/reference/put-policies-logging — See documentation for this operation in Akamai's Application Security API
# operationId: put-policies-logging
# --cookies shape: {type: "all"|"none"|"exclude"|"only", values?: list}
# --customHeaders shape: {type: "all"|"none"|"exclude"|"only", values?: list}
# --standardHeaders shape: {type: "all"|"none"|"exclude"|"only", values?: list}
export def "configs-versions-security-policies-advanced-settings-logging put-policies-logging" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --allowSampling: oneof<nothing, bool> # Whether you enabled the header data sampling.
  --cookies: record # When enabled, filter requests whose headers you log by cookie. — shape: {type: "all"|"none"|"exclude"|"only", values?: list}
  --customHeaders: record # When enabled, filter requests you log by custom headers you specify. — shape: {type: "all"|"none"|"exclude"|"only", values?: list}
  --override: oneof<nothing, bool> # When enabled, your security configuration won't log any header data for security events triggered by settings in the security configuration.
  --standardHeaders: record # When enabled, filter requests you log by standard headers you specify. — shape: {type: "all"|"none"|"exclude"|"only", values?: list}
]: any -> record<allowSampling: bool, cookies: record<type: string, values: list<string>>, customHeaders: record<type: string, values: list<string>>, override: bool, standardHeaders: record<type: string, values: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/advanced-settings/logging" $qp)
  let body = {allowSampling: $allowSampling, cookies: $cookies, customHeaders: $customHeaders, override: $override, standardHeaders: $standardHeaders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get attack payload logging settings for a policy
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/advanced-settings/logging/attack-payload
# Docs: https://techdocs.akamai.com/application-security/reference/get-policies-attack-payload-logging — See documentation for this operation in Akamai's Application Security API
# operationId: get-policies-attack-payload-logging
export def "configs-versions-security-policies-advanced-settings-logging-attack-payload get-policies-attack-payload-logging" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<enabled: bool, override: bool, requestBody: record<type: string>, responseBody: record<type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/advanced-settings/logging/attack-payload" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify attack payload logging settings for a policy
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/advanced-settings/logging/attack-payload
# Docs: https://techdocs.akamai.com/application-security/reference/put-policies-attack-payload-logging — See documentation for this operation in Akamai's Application Security API
# operationId: put-policies-attack-payload-logging
# --requestBody shape: {type: "ATTACK_PAYLOAD"|"NONE"}
# --responseBody shape: {type: "ATTACK_PAYLOAD"|"NONE"}
export def "configs-versions-security-policies-advanced-settings-logging-attack-payload put-policies-attack-payload-logging" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --enabled: oneof<nothing, bool> # When enabled, log attack payloads in requests and responses.
  --override: oneof<nothing, bool> # When `true`, use the security policy's attack payload logging settings instead of the settings at the configuration level. Note that when `type` is `NONE`, the request body and response body show as redacted in the log. For example, `JSON_PAIRS:redacted`.
  requestBody: record # The settings for how Akamai's network logs attack payloads in request bodies. — shape: {type: "ATTACK_PAYLOAD"|"NONE"}
  responseBody: record # The settings for how Akamai's network logs attack payloads in response bodies. — shape: {type: "ATTACK_PAYLOAD"|"NONE"}
]: any -> record<enabled: bool, override: bool, requestBody: record<type: string>, responseBody: record<type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/advanced-settings/logging/attack-payload" $qp)
  let body = {enabled: $enabled, override: $override, requestBody: $requestBody, responseBody: $responseBody} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Pragma settings for a security policy
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/advanced-settings/pragma-header
# Docs: https://techdocs.akamai.com/application-security/reference/get-policies-pragma-header — See documentation for this operation in Akamai's Application Security API
# operationId: get-policies-pragma-header
export def "configs-versions-security-policies-advanced-settings-pragma-header get-policies-pragma-header" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<action: string, conditionOperator: string, excludeCondition: table<header: string, name: string, positiveMatch: bool, type: string, useHeaders: bool, value: list, valueCase: bool, valueWildcard: bool>, override: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/advanced-settings/pragma-header" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify Pragma settings for a security policy
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/advanced-settings/pragma-header
# Docs: https://techdocs.akamai.com/application-security/reference/put-policies-pragma-header — See documentation for this operation in Akamai's Application Security API
# operationId: put-policies-pragma-header
# --excludeCondition item shape: {header?: string, name?: string, positiveMatch: bool, type: "requestHeaderValueMatch"|"ipMatch"|"networkList"|"queryParamNameValueMatch", useHeaders?: bool, value: list, valueCase?: bool, valueWildcard?: bool}
export def "configs-versions-security-policies-advanced-settings-pragma-header put-policies-pragma-header" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  action: string@action-completer-2 # The action to perform when a user passes a `Pragma` header. The only action currently supported is `REMOVE`.
  --conditionOperator: string@conditionOperator-completer # Use `OR` to match any condition, or `AND` to match on all conditions.
  --excludeCondition: list # The conditions to exclude from the default `remove` action. Any condition you set in this object appears in the `Pragma` header debug response object. — item shape: {header?: string, name?: string, positiveMatch: bool, type: "requestHeaderValueMatch"|"ipMatch"|"networkList"|"queryParamNameValueMatch", useHeaders?: bool, value: list, valueCase?: bool, valueWildcard?: bool}
  --override: oneof<nothing, bool> # Whether `Pragma` header override is enabled or disabled.
]: any -> record<action: string, conditionOperator: string, excludeCondition: table<header: string, name: string, positiveMatch: bool, type: string, useHeaders: bool, value: list, valueCase: bool, valueWildcard: bool>, override: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/advanced-settings/pragma-header" $qp)
  let body = {action: $action, conditionOperator: $conditionOperator, excludeCondition: $excludeCondition, override: $override} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get request body inspection limit settings for a security policy
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/advanced-settings/request-body
# Docs: https://techdocs.akamai.com/application-security/reference/get-policies-request-body — See documentation for this operation in Akamai's Application Security API
# operationId: get-policies-request-body
export def "configs-versions-security-policies-advanced-settings-request-body get-policies-request-body" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<requestBodyInspectionLimitInKB: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/advanced-settings/request-body" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify request body size settings for a security policy
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/advanced-settings/request-body
# Docs: https://techdocs.akamai.com/application-security/reference/put-policies-request-body — See documentation for this operation in Akamai's Application Security API
# operationId: put-policies-request-body
export def "configs-versions-security-policies-advanced-settings-request-body put-policies-request-body" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --requestBodyInspectionLimitInKB: string@requestBodyInspectionLimitInKB-completer # Request body size in KB, either `8`, `16`, or `32` as string-formatted integers, or `default` to use Akamai's best practice value.
]: any -> record<requestBodyInspectionLimitInKB: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/advanced-settings/request-body" $qp)
  let body = {requestBodyInspectionLimitInKB: $requestBodyInspectionLimitInKB} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List API endpoints
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/api-endpoints
# Docs: https://techdocs.akamai.com/application-security/reference/get-api-endpoints — See documentation for this operation in Akamai's Application Security API
# operationId: get-api-endpoints
export def "configs-versions-security-policies-api-endpoints get-api-endpoints" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<apiEndpoints: table<apiEndPointHosts: list, apiResources: list, basePath: string, categories: list, id: int, name: string, productionVersion: record, requestConstraintsEnabled: bool, stagingVersion: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/api-endpoints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List API request constraints and actions
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/api-request-constraints
# Docs: https://techdocs.akamai.com/application-security/reference/get-api-request-constraints — See documentation for this operation in Akamai's Application Security API
# operationId: get-api-request-constraints
export def "configs-versions-security-policies-api-request-constraints get-api-request-constraints" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<apiEndpoints: table<action: string, id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/api-request-constraints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the request constraint action for all APIs
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/api-request-constraints
# Docs: https://techdocs.akamai.com/application-security/reference/put-api-request-constraints — See documentation for this operation in Akamai's Application Security API
# operationId: put-api-request-constraints
export def "configs-versions-security-policies-api-request-constraints put-api-request-constraints" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  action: string@action-completer-4 # The action to assign to API request constraints, either `alert`, `deny`, or `none`. Use `deny_custom_{custom_deny_id}` to apply a custom action instead of Akamai's default. Run [Modify a custom deny action](https://techdocs.akamai.com/application-security/reference/put-custom-deny) to manage your custom deny actions. If the action is `none`, the rule is inactive in the policy.
]: any -> record<apiEndpoints: table<action: string, id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/api-request-constraints" $qp)
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Modify an API request constraint's action
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/api-request-constraints/{apiId}
# Docs: https://techdocs.akamai.com/application-security/reference/put-api-request-constraints-api — See documentation for this operation in Akamai's Application Security API
# operationId: put-api-request-constraints-api
export def "configs-versions-security-policies-api-request-constraints put-api-request-constraints-api" [
  configId: int
  versionNumber: int
  policyId: string
  apiId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  action: string@action-completer-4 # The action to assign to API request constraints, either `alert`, `deny`, or `none`. Use `deny_custom_{custom_deny_id}` to apply a custom action instead of Akamai's default. Run [Modify a custom deny action](https://techdocs.akamai.com/application-security/reference/put-custom-deny) to manage your custom deny actions. If the action is `none`, the rule is inactive in the policy.
]: any -> record<action: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/api-request-constraints/($apiId)" $qp)
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List attack groups
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/attack-groups
# Docs: https://techdocs.akamai.com/application-security/reference/get-policy-attack-groups — See documentation for this operation in Akamai's Application Security API
# operationId: get-policy-attack-groups
export def "configs-versions-security-policies-attack-groups get-policy-attack-groups" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<attackGroupActions: table<action: string, group: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/attack-groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the action for an attack group
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/attack-groups/{attackGroupId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-policy-attack-group — See documentation for this operation in Akamai's Application Security API
# operationId: get-policy-attack-group
export def "configs-versions-security-policies-attack-groups get-policy-attack-group" [
  configId: int
  versionNumber: int
  policyId: string
  attackGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<action: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/attack-groups/($attackGroupId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the action for an attack group
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/attack-groups/{attackGroupId}
# Docs: https://techdocs.akamai.com/application-security/reference/put-attack-group — See documentation for this operation in Akamai's Application Security API
# operationId: put-attack-group
export def "configs-versions-security-policies-attack-groups put-attack-group" [
  configId: int
  versionNumber: int
  policyId: string
  attackGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  action: string@action-completer-4 # The attack group action, either `alert`, `deny`, or `none`.
]: any -> record<action: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/attack-groups/($attackGroupId)" $qp)
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the exceptions of an attack group
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/attack-groups/{attackGroupId}/condition-exception
# Docs: https://techdocs.akamai.com/application-security/reference/get-attack-group-condition-exception — See documentation for this operation in Akamai's Application Security API
# operationId: get-attack-group-condition-exception
export def "configs-versions-security-policies-attack-groups-condition-exception get-attack-group-condition-exception" [
  configId: int
  versionNumber: int
  policyId: string
  attackGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<advancedExceptions: record<conditionOperator: string, conditions: list<record>, headerCookieOrParamValues: list<record>, specificHeaderCookieOrParamNameValue: list<record>, specificHeaderCookieParamXmlOrJsonNames: list<record>>, conditions: table<caseSensitive: bool, clientLists: list, extensions: list, filenames: list, header: string, hosts: list, ips: list, methods: list, name: string, nameCase: bool, paths: list, positiveMatch: bool, type: string, useHeaders: bool, value: string, valueCase: bool, valueWildcard: bool, wildcard: bool>, exception: record<anyHeaderCookieOrParam: list<string>, headerCookieOrParamValues: list<string>, specificHeaderCookieOrParamNameValue: record<name: string, selector: string, value: string>, specificHeaderCookieOrParamNames: record<names: list, selector: string>, specificHeaderCookieOrParamPrefix: record<prefix: string, selector: string>, specificHeaderCookieParamXmlOrJsonNames: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/attack-groups/($attackGroupId)/condition-exception" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the exceptions of an attack group
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/attack-groups/{attackGroupId}/condition-exception
# Docs: https://techdocs.akamai.com/application-security/reference/put-attack-group-condition-exception — See documentation for this operation in Akamai's Application Security API
# operationId: put-attack-group-condition-exception
# --advancedExceptions shape: {conditionOperator?: "OR"|"AND", conditions?: list, headerCookieOrParamValues?: list, specificHeaderCookieOrParamNameValue?: list, specificHeaderCookieParamXmlOrJsonNames?: list}
# --conditions item shape: {caseSensitive?: bool, clientLists?: list, extensions?: list, filenames?: list, header?: string, hosts?: list, ips?: list, methods?: list, name?: string, nameCase?: bool, paths?: list, positiveMatch: bool, type: "hostMatch"|"pathMatch"|"filenameMatch"|"extensionMatch"|"uriQueryMatch"|"ipMatch"|"requestMethodMatch"|"requestHeaderMatch"|"clientListMatch", useHeaders?: bool, value?: string, valueCase?: bool, valueWildcard?: bool, wildcard?: bool}
# --exception shape: {anyHeaderCookieOrParam?: list, headerCookieOrParamValues?: list, specificHeaderCookieOrParamNameValue?: record, specificHeaderCookieOrParamNames?: record, specificHeaderCookieOrParamPrefix?: record, specificHeaderCookieParamXmlOrJsonNames?: list}
export def "configs-versions-security-policies-attack-groups-condition-exception put-attack-group-condition-exception" [
  configId: int
  versionNumber: int
  policyId: string
  attackGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --advancedExceptions: record # Describes the advanced exception fields that allow you to conditionally exclude requests from inspection. This is only available for attack groups and when the advanced exception feature is enabled. — shape: {conditionOperator?: "OR"|"AND", conditions?: list, headerCookieOrParamValues?: list, specificHeaderCookieOrParamNameValue?: list, specificHeaderCookieParamXmlOrJsonNames?: list}
  --conditions: list # The conditions list for a rule. — item shape: {caseSensitive?: bool, clientLists?: list, extensions?: list, filenames?: list, header?: string, hosts?: list, ips?: list, methods?: list, name?: string, nameCase?: bool, paths?: list, positiveMatch: bool, type: "hostMatch"|"pathMatch"|"filenameMatch"|"extensionMatch"|"uriQueryMatch"|"ipMatch"|"requestMethodMatch"|"requestHeaderMatch"|"clientListMatch", useHeaders?: bool, value?: string, valueCase?: bool, valueWildcard?: bool, wildcard?: bool}
  --exception: record # Describes the exception fields that allow you to conditionally exclude requests from inspection. — shape: {anyHeaderCookieOrParam?: list, headerCookieOrParamValues?: list, specificHeaderCookieOrParamNameValue?: record, specificHeaderCookieOrParamNames?: record, specificHeaderCookieOrParamPrefix?: record, specificHeaderCookieParamXmlOrJsonNames?: list}
]: any -> record<advancedExceptions: record<conditionOperator: string, conditions: list<record>, headerCookieOrParamValues: list<record>, specificHeaderCookieOrParamNameValue: list<record>, specificHeaderCookieParamXmlOrJsonNames: list<record>>, conditions: table<caseSensitive: bool, clientLists: list, extensions: list, filenames: list, header: string, hosts: list, ips: list, methods: list, name: string, nameCase: bool, paths: list, positiveMatch: bool, type: string, useHeaders: bool, value: string, valueCase: bool, valueWildcard: bool, wildcard: bool>, exception: record<anyHeaderCookieOrParam: list<string>, headerCookieOrParamValues: list<string>, specificHeaderCookieOrParamNameValue: record<name: string, selector: string, value: string>, specificHeaderCookieOrParamNames: record<names: list, selector: string>, specificHeaderCookieOrParamPrefix: record<prefix: string, selector: string>, specificHeaderCookieParamXmlOrJsonNames: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/attack-groups/($attackGroupId)/condition-exception" $qp)
  let body = {advancedExceptions: $advancedExceptions, conditions: $conditions, exception: $exception} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Behavioral DDoS profile actions
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/behavioral-ddos
# Docs: https://techdocs.akamai.com/application-security/reference/get-behavioral-ddos-actions — See documentation for this operation in Akamai's Application Security API
# operationId: get-behavioral-ddos-actions
export def "configs-versions-security-policies-behavioral-ddos get-behavioral-ddos-actions" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<behavioralDdosActions: table<action: any, profileId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/behavioral-ddos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Behavioral DDoS profile action
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/behavioral-ddos/{profileId}
# Docs: https://techdocs.akamai.com/application-security/reference/put-behavioral-ddos-profile-action — See documentation for this operation in Akamai's Application Security API
# operationId: put-behavioral-ddos-profile-action
export def "configs-versions-security-policies-behavioral-ddos put-behavioral-ddos-profile-action" [
  configId: int
  versionNumber: int
  policyId: string
  profileId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  action: any # The action to assign to this Behavioral DDoS profile. Choose `alert`, `deny`, `none`, or `deny_custom_{custom_deny_id}`. Run [Modify a custom deny action](https://techdocs.akamai.com/application-security/reference/put-custom-deny) to manage your custom deny actions. If the action is `none`, the Behavioral DDoS profile is inactive in the policy.
]: any -> record<action: any, profileId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/behavioral-ddos/($profileId)" $qp)
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the bypass network lists settings for a security policy
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/bypass-network-lists
# Docs: https://techdocs.akamai.com/application-security/reference/get-bypass-network-lists-per-policy — See documentation for this operation in Akamai's Application Security API
# operationId: get-bypass-network-lists-per-policy
export def "configs-versions-security-policies-bypass-network-lists get-bypass-network-lists-per-policy" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<networkLists: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/bypass-network-lists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the bypass network lists settings for a security policy
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/bypass-network-lists
# Docs: https://techdocs.akamai.com/application-security/reference/put-bypass-network-lists-per-policy — See documentation for this operation in Akamai's Application Security API
# operationId: put-bypass-network-lists-per-policy
export def "configs-versions-security-policies-bypass-network-lists put-bypass-network-lists-per-policy" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  networkLists: list # Contains a list of network list IDs.
]: any -> record<networkLists: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/bypass-network-lists" $qp)
  let body = {networkLists: $networkLists} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Client-Side Protection & Compliance settings
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/cpc
# Docs: https://techdocs.akamai.com/application-security/reference/get-policy-cpc — See documentation for this operation in Akamai's Application Security API
# operationId: get-policy-cpc
export def "configs-versions-security-policies-cpc get-policy-cpc" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<edgeInjection: record<autoLoadStaging: bool, clientSideProtectionConfigId: int, loadScriptAsync: bool>, edgeTestParameters: record<disableInjectionKey: string, disableInjectionValue: string, forceInjectionKey: string, forceInjectionValue: string>, injectionCriteria: record<injectionPathExcludes: string, injectionPathIncludes: string, injectionPercent: int, injectionPolicy: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/cpc" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify Client-Side Protections & Compliance settings
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/cpc
# Docs: https://techdocs.akamai.com/application-security/reference/put-policy-cpc — See documentation for this operation in Akamai's Application Security API
# operationId: put-policy-cpc
# --edgeInjection shape: {autoLoadStaging: bool, clientSideProtectionConfigId: int, loadScriptAsync: bool}
# --edgeTestParameters shape: {disableInjectionKey?: string, disableInjectionValue?: string, forceInjectionKey?: string, forceInjectionValue?: string}
# --injectionCriteria shape: {injectionPathExcludes?: string, injectionPathIncludes?: string, injectionPercent: int, injectionPolicy: "late_head"|"early_head"|"mid_head"|"first_script"|"legacy"}
export def "configs-versions-security-policies-cpc put-policy-cpc" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  edgeInjection: record # Specifies the Client-Side Protection & Compliance (CPC) configuration you want to apply, and which pages get monitored by CPC's JavaScript injection to flag suspicious activity. See [Client-Side Protection & Compliance](https://techdocs.akamai.com/client-side-protect-compliance/docs/client-side-protect-compliance-ov) for more information. — shape: {autoLoadStaging: bool, clientSideProtectionConfigId: int, loadScriptAsync: bool}
  edgeTestParameters: record # Use these query string parameters to unit test an edge server's behavior. Entries here override the sampling percentage, ensuring or disabling JavaScript injection. — shape: {disableInjectionKey?: string, disableInjectionValue?: string, forceInjectionKey?: string, forceInjectionValue?: string}
  injectionCriteria: record # Specifies the criteria for agent injection. — shape: {injectionPathExcludes?: string, injectionPathIncludes?: string, injectionPercent: int, injectionPolicy: "late_head"|"early_head"|"mid_head"|"first_script"|"legacy"}
]: any -> record<edgeInjection: record<autoLoadStaging: bool, clientSideProtectionConfigId: int, loadScriptAsync: bool>, edgeTestParameters: record<disableInjectionKey: string, disableInjectionValue: string, forceInjectionKey: string, forceInjectionValue: string>, injectionCriteria: record<injectionPathExcludes: string, injectionPathIncludes: string, injectionPercent: int, injectionPolicy: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/cpc" $qp)
  let body = {edgeInjection: $edgeInjection, edgeTestParameters: $edgeTestParameters, injectionCriteria: $injectionCriteria} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List custom rule actions
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/custom-rules
# Docs: https://techdocs.akamai.com/application-security/reference/get-custom-rules — See documentation for this operation in Akamai's Application Security API
# operationId: get-custom-rules
export def "configs-versions-security-policies-custom-rules get-custom-rules" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<customRules: table<action: string, id: int, link: string, name: string, status: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/custom-rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a custom rule action
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/custom-rules/{ruleId}
# Docs: https://techdocs.akamai.com/application-security/reference/put-custom-rule — See documentation for this operation in Akamai's Application Security API
# operationId: put-custom-rule
export def "configs-versions-security-policies-custom-rules put-custom-rule" [
  configId: int
  versionNumber: int
  policyId: string
  ruleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  action: string@action-completer-4 # Specifies the action that the rule should trigger. Either `alert`, `deny`, deny_custom_{custom_deny_id}, or `none`.  If the action is `none`, it isn't associated with the policy.
]: any -> record<action: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/custom-rules/($ruleId)" $qp)
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set evaluation mode
#
# POST /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/eval
# Docs: https://techdocs.akamai.com/application-security/reference/post-policy-eval — See documentation for this operation in Akamai's Application Security API
# operationId: post-policy-eval
export def "configs-versions-security-policies-eval post-policy-eval" [
  policyId: string
  versionNumber: int
  configId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  eval: string@eval-completer # Set `eval` to `start`, `stop`, `restart`, `complete`, or `update` to manage the evaluation of new rules you want to test before you upgrade. If you set `eval` to `start`, `restart`, or `update`, the response object will have an `eval` value of `enabled`. The value is `disabled` for requests of `stop` or `complete`. For more information see [Set evaluation mode](https://techdocs.akamai.com/application-security/reference/post-policy-eval).
  --mode: string@mode-completer-1 # Optionally lets you specify between two Adaptive Security Engine (ASE) rule set types. Use `ASE_AUTO` for automatic updates to the ASE evaluation rules, or `ASE_MANUAL` to manually retrieve current evaluation rules. When not specified, the mode uses default settings. For a KRS 1.0 policy, that means using the KRS 1.0 rule set.
]: any -> record<current: string, eval: string, evaluating: string, expires: string, mode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/eval" $qp)
  let body = {eval: $eval, mode: $mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List evaluation attack groups
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/eval-groups
# Docs: https://techdocs.akamai.com/application-security/reference/get-policy-eval-groups — See documentation for this operation in Akamai's Application Security API
# operationId: get-policy-eval-groups
export def "configs-versions-security-policies-eval-groups get-policy-eval-groups" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<attackGroupActions: table<action: string, group: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/eval-groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the action for an evaluation attack group
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/eval-groups/{attackGroupId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-policy-eval-group — See documentation for this operation in Akamai's Application Security API
# operationId: get-policy-eval-group
export def "configs-versions-security-policies-eval-groups get-policy-eval-group" [
  configId: int
  versionNumber: int
  policyId: string
  attackGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<action: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/eval-groups/($attackGroupId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the action for an evaluation attack group
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/eval-groups/{attackGroupId}
# Docs: https://techdocs.akamai.com/application-security/reference/put-eval-group — See documentation for this operation in Akamai's Application Security API
# operationId: put-eval-group
export def "configs-versions-security-policies-eval-groups put-eval-group" [
  configId: int
  versionNumber: int
  policyId: string
  attackGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  action: string@action-completer-4 # The attack group action, either `alert`, `deny`, or `none`.
]: any -> record<action: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/eval-groups/($attackGroupId)" $qp)
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the exceptions of an evaluation attack group
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/eval-groups/{attackGroupId}/condition-exception
# Docs: https://techdocs.akamai.com/application-security/reference/get-eval-group-condition-exception — See documentation for this operation in Akamai's Application Security API
# operationId: get-eval-group-condition-exception
export def "configs-versions-security-policies-eval-groups-condition-exception get-eval-group-condition-exception" [
  configId: int
  versionNumber: int
  policyId: string
  attackGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<advancedExceptions: record<conditionOperator: string, conditions: list<record>, headerCookieOrParamValues: list<record>, specificHeaderCookieOrParamNameValue: list<record>, specificHeaderCookieParamXmlOrJsonNames: list<record>>, conditions: table<caseSensitive: bool, clientLists: list, extensions: list, filenames: list, header: string, hosts: list, ips: list, methods: list, name: string, nameCase: bool, paths: list, positiveMatch: bool, type: string, useHeaders: bool, value: string, valueCase: bool, valueWildcard: bool, wildcard: bool>, exception: record<anyHeaderCookieOrParam: list<string>, headerCookieOrParamValues: list<string>, specificHeaderCookieOrParamNameValue: record<name: string, selector: string, value: string>, specificHeaderCookieOrParamNames: record<names: list, selector: string>, specificHeaderCookieOrParamPrefix: record<prefix: string, selector: string>, specificHeaderCookieParamXmlOrJsonNames: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/eval-groups/($attackGroupId)/condition-exception" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the exceptions of an evaluation attack group
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/eval-groups/{attackGroupId}/condition-exception
# Docs: https://techdocs.akamai.com/application-security/reference/put-eval-group-condition-exception — See documentation for this operation in Akamai's Application Security API
# operationId: put-eval-group-condition-exception
# --advancedExceptions shape: {conditionOperator?: "OR"|"AND", conditions?: list, headerCookieOrParamValues?: list, specificHeaderCookieOrParamNameValue?: list, specificHeaderCookieParamXmlOrJsonNames?: list}
# --conditions item shape: {caseSensitive?: bool, clientLists?: list, extensions?: list, filenames?: list, header?: string, hosts?: list, ips?: list, methods?: list, name?: string, nameCase?: bool, paths?: list, positiveMatch: bool, type: "hostMatch"|"pathMatch"|"filenameMatch"|"extensionMatch"|"uriQueryMatch"|"ipMatch"|"requestMethodMatch"|"requestHeaderMatch"|"clientListMatch", useHeaders?: bool, value?: string, valueCase?: bool, valueWildcard?: bool, wildcard?: bool}
# --exception shape: {anyHeaderCookieOrParam?: list, headerCookieOrParamValues?: list, specificHeaderCookieOrParamNameValue?: record, specificHeaderCookieOrParamNames?: record, specificHeaderCookieOrParamPrefix?: record, specificHeaderCookieParamXmlOrJsonNames?: list}
export def "configs-versions-security-policies-eval-groups-condition-exception put-eval-group-condition-exception" [
  configId: int
  versionNumber: int
  policyId: string
  attackGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --advancedExceptions: record # Describes the advanced exception fields that allow you to conditionally exclude requests from inspection. This is only available for attack groups and when the advanced exception feature is enabled. — shape: {conditionOperator?: "OR"|"AND", conditions?: list, headerCookieOrParamValues?: list, specificHeaderCookieOrParamNameValue?: list, specificHeaderCookieParamXmlOrJsonNames?: list}
  --conditions: list # The conditions list for a rule. — item shape: {caseSensitive?: bool, clientLists?: list, extensions?: list, filenames?: list, header?: string, hosts?: list, ips?: list, methods?: list, name?: string, nameCase?: bool, paths?: list, positiveMatch: bool, type: "hostMatch"|"pathMatch"|"filenameMatch"|"extensionMatch"|"uriQueryMatch"|"ipMatch"|"requestMethodMatch"|"requestHeaderMatch"|"clientListMatch", useHeaders?: bool, value?: string, valueCase?: bool, valueWildcard?: bool, wildcard?: bool}
  --exception: record # Describes the exception fields that allow you to conditionally exclude requests from inspection. — shape: {anyHeaderCookieOrParam?: list, headerCookieOrParamValues?: list, specificHeaderCookieOrParamNameValue?: record, specificHeaderCookieOrParamNames?: record, specificHeaderCookieOrParamPrefix?: record, specificHeaderCookieParamXmlOrJsonNames?: list}
]: any -> record<advancedExceptions: record<conditionOperator: string, conditions: list<record>, headerCookieOrParamValues: list<record>, specificHeaderCookieOrParamNameValue: list<record>, specificHeaderCookieParamXmlOrJsonNames: list<record>>, conditions: table<caseSensitive: bool, clientLists: list, extensions: list, filenames: list, header: string, hosts: list, ips: list, methods: list, name: string, nameCase: bool, paths: list, positiveMatch: bool, type: string, useHeaders: bool, value: string, valueCase: bool, valueWildcard: bool, wildcard: bool>, exception: record<anyHeaderCookieOrParam: list<string>, headerCookieOrParamValues: list<string>, specificHeaderCookieOrParamNameValue: record<name: string, selector: string, value: string>, specificHeaderCookieOrParamNames: record<names: list, selector: string>, specificHeaderCookieOrParamPrefix: record<prefix: string, selector: string>, specificHeaderCookieParamXmlOrJsonNames: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/eval-groups/($attackGroupId)/condition-exception" $qp)
  let body = {advancedExceptions: $advancedExceptions, conditions: $conditions, exception: $exception} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List evaluation hostnames for a security policy
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/eval-hostnames
# Docs: https://techdocs.akamai.com/application-security/reference/get-eval-hostnames — See documentation for this operation in Akamai's Application Security API
# operationId: get-eval-hostnames
export def "configs-versions-security-policies-eval-hostnames get-eval-hostnames" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<hostnames: list<string>, mode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/eval-hostnames" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify evaluation hostnames for a security policy
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/eval-hostnames
# Docs: https://techdocs.akamai.com/application-security/reference/put-eval-hostnames — See documentation for this operation in Akamai's Application Security API
# operationId: put-eval-hostnames
export def "configs-versions-security-policies-eval-hostnames put-eval-hostnames" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  hostnames: list # Contains a list of hostnames.
  --mode: string@mode-completer # The type of update you want to make to the evaluation hostname list. You can `append` additional hostnames, `remove` hostnames from the list, or `replace` the existing list with the hostnames you pass in your request.
]: any -> record<hostnames: list<string>, mode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/eval-hostnames" $qp)
  let body = {hostnames: $hostnames, mode: $mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the penalty box for a policy in evaluation mode
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/eval-penalty-box
# Docs: https://techdocs.akamai.com/application-security/reference/get-eval-policy-penalty-box — See documentation for this operation in Akamai's Application Security API
# operationId: get-eval-policy-penalty-box
export def "configs-versions-security-policies-eval-penalty-box get-eval-policy-penalty-box" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<action: any, penaltyBoxProtection: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/eval-penalty-box" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the evaluation penalty box
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/eval-penalty-box
# Docs: https://techdocs.akamai.com/application-security/reference/put-eval-policy-penalty-box — See documentation for this operation in Akamai's Application Security API
# operationId: put-eval-policy-penalty-box
export def "configs-versions-security-policies-eval-penalty-box put-eval-policy-penalty-box" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  action: any
  --penaltyBoxProtection: oneof<nothing, bool> # Specifies whether penalty box protection is enabled for the security policy. When set to `true` the `action` occurs if triggered by a request.
]: any -> record<action: any, penaltyBoxProtection: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/eval-penalty-box" $qp)
  let body = {action: $action, penaltyBoxProtection: $penaltyBoxProtection} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get penalty box conditions in evaluation mode
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/eval-penalty-box/conditions
# Docs: https://techdocs.akamai.com/application-security/reference/get-eval-policy-penalty-box-conditions — See documentation for this operation in Akamai's Application Security API
# operationId: get-eval-policy-penalty-box-conditions
export def "configs-versions-security-policies-eval-penalty-box-conditions get-eval-policy-penalty-box-conditions" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<conditionOperator: string, conditions: table<caseSensitive: bool, clientLists: list, extensions: list, filenames: list, header: string, hosts: list, ips: list, methods: list, name: string, nameCase: bool, paths: list, positiveMatch: bool, type: string, useHeaders: bool, value: string, valueCase: bool, valueWildcard: bool, wildcard: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/eval-penalty-box/conditions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the penalty box conditions in evaluation mode
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/eval-penalty-box/conditions
# Docs: https://techdocs.akamai.com/application-security/reference/put-eval-policy-penalty-box-conditions — See documentation for this operation in Akamai's Application Security API
# operationId: put-eval-policy-penalty-box-conditions
# --conditions item shape: {caseSensitive?: bool, clientLists?: list, extensions?: list, filenames?: list, header?: string, hosts?: list, ips?: list, methods?: list, name?: string, nameCase?: bool, paths?: list, positiveMatch: bool, type: "hostMatch"|"pathMatch"|"filenameMatch"|"extensionMatch"|"uriQueryMatch"|"ipMatch"|"requestMethodMatch"|"requestHeaderMatch"|"clientListMatch", useHeaders?: bool, value?: string, valueCase?: bool, valueWildcard?: bool, wildcard?: bool}
export def "configs-versions-security-policies-eval-penalty-box-conditions put-eval-policy-penalty-box-conditions" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  conditionOperator: string@conditionOperator-completer # The logic to apply to a set of penalty box conditions: either `OR` to satisfy any condition, or `AND` to satisfy all conditions.
  conditions: list # The conditions list for the penalty box. — item shape: {caseSensitive?: bool, clientLists?: list, extensions?: list, filenames?: list, header?: string, hosts?: list, ips?: list, methods?: list, name?: string, nameCase?: bool, paths?: list, positiveMatch: bool, type: "hostMatch"|"pathMatch"|"filenameMatch"|"extensionMatch"|"uriQueryMatch"|"ipMatch"|"requestMethodMatch"|"requestHeaderMatch"|"clientListMatch", useHeaders?: bool, value?: string, valueCase?: bool, valueWildcard?: bool, wildcard?: bool}
]: any -> record<conditionOperator: string, conditions: table<caseSensitive: bool, clientLists: list, extensions: list, filenames: list, header: string, hosts: list, ips: list, methods: list, name: string, nameCase: bool, paths: list, positiveMatch: bool, type: string, useHeaders: bool, value: string, valueCase: bool, valueWildcard: bool, wildcard: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/eval-penalty-box/conditions" $qp)
  let body = {conditionOperator: $conditionOperator, conditions: $conditions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List evaluation rules
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/eval-rules
# Docs: https://techdocs.akamai.com/application-security/reference/get-policy-eval-rules — See documentation for this operation in Akamai's Application Security API
# operationId: get-policy-eval-rules
export def "configs-versions-security-policies-eval-rules get-policy-eval-rules" [
  policyId: string
  versionNumber: int
  configId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<evalRuleActions: table<action: string, id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/eval-rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the action of an evaluation rule
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/eval-rules/{ruleId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-policy-eval-rule — See documentation for this operation in Akamai's Application Security API
# operationId: get-policy-eval-rule
export def "configs-versions-security-policies-eval-rules get-policy-eval-rule" [
  ruleId: int
  policyId: string
  versionNumber: int
  configId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<action: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/eval-rules/($ruleId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the action of an evaluation rule
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/eval-rules/{ruleId}
# Docs: https://techdocs.akamai.com/application-security/reference/put-policy-eval-rule — See documentation for this operation in Akamai's Application Security API
# operationId: put-policy-eval-rule
export def "configs-versions-security-policies-eval-rules put-policy-eval-rule" [
  ruleId: int
  policyId: string
  versionNumber: int
  configId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  action: string@action-completer-4 # The rule's action, either `alert`, `deny`, or `none`. If the action is `none`, the rule is inactive in the policy.
]: any -> record<action: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/eval-rules/($ruleId)" $qp)
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the conditions and exceptions for an evaluation rule
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/eval-rules/{ruleId}/condition-exception
# Docs: https://techdocs.akamai.com/application-security/reference/get-condition-exception — See documentation for this operation in Akamai's Application Security API
# operationId: get-condition-exception
export def "configs-versions-security-policies-eval-rules-condition-exception get-condition-exception" [
  ruleId: int
  policyId: string
  versionNumber: int
  configId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<advancedExceptions: record<conditionOperator: string, conditions: list<record>, headerCookieOrParamValues: list<record>, specificHeaderCookieOrParamNameValue: list<record>, specificHeaderCookieParamXmlOrJsonNames: list<record>>, conditions: table<caseSensitive: bool, clientLists: list, extensions: list, filenames: list, header: string, hosts: list, ips: list, methods: list, name: string, nameCase: bool, paths: list, positiveMatch: bool, type: string, useHeaders: bool, value: string, valueCase: bool, valueWildcard: bool, wildcard: bool>, exception: record<anyHeaderCookieOrParam: list<string>, headerCookieOrParamValues: list<string>, specificHeaderCookieOrParamNameValue: record<name: string, selector: string, value: string>, specificHeaderCookieOrParamNames: record<names: list, selector: string>, specificHeaderCookieOrParamPrefix: record<prefix: string, selector: string>, specificHeaderCookieParamXmlOrJsonNames: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/eval-rules/($ruleId)/condition-exception" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the conditions and exceptions for an evaluation rule
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/eval-rules/{ruleId}/condition-exception
# Docs: https://techdocs.akamai.com/application-security/reference/put-condition-exception — See documentation for this operation in Akamai's Application Security API
# operationId: put-condition-exception
# --advancedExceptions shape: {conditionOperator?: "OR"|"AND", conditions?: list, headerCookieOrParamValues?: list, specificHeaderCookieOrParamNameValue?: list, specificHeaderCookieParamXmlOrJsonNames?: list}
# --conditions item shape: {caseSensitive?: bool, clientLists?: list, extensions?: list, filenames?: list, header?: string, hosts?: list, ips?: list, methods?: list, name?: string, nameCase?: bool, paths?: list, positiveMatch: bool, type: "hostMatch"|"pathMatch"|"filenameMatch"|"extensionMatch"|"uriQueryMatch"|"ipMatch"|"requestMethodMatch"|"requestHeaderMatch"|"clientListMatch", useHeaders?: bool, value?: string, valueCase?: bool, valueWildcard?: bool, wildcard?: bool}
# --exception shape: {anyHeaderCookieOrParam?: list, headerCookieOrParamValues?: list, specificHeaderCookieOrParamNameValue?: record, specificHeaderCookieOrParamNames?: record, specificHeaderCookieOrParamPrefix?: record, specificHeaderCookieParamXmlOrJsonNames?: list}
export def "configs-versions-security-policies-eval-rules-condition-exception put-condition-exception" [
  ruleId: int
  policyId: string
  versionNumber: int
  configId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --advancedExceptions: record # Describes the advanced exception fields that allow you to conditionally exclude requests from inspection. This is only available for attack groups and when the advanced exception feature is enabled. — shape: {conditionOperator?: "OR"|"AND", conditions?: list, headerCookieOrParamValues?: list, specificHeaderCookieOrParamNameValue?: list, specificHeaderCookieParamXmlOrJsonNames?: list}
  --conditions: list # The conditions list for a rule or attack group. — item shape: {caseSensitive?: bool, clientLists?: list, extensions?: list, filenames?: list, header?: string, hosts?: list, ips?: list, methods?: list, name?: string, nameCase?: bool, paths?: list, positiveMatch: bool, type: "hostMatch"|"pathMatch"|"filenameMatch"|"extensionMatch"|"uriQueryMatch"|"ipMatch"|"requestMethodMatch"|"requestHeaderMatch"|"clientListMatch", useHeaders?: bool, value?: string, valueCase?: bool, valueWildcard?: bool, wildcard?: bool}
  --exception: record # Describes the exception fields that allow you to conditionally exclude requests from inspection. — shape: {anyHeaderCookieOrParam?: list, headerCookieOrParamValues?: list, specificHeaderCookieOrParamNameValue?: record, specificHeaderCookieOrParamNames?: record, specificHeaderCookieOrParamPrefix?: record, specificHeaderCookieParamXmlOrJsonNames?: list}
]: any -> record<advancedExceptions: record<conditionOperator: string, conditions: list<record>, headerCookieOrParamValues: list<record>, specificHeaderCookieOrParamNameValue: list<record>, specificHeaderCookieParamXmlOrJsonNames: list<record>>, conditions: table<caseSensitive: bool, clientLists: list, extensions: list, filenames: list, header: string, hosts: list, ips: list, methods: list, name: string, nameCase: bool, paths: list, positiveMatch: bool, type: string, useHeaders: bool, value: string, valueCase: bool, valueWildcard: bool, wildcard: bool>, exception: record<anyHeaderCookieOrParam: list<string>, headerCookieOrParamValues: list<string>, specificHeaderCookieOrParamNameValue: record<name: string, selector: string, value: string>, specificHeaderCookieOrParamNames: record<names: list, selector: string>, specificHeaderCookieOrParamPrefix: record<prefix: string, selector: string>, specificHeaderCookieParamXmlOrJsonNames: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/eval-rules/($ruleId)/condition-exception" $qp)
  let body = {advancedExceptions: $advancedExceptions, conditions: $conditions, exception: $exception} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get IP/Geo Firewall settings
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/ip-geo-firewall
# Docs: https://techdocs.akamai.com/application-security/reference/get-policy-ip-geo-firewall — See documentation for this operation in Akamai's Application Security API
# operationId: get-policy-ip-geo-firewall
export def "configs-versions-security-policies-ip-geo-firewall get-policy-ip-geo-firewall" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<asnControls: record<allowedIPNetworkLists: record<action: string, networkList: list>, blockedIPNetworkLists: record<action: string, networkList: list>>, block: string, blockAllAction: string, geoControls: record<blockedIPNetworkLists: record<action: string, networkList: list>>, ipControls: record<allowedIPNetworkLists: record<action: string, networkList: list>, blockedIPNetworkLists: record<action: string, networkList: list>>, ukraineGeoControl: record<action: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/ip-geo-firewall" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify IP/Geo Firewall settings
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/ip-geo-firewall
# Docs: https://techdocs.akamai.com/application-security/reference/put-policy-ip-geo-firewall — See documentation for this operation in Akamai's Application Security API
# operationId: put-policy-ip-geo-firewall
# --asnControls shape: {allowedIPNetworkLists?: record, blockedIPNetworkLists?: record}
# --geoControls shape: {blockedIPNetworkLists?: record}
# --ipControls shape: {allowedIPNetworkLists?: record, blockedIPNetworkLists?: record}
# --ukraineGeoControl shape: {action?: string}
export def "configs-versions-security-policies-ip-geo-firewall put-policy-ip-geo-firewall" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --asnControls: record # The network lists you block or allow by AS number. — shape: {allowedIPNetworkLists?: record, blockedIPNetworkLists?: record}
  block: string@block-completer # Prevents or allows requests by IP and geographic location. Value is one of:   - `blockSpecificIPGeo`. Blocks traffic based on the values in your allowed, blocked, and Ukraine control network lists.   - `blockAllTrafficExceptAllowedIPs`. Blocks all traffic except the values in your allowed network lists.
  --blockAllAction: string # The type of deny action to take. Value is one of:   - `deny`. Default. Blocked traffic gets a `403` response.   - `deny_custom_{custom_deny_id}`. Blocked traffic gets a customized deny response.
  --geoControls: record # The network lists you block geographically. — shape: {blockedIPNetworkLists?: record}
  --ipControls: record # The network lists you block or allow by IP. — shape: {allowedIPNetworkLists?: record, blockedIPNetworkLists?: record}
  --ukraineGeoControl: record # The settings for requests to and from Ukraine. — shape: {action?: string}
]: any -> record<asnControls: record<allowedIPNetworkLists: record<action: string, networkList: list>, blockedIPNetworkLists: record<action: string, networkList: list>>, block: string, geoControls: record<blockedIPNetworkLists: record<action: string, networkList: list>>, ipControls: record<allowedIPNetworkLists: record<action: string, networkList: list>, blockedIPNetworkLists: record<action: string, networkList: list>>, ukraineGeoControl: record<action: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/ip-geo-firewall" $qp)
  let body = {asnControls: $asnControls, block: $block, blockAllAction: $blockAllAction, geoControls: $geoControls, ipControls: $ipControls, ukraineGeoControl: $ukraineGeoControl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List malware policy actions
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/malware-policies
# Docs: https://techdocs.akamai.com/application-security/reference/get-malware-policies-actions — See documentation for this operation in Akamai's Application Security API
# operationId: get-malware-policies-actions
export def "configs-versions-security-policies-malware-policies get-malware-policies-actions" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<malwarePolicyActions: table<action: string, id: int, unscannedAction: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/malware-policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a malware policy action
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/malware-policies/{malwarePolicyId}
# Docs: https://techdocs.akamai.com/application-security/reference/put-malware-policy-action — See documentation for this operation in Akamai's Application Security API
# operationId: put-malware-policy-action
export def "configs-versions-security-policies-malware-policies put-malware-policy-action" [
  configId: int
  versionNumber: int
  policyId: string
  malwarePolicyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  action: string@action-completer-4 # Specifies the action the malware policy triggers. Either `alert`, `deny`, or `none`. Use `deny_custom_{custom_deny_id}` to apply a custom action instead of Akamai's default. Run [Modify a custom deny action](https://techdocs.akamai.com/application-security/reference/put-custom-deny) to manage your custom deny actions.  If the action is `none`, it isn't associated with the policy.
  unscannedAction: string@unscannedAction-completer # Specifies the action to take when the file is outside the 5 MB scan limit. Either `alert`, `deny`, or `none`. Use `deny_custom_{custom_deny_id}` to apply a custom action instead of Akamai's default. Run [Modify a custom deny action](https://techdocs.akamai.com/application-security/reference/put-custom-deny) to manage your custom deny actions.  When the `action` is `none`, it behaves as if you aren't using malware protections.
]: any -> record<action: string, unscannedAction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/malware-policies/($malwarePolicyId)" $qp)
  let body = {action: $action, unscannedAction: $unscannedAction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the current mode
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/mode
# Docs: https://techdocs.akamai.com/application-security/reference/get-policy-mode — See documentation for this operation in Akamai's Application Security API
# operationId: get-policy-mode
export def "configs-versions-security-policies-mode get-policy-mode" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<current: string, eval: string, evaluating: string, expires: string, mode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/mode" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the mode
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/mode
# Docs: https://techdocs.akamai.com/application-security/reference/put-policy-mode — See documentation for this operation in Akamai's Application Security API
# operationId: put-policy-mode
export def "configs-versions-security-policies-mode put-policy-mode" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  mode: string@mode-completer-2 # The security policy rule update mode. Use `KRS` to update rules manually, or `AAG` to update rules automatically. For Adaptive Security Engine (ASE), use `ASE_AUTO` for automatic updates or `ASE_MANUAL` to manually get current rules. When switching from one mode to another, any rule actions you have migrate to the new mode. For example, your rule actions for `ASE_AUTO` become the rule actions for `ASE_MANUAL` when you switch from auto to manual modes, and vice versa. Rule actions for `ASE_AUTO` are currently in beta. Contact your account team to access this option.
]: any -> record<current: string, mode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/mode" $qp)
  let body = {mode: $mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the penalty box
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/penalty-box
# Docs: https://techdocs.akamai.com/application-security/reference/get-policy-penalty-box — See documentation for this operation in Akamai's Application Security API
# operationId: get-policy-penalty-box
export def "configs-versions-security-policies-penalty-box get-policy-penalty-box" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<action: any, penaltyBoxProtection: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/penalty-box" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the penalty box
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/penalty-box
# Docs: https://techdocs.akamai.com/application-security/reference/put-policy-penalty-box — See documentation for this operation in Akamai's Application Security API
# operationId: put-policy-penalty-box
export def "configs-versions-security-policies-penalty-box put-policy-penalty-box" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  action: any
  --penaltyBoxProtection: oneof<nothing, bool> # Specifies whether penalty box protection is enabled for the security policy. When set to `true` the `action` occurs if triggered by a request.
]: any -> record<action: any, penaltyBoxProtection: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/penalty-box" $qp)
  let body = {action: $action, penaltyBoxProtection: $penaltyBoxProtection} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get penalty box condition
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/penalty-box/conditions
# Docs: https://techdocs.akamai.com/application-security/reference/get-policy-penalty-box-conditions — See documentation for this operation in Akamai's Application Security API
# operationId: get-policy-penalty-box-conditions
export def "configs-versions-security-policies-penalty-box-conditions get-policy-penalty-box-conditions" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<conditionOperator: string, conditions: table<caseSensitive: bool, clientLists: list, extensions: list, filenames: list, header: string, hosts: list, ips: list, methods: list, name: string, nameCase: bool, paths: list, positiveMatch: bool, type: string, useHeaders: bool, value: string, valueCase: bool, valueWildcard: bool, wildcard: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/penalty-box/conditions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the penalty box conditions
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/penalty-box/conditions
# Docs: https://techdocs.akamai.com/application-security/reference/put-policy-penalty-box-conditions — See documentation for this operation in Akamai's Application Security API
# operationId: put-policy-penalty-box-conditions
# --conditions item shape: {caseSensitive?: bool, clientLists?: list, extensions?: list, filenames?: list, header?: string, hosts?: list, ips?: list, methods?: list, name?: string, nameCase?: bool, paths?: list, positiveMatch: bool, type: "hostMatch"|"pathMatch"|"filenameMatch"|"extensionMatch"|"uriQueryMatch"|"ipMatch"|"requestMethodMatch"|"requestHeaderMatch"|"clientListMatch", useHeaders?: bool, value?: string, valueCase?: bool, valueWildcard?: bool, wildcard?: bool}
export def "configs-versions-security-policies-penalty-box-conditions put-policy-penalty-box-conditions" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  conditionOperator: string@conditionOperator-completer # The logic to apply to a set of penalty box conditions: either `OR` to satisfy any condition, or `AND` to satisfy all conditions.
  conditions: list # The conditions list for the penalty box. — item shape: {caseSensitive?: bool, clientLists?: list, extensions?: list, filenames?: list, header?: string, hosts?: list, ips?: list, methods?: list, name?: string, nameCase?: bool, paths?: list, positiveMatch: bool, type: "hostMatch"|"pathMatch"|"filenameMatch"|"extensionMatch"|"uriQueryMatch"|"ipMatch"|"requestMethodMatch"|"requestHeaderMatch"|"clientListMatch", useHeaders?: bool, value?: string, valueCase?: bool, valueWildcard?: bool, wildcard?: bool}
]: any -> record<conditionOperator: string, conditions: table<caseSensitive: bool, clientLists: list, extensions: list, filenames: list, header: string, hosts: list, ips: list, methods: list, name: string, nameCase: bool, paths: list, positiveMatch: bool, type: string, useHeaders: bool, value: string, valueCase: bool, valueWildcard: bool, wildcard: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/penalty-box/conditions" $qp)
  let body = {conditionOperator: $conditionOperator, conditions: $conditions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Protect evaluation hostnames for a security policy
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/protect-eval-hostnames
# Docs: https://techdocs.akamai.com/application-security/reference/put-protect-eval-hostnames-per-policy — See documentation for this operation in Akamai's Application Security API
# operationId: put-protect-eval-hostnames-per-policy
export def "configs-versions-security-policies-protect-eval-hostnames put-protect-eval-hostnames-per-policy" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  hostnames: list # Contains a list of hostnames.
  --mode: string@mode-completer # The type of update you want to make to the evaluation hostname list. You can `append` additional hostnames, `remove` hostnames from the list, or `replace` the existing list with the hostnames you pass in your request.
]: any -> record<hostnames: list<string>, mode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/protect-eval-hostnames" $qp)
  let body = {hostnames: $hostnames, mode: $mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get protections
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/protections
# Docs: https://techdocs.akamai.com/application-security/reference/get-policy-protections — See documentation for this operation in Akamai's Application Security API
# operationId: get-policy-protections
export def "configs-versions-security-policies-protections get-policy-protections" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<applyApiConstraints: bool, applyApplicationLayerControls: bool, applyCpcControls: bool, applyMalwareControls: bool, applyNetworkLayerControls: bool, applyRateControls: bool, applyReputationControls: bool, applySlowPostControls: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/protections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify protections
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/protections
# Docs: https://techdocs.akamai.com/application-security/reference/put-policy-protections — See documentation for this operation in Akamai's Application Security API
# operationId: put-policy-protections
export def "configs-versions-security-policies-protections put-policy-protections" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --applyApiConstraints: oneof<nothing, bool> # When enabled, this protection responds to triggers with a specified action.
  --applyApplicationLayerControls: oneof<nothing, bool> # When enabled, your security policy applies the Web Application Firewall controls to your traffic.
  --applyCpcControls: oneof<nothing, bool> # When enabled, your security policy applies Client-Side Protection & Compliance controls to your match target. (default: false)
  --applyMalwareControls: oneof<nothing, bool> # When enabled, your security policy applies file malware scanning controls to your traffic.
  --applyNetworkLayerControls: oneof<nothing, bool> # When enabled, your security policy applies the network layer control settings to your traffic.
  --applyRateControls: oneof<nothing, bool> # When enabled, your security policy applies the rate control settings to your traffic. Rate controls monitor and flag traffic too fast to be from a human.
  --applyReputationControls: oneof<nothing, bool> # When enabled, your security policy applies the reputation profile settings to your traffic. Reputation profile analyses IP addresses based on their prior interactions with Akamai customers, then alerts on or blocks potentially malicious IP addresses from issuing requests.
  --applySlowPostControls: oneof<nothing, bool> # When enabled, your security policy applies slow POST controls to your traffic.
]: any -> record<applyApiConstraints: bool, applyApplicationLayerControls: bool, applyCpcControls: bool, applyMalwareControls: bool, applyNetworkLayerControls: bool, applyRateControls: bool, applyReputationControls: bool, applySlowPostControls: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/protections" $qp)
  let body = {applyApiConstraints: $applyApiConstraints, applyApplicationLayerControls: $applyApplicationLayerControls, applyCpcControls: $applyCpcControls, applyMalwareControls: $applyMalwareControls, applyNetworkLayerControls: $applyNetworkLayerControls, applyRateControls: $applyRateControls, applyReputationControls: $applyReputationControls, applySlowPostControls: $applySlowPostControls} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List rapid rules
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/rapid-rules
# Docs: https://techdocs.akamai.com/application-security/reference/get-policy-rapid-rules — See documentation for this operation in Akamai's Application Security API
# operationId: get-policy-rapid-rules
export def "configs-versions-security-policies-rapid-rules get-policy-rapid-rules" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<policyRules: table<action: record, conditionException: record, id: int, lock: bool, riskScoreGroups: list, title: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/rapid-rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get rapid rules' default action
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/rapid-rules/action
# Docs: https://techdocs.akamai.com/application-security/reference/get-policy-rapid-rules-action — See documentation for this operation in Akamai's Application Security API
# operationId: get-policy-rapid-rules-action
export def "configs-versions-security-policies-rapid-rules-action get-policy-rapid-rules-action" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<action: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/rapid-rules/action" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update rapid rules' default action
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/rapid-rules/action
# Docs: https://techdocs.akamai.com/application-security/reference/put-policy-rapid-rules-action — See documentation for this operation in Akamai's Application Security API
# operationId: put-policy-rapid-rules-action
export def "configs-versions-security-policies-rapid-rules-action put-policy-rapid-rules-action" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  action: record # The list of rapid rule actions, either `alert`, `deny`, or `none`. Use `deny_custom_{custom_deny_id}` to apply a custom action instead of Akamai's default. Run [Modify a custom deny action](https://techdocs.akamai.com/application-security/reference/put-custom-deny) to manage your custom deny actions. If the action is `none`, the rule is inactive in the policy.
]: any -> record<action: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/rapid-rules/action" $qp)
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get rapid rules' status
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/rapid-rules/status
# Docs: https://techdocs.akamai.com/application-security/reference/get-policy-rapid-rules-status — See documentation for this operation in Akamai's Application Security API
# operationId: get-policy-rapid-rules-status
export def "configs-versions-security-policies-rapid-rules-status get-policy-rapid-rules-status" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/rapid-rules/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update rapid rules' status
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/rapid-rules/status
# Docs: https://techdocs.akamai.com/application-security/reference/put-policy-rapid-rules-status — See documentation for this operation in Akamai's Application Security API
# operationId: put-policy-rapid-rules-status
export def "configs-versions-security-policies-rapid-rules-status put-policy-rapid-rules-status" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --enabled: oneof<nothing, bool> # Whether the rapid rule is active.
]: any -> record<enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/rapid-rules/status" $qp)
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List a rapid rule's conditions and exceptions
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/rapid-rules/{ruleId}/condition-exception
# Docs: https://techdocs.akamai.com/application-security/reference/get-policy-rapid-rule-condition-exception — See documentation for this operation in Akamai's Application Security API
# operationId: get-policy-rapid-rule-condition-exception
export def "configs-versions-security-policies-rapid-rules-condition-exception get-policy-rapid-rule-condition-exception" [
  configId: int
  versionNumber: int
  policyId: string
  ruleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<advancedExceptions: record<conditionOperator: string, conditions: list<record>, headerCookieOrParamValues: list<record>, specificHeaderCookieOrParamNameValue: list<record>, specificHeaderCookieParamXmlOrJsonNames: list<record>>, conditions: table<caseSensitive: bool, clientLists: list, extensions: list, filenames: list, header: string, hosts: list, ips: list, methods: list, name: string, nameCase: bool, paths: list, positiveMatch: bool, type: string, useHeaders: bool, value: string, valueCase: bool, valueWildcard: bool, wildcard: bool>, exception: record<anyHeaderCookieOrParam: list<string>, headerCookieOrParamValues: list<string>, specificHeaderCookieOrParamNameValue: record<name: string, selector: string, value: string>, specificHeaderCookieOrParamNames: record<names: list, selector: string>, specificHeaderCookieOrParamPrefix: record<prefix: string, selector: string>, specificHeaderCookieParamXmlOrJsonNames: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/rapid-rules/($ruleId)/condition-exception" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a rapid rule's conditions and exceptions
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/rapid-rules/{ruleId}/condition-exception
# Docs: https://techdocs.akamai.com/application-security/reference/put-policy-rapid-rule-condition-exception — See documentation for this operation in Akamai's Application Security API
# operationId: put-policy-rapid-rule-condition-exception
# --advancedExceptions shape: {conditionOperator?: "OR"|"AND", conditions?: list, headerCookieOrParamValues?: list, specificHeaderCookieOrParamNameValue?: list, specificHeaderCookieParamXmlOrJsonNames?: list}
# --conditions item shape: {caseSensitive?: bool, clientLists?: list, extensions?: list, filenames?: list, header?: string, hosts?: list, ips?: list, methods?: list, name?: string, nameCase?: bool, paths?: list, positiveMatch: bool, type: "hostMatch"|"pathMatch"|"filenameMatch"|"extensionMatch"|"uriQueryMatch"|"ipMatch"|"requestMethodMatch"|"requestHeaderMatch"|"clientListMatch", useHeaders?: bool, value?: string, valueCase?: bool, valueWildcard?: bool, wildcard?: bool}
# --exception shape: {anyHeaderCookieOrParam?: list, headerCookieOrParamValues?: list, specificHeaderCookieOrParamNameValue?: record, specificHeaderCookieOrParamNames?: record, specificHeaderCookieOrParamPrefix?: record, specificHeaderCookieParamXmlOrJsonNames?: list}
export def "configs-versions-security-policies-rapid-rules-condition-exception put-policy-rapid-rule-condition-exception" [
  configId: int
  versionNumber: int
  policyId: string
  ruleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --advancedExceptions: record # Describes the advanced exception fields that allow you to conditionally exclude requests from inspection. This is only available for attack groups and when the advanced exception feature is enabled. — shape: {conditionOperator?: "OR"|"AND", conditions?: list, headerCookieOrParamValues?: list, specificHeaderCookieOrParamNameValue?: list, specificHeaderCookieParamXmlOrJsonNames?: list}
  --conditions: list # The conditions list for a rule. — item shape: {caseSensitive?: bool, clientLists?: list, extensions?: list, filenames?: list, header?: string, hosts?: list, ips?: list, methods?: list, name?: string, nameCase?: bool, paths?: list, positiveMatch: bool, type: "hostMatch"|"pathMatch"|"filenameMatch"|"extensionMatch"|"uriQueryMatch"|"ipMatch"|"requestMethodMatch"|"requestHeaderMatch"|"clientListMatch", useHeaders?: bool, value?: string, valueCase?: bool, valueWildcard?: bool, wildcard?: bool}
  --exception: record # Describes the exception fields that allow you to conditionally exclude requests from inspection. — shape: {anyHeaderCookieOrParam?: list, headerCookieOrParamValues?: list, specificHeaderCookieOrParamNameValue?: record, specificHeaderCookieOrParamNames?: record, specificHeaderCookieOrParamPrefix?: record, specificHeaderCookieParamXmlOrJsonNames?: list}
]: any -> record<advancedExceptions: record<conditionOperator: string, conditions: list<record>, headerCookieOrParamValues: list<record>, specificHeaderCookieOrParamNameValue: list<record>, specificHeaderCookieParamXmlOrJsonNames: list<record>>, conditions: table<caseSensitive: bool, clientLists: list, extensions: list, filenames: list, header: string, hosts: list, ips: list, methods: list, name: string, nameCase: bool, paths: list, positiveMatch: bool, type: string, useHeaders: bool, value: string, valueCase: bool, valueWildcard: bool, wildcard: bool>, exception: record<anyHeaderCookieOrParam: list<string>, headerCookieOrParamValues: list<string>, specificHeaderCookieOrParamNameValue: record<name: string, selector: string, value: string>, specificHeaderCookieOrParamNames: record<names: list, selector: string>, specificHeaderCookieOrParamPrefix: record<prefix: string, selector: string>, specificHeaderCookieParamXmlOrJsonNames: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/rapid-rules/($ruleId)/condition-exception" $qp)
  let body = {advancedExceptions: $advancedExceptions, conditions: $conditions, exception: $exception} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a rapid rule's lock status
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/rapid-rules/{ruleId}/lock
# Docs: https://techdocs.akamai.com/application-security/reference/get-policy-rapid-rule-lock — See documentation for this operation in Akamai's Application Security API
# operationId: get-policy-rapid-rule-lock
export def "configs-versions-security-policies-rapid-rules-lock get-policy-rapid-rule-lock" [
  configId: int
  versionNumber: int
  policyId: string
  ruleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/rapid-rules/($ruleId)/lock" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a rapid rule's lock status
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/rapid-rules/{ruleId}/lock
# Docs: https://techdocs.akamai.com/application-security/reference/put-policy-rapid-rule-lock — See documentation for this operation in Akamai's Application Security API
# operationId: put-policy-rapid-rule-lock
export def "configs-versions-security-policies-rapid-rules-lock put-policy-rapid-rule-lock" [
  configId: int
  versionNumber: int
  policyId: string
  ruleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --enabled: oneof<nothing, bool> # Whether you've locked the rapid rule's action. When locked, future versions of this rule continue to use the action you originally selected.
]: any -> record<enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/rapid-rules/($ruleId)/lock" $qp)
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a rapid rule's action
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/rapid-rules/{ruleId}/versions/{ruleVersion}/action
# Docs: https://techdocs.akamai.com/application-security/reference/get-policy-rapid-rule-action — See documentation for this operation in Akamai's Application Security API
# operationId: get-policy-rapid-rule-action
export def "configs-versions-security-policies-rapid-rules-versions-action get-policy-rapid-rule-action" [
  configId: int
  versionNumber: int
  policyId: string
  ruleId: int
  ruleVersion: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<action: record, lock: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/rapid-rules/($ruleId)/versions/($ruleVersion)/action" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a rapid rule's action
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/rapid-rules/{ruleId}/versions/{ruleVersion}/action
# Docs: https://techdocs.akamai.com/application-security/reference/put-policy-rapid-rule-action — See documentation for this operation in Akamai's Application Security API
# operationId: put-policy-rapid-rule-action
export def "configs-versions-security-policies-rapid-rules-versions-action put-policy-rapid-rule-action" [
  configId: int
  versionNumber: int
  policyId: string
  ruleId: int
  ruleVersion: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  action: record # The list of rapid rule actions, either `alert`, `deny`, or `none`. Use `deny_custom_{custom_deny_id}` to apply a custom action instead of Akamai's default. Run [Modify a custom deny action](https://techdocs.akamai.com/application-security/reference/put-custom-deny) to manage your custom deny actions. If the action is `none`, the rule is inactive in the policy.
]: any -> record<action: record, lock: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/rapid-rules/($ruleId)/versions/($ruleVersion)/action" $qp)
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List rate policy actions
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/rate-policies
# Docs: https://techdocs.akamai.com/application-security/reference/get-rate-policies-actions — See documentation for this operation in Akamai's Application Security API
# operationId: get-rate-policies-actions
export def "configs-versions-security-policies-rate-policies get-rate-policies-actions" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<ratePolicyActions: table<id: int, ipv4Action: string, ipv6Action: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/rate-policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a rate policy action
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/rate-policies/{ratePolicyId}
# Docs: https://techdocs.akamai.com/application-security/reference/put-rate-policy-action — See documentation for this operation in Akamai's Application Security API
# operationId: put-rate-policy-action
export def "configs-versions-security-policies-rate-policies put-rate-policy-action" [
  configId: int
  versionNumber: int
  policyId: string
  ratePolicyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  ipv4Action: string # The IPv4 action to assign to this rate policy. For `BOTMAN` policies, choose `monitor`, `delay`, `slow`, `deny`,` tarpit`, `none`, or a custom action. For `WAF` policies, choose `alert`, `deny`, `challenge_{id}`, or `none`. Or use `deny_custom_{custom_deny_id}` to apply a custom action to your WAF rate policy. Run [Modify a custom deny action](https://techdocs.akamai.com/application-security/reference/put-custom-deny) to manage your custom deny actions. If the action is `none`, the rate policy is inactive in the policy. Refer to [Challenge actions](https://techdocs.akamai.com/application-security/reference/post-challenge-action) for `POST`, `GET`, `PUT`, and `DELETE` operation details.
  ipv6Action: string # The IPv6 action to assign to this rate policy. For `BOTMAN` policies, specify the same action you chose for `ipv4Action`. For `WAF` policies, choose `alert`, `deny`, `challenge_{id}`, or `none`. Or use `deny_custom_{custom_deny_id}` to apply a custom action to your WAF rate policy. Run [Modify a custom deny action](https://techdocs.akamai.com/application-security/reference/put-custom-deny) to manage your custom deny actions. If the action is `none`, the rate policy is inactive in the policy. Refer to [Challenge actions](https://techdocs.akamai.com/application-security/reference/post-challenge-action) for `POST`, `GET`, `PUT`, and `DELETE` operation details. 
]: any -> record<ipv4Action: string, ipv6Action: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/rate-policies/($ratePolicyId)" $qp)
  let body = {ipv4Action: $ipv4Action, ipv6Action: $ipv6Action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Respond to exception recommendations
#
# POST /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/recommendations
# Docs: https://techdocs.akamai.com/application-security/reference/post-recommendations — See documentation for this operation in Akamai's Application Security API
# operationId: post-recommendations
export def "configs-versions-security-policies-recommendations post-recommendations" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-3 # __Enum__ If `ACTIVE`, includes only active recommendations, the default. If `EVALUATION`, includes only evaluation recommendations. If `ALL`, includes both active and evaluation recommendations. (default: ACTIVE, e.g. ACTIVE)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  action: string@action-completer-5 # How you want to respond to the exception recommendation. Use `ACCEPT` to add the recommendation to your policy, rule, or attack group. Use `DECLINE` to reject the recommendation, or `RESET` to undo a previous `DECLINE` action.
  selectorId: int # The unique identifier for the selector referenced in the recommendation.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/recommendations" $qp)
  let body = {action: $action, selectorId: $selectorId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get tuning recommendations for a policy
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/recommendations
# Docs: https://techdocs.akamai.com/application-security/reference/get-recommendations — See documentation for this operation in Akamai's Application Security API
# operationId: get-recommendations
export def "configs-versions-security-policies-recommendations get-recommendations" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-3 # __Enum__ If `ACTIVE`, includes only active recommendations, the default. If `EVALUATION`, includes only evaluation recommendations. If `ALL`, includes both active and evaluation recommendations. (default: ACTIVE, e.g. ACTIVE)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<attackGroupRecommendations: table<declinedRecommendations: list, group: string, recommendations: list>, evaluationPeriodEnd: string, evaluationPeriodStart: string, ruleRecommendations: table<declinedRecommendations: list, id: int, recommendations: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/recommendations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List tuning recommendations for an attack group
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/recommendations/attack-groups/{attackGroupId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-attack-group — See documentation for this operation in Akamai's Application Security API
# operationId: get-attack-group
export def "configs-versions-security-policies-recommendations-attack-groups get-attack-group" [
  configId: int
  versionNumber: int
  policyId: string
  attackGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-3 # __Enum__ If `ACTIVE`, includes only active recommendations, the default. If `EVALUATION`, includes only evaluation recommendations. If `ALL`, includes both active and evaluation recommendations. (default: ACTIVE, e.g. ACTIVE)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<declinedRecommendations: table<description: string, evidences: string, exceptions: list, ruleSetType: string>, group: string, recommendations: table<description: string, evidences: string, exceptions: list, ruleSetType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/recommendations/attack-groups/($attackGroupId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List tuning recommendations for a rule
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/recommendations/rules/{ruleId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-recommendations-rule — See documentation for this operation in Akamai's Application Security API
# operationId: get-recommendations-rule
export def "configs-versions-security-policies-recommendations-rules get-recommendations-rule" [
  configId: int
  versionNumber: int
  policyId: string
  ruleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-3 # __Enum__ If `ACTIVE`, includes only active recommendations, the default. If `EVALUATION`, includes only evaluation recommendations. If `ALL`, includes both active and evaluation recommendations. (default: ACTIVE, e.g. ACTIVE)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<declinedRecommendations: table<description: string, evidences: string, exceptions: list, ruleSetType: string>, id: int, recommendations: table<description: string, evidences: string, exceptions: list, ruleSetType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/recommendations/rules/($ruleId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get reputation analysis settings
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/reputation-analysis
# Docs: https://techdocs.akamai.com/application-security/reference/get-reputation-analysis — See documentation for this operation in Akamai's Application Security API
# operationId: get-reputation-analysis
export def "configs-versions-security-policies-reputation-analysis get-reputation-analysis" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<forwardSharedIPToHTTPHeaderAndSIEM: bool, forwardToHTTPHeader: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/reputation-analysis" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify reputation analysis settings
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/reputation-analysis
# Docs: https://techdocs.akamai.com/application-security/reference/put-reputation-analysis — See documentation for this operation in Akamai's Application Security API
# operationId: put-reputation-analysis
export def "configs-versions-security-policies-reputation-analysis put-reputation-analysis" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --forwardSharedIPToHTTPHeaderAndSIEM: oneof<nothing, bool> # Whether to enable the option to add value indicating that shared IPs are included in HTTP header and SIEM integration when used.
  --forwardToHTTPHeader: oneof<nothing, bool> # Whether to enable the option to add client reputation details to requests forwarded to origin in an HTTP header.
]: any -> record<forwardSharedIPToHTTPHeaderAndSIEM: bool, forwardToHTTPHeader: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/reputation-analysis" $qp)
  let body = {forwardSharedIPToHTTPHeaderAndSIEM: $forwardSharedIPToHTTPHeaderAndSIEM, forwardToHTTPHeader: $forwardToHTTPHeader} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List reputation profile actions
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/reputation-profiles
# Docs: https://techdocs.akamai.com/application-security/reference/get-reputation-profiles-actions — See documentation for this operation in Akamai's Application Security API
# operationId: get-reputation-profiles-actions
export def "configs-versions-security-policies-reputation-profiles get-reputation-profiles-actions" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<reputationProfiles: table<action: string, id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/reputation-profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the action for a reputation profile
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/reputation-profiles/{reputationProfileId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-reputation-profile-action — See documentation for this operation in Akamai's Application Security API
# operationId: get-reputation-profile-action
export def "configs-versions-security-policies-reputation-profiles get-reputation-profile-action" [
  configId: int
  versionNumber: int
  policyId: string
  reputationProfileId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<action: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/reputation-profiles/($reputationProfileId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the action for a reputation profile
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/reputation-profiles/{reputationProfileId}
# Docs: https://techdocs.akamai.com/application-security/reference/put-reputation-profile-action — See documentation for this operation in Akamai's Application Security API
# operationId: put-reputation-profile-action
export def "configs-versions-security-policies-reputation-profiles put-reputation-profile-action" [
  configId: int
  versionNumber: int
  policyId: string
  reputationProfileId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  action: string@action-completer-4 # The action of a reputation profile. Use `alert` to record the trigger of the event, `deny` to block the request, or `none` to take no action. Use `deny_custom_{custom_deny_id}` to apply a custom action instead of Akamai's default. Run [Modify a custom deny action](https://techdocs.akamai.com/application-security/reference/put-custom-deny) to manage your custom deny actions.
]: any -> record<action: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/reputation-profiles/($reputationProfileId)" $qp)
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List rules
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/rules
# Docs: https://techdocs.akamai.com/application-security/reference/get-policy-rules — See documentation for this operation in Akamai's Application Security API
# operationId: get-policy-rules
export def "configs-versions-security-policies-rules get-policy-rules" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<ruleActions: table<action: string, id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upgrade KRS ruleset
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/rules
# Docs: https://techdocs.akamai.com/application-security/reference/put-policy-rules — See documentation for this operation in Akamai's Application Security API
# operationId: put-policy-rules
export def "configs-versions-security-policies-rules put-policy-rules" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --upgrade: oneof<nothing, bool> # Whether the upgrade is enabled.
]: any -> record<current: string, eval: string, evaluating: string, expires: string, mode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/rules" $qp)
  let body = {upgrade: $upgrade} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get upgrade details
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/rules/upgrade-details
# Docs: https://techdocs.akamai.com/application-security/reference/get-rules-upgrade-details — See documentation for this operation in Akamai's Application Security API
# operationId: get-rules-upgrade-details
export def "configs-versions-security-policies-rules-upgrade-details get-rules-upgrade-details" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<current: string, evalToEvalUpdates: record<deletedAttackGroups: list<record>, deletedRules: list<record>, newAttackGroups: list<record>, newRules: list<record>, updatedAttackGroups: list<record>, updatedRules: list<record>>, evaluating: string, krsToEvalUpdates: record<deletedAttackGroups: list<record>, deletedRules: list<record>, newAttackGroups: list<record>, newRules: list<record>, updatedAttackGroups: list<record>, updatedRules: list<record>>, krsToLatestUpdates: record<deletedAttackGroups: list<record>, deletedRules: list<record>, newAttackGroups: list<record>, newRules: list<record>, updatedAttackGroups: list<record>, updatedRules: list<record>>, latest: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/rules/upgrade-details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the action for a rule
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/rules/{ruleId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-rule — See documentation for this operation in Akamai's Application Security API
# operationId: get-rule
export def "configs-versions-security-policies-rules get-rule" [
  configId: int
  versionNumber: int
  policyId: string
  ruleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<action: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/rules/($ruleId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the action for a rule
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/rules/{ruleId}
# Docs: https://techdocs.akamai.com/application-security/reference/put-rule — See documentation for this operation in Akamai's Application Security API
# operationId: put-rule
export def "configs-versions-security-policies-rules put-rule" [
  configId: int
  versionNumber: int
  policyId: string
  ruleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  action: string@action-completer-4 # The action of the rule, either `alert`, `deny`, or `none`.
]: any -> record<action: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/rules/($ruleId)" $qp)
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the conditions and exceptions of a rule
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/rules/{ruleId}/condition-exception
# Docs: https://techdocs.akamai.com/application-security/reference/get-rule-condition-exception — See documentation for this operation in Akamai's Application Security API
# operationId: get-rule-condition-exception
export def "configs-versions-security-policies-rules-condition-exception get-rule-condition-exception" [
  configId: int
  versionNumber: int
  policyId: string
  ruleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<advancedExceptions: record<conditionOperator: string, conditions: list<record>, headerCookieOrParamValues: list<record>, specificHeaderCookieOrParamNameValue: list<record>, specificHeaderCookieParamXmlOrJsonNames: list<record>>, conditions: table<caseSensitive: bool, clientLists: list, extensions: list, filenames: list, header: string, hosts: list, ips: list, methods: list, name: string, nameCase: bool, paths: list, positiveMatch: bool, type: string, useHeaders: bool, value: string, valueCase: bool, valueWildcard: bool, wildcard: bool>, exception: record<anyHeaderCookieOrParam: list<string>, headerCookieOrParamValues: list<string>, specificHeaderCookieOrParamNameValue: record<name: string, selector: string, value: string>, specificHeaderCookieOrParamNames: record<names: list, selector: string>, specificHeaderCookieOrParamPrefix: record<prefix: string, selector: string>, specificHeaderCookieParamXmlOrJsonNames: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/rules/($ruleId)/condition-exception" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the conditions and exceptions of a rule
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/rules/{ruleId}/condition-exception
# Docs: https://techdocs.akamai.com/application-security/reference/put-rule-condition-exception — See documentation for this operation in Akamai's Application Security API
# operationId: put-rule-condition-exception
# --advancedExceptions shape: {conditionOperator?: "OR"|"AND", conditions?: list, headerCookieOrParamValues?: list, specificHeaderCookieOrParamNameValue?: list, specificHeaderCookieParamXmlOrJsonNames?: list}
# --conditions item shape: {caseSensitive?: bool, clientLists?: list, extensions?: list, filenames?: list, header?: string, hosts?: list, ips?: list, methods?: list, name?: string, nameCase?: bool, paths?: list, positiveMatch: bool, type: "hostMatch"|"pathMatch"|"filenameMatch"|"extensionMatch"|"uriQueryMatch"|"ipMatch"|"requestMethodMatch"|"requestHeaderMatch"|"clientListMatch", useHeaders?: bool, value?: string, valueCase?: bool, valueWildcard?: bool, wildcard?: bool}
# --exception shape: {anyHeaderCookieOrParam?: list, headerCookieOrParamValues?: list, specificHeaderCookieOrParamNameValue?: record, specificHeaderCookieOrParamNames?: record, specificHeaderCookieOrParamPrefix?: record, specificHeaderCookieParamXmlOrJsonNames?: list}
export def "configs-versions-security-policies-rules-condition-exception put-rule-condition-exception" [
  configId: int
  versionNumber: int
  policyId: string
  ruleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --advancedExceptions: record # Describes the advanced exception fields that allow you to conditionally exclude requests from inspection. This is only available for attack groups and when the advanced exception feature is enabled. — shape: {conditionOperator?: "OR"|"AND", conditions?: list, headerCookieOrParamValues?: list, specificHeaderCookieOrParamNameValue?: list, specificHeaderCookieParamXmlOrJsonNames?: list}
  --conditions: list # The conditions list for a rule. — item shape: {caseSensitive?: bool, clientLists?: list, extensions?: list, filenames?: list, header?: string, hosts?: list, ips?: list, methods?: list, name?: string, nameCase?: bool, paths?: list, positiveMatch: bool, type: "hostMatch"|"pathMatch"|"filenameMatch"|"extensionMatch"|"uriQueryMatch"|"ipMatch"|"requestMethodMatch"|"requestHeaderMatch"|"clientListMatch", useHeaders?: bool, value?: string, valueCase?: bool, valueWildcard?: bool, wildcard?: bool}
  --exception: record # Describes the exception fields that allow you to conditionally exclude requests from inspection. — shape: {anyHeaderCookieOrParam?: list, headerCookieOrParamValues?: list, specificHeaderCookieOrParamNameValue?: record, specificHeaderCookieOrParamNames?: record, specificHeaderCookieOrParamPrefix?: record, specificHeaderCookieParamXmlOrJsonNames?: list}
]: any -> record<advancedExceptions: record<conditionOperator: string, conditions: list<record>, headerCookieOrParamValues: list<record>, specificHeaderCookieOrParamNameValue: list<record>, specificHeaderCookieParamXmlOrJsonNames: list<record>>, conditions: table<caseSensitive: bool, clientLists: list, extensions: list, filenames: list, header: string, hosts: list, ips: list, methods: list, name: string, nameCase: bool, paths: list, positiveMatch: bool, type: string, useHeaders: bool, value: string, valueCase: bool, valueWildcard: bool, wildcard: bool>, exception: record<anyHeaderCookieOrParam: list<string>, headerCookieOrParamValues: list<string>, specificHeaderCookieOrParamNameValue: record<name: string, selector: string, value: string>, specificHeaderCookieOrParamNames: record<names: list, selector: string>, specificHeaderCookieOrParamPrefix: record<prefix: string, selector: string>, specificHeaderCookieParamXmlOrJsonNames: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/rules/($ruleId)/condition-exception" $qp)
  let body = {advancedExceptions: $advancedExceptions, conditions: $conditions, exception: $exception} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List selected hostnames for a security policy
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/selected-hostnames
# Docs: https://techdocs.akamai.com/application-security/reference/get-selected-hostnames-per-policy — See documentation for this operation in Akamai's Application Security API
# operationId: get-selected-hostnames-per-policy
export def "configs-versions-security-policies-selected-hostnames get-selected-hostnames-per-policy" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<hostnameList: table<hostname: string>, mode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/selected-hostnames" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify selected hostnames for a security policy
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/selected-hostnames
# Docs: https://techdocs.akamai.com/application-security/reference/put-selected-hostnames-per-config — See documentation for this operation in Akamai's Application Security API
# operationId: put-selected-hostnames-per-config
# --hostnameList item shape: {hostname: string}
export def "configs-versions-security-policies-selected-hostnames put-selected-hostnames-per-config" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  hostnameList: list # The list of hostnames for a configuration version. — item shape: {hostname: string}
  --mode: string@mode-completer # The type of update you want to make to the evaluation hostname list. Use `append` to add additional hostnames, `remove` to delete the hostnames from the list, or `replace` to replace the existing list with the hostnames you pass in your request.
]: any -> record<hostnameList: table<hostname: string>, mode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/selected-hostnames" $qp)
  let body = {hostnameList: $hostnameList, mode: $mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get slow POST protection settings
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/slow-post
# Docs: https://techdocs.akamai.com/application-security/reference/get-policy-slow-post — See documentation for this operation in Akamai's Application Security API
# operationId: get-policy-slow-post
export def "configs-versions-security-policies-slow-post get-policy-slow-post" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<action: string, durationThreshold: record<timeout: int>, slowRateThreshold: record<period: int, rate: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/slow-post" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify slow POST protection settings
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/slow-post
# Docs: https://techdocs.akamai.com/application-security/reference/put-policy-slow-post — See documentation for this operation in Akamai's Application Security API
# operationId: put-policy-slow-post
# --durationThreshold shape: {timeout: int}
# --slowRateThreshold shape: {period: int, rate: int}
export def "configs-versions-security-policies-slow-post put-policy-slow-post" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  action: string@action-completer-6 # Specifies the  action that the rule should trigger. Either `alert` or `abort`.
  --durationThreshold: record # If the edge server doesn't receive the first eight kilobytes of the POST body transfer within the specified time, the specified action in the policy is applied. — shape: {timeout: int}
  --slowRateThreshold: record # The average rate in bytes per second over a period of time that you specify before an action (`alert` or `abort`) in the policy triggers. For example, if you set the `slowRateThreshold` to an average of 10 bytes per second in a 60 second period and a request comes in at an average of 5 bytes per second in a 60 second period, the action you specified in the policy triggers. — shape: {period: int, rate: int}
]: any -> record<action: string, durationThreshold: record<timeout: int>, slowRateThreshold: record<period: int, rate: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/slow-post" $qp)
  let body = {action: $action, durationThreshold: $durationThreshold, slowRateThreshold: $slowRateThreshold} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get adaptive intelligence settings
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/threat-intel
# Docs: https://techdocs.akamai.com/application-security/reference/get-rules-threat-intel — See documentation for this operation in Akamai's Application Security API
# operationId: get-rules-threat-intel
export def "configs-versions-security-policies-threat-intel get-rules-threat-intel" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<threatIntel: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/threat-intel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify adaptive intelligence settings
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/threat-intel
# Docs: https://techdocs.akamai.com/application-security/reference/put-rules-threat-intel — See documentation for this operation in Akamai's Application Security API
# operationId: put-rules-threat-intel
export def "configs-versions-security-policies-threat-intel put-rules-threat-intel" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --threatIntel: string@threatIntel-completer # Set to `on` so our network analyzes a request and dynamically modifies protection methods to fit the detected threat level. Set to `off` to manually fine-tune your rule sets.
]: any -> record<threatIntel: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/threat-intel" $qp)
  let body = {threatIntel: $threatIntel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List URL protection policy actions
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/url-protections
# Docs: https://techdocs.akamai.com/application-security/reference/get-url-protection-policies-actions — See documentation for this operation in Akamai's Application Security API
# operationId: get-url-protection-policies-actions
export def "configs-versions-security-policies-url-protections get-url-protection-policies-actions" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<urlProtectionActions: table<loadSheddingAction: any, maxRpsAction: any, policyId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/url-protections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a URL protection policy action
#
# PUT /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/url-protections/{urlProtectionPolicyId}
# Docs: https://techdocs.akamai.com/application-security/reference/put-url-protection-policy-action — See documentation for this operation in Akamai's Application Security API
# operationId: put-url-protection-policy-action
export def "configs-versions-security-policies-url-protections put-url-protection-policy-action" [
  configId: int
  versionNumber: int
  policyId: string
  urlProtectionPolicyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  action: any # The action to assign to this URL protection policy once the rate control threshold is reached. Choose `alert`, `deny`, `none`, `deny_custom_{custom_deny_id}` or `challenge_{id}`. Run [Modify a custom deny action](https://techdocs.akamai.com/application-security/reference/put-custom-deny) to manage your custom deny actions. If the action is `none`, the URL protection policy is inactive in the policy. Refer to [Challenge actions](https://techdocs.akamai.com/app-api-protector/docs/challenge-actions) for details.
  --loadSheddingAction: any # The action to assign to this URL protection policy once the intelligent load shedding threshold is reached. Choose `alert`, `deny`, `none`, `deny_custom_{custom_deny_id}` or `challenge_{id}`. Run [Modify a custom deny action](https://techdocs.akamai.com/application-security/reference/put-custom-deny) to manage your custom deny actions. If the action is `none`, the URL protection policy is inactive in the policy. Refer to [Challenge actions](https://techdocs.akamai.com/app-api-protector/docs/challenge-actions) for details.
]: any -> record<action: any, loadSheddingAction: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/url-protections/($urlProtectionPolicyId)" $qp)
  let body = {action: $action, loadSheddingAction: $loadSheddingAction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a security policy's rule set
#
# GET /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/web-application-firewall/ruleset
# Docs: https://techdocs.akamai.com/application-security/reference/get-waf-policy-ruleset-composite — See documentation for this operation in Akamai's Application Security API
# operationId: get-waf-policy-ruleset-composite
export def "configs-versions-security-policies-web-application-firewall-ruleset get-waf-policy-ruleset-composite" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<adaptiveIntelligence: record<threatIntelEnabled: bool>, attackGroups: table<action: string, conditionException: record, group: string>, ruleSetInfo: record<ruleSetVersion: float>, rules: table<action: string, conditionException: record, ruleId: int, ruleName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/web-application-firewall/ruleset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a security policy's rule set
#
# PATCH /configs/{configId}/versions/{versionNumber}/security-policies/{policyId}/web-application-firewall/ruleset
# Docs: https://techdocs.akamai.com/application-security/reference/patch-waf-policy-ruleset-composite — See documentation for this operation in Akamai's Application Security API
# operationId: patch-waf-policy-ruleset-composite
# --attackGroups item shape: {action: string, conditionException?: record, group: string}
# --rules item shape: {action: string, conditionException?: record, ruleId: int}
export def "configs-versions-security-policies-web-application-firewall-ruleset patch-waf-policy-ruleset-composite" [
  configId: int
  versionNumber: int
  policyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --attackGroups: list # Attack groups in the security policy with their actions and condition exceptions. — item shape: {action: string, conditionException?: record, group: string}
  --rules: list # The rules in security policy, including the rules' names, actions, and condition exceptions. — item shape: {action: string, conditionException?: record, ruleId: int}
]: any -> record<adaptiveIntelligence: record<threatIntelEnabled: bool>, attackGroups: table<action: string, conditionException: record, group: string>, ruleSetInfo: record<ruleSetVersion: float>, rules: table<action: string, conditionException: record, ruleId: int, ruleName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/security-policies/($policyId)/web-application-firewall/ruleset" $qp)
  let body = {attackGroups: $attackGroups, rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List selectable hostnames
#
# GET /configs/{configId}/versions/{versionNumber}/selectable-hostnames
# Docs: https://techdocs.akamai.com/application-security/reference/get-selectable-hostnames — See documentation for this operation in Akamai's Application Security API
# operationId: get-selectable-hostnames
export def "configs-versions-selectable-hostnames get-selectable-hostnames" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<availableSet: table<activeInProduction: bool, activeInStaging: bool, arlInclusion: bool, configIdInProduction: int, configNameInProduction: string, hostname: string>, configId: int, configVersion: int, errorSet: table<hostname: string, reason: string, reasonCode: int>, protectARLInclusionHost: bool, selectedSet: table<activeInProduction: bool, activeInStaging: bool, arlInclusion: bool, configIdInProduction: int, configNameInProduction: string, hostname: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/selectable-hostnames" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List selected hostnames
#
# GET /configs/{configId}/versions/{versionNumber}/selected-hostnames
# Docs: https://techdocs.akamai.com/application-security/reference/get-selected-hostnames — See documentation for this operation in Akamai's Application Security API
# operationId: get-selected-hostnames
export def "configs-versions-selected-hostnames get-selected-hostnames" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<hostnameList: table<hostname: string>, mode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/selected-hostnames" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify selected hostnames
#
# PUT /configs/{configId}/versions/{versionNumber}/selected-hostnames
# Docs: https://techdocs.akamai.com/application-security/reference/put-selected-hostnames — See documentation for this operation in Akamai's Application Security API
# operationId: put-selected-hostnames
# --hostnameList item shape: {hostname: string}
export def "configs-versions-selected-hostnames put-selected-hostnames" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  hostnameList: list # The list of hostnames for a configuration version. — item shape: {hostname: string}
  --mode: string@mode-completer # The type of update you want to make to the evaluation hostname list. Use `append` to add additional hostnames, `remove` to delete the hostnames from the list, or `replace` to replace the existing list with the hostnames you pass in your request.
]: any -> record<hostnameList: table<hostname: string>, mode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/selected-hostnames" $qp)
  let body = {hostnameList: $hostnameList, mode: $mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List evaluation hostnames
#
# GET /configs/{configId}/versions/{versionNumber}/selected-hostnames/eval-hostnames
# Docs: https://techdocs.akamai.com/application-security/reference/get-selected-hostnames-eval-hostnames — See documentation for this operation in Akamai's Application Security API
# operationId: get-selected-hostnames-eval-hostnames
export def "configs-versions-selected-hostnames-eval-hostnames get-selected-hostnames-eval-hostnames" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<hostnames: list<string>, mode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/selected-hostnames/eval-hostnames" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify evaluation hostnames
#
# PUT /configs/{configId}/versions/{versionNumber}/selected-hostnames/eval-hostnames
# Docs: https://techdocs.akamai.com/application-security/reference/put-selected-eval-hostnames — See documentation for this operation in Akamai's Application Security API
# operationId: put-selected-eval-hostnames
export def "configs-versions-selected-hostnames-eval-hostnames put-selected-eval-hostnames" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  hostnames: list # Contains a list of hostnames.
  --mode: string@mode-completer # The type of update you want to make to the evaluation hostname list. You can `append` additional hostnames, `remove` hostnames from the list, or `replace` the existing list with the hostnames you pass in your request.
]: any -> record<hostnames: list<string>, mode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/selected-hostnames/eval-hostnames" $qp)
  let body = {hostnames: $hostnames, mode: $mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get SIEM settings
#
# GET /configs/{configId}/versions/{versionNumber}/siem
# Docs: https://techdocs.akamai.com/application-security/reference/get-siem — See documentation for this operation in Akamai's Application Security API
# operationId: get-siem
export def "configs-versions-siem get-siem" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<enableForAllPolicies: bool, enableSiem: bool, enabledBotmanSiemEvents: bool, exceptions: table<actionTypes: list, protection: string>, firewallPolicyIds: list<string>, includeJA4FingerprintToSiem: bool, siemDefinitionId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/siem" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify SIEM settings
#
# PUT /configs/{configId}/versions/{versionNumber}/siem
# Docs: https://techdocs.akamai.com/application-security/reference/put-siem — See documentation for this operation in Akamai's Application Security API
# operationId: put-siem
# --exceptions item shape: {actionTypes?: list, protection?: "ipgeo"|"rate"|"urlProtection"|"slowpost"|"customrules"|"waf"|"apirequestconstraints"|"clientrep"|"malwareprotection"|"botmanagement"|"aprProtection"|"aifirewallprotection"}
@deprecated --flag enabledBotmanSiemEvents
export def "configs-versions-siem put-siem" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --enableForAllPolicies: oneof<nothing, bool> # Whether you enabled SIEM for all the security policies in the configuration version.
  --enableSiem: oneof<nothing, bool> # Whether you enabled SIEM in a security configuration version.
  --enabledBotmanSiemEvents: oneof<nothing, bool> # __Deprecated__ Whether you enabled SIEM for the Bot Manager events. Use `exceptions` parameter instead to set botman siem events exception. (DEPRECATED)
  --exceptions: list # Describes all attack type exceptions that will be ignored in SIEM events. — item shape: {actionTypes?: list, protection?: "ipgeo"|"rate"|"urlProtection"|"slowpost"|"customrules"|"waf"|"apirequestconstraints"|"clientrep"|"malwareprotection"|"botmanagement"|"aprProtection"|"aifirewallprotection"}
  --firewallPolicyIds: list # The list of security policy identifiers for which to enable the SIEM integration.
  --includeJA4FingerprintToSiem: oneof<nothing, bool> # Whether you enabled JA4 header forwarding for SIEM.
  --siemDefinitionId: int # Uniquely identifies the SIEM settings.
]: any -> record<enableForAllPolicies: bool, enableSiem: bool, enabledBotmanSiemEvents: bool, exceptions: table<actionTypes: list, protection: string>, firewallPolicyIds: list<string>, includeJA4FingerprintToSiem: bool, siemDefinitionId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/siem" $qp)
  let body = {enableForAllPolicies: $enableForAllPolicies, enableSiem: $enableSiem, enabledBotmanSiemEvents: $enabledBotmanSiemEvents, exceptions: $exceptions, firewallPolicyIds: $firewallPolicyIds, includeJA4FingerprintToSiem: $includeJA4FingerprintToSiem, siemDefinitionId: $siemDefinitionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a URL protection policy
#
# POST /configs/{configId}/versions/{versionNumber}/url-protections
# Docs: https://techdocs.akamai.com/application-security/reference/post-url-protection-policies — See documentation for this operation in Akamai's Application Security API
# operationId: post-url-protection-policies
# --apiDefinitions item shape: {apiDefinitionId: int, definedResources?: bool, resourceIds?: list, undefinedResources?: bool}
# --bypassCondition shape: {atomicConditions?: list}
# --hostnamePaths item shape: {hostname: string, paths: list}
export def "configs-versions-url-protections post-url-protection-policies" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --apiDefinitions: list # The API endpoints to match on in incoming requests. This only applies to the `api` `matchType`. — item shape: {apiDefinitionId: int, definedResources?: bool, resourceIds?: list, undefinedResources?: bool}
  --bypassCondition: record # Exempts specific clients from being processed by the URL protection policy. — shape: {atomicConditions?: list}
  --categories: list # The traffic categories to perform load shedding on when the origin traffic rate exceeds the load shedding threshold. If `intelligentLoadShedding` is set to `true`, specify one or more categories.
  --body-configId: int # Uniquely identifies the security configuration. (format: int64)
  --configVersion: int # The security configuration version.
  --description: string # A description of the rate policy.
  --hostnamePaths: list # The hostname and path combinations to match on. — item shape: {hostname: string, paths: list}
  --intelligentLoadShedding: oneof<nothing, bool> # Enable or disable intelligent load shedding. If enabled, traffic that matches the load shedding categories is eligible for shedding if the origin rate exceeds the load shedding threshold.
  name: string # The rate policy's unique name.
  --protectionType: string@protectionType-completer # If matching on `hostnamePaths`, specify `SINGLE` to match on a hostname and path, or `MULTIPLE` to match on hostname and path combinations.
  rateThreshold: int # The allowed hits per second during any five-second interval.
  --sheddingThresholdHitsPerSec: int # Specify the threshold value, in hits per second, after which traffic can be shed. The `sheddingThresholdHitsPerSec` value must be between 25%-90% of the `rateThreshold` value. If you enabled `intelligentLoadShedding`, this value is required.
]: any -> record<apiDefinitions: table<apiDefinitionId: int, definedResources: bool, resourceIds: list, undefinedResources: bool>, bypassCondition: record<atomicConditions: list<any>>, categories: list<any>, configId: int, configVersion: int, createDate: string, createdBy: string, description: string, hostnamePaths: table<hostname: string, paths: list>, intelligentLoadShedding: bool, name: string, policyId: int, protectionType: string, rateThreshold: int, sheddingThresholdHitsPerSec: int, updateDate: string, updatedBy: string, used: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/url-protections" $qp)
  let body = {apiDefinitions: $apiDefinitions, bypassCondition: $bypassCondition, categories: $categories, configId: $body_configId, configVersion: $configVersion, description: $description, hostnamePaths: $hostnamePaths, intelligentLoadShedding: $intelligentLoadShedding, name: $name, protectionType: $protectionType, rateThreshold: $rateThreshold, sheddingThresholdHitsPerSec: $sheddingThresholdHitsPerSec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List URL protection policies
#
# GET /configs/{configId}/versions/{versionNumber}/url-protections
# Docs: https://techdocs.akamai.com/application-security/reference/get-url-protection-policies — See documentation for this operation in Akamai's Application Security API
# operationId: get-url-protection-policies
export def "configs-versions-url-protections get-url-protection-policies" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<urlProtectionPolicies: table<apiDefinitions: list, bypassCondition: record, categories: list, configId: int, configVersion: int, createDate: string, createdBy: string, description: string, hostnamePaths: list, intelligentLoadShedding: bool, name: string, policyId: int, protectionType: string, rateThreshold: int, sheddingThresholdHitsPerSec: int, updateDate: string, updatedBy: string, used: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/url-protections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a URL protection policy
#
# GET /configs/{configId}/versions/{versionNumber}/url-protections/{urlProtectionPolicyId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-url-protection-policy — See documentation for this operation in Akamai's Application Security API
# operationId: get-url-protection-policy
export def "configs-versions-url-protections get-url-protection-policy" [
  configId: int
  versionNumber: int
  urlProtectionPolicyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<apiDefinitions: table<apiDefinitionId: int, definedResources: bool, resourceIds: list, undefinedResources: bool>, bypassCondition: record<atomicConditions: list<any>>, categories: list<any>, configId: int, configVersion: int, createDate: string, createdBy: string, description: string, hostnamePaths: table<hostname: string, paths: list>, intelligentLoadShedding: bool, name: string, policyId: int, protectionType: string, rateThreshold: int, sheddingThresholdHitsPerSec: int, updateDate: string, updatedBy: string, used: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/url-protections/($urlProtectionPolicyId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a URL protection policy
#
# PUT /configs/{configId}/versions/{versionNumber}/url-protections/{urlProtectionPolicyId}
# Docs: https://techdocs.akamai.com/application-security/reference/put-url-protection-policy — See documentation for this operation in Akamai's Application Security API
# operationId: put-url-protection-policy
# --apiDefinitions item shape: {apiDefinitionId: int, definedResources?: bool, resourceIds?: list, undefinedResources?: bool}
# --bypassCondition shape: {atomicConditions?: list}
# --hostnamePaths item shape: {hostname: string, paths: list}
export def "configs-versions-url-protections put-url-protection-policy" [
  configId: int
  versionNumber: int
  urlProtectionPolicyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --apiDefinitions: list # The API endpoints to match on in incoming requests. This only applies to the `api` `matchType`. — item shape: {apiDefinitionId: int, definedResources?: bool, resourceIds?: list, undefinedResources?: bool}
  --bypassCondition: record # Exempts specific clients from being processed by the URL protection policy. — shape: {atomicConditions?: list}
  --categories: list # The traffic categories to perform load shedding on when the origin traffic rate exceeds the load shedding threshold. If `intelligentLoadShedding` is set to `true`, specify one or more categories.
  --body-configId: int # Uniquely identifies the security configuration. (format: int64)
  --configVersion: int # The security configuration version.
  --description: string # A description of the rate policy.
  --hostnamePaths: list # The hostname and path combinations to match on. — item shape: {hostname: string, paths: list}
  --intelligentLoadShedding: oneof<nothing, bool> # Enable or disable intelligent load shedding. If enabled, traffic that matches the load shedding categories is eligible for shedding if the origin rate exceeds the load shedding threshold.
  name: string # The rate policy's unique name.
  --protectionType: string@protectionType-completer # If matching on `hostnamePaths`, specify `SINGLE` to match on a hostname and path, or `MULTIPLE` to match on hostname and path combinations.
  rateThreshold: int # The allowed hits per second during any five-second interval.
  --sheddingThresholdHitsPerSec: int # Specify the threshold value, in hits per second, after which traffic can be shed. The `sheddingThresholdHitsPerSec` value must be between 25%-90% of the `rateThreshold` value. If you enabled `intelligentLoadShedding`, this value is required.
]: any -> record<apiDefinitions: table<apiDefinitionId: int, definedResources: bool, resourceIds: list, undefinedResources: bool>, bypassCondition: record<atomicConditions: list<any>>, categories: list<any>, configId: int, configVersion: int, createDate: string, createdBy: string, description: string, hostnamePaths: table<hostname: string, paths: list>, intelligentLoadShedding: bool, name: string, policyId: int, protectionType: string, rateThreshold: int, sheddingThresholdHitsPerSec: int, updateDate: string, updatedBy: string, used: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/url-protections/($urlProtectionPolicyId)" $qp)
  let body = {apiDefinitions: $apiDefinitions, bypassCondition: $bypassCondition, categories: $categories, configId: $body_configId, configVersion: $configVersion, description: $description, hostnamePaths: $hostnamePaths, intelligentLoadShedding: $intelligentLoadShedding, name: $name, protectionType: $protectionType, rateThreshold: $rateThreshold, sheddingThresholdHitsPerSec: $sheddingThresholdHitsPerSec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a URL protection policy
#
# DELETE /configs/{configId}/versions/{versionNumber}/url-protections/{urlProtectionPolicyId}
# Docs: https://techdocs.akamai.com/application-security/reference/delete-url-protection-policy — See documentation for this operation in Akamai's Application Security API
# operationId: delete-url-protection-policy
export def "configs-versions-url-protections delete-url-protection-policy" [
  configId: int
  versionNumber: int
  urlProtectionPolicyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/url-protections/($urlProtectionPolicyId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the version notes
#
# GET /configs/{configId}/versions/{versionNumber}/version-notes
# Docs: https://techdocs.akamai.com/application-security/reference/get-version-notes — See documentation for this operation in Akamai's Application Security API
# operationId: get-version-notes
export def "configs-versions-version-notes get-version-notes" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<notes: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/version-notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify version notes
#
# PUT /configs/{configId}/versions/{versionNumber}/version-notes
# Docs: https://techdocs.akamai.com/application-security/reference/put-version-notes — See documentation for this operation in Akamai's Application Security API
# operationId: put-version-notes
export def "configs-versions-version-notes put-version-notes" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --notes: string # The version notes.
]: any -> record<notes: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($configId)/versions/($versionNumber)/version-notes" $qp)
  let body = {notes: $notes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List contracts and groups
#
# GET /contracts-groups
# Docs: https://techdocs.akamai.com/application-security/reference/get-contracts-groups — See documentation for this operation in Akamai's Application Security API
# operationId: get-contracts-groups
export def "contracts-groups get-contracts-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<contract_groups: table<contractId: string, displayName: string, groupId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contracts-groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List available hostnames for a new configuration
#
# GET /contracts/{contractId}/groups/{groupId}/selectable-hostnames
# Docs: https://techdocs.akamai.com/application-security/reference/get-selectable-hostnames-per-config — See documentation for this operation in Akamai's Application Security API
# operationId: get-selectable-hostnames-per-config
export def "contracts-groups-selectable-hostnames get-selectable-hostnames-per-config" [
  groupId: string
  contractId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<availableSet: table<activeInProduction: bool, activeInStaging: bool, arlInclusion: bool, configIdInProduction: int, configNameInProduction: string, hostname: string>, configId: int, configVersion: int, errorSet: table<hostname: string, reason: string, reasonCode: int>, protectARLInclusionHost: bool, selectedSet: table<activeInProduction: bool, activeInStaging: bool, arlInclusion: bool, configIdInProduction: int, configNameInProduction: string, hostname: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contracts/($contractId)/groups/($groupId)/selectable-hostnames" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List CVEs
#
# GET /cves
# Docs: https://techdocs.akamai.com/application-security/reference/get-cves — See documentation for this operation in Akamai's Application Security API
# operationId: get-cves
export def "cves get-cves" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --modifiedAfter: string # Filters CVEs by `modifiedDate`, returning all CVEs modified after that time. (format: date-time, e.g. 2023-10-22T14:30:45Z)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<cves: table<coverage: string, cveId: string, description: string, impactScore: float, impactSeverity: string, modifiedDate: string, publishedDate: string, weaknessIds: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "modifiedAfter" $modifiedAfter "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cves" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe to CVEs
#
# POST /cves/subscribe
# Docs: https://techdocs.akamai.com/application-security/reference/post-subscribe — See documentation for this operation in Akamai's Application Security API
# operationId: post-subscribe
export def "cves-subscribe post-subscribe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  cveIds: list # Identifiers for the CVEs you want to subscribe to.
]: any -> record<cveIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cves/subscribe" $qp)
  let body = {cveIds: $cveIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List subscribed CVEs
#
# GET /cves/subscribed
# Docs: https://techdocs.akamai.com/application-security/reference/get-subscribed — See documentation for this operation in Akamai's Application Security API
# operationId: get-subscribed
export def "cves-subscribed get-subscribed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<cves: table<coverage: string, cveId: string, description: string, impactScore: float, impactSeverity: string, modifiedDate: string, publishedDate: string, weaknessIds: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cves/subscribed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unsubscribe from CVEs
#
# POST /cves/unsubscribe
# Docs: https://techdocs.akamai.com/application-security/reference/post-unsubscribe — See documentation for this operation in Akamai's Application Security API
# operationId: post-unsubscribe
export def "cves-unsubscribe post-unsubscribe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Whether to unsubscribe from all CVEs, `false` by default. (default: false, e.g. true)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --cveIds: list # The identifiers for the CVEs you want to unsubscribe from.
]: any -> record<cveIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cves/unsubscribe" $qp)
  let body = {cveIds: $cveIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a CVE
#
# GET /cves/{cveId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-cve — See documentation for this operation in Akamai's Application Security API
# operationId: get-cve
export def "cves get-cve" [
  cveId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<affectedSystems: table<systemProduct: string, systemVendor: string>, coverage: string, cveId: string, cveStatus: string, description: string, impactScore: float, impactSeverity: string, mitigation: record<attackGroups: list<record>>, modifiedDate: string, publishedDate: string, weaknessIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cves/($cveId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get CVE coverage
#
# GET /cves/{cveId}/security-coverage
# Docs: https://techdocs.akamai.com/application-security/reference/get-security-coverage — See documentation for this operation in Akamai's Application Security API
# operationId: get-security-coverage
export def "cves-security-coverage get-security-coverage" [
  cveId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<configurations: table<configId: int, configName: string, policies: list, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cves/($cveId)/security-coverage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export a configuration version
#
# GET /export/configs/{configId}/versions/{versionNumber}
# Docs: https://techdocs.akamai.com/application-security/reference/get-export-config-version — See documentation for this operation in Akamai's Application Security API
# operationId: get-export-config-version
export def "export-configs-versions get-export-config-version" [
  configId: int
  versionNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<advancedOptions: record<asePenaltyBox: record<akamaiManagedExclusions: record, blockDuration: int, clientIdentifiers: list, qualificationExclusions: record, requestCount: int>, ja4Fingerprint: record<headerNames: list>, logging: record<allowSampling: bool, cookies: record, customHeaders: record, standardHeaders: record>, pragmaHeader: record<action: string, conditionOperator: string, excludeCondition: list, override: bool>, prefetch: record<allExtensions: bool, enableAppLayer: bool, enableRateControls: bool, extensions: list>, requestBody: record<requestBodyInspectionLimitInKB: string>>, basedOn: int, configId: int, configName: string, createDate: string, createdBy: string, customDenyList: table<customDenyList: list>, customRules: table<conditions: list, description: string, id: int, inspectRequest: bool, inspectResponse: bool, loggingOptions: list, metadata: string, name: string, operation: string, ruleActivated: bool, stagingOnly: bool, structured: bool, tag: list, version: int>, errorHosts: table<hostname: string, reason: string, reasonCode: int>, evaluating: record<securityPolicies: list<record>>, malwarePolicies: table<allowListId: string, blockListId: string, contentTypes: list, description: string, hostnames: list, id: int, logFilename: bool, name: string, paths: list>, matchTargets: record<apiTargets: list<record>, websiteTargets: list<record>>, production: record<action: string, status: string, time: string>, ratePolicies: table<additionalMatchOptions: list, apiSelectors: list, averageThreshold: int, bodyParameters: list, burstThreshold: int, burstWindow: int, clientIdentifier: string, clientIdentifiers: list, condition: record, counterType: string, createDate: string, description: string, evaluation: record, fileExtensions: record, hostnames: list, hosts: record, id: int, matchType: string, name: string, path: record, pathMatchType: string, pathUriPositiveMatch: bool, penaltyBoxDuration: string, queryParameters: list, requestType: string, sameActionOnIpv6: bool, type: string, updateDate: string, useXForwardForHeaders: bool, used: bool>, reputationProfiles: table<condition: record, context: string, contextReadable: string, description: string, enabled: bool, id: int, name: string, threshold: float>, rulesets: table<attackGroups: list, id: int, releaseDate: string, rules: list, rulesetVersionId: int, type: string>, securityPolicies: table<apiRequestConstraints: record, clientReputation: record, customRuleActions: list, evaluationPenaltyBox: record, hasRatePolicyWithApiKey: bool, id: string, ipGeoFirewall: record, loggingOverrides: record, malwarePolicyActions: list, name: string, penaltyBox: record, pragmaHeader: record, rapidRules: record, ratePolicyActions: list, requestBody: record, securityControls: record, slowPost: record, webApplicationFirewall: record>, selectableHosts: list<string>, selectedHosts: list<string>, siem: record<enableForAllPolicies: bool, enableSiem: bool, enabledBotmanSiemEvents: bool, exceptions: list<record>, firewallPolicyIds: list<string>, siemDefinitionId: int>, staging: record<action: string, status: string, time: string>, version: int, versionNotes: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/export/configs/($configId)/versions/($versionNumber)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get hostname coverage
#
# GET /hostname-coverage
# Docs: https://techdocs.akamai.com/application-security/reference/get-hostname-coverage — See documentation for this operation in Akamai's Application Security API
# operationId: get-hostname-coverage
export def "hostname-coverage get-hostname-coverage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<hostnameCoverage: table<configuration: record, hasMatchTarget: bool, hostname: string, policyNames: list, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hostname-coverage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an onboarding
#
# POST /onboardings
# Docs: https://techdocs.akamai.com/application-security/reference/post-onboarding — See documentation for this operation in Akamai's Application Security API
# operationId: post-onboarding
export def "onboardings post-onboarding" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --createNewResourcesOnly: oneof<nothing, bool> # This creates an onboarding with a new CPS certificate and security protections. If your contract limits how many certificates you create, the API responds with an error. (default: false, e.g. true)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  contractId: string # A unique identifier for a contract. Run [List contracts and groups](https://techdocs.akamai.com/application-security/docs/get-contracts-groups) to get the `contractId` if you don't have one already.
  groupId: int # A unique identifier for a group. (format: int32)
  hostnames: list # List of hostnames you are setting up with Akamai services.
]: any -> record<accountId: string, activations: table<activationId: int, activationLink: string, activationStatus: string, completedDate: string, createdDate: string, network: string>, contractId: string, createdBy: string, createdDate: string, currentStep: float, groupId: int, hostnames: list<string>, modifiedBy: string, modifiedDate: string, nextSteps: table<stepDescription: string, stepLink: string, stepName: string>, onboardingId: int, onboardingLink: string, onboardingStatus: string, product: string, settings: record<certificate: record<adminContact: record, certificateType: string, commonName: string, enrollmentId: int, enrollmentLink: string>, delivery: record<origins: list>, security: record<cloneVersion: int, configId: int, configLink: string, configName: string, configType: string, evalRequired: bool, policyId: string, policyLink: string, policyName: string, policyType: string, protections: record>, settingsLink: string>, totalSteps: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "createNewResourcesOnly" $createNewResourcesOnly "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/onboardings" $qp)
  let body = {contractId: $contractId, groupId: $groupId, hostnames: $hostnames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List onboardings
#
# GET /onboardings
# Docs: https://techdocs.akamai.com/application-security/reference/get-onboardings — See documentation for this operation in Akamai's Application Security API
# operationId: get-onboardings
export def "onboardings get-onboardings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --onboardingStatuses: list # Lists onboardings for a specific status. (e.g. [VALIDATION_PENDING, COMPLETE])
  --hostnames: list # Returns onboardings containing the specified hostnames.
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<onboardings: table<createdBy: string, createdTime: string, hostnames: list, modifiedBy: string, modifiedTime: string, onboardingId: int, onboardingLink: string, onboardingStatus: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "onboardingStatuses" $onboardingStatuses "csv") (serialize-qp "hostnames" $hostnames "csv") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/onboardings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an onboarding
#
# GET /onboardings/{onboardingId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-onboarding — See documentation for this operation in Akamai's Application Security API
# operationId: get-onboarding
export def "onboardings get-onboarding" [
  onboardingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<accountId: string, activations: table<activationId: int, activationLink: string, activationStatus: string, completedDate: string, createdDate: string, network: string>, contractId: string, createdBy: string, createdDate: string, currentStep: float, groupId: int, hostnames: list<string>, modifiedBy: string, modifiedDate: string, nextSteps: table<stepDescription: string, stepLink: string, stepName: string>, onboardingId: int, onboardingLink: string, onboardingStatus: string, product: string, settings: record<certificate: record<adminContact: record, certificateType: string, commonName: string, enrollmentId: int, enrollmentLink: string>, delivery: record<origins: list>, security: record<cloneVersion: int, configId: int, configLink: string, configName: string, configType: string, evalRequired: bool, policyId: string, policyLink: string, policyName: string, policyType: string, protections: record>, settingsLink: string>, totalSteps: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onboardings/($onboardingId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an onboarding
#
# DELETE /onboardings/{onboardingId}
# Docs: https://techdocs.akamai.com/application-security/reference/delete-onboarding — See documentation for this operation in Akamai's Application Security API
# operationId: delete-onboarding
export def "onboardings delete-onboarding" [
  onboardingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onboardings/($onboardingId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Activate an onboarding
#
# POST /onboardings/{onboardingId}/activations
# Docs: https://techdocs.akamai.com/application-security/reference/post-onboarding-activation — See documentation for this operation in Akamai's Application Security API
# operationId: post-onboarding-activation
export def "onboardings-activations post-onboarding-activation" [
  onboardingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  network: string@network-completer # The target Akamai activation environment, either `STAGING`` or `PRODUCTION``.
  notificationEmails: list # The email addresses to receive notifications regarding the activation.
]: any -> record<activationId: int, activationStatus: string, activationStatusLink: string, completedDate: string, createdBy: string, createdDate: string, network: string, onboardingLink: string, percentComplete: int, retryAfter: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onboardings/($onboardingId)/activations" $qp)
  let body = {network: $network, notificationEmails: $notificationEmails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an onboarding activation
#
# GET /onboardings/{onboardingId}/activations/{activationId}
# Docs: https://techdocs.akamai.com/application-security/reference/get-onboarding-activation-status — See documentation for this operation in Akamai's Application Security API
# operationId: get-onboarding-activation-status
export def "onboardings-activations get-onboarding-activation-status" [
  onboardingId: int
  activationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<activationId: int, activationStatus: string, activationStatusLink: string, completedDate: string, createdBy: string, createdDate: string, network: string, onboardingLink: string, percentComplete: int, retryAfter: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onboardings/($onboardingId)/activations/($activationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List onboarding certificate challenges
#
# GET /onboardings/{onboardingId}/certificate-validation
# Docs: https://techdocs.akamai.com/application-security/reference/get-onboarding-certificate-validation — See documentation for this operation in Akamai's Application Security API
# operationId: get-onboarding-certificate-validation
export def "onboardings-certificate-validation get-onboarding-certificate-validation" [
  onboardingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<certificateValidateLink: string, certificateValidationStatus: string, description: string, onboardingLink: string, records: table<hostname: string, httpFilePath: string, httpToken: string, recordName: string, recordStatus: string, recordTtl: int, recordType: string, recordValue: string, urlRedirectFrom: string, urlRedirectTo: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onboardings/($onboardingId)/certificate-validation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validate onboarding certificate
#
# POST /onboardings/{onboardingId}/certificate-validation/validate
# Docs: https://techdocs.akamai.com/application-security/reference/post-onboarding-certificate-validation — See documentation for this operation in Akamai's Application Security API
# operationId: post-onboarding-certificate-validation
export def "onboardings-certificate-validation-validate post-onboarding-certificate-validation" [
  onboardingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<certificateValidateLink: string, certificateValidationStatus: string, description: string, onboardingLink: string, records: table<hostname: string, httpFilePath: string, httpToken: string, recordName: string, recordStatus: string, recordTtl: int, recordType: string, recordValue: string, urlRedirectFrom: string, urlRedirectTo: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onboardings/($onboardingId)/certificate-validation/validate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List hostname CNAME DNS records
#
# GET /onboardings/{onboardingId}/cname-to-akamai
# Docs: https://techdocs.akamai.com/application-security/reference/get-onboarding-cname-records — See documentation for this operation in Akamai's Application Security API
# operationId: get-onboarding-cname-records
export def "onboardings-cname-to-akamai get-onboarding-cname-records" [
  onboardingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<cnameValidateLink: string, cnameValidationStatus: string, description: string, onboardingLink: string, records: table<recordName: string, recordStatus: string, recordTtl: int, recordType: string, recordValue: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onboardings/($onboardingId)/cname-to-akamai" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validate hostname CNAME DNS records
#
# POST /onboardings/{onboardingId}/cname-to-akamai/validate
# Docs: https://techdocs.akamai.com/application-security/reference/post-validate-onboarding-cname-records — See documentation for this operation in Akamai's Application Security API
# operationId: post-validate-onboarding-cname-records
export def "onboardings-cname-to-akamai-validate post-validate-onboarding-cname-records" [
  onboardingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<cnameValidationStatus: string, description: string, onboardingLink: string, records: table<recordName: string, recordStatus: string, recordTtl: int, recordType: string, recordValue: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onboardings/($onboardingId)/cname-to-akamai/validate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List onboarding domain challenges
#
# GET /onboardings/{onboardingId}/domain-validation
# Docs: https://techdocs.akamai.com/application-security/reference/get-onboarding-domain-validation — See documentation for this operation in Akamai's Application Security API
# operationId: get-onboarding-domain-validation
export def "onboardings-domain-validation get-onboarding-domain-validation" [
  onboardingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<description: string, domainValidationLink: string, domainValidationStatus: string, onboardingLink: string, records: table<hostname: string, httpFilePath: string, httpToken: string, recordName: string, recordStatus: string, recordTtl: int, recordType: string, recordValue: string, urlRedirectFrom: string, urlRedirectTo: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onboardings/($onboardingId)/domain-validation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validate onboarding domains
#
# POST /onboardings/{onboardingId}/domain-validation/validate
# Docs: https://techdocs.akamai.com/application-security/reference/post-onboarding-domain-validation — See documentation for this operation in Akamai's Application Security API
# operationId: post-onboarding-domain-validation
export def "onboardings-domain-validation-validate post-onboarding-domain-validation" [
  onboardingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<description: string, domainValidationLink: string, domainValidationStatus: string, onboardingLink: string, records: table<hostname: string, httpFilePath: string, httpToken: string, recordName: string, recordStatus: string, recordTtl: int, recordType: string, recordValue: string, urlRedirectFrom: string, urlRedirectTo: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onboardings/($onboardingId)/domain-validation/validate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List origin hostname DNS records
#
# GET /onboardings/{onboardingId}/origin-validation
# Docs: https://techdocs.akamai.com/application-security/reference/get-onboarding-origin-validation — See documentation for this operation in Akamai's Application Security API
# operationId: get-onboarding-origin-validation
export def "onboardings-origin-validation get-onboarding-origin-validation" [
  onboardingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<description: string, onboardingLink: string, originSkipLink: string, originValidateLink: string, originValidationStatus: string, records: table<hostname: string, recordName: string, recordStatus: string, recordTtl: int, recordType: string, recordValue: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onboardings/($onboardingId)/origin-validation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Skip origin hostnames DNS record validation
#
# POST /onboardings/{onboardingId}/origin-validation/skip
# Docs: https://techdocs.akamai.com/application-security/reference/post-skip-onboarding-origin-validation — See documentation for this operation in Akamai's Application Security API
# operationId: post-skip-onboarding-origin-validation
export def "onboardings-origin-validation-skip post-skip-onboarding-origin-validation" [
  onboardingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<description: string, onboardingLink: string, originValidationStatus: string, records: table<hostname: string, recordName: string, recordStatus: string, recordTtl: int, recordType: string, recordValue: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onboardings/($onboardingId)/origin-validation/skip" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validate origin hostnames DNS records
#
# POST /onboardings/{onboardingId}/origin-validation/validate
# Docs: https://techdocs.akamai.com/application-security/reference/post-onboarding-origin-validation — See documentation for this operation in Akamai's Application Security API
# operationId: post-onboarding-origin-validation
export def "onboardings-origin-validation-validate post-onboarding-origin-validation" [
  onboardingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<description: string, onboardingLink: string, originValidationStatus: string, records: table<hostname: string, recordName: string, recordStatus: string, recordTtl: int, recordType: string, recordValue: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onboardings/($onboardingId)/origin-validation/validate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get onboarding settings
#
# GET /onboardings/{onboardingId}/settings
# Docs: https://techdocs.akamai.com/application-security/reference/get-onboarding-settings — See documentation for this operation in Akamai's Application Security API
# operationId: get-onboarding-settings
export def "onboardings-settings get-onboarding-settings" [
  onboardingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<certificate: record<adminContact: record<email: string, firstName: string, lastName: string, phone: string>, certificateType: string, commonName: string, enrollmentId: int, enrollmentLink: string>, delivery: record<origins: list<record>>, onboardingLink: string, security: record<cloneVersion: int, configId: int, configLink: string, configName: string, configType: string, evalRequired: bool, policyId: string, policyLink: string, policyName: string, policyType: string, protections: record<applyApplicationLayerControls: bool, applyBotmanControls: bool, applyNetworkLayerControls: bool, applyRateControls: bool, applyReputationControls: bool, applySlowPostControls: bool>>, settingsLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onboardings/($onboardingId)/settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify onboarding settings
#
# PUT /onboardings/{onboardingId}/settings
# Docs: https://techdocs.akamai.com/application-security/reference/put-onboarding-settings — See documentation for this operation in Akamai's Application Security API
# operationId: put-onboarding-settings
# --certificate shape: {adminContact: record, certificateType: "DEFAULT"|"CUSTOM_EXISTING"|"CUSTOM_NEW", commonName?: string, enrollmentId?: int, enrollmentLink?: string}
# --delivery shape: {origins: list}
# --security shape: {cloneVersion?: int, configId?: int, configLink?: string, configName?: string, configType: "NEW"|"EXISTING", evalRequired?: bool, policyId?: string, policyLink?: string, policyName?: string, policyType: "NEW"|"EXISTING", protections: record}
export def "onboardings-settings put-onboarding-settings" [
  onboardingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  certificate: record # The certificate settings to secure your site. — shape: {adminContact: record, certificateType: "DEFAULT"|"CUSTOM_EXISTING"|"CUSTOM_NEW", commonName?: string, enrollmentId?: int, enrollmentLink?: string}
  delivery: record # The delivery settings for your site traffic. — shape: {origins: list}
  onboardingLink: string # The URL to call when you want to access this onboarding at a later time. (format: uri)
  security: record # The security settings for your site. — shape: {cloneVersion?: int, configId?: int, configLink?: string, configName?: string, configType: "NEW"|"EXISTING", evalRequired?: bool, policyId?: string, policyLink?: string, policyName?: string, policyType: "NEW"|"EXISTING", protections: record}
  settingsLink: string # The URL to call to manage onboarding settings after you finishing the initial creation. (format: uri)
]: any -> record<certificate: record<adminContact: record<email: string, firstName: string, lastName: string, phone: string>, certificateType: string, commonName: string, enrollmentId: int, enrollmentLink: string>, delivery: record<origins: list<record>>, onboardingLink: string, security: record<cloneVersion: int, configId: int, configLink: string, configName: string, configType: string, evalRequired: bool, policyId: string, policyLink: string, policyName: string, policyType: string, protections: record<applyApplicationLayerControls: bool, applyBotmanControls: bool, applyNetworkLayerControls: bool, applyRateControls: bool, applyReputationControls: bool, applySlowPostControls: bool>>, settingsLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onboardings/($onboardingId)/settings" $qp)
  let body = {certificate: $certificate, delivery: $delivery, onboardingLink: $onboardingLink, security: $security, settingsLink: $settingsLink} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get SIEM versions
#
# GET /siem-definitions
# Docs: https://techdocs.akamai.com/application-security/reference/get-siem-definitions — See documentation for this operation in Akamai's Application Security API
# operationId: get-siem-definitions
export def "siem-definitions get-siem-definitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<siemDefinitions: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/siem-definitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
