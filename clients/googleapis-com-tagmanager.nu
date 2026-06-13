# Auto-generated client for Tag Manager API vv2
# Source: https://api.apis.guru/v2/specs/googleapis.com/tagmanager/v2/openapi.json
# Auth: --token flag or $env.TAG_MANAGER_API_TOKEN

const BASE_URL = "https://tagmanager.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TAG_MANAGER_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://tagmanager.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def type-completer [] { ["latest" "live" "user" "workspace"] }
def tagFiringOption-completer [] { ["oncePerEvent" "oncePerLoad" "tagFiringOptionUnspecified" "unlimited"] }
def type-completer-1 [] { ["always" "ampClick" "ampScroll" "ampTimer" "ampVisibility" "click" "consentInit" "customEvent" "domReady" "elementVisibility" "eventTypeUnspecified" "firebaseAppException" "firebaseAppUpdate" "firebaseCampaign" "firebaseFirstOpen" "firebaseInAppPurchase" "firebaseNotificationDismiss" "firebaseNotificationForeground" "firebaseNotificationOpen" "firebaseNotificationReceive" "firebaseOsUpdate" "firebaseSessionStart" "firebaseUserEngagement" "formSubmission" "historyChange" "init" "jsError" "linkClick" "pageview" "scrollDepth" "serverPageview" "timer" "triggerGroup" "windowLoaded" "youTubeVideo"] }
def type-completer-2 [] { ["advertiserId" "advertisingTrackingEnabled" "ampBrowserLanguage" "ampCanonicalHost" "ampCanonicalPath" "ampCanonicalUrl" "ampClientId" "ampClientMaxScrollX" "ampClientMaxScrollY" "ampClientScreenHeight" "ampClientScreenWidth" "ampClientScrollX" "ampClientScrollY" "ampClientTimestamp" "ampClientTimezone" "ampGtmEvent" "ampPageDownloadTime" "ampPageLoadTime" "ampPageViewId" "ampReferrer" "ampTitle" "ampTotalEngagedTime" "appId" "appName" "appVersionCode" "appVersionName" "builtInVariableTypeUnspecified" "clickClasses" "clickElement" "clickId" "clickTarget" "clickText" "clickUrl" "clientName" "containerId" "containerVersion" "debugMode" "deviceName" "elementVisibilityFirstTime" "elementVisibilityRatio" "elementVisibilityRecentTime" "elementVisibilityTime" "environmentName" "errorLine" "errorMessage" "errorUrl" "event" "eventName" "firebaseEventParameterCampaign" "firebaseEventParameterCampaignAclid" "firebaseEventParameterCampaignAnid" "firebaseEventParameterCampaignClickTimestamp" "firebaseEventParameterCampaignContent" "firebaseEventParameterCampaignCp1" "firebaseEventParameterCampaignGclid" "firebaseEventParameterCampaignSource" "firebaseEventParameterCampaignTerm" "firebaseEventParameterCurrency" "firebaseEventParameterDynamicLinkAcceptTime" "firebaseEventParameterDynamicLinkLinkid" "firebaseEventParameterNotificationMessageDeviceTime" "firebaseEventParameterNotificationMessageId" "firebaseEventParameterNotificationMessageName" "firebaseEventParameterNotificationMessageTime" "firebaseEventParameterNotificationTopic" "firebaseEventParameterPreviousAppVersion" "firebaseEventParameterPreviousOsVersion" "firebaseEventParameterPrice" "firebaseEventParameterProductId" "firebaseEventParameterQuantity" "firebaseEventParameterValue" "firstPartyServingUrl" "formClasses" "formElement" "formId" "formTarget" "formText" "formUrl" "historySource" "htmlId" "language" "newHistoryFragment" "newHistoryState" "newHistoryUrl" "oldHistoryFragment" "oldHistoryState" "oldHistoryUrl" "osVersion" "pageHostname" "pagePath" "pageUrl" "platform" "queryString" "randomNumber" "referrer" "requestMethod" "requestPath" "resolution" "scrollDepthDirection" "scrollDepthThreshold" "scrollDepthUnits" "sdkVersion" "serverPageLocationHostname" "serverPageLocationPath" "serverPageLocationUrl" "videoCurrentTime" "videoDuration" "videoPercent" "videoProvider" "videoStatus" "videoTitle" "videoUrl" "videoVisible" "visitorRegion"] }
def settingSource-completer [] { ["current" "other" "settingSourceUnspecified"] }
def changeStatus-completer [] { ["added" "changeStatusUnspecified" "deleted" "none" "updated"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "tagmanager-accounts tagmanageraccountslist" } } | get name | first)
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

# Lists all GTM Accounts that a user has access to.
#
# GET /tagmanager/v2/accounts
# operationId: tagmanager.accounts.list
export def "tagmanager-accounts tagmanageraccountslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --includeGoogleTags: oneof<nothing, bool> # Also retrieve accounts associated with Google Tag when true.
  --pageToken: string # Continuation token for fetching the next page of results.
]: nothing -> record<account: table<accountId: string, features: record, fingerprint: string, name: string, path: string, shareData: bool, tagManagerUrl: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "includeGoogleTags" $includeGoogleTags "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tagmanager/v2/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Looks up a Container by destination ID.
#
# GET /tagmanager/v2/accounts/containers:lookup
# operationId: tagmanager.accounts.containers.lookup
export def "tagmanager-accounts-containers-lookup tagmanageraccountscontainerslookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --destinationId: string # Destination ID linked to a GTM Container, e.g. AW-123456789. Example: accounts/containers:lookup?destination_id={destination_id}.
]: nothing -> record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "destinationId" $destinationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tagmanager/v2/accounts/containers:lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the enabled Built-In Variables of a GTM Container.
#
# GET /tagmanager/v2/{parent}/built_in_variables
# operationId: tagmanager.accounts.containers.workspaces.built_in_variables.list
export def "tagmanager-built-in-variables variableslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageToken: string # Continuation token for fetching the next page of results.
]: nothing -> record<builtInVariable: table<accountId: string, containerId: string, name: string, path: string, type: string, workspaceId: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/built_in_variables" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates one or more GTM Built-In Variables.
#
# POST /tagmanager/v2/{parent}/built_in_variables
# operationId: tagmanager.accounts.containers.workspaces.built_in_variables.create
export def "tagmanager-built-in-variables variablescreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --type: list # The types of built-in variables to enable.
]: nothing -> record<builtInVariable: table<accountId: string, containerId: string, name: string, path: string, type: string, workspaceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "type" $type "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/built_in_variables" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all GTM Clients of a GTM container workspace.
#
# GET /tagmanager/v2/{parent}/clients
# operationId: tagmanager.accounts.containers.workspaces.clients.list
export def "tagmanager-clients tagmanageraccountscontainersworkspacesclientslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageToken: string # Continuation token for fetching the next page of results.
]: nothing -> record<client: table<accountId: string, clientId: string, containerId: string, fingerprint: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, priority: int, tagManagerUrl: string, type: string, workspaceId: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/clients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a GTM Client.
#
# POST /tagmanager/v2/{parent}/clients
# operationId: tagmanager.accounts.containers.workspaces.clients.create
# --parameter item shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
export def "tagmanager-clients tagmanageraccountscontainersworkspacesclientscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --accountId: string # GTM Account ID.
  --clientId: string # The Client ID uniquely identifies the GTM client.
  --containerId: string # GTM Container ID.
  --fingerprint: string # The fingerprint of the GTM Client as computed at storage time. This value is recomputed whenever the client is modified.
  --name: string # Client display name. @mutable tagmanager.accounts.containers.workspaces.clients.create @mutable tagmanager.accounts.containers.workspaces.clients.update
  --notes: string # User notes on how to apply this tag in the container. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --parameter: list # The client's parameters. @mutable tagmanager.accounts.containers.workspaces.clients.create @mutable tagmanager.accounts.containers.workspaces.clients.update — item shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --parentFolderId: string # Parent folder id.
  --path: string # GTM client's API relative path.
  --priority: int # Priority determines relative firing order. @mutable tagmanager.accounts.containers.workspaces.clients.create @mutable tagmanager.accounts.containers.workspaces.clients.update (format: int32)
  --tagManagerUrl: string # Auto generated link to the tag manager UI
  --type: string # Client type. @mutable tagmanager.accounts.containers.workspaces.clients.create @mutable tagmanager.accounts.containers.workspaces.clients.update
  --workspaceId: string # GTM Workspace ID.
]: any -> record<accountId: string, clientId: string, containerId: string, fingerprint: string, name: string, notes: string, parameter: table<key: string, list: list, map: list, type: string, value: string>, parentFolderId: string, path: string, priority: int, tagManagerUrl: string, type: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/clients" $qp)
  let body = {accountId: $accountId, clientId: $clientId, containerId: $containerId, fingerprint: $fingerprint, name: $name, notes: $notes, parameter: $parameter, parentFolderId: $parentFolderId, path: $path, priority: $priority, tagManagerUrl: $tagManagerUrl, type: $type, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all Containers that belongs to a GTM Account.
#
# GET /tagmanager/v2/{parent}/containers
# operationId: tagmanager.accounts.containers.list
export def "tagmanager-containers tagmanageraccountscontainerslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageToken: string # Continuation token for fetching the next page of results.
]: nothing -> record<container: table<accountId: string, containerId: string, domainName: list, features: record, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list, tagManagerUrl: string, taggingServerUrls: list, usageContext: list>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/containers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Container.
#
# POST /tagmanager/v2/{parent}/containers
# operationId: tagmanager.accounts.containers.create
# --features shape: {supportBuiltInVariables?: bool, supportClients?: bool, supportEnvironments?: bool, supportFolders?: bool, supportGtagConfigs?: bool, supportTags?: bool, supportTemplates?: bool, supportTriggers?: bool, supportUserPermissions?: bool, supportVariables?: bool, supportVersions?: bool, supportWorkspaces?: bool, supportZones?: bool}
export def "tagmanager-containers tagmanageraccountscontainerscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --accountId: string # GTM Account ID.
  --containerId: string # The Container ID uniquely identifies the GTM Container.
  --domainName: list # List of domain names associated with the Container. @mutable tagmanager.accounts.containers.create @mutable tagmanager.accounts.containers.update
  --features: record # shape: {supportBuiltInVariables?: bool, supportClients?: bool, supportEnvironments?: bool, supportFolders?: bool, supportGtagConfigs?: bool, supportTags?: bool, supportTemplates?: bool, supportTriggers?: bool, supportUserPermissions?: bool, supportVariables?: bool, supportVersions?: bool, supportWorkspaces?: bool, supportZones?: bool}
  --fingerprint: string # The fingerprint of the GTM Container as computed at storage time. This value is recomputed whenever the account is modified.
  --name: string # Container display name. @mutable tagmanager.accounts.containers.create @mutable tagmanager.accounts.containers.update
  --notes: string # Container Notes. @mutable tagmanager.accounts.containers.create @mutable tagmanager.accounts.containers.update
  --path: string # GTM Container's API relative path.
  --publicId: string # Container Public ID.
  --tagIds: list # All Tag IDs that refer to this Container.
  --tagManagerUrl: string # Auto generated link to the tag manager UI
  --taggingServerUrls: list # List of server-side container URLs for the Container. If multiple URLs are provided, all URL paths must match. @mutable tagmanager.accounts.containers.create @mutable tagmanager.accounts.containers.update
  --usageContext: list # List of Usage Contexts for the Container. Valid values include: web, android, or ios. @mutable tagmanager.accounts.containers.create @mutable tagmanager.accounts.containers.update
]: any -> record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/containers" $qp)
  let body = {accountId: $accountId, containerId: $containerId, domainName: $domainName, features: $features, fingerprint: $fingerprint, name: $name, notes: $notes, path: $path, publicId: $publicId, tagIds: $tagIds, tagManagerUrl: $tagManagerUrl, taggingServerUrls: $taggingServerUrls, usageContext: $usageContext} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all Destinations linked to a GTM Container.
#
# GET /tagmanager/v2/{parent}/destinations
# operationId: tagmanager.accounts.containers.destinations.list
export def "tagmanager-destinations tagmanageraccountscontainersdestinationslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<destination: table<accountId: string, containerId: string, destinationId: string, destinationLinkId: string, fingerprint: string, name: string, path: string, tagManagerUrl: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/destinations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a Destination to this Container and removes it from the Container to which it is currently linked.
#
# POST /tagmanager/v2/{parent}/destinations:link
# operationId: tagmanager.accounts.containers.destinations.link
export def "tagmanager-destinations-link tagmanageraccountscontainersdestinationslink" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --allowUserPermissionFeatureUpdate: oneof<nothing, bool> # Must be set to true to allow features.user_permissions to change from false to true. If this operation causes an update but this bit is false, the operation will fail.
  --destinationId: string # Destination ID to be linked to the current container.
]: nothing -> record<accountId: string, containerId: string, destinationId: string, destinationLinkId: string, fingerprint: string, name: string, path: string, tagManagerUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "allowUserPermissionFeatureUpdate" $allowUserPermissionFeatureUpdate "scalar") (serialize-qp "destinationId" $destinationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/destinations:link" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all GTM Environments of a GTM Container.
#
# GET /tagmanager/v2/{parent}/environments
# operationId: tagmanager.accounts.containers.environments.list
export def "tagmanager-environments tagmanageraccountscontainersenvironmentslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageToken: string # Continuation token for fetching the next page of results.
]: nothing -> record<environment: table<accountId: string, authorizationCode: string, authorizationTimestamp: string, containerId: string, containerVersionId: string, description: string, enableDebug: bool, environmentId: string, fingerprint: string, name: string, path: string, tagManagerUrl: string, type: string, url: string, workspaceId: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/environments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a GTM Environment.
#
# POST /tagmanager/v2/{parent}/environments
# operationId: tagmanager.accounts.containers.environments.create
export def "tagmanager-environments tagmanageraccountscontainersenvironmentscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --accountId: string # GTM Account ID.
  --authorizationCode: string # The environment authorization code.
  --authorizationTimestamp: string # The last update time-stamp for the authorization code. (format: google-datetime)
  --containerId: string # GTM Container ID.
  --containerVersionId: string # Represents a link to a container version.
  --description: string # The environment description. Can be set or changed only on USER type environments. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --enableDebug: oneof<nothing, bool> # Whether or not to enable debug by default for the environment. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --environmentId: string # GTM Environment ID uniquely identifies the GTM Environment.
  --fingerprint: string # The fingerprint of the GTM environment as computed at storage time. This value is recomputed whenever the environment is modified.
  --name: string # The environment display name. Can be set or changed only on USER type environments. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --path: string # GTM Environment's API relative path.
  --tagManagerUrl: string # Auto generated link to the tag manager UI
  --type: string@type-completer # The type of this environment.
  --body-url: string # Default preview page url for the environment. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --workspaceId: string # Represents a link to a quick preview of a workspace.
]: any -> record<accountId: string, authorizationCode: string, authorizationTimestamp: string, containerId: string, containerVersionId: string, description: string, enableDebug: bool, environmentId: string, fingerprint: string, name: string, path: string, tagManagerUrl: string, type: string, url: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/environments" $qp)
  let body = {accountId: $accountId, authorizationCode: $authorizationCode, authorizationTimestamp: $authorizationTimestamp, containerId: $containerId, containerVersionId: $containerVersionId, description: $description, enableDebug: $enableDebug, environmentId: $environmentId, fingerprint: $fingerprint, name: $name, path: $path, tagManagerUrl: $tagManagerUrl, type: $type, url: $body_url, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all GTM Folders of a Container.
#
# GET /tagmanager/v2/{parent}/folders
# operationId: tagmanager.accounts.containers.workspaces.folders.list
export def "tagmanager-folders tagmanageraccountscontainersworkspacesfolderslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageToken: string # Continuation token for fetching the next page of results.
]: nothing -> record<folder: table<accountId: string, containerId: string, fingerprint: string, folderId: string, name: string, notes: string, path: string, tagManagerUrl: string, workspaceId: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/folders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a GTM Folder.
#
# POST /tagmanager/v2/{parent}/folders
# operationId: tagmanager.accounts.containers.workspaces.folders.create
export def "tagmanager-folders tagmanageraccountscontainersworkspacesfolderscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --accountId: string # GTM Account ID.
  --containerId: string # GTM Container ID.
  --fingerprint: string # The fingerprint of the GTM Folder as computed at storage time. This value is recomputed whenever the folder is modified.
  --folderId: string # The Folder ID uniquely identifies the GTM Folder.
  --name: string # Folder display name. @mutable tagmanager.accounts.containers.workspaces.folders.create @mutable tagmanager.accounts.containers.workspaces.folders.update
  --notes: string # User notes on how to apply this folder in the container. @mutable tagmanager.accounts.containers.workspaces.folders.create @mutable tagmanager.accounts.containers.workspaces.folders.update
  --path: string # GTM Folder's API relative path.
  --tagManagerUrl: string # Auto generated link to the tag manager UI
  --workspaceId: string # GTM Workspace ID.
]: any -> record<accountId: string, containerId: string, fingerprint: string, folderId: string, name: string, notes: string, path: string, tagManagerUrl: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/folders" $qp)
  let body = {accountId: $accountId, containerId: $containerId, fingerprint: $fingerprint, folderId: $folderId, name: $name, notes: $notes, path: $path, tagManagerUrl: $tagManagerUrl, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all Google tag configs in a Container.
#
# GET /tagmanager/v2/{parent}/gtag_config
# operationId: tagmanager.accounts.containers.workspaces.gtag_config.list
export def "tagmanager-gtag-config configlist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageToken: string # Continuation token for fetching the next page of results.
]: nothing -> record<gtagConfig: table<accountId: string, containerId: string, fingerprint: string, gtagConfigId: string, parameter: list, path: string, tagManagerUrl: string, type: string, workspaceId: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/gtag_config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Google tag config.
#
# POST /tagmanager/v2/{parent}/gtag_config
# operationId: tagmanager.accounts.containers.workspaces.gtag_config.create
# --parameter item shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
export def "tagmanager-gtag-config configcreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --accountId: string # Google tag account ID.
  --containerId: string # Google tag container ID.
  --fingerprint: string # The fingerprint of the Google tag config as computed at storage time. This value is recomputed whenever the config is modified.
  --gtagConfigId: string # The ID uniquely identifies the Google tag config.
  --parameter: list # The Google tag config's parameters. @mutable tagmanager.accounts.containers.workspaces.gtag_config.create @mutable tagmanager.accounts.containers.workspaces.gtag_config.update — item shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --path: string # Google tag config's API relative path.
  --tagManagerUrl: string # Auto generated link to the tag manager UI
  --type: string # Google tag config type. @required tagmanager.accounts.containers.workspaces.gtag_config.create @required tagmanager.accounts.containers.workspaces.gtag_config.update @mutable tagmanager.accounts.containers.workspaces.gtag_config.create @mutable tagmanager.accounts.containers.workspaces.gtag_config.update
  --workspaceId: string # Google tag workspace ID. Only used by GTM containers. Set to 0 otherwise.
]: any -> record<accountId: string, containerId: string, fingerprint: string, gtagConfigId: string, parameter: table<key: string, list: list, map: list, type: string, value: string>, path: string, tagManagerUrl: string, type: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/gtag_config" $qp)
  let body = {accountId: $accountId, containerId: $containerId, fingerprint: $fingerprint, gtagConfigId: $gtagConfigId, parameter: $parameter, path: $path, tagManagerUrl: $tagManagerUrl, type: $type, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all GTM Tags of a Container.
#
# GET /tagmanager/v2/{parent}/tags
# operationId: tagmanager.accounts.containers.workspaces.tags.list
export def "tagmanager-tags tagmanageraccountscontainersworkspacestagslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageToken: string # Continuation token for fetching the next page of results.
]: nothing -> record<nextPageToken: string, tag: table<accountId: string, blockingRuleId: list, blockingTriggerId: list, consentSettings: record, containerId: string, fingerprint: string, firingRuleId: list, firingTriggerId: list, liveOnly: bool, monitoringMetadata: record, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, paused: bool, priority: record, scheduleEndMs: string, scheduleStartMs: string, setupTag: list, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: list, type: string, workspaceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a GTM Tag.
#
# POST /tagmanager/v2/{parent}/tags
# operationId: tagmanager.accounts.containers.workspaces.tags.create
# --consentSettings shape: {consentStatus?: "notSet"|"notNeeded"|"needed", consentType?: record}
# --monitoringMetadata shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
# --parameter item shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
# --priority shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
# --setupTag item shape: {stopOnSetupFailure?: bool, tagName?: string}
# --teardownTag item shape: {stopTeardownOnFailure?: bool, tagName?: string}
export def "tagmanager-tags tagmanageraccountscontainersworkspacestagscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --accountId: string # GTM Account ID.
  --blockingRuleId: list # Blocking rule IDs. If any of the listed rules evaluate to true, the tag will not fire. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --blockingTriggerId: list # Blocking trigger IDs. If any of the listed triggers evaluate to true, the tag will not fire. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --consentSettings: record # shape: {consentStatus?: "notSet"|"notNeeded"|"needed", consentType?: record}
  --containerId: string # GTM Container ID.
  --fingerprint: string # The fingerprint of the GTM Tag as computed at storage time. This value is recomputed whenever the tag is modified.
  --firingRuleId: list # Firing rule IDs. A tag will fire when any of the listed rules are true and all of its blockingRuleIds (if any specified) are false. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --firingTriggerId: list # Firing trigger IDs. A tag will fire when any of the listed triggers are true and all of its blockingTriggerIds (if any specified) are false. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --liveOnly: oneof<nothing, bool> # If set to true, this tag will only fire in the live environment (e.g. not in preview or debug mode). @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --monitoringMetadata: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --monitoringMetadataTagNameKey: string # If non-empty, then the tag display name will be included in the monitoring metadata map using the key specified. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --name: string # Tag display name. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --notes: string # User notes on how to apply this tag in the container. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --parameter: list # The tag's parameters. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update — item shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --parentFolderId: string # Parent folder id.
  --path: string # GTM Tag's API relative path.
  --paused: oneof<nothing, bool> # Indicates whether the tag is paused, which prevents the tag from firing. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --priority: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --scheduleEndMs: string # The end timestamp in milliseconds to schedule a tag. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update (format: int64)
  --scheduleStartMs: string # The start timestamp in milliseconds to schedule a tag. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update (format: int64)
  --setupTag: list # The list of setup tags. Currently we only allow one. — item shape: {stopOnSetupFailure?: bool, tagName?: string}
  --tagFiringOption: string@tagFiringOption-completer # Option to fire this tag.
  --tagId: string # The Tag ID uniquely identifies the GTM Tag.
  --tagManagerUrl: string # Auto generated link to the tag manager UI
  --teardownTag: list # The list of teardown tags. Currently we only allow one. — item shape: {stopTeardownOnFailure?: bool, tagName?: string}
  --type: string # GTM Tag Type. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --workspaceId: string # GTM Workspace ID.
]: any -> record<accountId: string, blockingRuleId: list<string>, blockingTriggerId: list<string>, consentSettings: record<consentStatus: string, consentType: record<key: string, list: list, map: list, type: string, value: string>>, containerId: string, fingerprint: string, firingRuleId: list<string>, firingTriggerId: list<string>, liveOnly: bool, monitoringMetadata: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: table<key: string, list: list, map: list, type: string, value: string>, parentFolderId: string, path: string, paused: bool, priority: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, scheduleEndMs: string, scheduleStartMs: string, setupTag: table<stopOnSetupFailure: bool, tagName: string>, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: table<stopTeardownOnFailure: bool, tagName: string>, type: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/tags" $qp)
  let body = {accountId: $accountId, blockingRuleId: $blockingRuleId, blockingTriggerId: $blockingTriggerId, consentSettings: $consentSettings, containerId: $containerId, fingerprint: $fingerprint, firingRuleId: $firingRuleId, firingTriggerId: $firingTriggerId, liveOnly: $liveOnly, monitoringMetadata: $monitoringMetadata, monitoringMetadataTagNameKey: $monitoringMetadataTagNameKey, name: $name, notes: $notes, parameter: $parameter, parentFolderId: $parentFolderId, path: $path, paused: $paused, priority: $priority, scheduleEndMs: $scheduleEndMs, scheduleStartMs: $scheduleStartMs, setupTag: $setupTag, tagFiringOption: $tagFiringOption, tagId: $tagId, tagManagerUrl: $tagManagerUrl, teardownTag: $teardownTag, type: $type, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all GTM Templates of a GTM container workspace.
#
# GET /tagmanager/v2/{parent}/templates
# operationId: tagmanager.accounts.containers.workspaces.templates.list
export def "tagmanager-templates tagmanageraccountscontainersworkspacestemplateslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageToken: string # Continuation token for fetching the next page of results.
]: nothing -> record<nextPageToken: string, template: table<accountId: string, containerId: string, fingerprint: string, galleryReference: record, name: string, path: string, tagManagerUrl: string, templateData: string, templateId: string, workspaceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a GTM Custom Template.
#
# POST /tagmanager/v2/{parent}/templates
# operationId: tagmanager.accounts.containers.workspaces.templates.create
# --galleryReference shape: {host?: string, isModified?: bool, owner?: string, repository?: string, signature?: string, version?: string}
export def "tagmanager-templates tagmanageraccountscontainersworkspacestemplatescreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --accountId: string # GTM Account ID.
  --containerId: string # GTM Container ID.
  --fingerprint: string # The fingerprint of the GTM Custom Template as computed at storage time. This value is recomputed whenever the template is modified.
  --galleryReference: record # Represents the link between a custom template and an entry on the Community Template Gallery site. — shape: {host?: string, isModified?: bool, owner?: string, repository?: string, signature?: string, version?: string}
  --name: string # Custom Template display name.
  --path: string # GTM Custom Template's API relative path.
  --tagManagerUrl: string # Auto generated link to the tag manager UI
  --templateData: string # The custom template in text format.
  --templateId: string # The Custom Template ID uniquely identifies the GTM custom template.
  --workspaceId: string # GTM Workspace ID.
]: any -> record<accountId: string, containerId: string, fingerprint: string, galleryReference: record<host: string, isModified: bool, owner: string, repository: string, signature: string, version: string>, name: string, path: string, tagManagerUrl: string, templateData: string, templateId: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/templates" $qp)
  let body = {accountId: $accountId, containerId: $containerId, fingerprint: $fingerprint, galleryReference: $galleryReference, name: $name, path: $path, tagManagerUrl: $tagManagerUrl, templateData: $templateData, templateId: $templateId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all GTM Triggers of a Container.
#
# GET /tagmanager/v2/{parent}/triggers
# operationId: tagmanager.accounts.containers.workspaces.triggers.list
export def "tagmanager-triggers tagmanageraccountscontainersworkspacestriggerslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageToken: string # Continuation token for fetching the next page of results.
]: nothing -> record<nextPageToken: string, trigger: table<accountId: string, autoEventFilter: list, checkValidation: record, containerId: string, continuousTimeMinMilliseconds: record, customEventFilter: list, eventName: record, filter: list, fingerprint: string, horizontalScrollPercentageList: record, interval: record, intervalSeconds: record, limit: record, maxTimerLengthSeconds: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, selector: record, tagManagerUrl: string, totalTimeMinMilliseconds: record, triggerId: string, type: string, uniqueTriggerId: record, verticalScrollPercentageList: record, visibilitySelector: record, visiblePercentageMax: record, visiblePercentageMin: record, waitForTags: record, waitForTagsTimeout: record, workspaceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/triggers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a GTM Trigger.
#
# POST /tagmanager/v2/{parent}/triggers
# operationId: tagmanager.accounts.containers.workspaces.triggers.create
# --autoEventFilter item shape: {parameter?: list, type?: "conditionTypeUnspecified"|"equals"|"contains"|"startsWith"|"endsWith"|"matchRegex"|"greater"|"greaterOrEquals"|"less"|"lessOrEquals"|"cssSelector"|"urlMatches"}
# --checkValidation shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
# --continuousTimeMinMilliseconds shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
# --customEventFilter item shape: {parameter?: list, type?: "conditionTypeUnspecified"|"equals"|"contains"|"startsWith"|"endsWith"|"matchRegex"|"greater"|"greaterOrEquals"|"less"|"lessOrEquals"|"cssSelector"|"urlMatches"}
# --eventName shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
# --filter item shape: {parameter?: list, type?: "conditionTypeUnspecified"|"equals"|"contains"|"startsWith"|"endsWith"|"matchRegex"|"greater"|"greaterOrEquals"|"less"|"lessOrEquals"|"cssSelector"|"urlMatches"}
# --horizontalScrollPercentageList shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
# --interval shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
# --intervalSeconds shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
# --limit shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
# --maxTimerLengthSeconds shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
# --parameter item shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
# --selector shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
# --totalTimeMinMilliseconds shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
# --uniqueTriggerId shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
# --verticalScrollPercentageList shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
# --visibilitySelector shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
# --visiblePercentageMax shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
# --visiblePercentageMin shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
# --waitForTags shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
# --waitForTagsTimeout shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
export def "tagmanager-triggers tagmanageraccountscontainersworkspacestriggerscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --accountId: string # GTM Account ID.
  --autoEventFilter: list # Used in the case of auto event tracking. @mutable tagmanager.accounts.containers.workspaces.triggers.create @mutable tagmanager.accounts.containers.workspaces.triggers.update — item shape: {parameter?: list, type?: "conditionTypeUnspecified"|"equals"|"contains"|"startsWith"|"endsWith"|"matchRegex"|"greater"|"greaterOrEquals"|"less"|"lessOrEquals"|"cssSelector"|"urlMatches"}
  --checkValidation: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --containerId: string # GTM Container ID.
  --continuousTimeMinMilliseconds: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --customEventFilter: list # Used in the case of custom event, which is fired iff all Conditions are true. @mutable tagmanager.accounts.containers.workspaces.triggers.create @mutable tagmanager.accounts.containers.workspaces.triggers.update — item shape: {parameter?: list, type?: "conditionTypeUnspecified"|"equals"|"contains"|"startsWith"|"endsWith"|"matchRegex"|"greater"|"greaterOrEquals"|"less"|"lessOrEquals"|"cssSelector"|"urlMatches"}
  --eventName: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --filter: list # The trigger will only fire iff all Conditions are true. @mutable tagmanager.accounts.containers.workspaces.triggers.create @mutable tagmanager.accounts.containers.workspaces.triggers.update — item shape: {parameter?: list, type?: "conditionTypeUnspecified"|"equals"|"contains"|"startsWith"|"endsWith"|"matchRegex"|"greater"|"greaterOrEquals"|"less"|"lessOrEquals"|"cssSelector"|"urlMatches"}
  --fingerprint: string # The fingerprint of the GTM Trigger as computed at storage time. This value is recomputed whenever the trigger is modified.
  --horizontalScrollPercentageList: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --interval: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --intervalSeconds: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --limit: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --maxTimerLengthSeconds: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --name: string # Trigger display name. @mutable tagmanager.accounts.containers.workspaces.triggers.create @mutable tagmanager.accounts.containers.workspaces.triggers.update
  --notes: string # User notes on how to apply this trigger in the container. @mutable tagmanager.accounts.containers.workspaces.triggers.create @mutable tagmanager.accounts.containers.workspaces.triggers.update
  --parameter: list # Additional parameters. @mutable tagmanager.accounts.containers.workspaces.triggers.create @mutable tagmanager.accounts.containers.workspaces.triggers.update — item shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --parentFolderId: string # Parent folder id.
  --path: string # GTM Trigger's API relative path.
  --selector: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --tagManagerUrl: string # Auto generated link to the tag manager UI
  --totalTimeMinMilliseconds: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --triggerId: string # The Trigger ID uniquely identifies the GTM Trigger.
  --type: string@type-completer-1 # Defines the data layer event that causes this trigger. @mutable tagmanager.accounts.containers.workspaces.triggers.create @mutable tagmanager.accounts.containers.workspaces.triggers.update
  --uniqueTriggerId: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --verticalScrollPercentageList: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --visibilitySelector: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --visiblePercentageMax: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --visiblePercentageMin: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --waitForTags: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --waitForTagsTimeout: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --workspaceId: string # GTM Workspace ID.
]: any -> record<accountId: string, autoEventFilter: table<parameter: list, type: string>, checkValidation: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, containerId: string, continuousTimeMinMilliseconds: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, customEventFilter: table<parameter: list, type: string>, eventName: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, filter: table<parameter: list, type: string>, fingerprint: string, horizontalScrollPercentageList: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, interval: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, intervalSeconds: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, limit: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, maxTimerLengthSeconds: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, name: string, notes: string, parameter: table<key: string, list: list, map: list, type: string, value: string>, parentFolderId: string, path: string, selector: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, tagManagerUrl: string, totalTimeMinMilliseconds: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, triggerId: string, type: string, uniqueTriggerId: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, verticalScrollPercentageList: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, visibilitySelector: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, visiblePercentageMax: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, visiblePercentageMin: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, waitForTags: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, waitForTagsTimeout: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/triggers" $qp)
  let body = {accountId: $accountId, autoEventFilter: $autoEventFilter, checkValidation: $checkValidation, containerId: $containerId, continuousTimeMinMilliseconds: $continuousTimeMinMilliseconds, customEventFilter: $customEventFilter, eventName: $eventName, filter: $filter, fingerprint: $fingerprint, horizontalScrollPercentageList: $horizontalScrollPercentageList, interval: $interval, intervalSeconds: $intervalSeconds, limit: $limit, maxTimerLengthSeconds: $maxTimerLengthSeconds, name: $name, notes: $notes, parameter: $parameter, parentFolderId: $parentFolderId, path: $path, selector: $selector, tagManagerUrl: $tagManagerUrl, totalTimeMinMilliseconds: $totalTimeMinMilliseconds, triggerId: $triggerId, type: $type, uniqueTriggerId: $uniqueTriggerId, verticalScrollPercentageList: $verticalScrollPercentageList, visibilitySelector: $visibilitySelector, visiblePercentageMax: $visiblePercentageMax, visiblePercentageMin: $visiblePercentageMin, waitForTags: $waitForTags, waitForTagsTimeout: $waitForTagsTimeout, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all users that have access to the account along with Account and Container user access granted to each of them.
#
# GET /tagmanager/v2/{parent}/user_permissions
# operationId: tagmanager.accounts.user_permissions.list
export def "tagmanager-user-permissions permissionslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageToken: string # Continuation token for fetching the next page of results.
]: nothing -> record<nextPageToken: string, userPermission: table<accountAccess: record, accountId: string, containerAccess: list, emailAddress: string, path: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/user_permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a user's Account & Container access.
#
# POST /tagmanager/v2/{parent}/user_permissions
# operationId: tagmanager.accounts.user_permissions.create
# --accountAccess shape: {permission?: "accountPermissionUnspecified"|"noAccess"|"user"|"admin"}
# --containerAccess item shape: {containerId?: string, permission?: "containerPermissionUnspecified"|"noAccess"|"read"|"edit"|"approve"|"publish"}
export def "tagmanager-user-permissions permissionscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --accountAccess: record # Defines the Google Tag Manager Account access permissions. — shape: {permission?: "accountPermissionUnspecified"|"noAccess"|"user"|"admin"}
  --accountId: string # The Account ID uniquely identifies the GTM Account.
  --containerAccess: list # GTM Container access permissions. @mutable tagmanager.accounts.permissions.create @mutable tagmanager.accounts.permissions.update — item shape: {containerId?: string, permission?: "containerPermissionUnspecified"|"noAccess"|"read"|"edit"|"approve"|"publish"}
  --emailAddress: string # User's email address. @mutable tagmanager.accounts.permissions.create
  --path: string # GTM UserPermission's API relative path.
]: any -> record<accountAccess: record<permission: string>, accountId: string, containerAccess: table<containerId: string, permission: string>, emailAddress: string, path: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/user_permissions" $qp)
  let body = {accountAccess: $accountAccess, accountId: $accountId, containerAccess: $containerAccess, emailAddress: $emailAddress, path: $path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all GTM Variables of a Container.
#
# GET /tagmanager/v2/{parent}/variables
# operationId: tagmanager.accounts.containers.workspaces.variables.list
export def "tagmanager-variables tagmanageraccountscontainersworkspacesvariableslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageToken: string # Continuation token for fetching the next page of results.
]: nothing -> record<nextPageToken: string, variable: table<accountId: string, containerId: string, disablingTriggerId: list, enablingTriggerId: list, fingerprint: string, formatValue: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/variables" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a GTM Variable.
#
# POST /tagmanager/v2/{parent}/variables
# operationId: tagmanager.accounts.containers.workspaces.variables.create
# --formatValue shape: {caseConversionType?: "none"|"lowercase"|"uppercase", convertFalseToValue?: record, convertNullToValue?: record, convertTrueToValue?: record, convertUndefinedToValue?: record}
# --parameter item shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
export def "tagmanager-variables tagmanageraccountscontainersworkspacesvariablescreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --accountId: string # GTM Account ID.
  --containerId: string # GTM Container ID.
  --disablingTriggerId: list # For mobile containers only: A list of trigger IDs for disabling conditional variables; the variable is enabled if one of the enabling trigger is true while all the disabling trigger are false. Treated as an unordered set. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update
  --enablingTriggerId: list # For mobile containers only: A list of trigger IDs for enabling conditional variables; the variable is enabled if one of the enabling triggers is true while all the disabling triggers are false. Treated as an unordered set. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update
  --fingerprint: string # The fingerprint of the GTM Variable as computed at storage time. This value is recomputed whenever the variable is modified.
  --formatValue: record # shape: {caseConversionType?: "none"|"lowercase"|"uppercase", convertFalseToValue?: record, convertNullToValue?: record, convertTrueToValue?: record, convertUndefinedToValue?: record}
  --name: string # Variable display name. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update
  --notes: string # User notes on how to apply this variable in the container. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update
  --parameter: list # The variable's parameters. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update — item shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --parentFolderId: string # Parent folder id.
  --path: string # GTM Variable's API relative path.
  --scheduleEndMs: string # The end timestamp in milliseconds to schedule a variable. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update (format: int64)
  --scheduleStartMs: string # The start timestamp in milliseconds to schedule a variable. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update (format: int64)
  --tagManagerUrl: string # Auto generated link to the tag manager UI
  --type: string # GTM Variable Type. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update
  --variableId: string # The Variable ID uniquely identifies the GTM Variable.
  --workspaceId: string # GTM Workspace ID.
]: any -> record<accountId: string, containerId: string, disablingTriggerId: list<string>, enablingTriggerId: list<string>, fingerprint: string, formatValue: record<caseConversionType: string, convertFalseToValue: record<key: string, list: list, map: list, type: string, value: string>, convertNullToValue: record<key: string, list: list, map: list, type: string, value: string>, convertTrueToValue: record<key: string, list: list, map: list, type: string, value: string>, convertUndefinedToValue: record<key: string, list: list, map: list, type: string, value: string>>, name: string, notes: string, parameter: table<key: string, list: list, map: list, type: string, value: string>, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/variables" $qp)
  let body = {accountId: $accountId, containerId: $containerId, disablingTriggerId: $disablingTriggerId, enablingTriggerId: $enablingTriggerId, fingerprint: $fingerprint, formatValue: $formatValue, name: $name, notes: $notes, parameter: $parameter, parentFolderId: $parentFolderId, path: $path, scheduleEndMs: $scheduleEndMs, scheduleStartMs: $scheduleStartMs, tagManagerUrl: $tagManagerUrl, type: $type, variableId: $variableId, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all Container Versions of a GTM Container.
#
# GET /tagmanager/v2/{parent}/version_headers
# operationId: tagmanager.accounts.containers.version_headers.list
export def "tagmanager-version-headers headerslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --includeDeleted: oneof<nothing, bool> # Also retrieve deleted (archived) versions when true.
  --pageToken: string # Continuation token for fetching the next page of results.
]: nothing -> record<containerVersionHeader: table<accountId: string, containerId: string, containerVersionId: string, deleted: bool, name: string, numClients: string, numCustomTemplates: string, numGtagConfigs: string, numMacros: string, numRules: string, numTags: string, numTransformations: string, numTriggers: string, numVariables: string, numZones: string, path: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "includeDeleted" $includeDeleted "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/version_headers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the latest container version header
#
# GET /tagmanager/v2/{parent}/version_headers:latest
# operationId: tagmanager.accounts.containers.version_headers.latest
export def "tagmanager-version-headers-latest headerslatest" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<accountId: string, containerId: string, containerVersionId: string, deleted: bool, name: string, numClients: string, numCustomTemplates: string, numGtagConfigs: string, numMacros: string, numRules: string, numTags: string, numTransformations: string, numTriggers: string, numVariables: string, numZones: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/version_headers:latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the live (i.e. published) container version
#
# GET /tagmanager/v2/{parent}/versions:live
# operationId: tagmanager.accounts.containers.versions.live
export def "tagmanager-versions-live tagmanageraccountscontainersversionslive" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<accountId: string, builtInVariable: table<accountId: string, containerId: string, name: string, path: string, type: string, workspaceId: string>, client: table<accountId: string, clientId: string, containerId: string, fingerprint: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, priority: int, tagManagerUrl: string, type: string, workspaceId: string>, container: record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>>, containerId: string, containerVersionId: string, customTemplate: table<accountId: string, containerId: string, fingerprint: string, galleryReference: record, name: string, path: string, tagManagerUrl: string, templateData: string, templateId: string, workspaceId: string>, deleted: bool, description: string, fingerprint: string, folder: table<accountId: string, containerId: string, fingerprint: string, folderId: string, name: string, notes: string, path: string, tagManagerUrl: string, workspaceId: string>, gtagConfig: table<accountId: string, containerId: string, fingerprint: string, gtagConfigId: string, parameter: list, path: string, tagManagerUrl: string, type: string, workspaceId: string>, name: string, path: string, tag: table<accountId: string, blockingRuleId: list, blockingTriggerId: list, consentSettings: record, containerId: string, fingerprint: string, firingRuleId: list, firingTriggerId: list, liveOnly: bool, monitoringMetadata: record, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, paused: bool, priority: record, scheduleEndMs: string, scheduleStartMs: string, setupTag: list, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: list, type: string, workspaceId: string>, tagManagerUrl: string, trigger: table<accountId: string, autoEventFilter: list, checkValidation: record, containerId: string, continuousTimeMinMilliseconds: record, customEventFilter: list, eventName: record, filter: list, fingerprint: string, horizontalScrollPercentageList: record, interval: record, intervalSeconds: record, limit: record, maxTimerLengthSeconds: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, selector: record, tagManagerUrl: string, totalTimeMinMilliseconds: record, triggerId: string, type: string, uniqueTriggerId: record, verticalScrollPercentageList: record, visibilitySelector: record, visiblePercentageMax: record, visiblePercentageMin: record, waitForTags: record, waitForTagsTimeout: record, workspaceId: string>, variable: table<accountId: string, containerId: string, disablingTriggerId: list, enablingTriggerId: list, fingerprint: string, formatValue: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string>, zone: table<accountId: string, boundary: record, childContainer: list, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record, workspaceId: string, zoneId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/versions:live" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all Workspaces that belong to a GTM Container.
#
# GET /tagmanager/v2/{parent}/workspaces
# operationId: tagmanager.accounts.containers.workspaces.list
export def "tagmanager-workspaces tagmanageraccountscontainersworkspaceslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageToken: string # Continuation token for fetching the next page of results.
]: nothing -> record<nextPageToken: string, workspace: table<accountId: string, containerId: string, description: string, fingerprint: string, name: string, path: string, tagManagerUrl: string, workspaceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/workspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Workspace.
#
# POST /tagmanager/v2/{parent}/workspaces
# operationId: tagmanager.accounts.containers.workspaces.create
export def "tagmanager-workspaces tagmanageraccountscontainersworkspacescreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --accountId: string # GTM Account ID.
  --containerId: string # GTM Container ID.
  --description: string # Workspace description. @mutable tagmanager.accounts.containers.workspaces.create @mutable tagmanager.accounts.containers.workspaces.update
  --fingerprint: string # The fingerprint of the GTM Workspace as computed at storage time. This value is recomputed whenever the workspace is modified.
  --name: string # Workspace display name. @mutable tagmanager.accounts.containers.workspaces.create @mutable tagmanager.accounts.containers.workspaces.update
  --path: string # GTM Workspace's API relative path.
  --tagManagerUrl: string # Auto generated link to the tag manager UI
  --workspaceId: string # The Workspace ID uniquely identifies the GTM Workspace.
]: any -> record<accountId: string, containerId: string, description: string, fingerprint: string, name: string, path: string, tagManagerUrl: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/workspaces" $qp)
  let body = {accountId: $accountId, containerId: $containerId, description: $description, fingerprint: $fingerprint, name: $name, path: $path, tagManagerUrl: $tagManagerUrl, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all GTM Zones of a GTM container workspace.
#
# GET /tagmanager/v2/{parent}/zones
# operationId: tagmanager.accounts.containers.workspaces.zones.list
export def "tagmanager-zones tagmanageraccountscontainersworkspaceszoneslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageToken: string # Continuation token for fetching the next page of results.
]: nothing -> record<nextPageToken: string, zone: table<accountId: string, boundary: record, childContainer: list, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record, workspaceId: string, zoneId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/zones" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a GTM Zone.
#
# POST /tagmanager/v2/{parent}/zones
# operationId: tagmanager.accounts.containers.workspaces.zones.create
# --boundary shape: {condition?: list, customEvaluationTriggerId?: list}
# --childContainer item shape: {nickname?: string, publicId?: string}
# --typeRestriction shape: {enable?: bool, whitelistedTypeId?: list}
export def "tagmanager-zones tagmanageraccountscontainersworkspaceszonescreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --accountId: string # GTM Account ID.
  --boundary: record # Represents a Zone's boundaries. — shape: {condition?: list, customEvaluationTriggerId?: list}
  --childContainer: list # Containers that are children of this Zone. — item shape: {nickname?: string, publicId?: string}
  --containerId: string # GTM Container ID.
  --fingerprint: string # The fingerprint of the GTM Zone as computed at storage time. This value is recomputed whenever the zone is modified.
  --name: string # Zone display name.
  --notes: string # User notes on how to apply this zone in the container.
  --path: string # GTM Zone's API relative path.
  --tagManagerUrl: string # Auto generated link to the tag manager UI
  --typeRestriction: record # Represents a Zone's type restrictions. — shape: {enable?: bool, whitelistedTypeId?: list}
  --workspaceId: string # GTM Workspace ID.
  --zoneId: string # The Zone ID uniquely identifies the GTM Zone.
]: any -> record<accountId: string, boundary: record<condition: list<record>, customEvaluationTriggerId: list<string>>, childContainer: table<nickname: string, publicId: string>, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record<enable: bool, whitelistedTypeId: list<string>>, workspaceId: string, zoneId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($parent)/zones" $qp)
  let body = {accountId: $accountId, boundary: $boundary, childContainer: $childContainer, containerId: $containerId, fingerprint: $fingerprint, name: $name, notes: $notes, path: $path, tagManagerUrl: $tagManagerUrl, typeRestriction: $typeRestriction, workspaceId: $workspaceId, zoneId: $zoneId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes a user from the account, revoking access to it and all of its containers.
#
# DELETE /tagmanager/v2/{path}
# operationId: tagmanager.accounts.user_permissions.delete
export def "tagmanager permissionsdelete" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --type: list # The types of built-in variables to delete.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "type" $type "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($path)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a user's Account & Container access.
#
# GET /tagmanager/v2/{path}
# operationId: tagmanager.accounts.user_permissions.get
export def "tagmanager permissionsget" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --containerVersionId: string # The GTM ContainerVersion ID. Specify published to retrieve the currently published version.
]: nothing -> record<accountAccess: record<permission: string>, accountId: string, containerAccess: table<containerId: string, permission: string>, emailAddress: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "containerVersionId" $containerVersionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($path)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a user's Account & Container access.
#
# PUT /tagmanager/v2/{path}
# operationId: tagmanager.accounts.user_permissions.update
# --accountAccess shape: {permission?: "accountPermissionUnspecified"|"noAccess"|"user"|"admin"}
# --containerAccess item shape: {containerId?: string, permission?: "containerPermissionUnspecified"|"noAccess"|"read"|"edit"|"approve"|"publish"}
export def "tagmanager permissionsupdate" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --fingerprint: string # When provided, this fingerprint must match the fingerprint of the zone in storage.
  --accountAccess: record # Defines the Google Tag Manager Account access permissions. — shape: {permission?: "accountPermissionUnspecified"|"noAccess"|"user"|"admin"}
  --accountId: string # The Account ID uniquely identifies the GTM Account.
  --containerAccess: list # GTM Container access permissions. @mutable tagmanager.accounts.permissions.create @mutable tagmanager.accounts.permissions.update — item shape: {containerId?: string, permission?: "containerPermissionUnspecified"|"noAccess"|"read"|"edit"|"approve"|"publish"}
  --emailAddress: string # User's email address. @mutable tagmanager.accounts.permissions.create
  --body-path: string # GTM UserPermission's API relative path.
]: any -> record<accountAccess: record<permission: string>, accountId: string, containerAccess: table<containerId: string, permission: string>, emailAddress: string, path: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "fingerprint" $fingerprint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($path)" $qp)
  let body = {accountAccess: $accountAccess, accountId: $accountId, containerAccess: $containerAccess, emailAddress: $emailAddress, path: $body_path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reverts changes to a GTM Built-In Variables in a GTM Workspace.
#
# POST /tagmanager/v2/{path}/built_in_variables:revert
# operationId: tagmanager.accounts.containers.workspaces.built_in_variables.revert
export def "tagmanager-built-in-variables-revert variablesrevert" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --type: string@type-completer-2 # The type of built-in variable to revert.
]: nothing -> record<enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($path)/built_in_variables:revert" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Finds conflicting and modified entities in the workspace.
#
# GET /tagmanager/v2/{path}/status
# operationId: tagmanager.accounts.containers.workspaces.getStatus
export def "tagmanager-status tagmanageraccountscontainersworkspacesgetStatus" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<mergeConflict: table<entityInBaseVersion: record, entityInWorkspace: record>, workspaceChange: table<changeStatus: string, client: record, folder: record, tag: record, trigger: record, variable: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($path)/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Combines Containers.
#
# POST /tagmanager/v2/{path}:combine
# operationId: tagmanager.accounts.containers.combine
export def "tagmanager tagmanageraccountscontainerscombine" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --allowUserPermissionFeatureUpdate: oneof<nothing, bool> # Must be set to true to allow features.user_permissions to change from false to true. If this operation causes an update but this bit is false, the operation will fail.
  --containerId: string # ID of container that will be merged into the current container.
  --settingSource: string@settingSource-completer # Specify the source of config setting after combine
]: nothing -> record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "allowUserPermissionFeatureUpdate" $allowUserPermissionFeatureUpdate "scalar") (serialize-qp "containerId" $containerId "scalar") (serialize-qp "settingSource" $settingSource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($path):combine" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Container Version from the entities present in the workspace, deletes the workspace, and sets the base container version to the newly created version.
#
# POST /tagmanager/v2/{path}:create_version
# operationId: tagmanager.accounts.containers.workspaces.create_version
export def "tagmanager version" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # The name of the container version to be created.
  --notes: string # The notes of the container version to be created.
]: any -> record<compilerError: bool, containerVersion: record<accountId: string, builtInVariable: list<record>, client: list<record>, container: record<accountId: string, containerId: string, domainName: list, features: record, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list, tagManagerUrl: string, taggingServerUrls: list, usageContext: list>, containerId: string, containerVersionId: string, customTemplate: list<record>, deleted: bool, description: string, fingerprint: string, folder: list<record>, gtagConfig: list<record>, name: string, path: string, tag: list<record>, tagManagerUrl: string, trigger: list<record>, variable: list<record>, zone: list<record>>, newWorkspacePath: string, syncStatus: record<mergeConflict: bool, syncError: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($path):create_version" $qp)
  let body = {name: $name, notes: $notes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all entities in a GTM Folder.
#
# POST /tagmanager/v2/{path}:entities
# operationId: tagmanager.accounts.containers.workspaces.folders.entities
export def "tagmanager tagmanageraccountscontainersworkspacesfoldersentities" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageToken: string # Continuation token for fetching the next page of results.
]: nothing -> record<nextPageToken: string, tag: table<accountId: string, blockingRuleId: list, blockingTriggerId: list, consentSettings: record, containerId: string, fingerprint: string, firingRuleId: list, firingTriggerId: list, liveOnly: bool, monitoringMetadata: record, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, paused: bool, priority: record, scheduleEndMs: string, scheduleStartMs: string, setupTag: list, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: list, type: string, workspaceId: string>, trigger: table<accountId: string, autoEventFilter: list, checkValidation: record, containerId: string, continuousTimeMinMilliseconds: record, customEventFilter: list, eventName: record, filter: list, fingerprint: string, horizontalScrollPercentageList: record, interval: record, intervalSeconds: record, limit: record, maxTimerLengthSeconds: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, selector: record, tagManagerUrl: string, totalTimeMinMilliseconds: record, triggerId: string, type: string, uniqueTriggerId: record, verticalScrollPercentageList: record, visibilitySelector: record, visiblePercentageMax: record, visiblePercentageMin: record, waitForTags: record, waitForTagsTimeout: record, workspaceId: string>, variable: table<accountId: string, containerId: string, disablingTriggerId: list, enablingTriggerId: list, fingerprint: string, formatValue: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($path):entities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Moves entities to a GTM Folder.
#
# POST /tagmanager/v2/{path}:move_entities_to_folder
# operationId: tagmanager.accounts.containers.workspaces.folders.move_entities_to_folder
export def "tagmanager folder" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --tagId: list # The tags to be moved to the folder.
  --triggerId: list # The triggers to be moved to the folder.
  --variableId: list # The variables to be moved to the folder.
  --accountId: string # GTM Account ID.
  --containerId: string # GTM Container ID.
  --fingerprint: string # The fingerprint of the GTM Folder as computed at storage time. This value is recomputed whenever the folder is modified.
  --folderId: string # The Folder ID uniquely identifies the GTM Folder.
  --name: string # Folder display name. @mutable tagmanager.accounts.containers.workspaces.folders.create @mutable tagmanager.accounts.containers.workspaces.folders.update
  --notes: string # User notes on how to apply this folder in the container. @mutable tagmanager.accounts.containers.workspaces.folders.create @mutable tagmanager.accounts.containers.workspaces.folders.update
  --body-path: string # GTM Folder's API relative path.
  --tagManagerUrl: string # Auto generated link to the tag manager UI
  --workspaceId: string # GTM Workspace ID.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "tagId" $tagId "multi") (serialize-qp "triggerId" $triggerId "multi") (serialize-qp "variableId" $variableId "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($path):move_entities_to_folder" $qp)
  let body = {accountId: $accountId, containerId: $containerId, fingerprint: $fingerprint, folderId: $folderId, name: $name, notes: $notes, path: $body_path, tagManagerUrl: $tagManagerUrl, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Move Tag ID out of a Container.
#
# POST /tagmanager/v2/{path}:move_tag_id
# operationId: tagmanager.accounts.containers.move_tag_id
export def "tagmanager id" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --allowUserPermissionFeatureUpdate: oneof<nothing, bool> # Must be set to true to allow features.user_permissions to change from false to true. If this operation causes an update but this bit is false, the operation will fail.
  --copySettings: oneof<nothing, bool> # Whether or not to copy tag settings from this tag to the new tag.
  --copyTermsOfService: oneof<nothing, bool> # Must be set to true to accept all terms of service agreements copied from the current tag to the newly created tag. If this bit is false, the operation will fail.
  --copyUsers: oneof<nothing, bool> # Whether or not to copy users from this tag to the new tag.
  --tagId: string # Tag ID to be removed from the current Container.
  --tagName: string # The name for the newly created tag.
]: nothing -> record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "allowUserPermissionFeatureUpdate" $allowUserPermissionFeatureUpdate "scalar") (serialize-qp "copySettings" $copySettings "scalar") (serialize-qp "copyTermsOfService" $copyTermsOfService "scalar") (serialize-qp "copyUsers" $copyUsers "scalar") (serialize-qp "tagId" $tagId "scalar") (serialize-qp "tagName" $tagName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($path):move_tag_id" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Publishes a Container Version.
#
# POST /tagmanager/v2/{path}:publish
# operationId: tagmanager.accounts.containers.versions.publish
export def "tagmanager tagmanageraccountscontainersversionspublish" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --fingerprint: string # When provided, this fingerprint must match the fingerprint of the container version in storage.
]: nothing -> record<compilerError: bool, containerVersion: record<accountId: string, builtInVariable: list<record>, client: list<record>, container: record<accountId: string, containerId: string, domainName: list, features: record, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list, tagManagerUrl: string, taggingServerUrls: list, usageContext: list>, containerId: string, containerVersionId: string, customTemplate: list<record>, deleted: bool, description: string, fingerprint: string, folder: list<record>, gtagConfig: list<record>, name: string, path: string, tag: list<record>, tagManagerUrl: string, trigger: list<record>, variable: list<record>, zone: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "fingerprint" $fingerprint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($path):publish" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Quick previews a workspace by creating a fake container version from all entities in the provided workspace.
#
# POST /tagmanager/v2/{path}:quick_preview
# operationId: tagmanager.accounts.containers.workspaces.quick_preview
export def "tagmanager preview" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<compilerError: bool, containerVersion: record<accountId: string, builtInVariable: list<record>, client: list<record>, container: record<accountId: string, containerId: string, domainName: list, features: record, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list, tagManagerUrl: string, taggingServerUrls: list, usageContext: list>, containerId: string, containerVersionId: string, customTemplate: list<record>, deleted: bool, description: string, fingerprint: string, folder: list<record>, gtagConfig: list<record>, name: string, path: string, tag: list<record>, tagManagerUrl: string, trigger: list<record>, variable: list<record>, zone: list<record>>, syncStatus: record<mergeConflict: bool, syncError: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($path):quick_preview" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Re-generates the authorization code for a GTM Environment.
#
# POST /tagmanager/v2/{path}:reauthorize
# operationId: tagmanager.accounts.containers.environments.reauthorize
export def "tagmanager tagmanageraccountscontainersenvironmentsreauthorize" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --accountId: string # GTM Account ID.
  --authorizationCode: string # The environment authorization code.
  --authorizationTimestamp: string # The last update time-stamp for the authorization code. (format: google-datetime)
  --containerId: string # GTM Container ID.
  --containerVersionId: string # Represents a link to a container version.
  --description: string # The environment description. Can be set or changed only on USER type environments. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --enableDebug: oneof<nothing, bool> # Whether or not to enable debug by default for the environment. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --environmentId: string # GTM Environment ID uniquely identifies the GTM Environment.
  --fingerprint: string # The fingerprint of the GTM environment as computed at storage time. This value is recomputed whenever the environment is modified.
  --name: string # The environment display name. Can be set or changed only on USER type environments. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --body-path: string # GTM Environment's API relative path.
  --tagManagerUrl: string # Auto generated link to the tag manager UI
  --type: string@type-completer # The type of this environment.
  --body-url: string # Default preview page url for the environment. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --workspaceId: string # Represents a link to a quick preview of a workspace.
]: any -> record<accountId: string, authorizationCode: string, authorizationTimestamp: string, containerId: string, containerVersionId: string, description: string, enableDebug: bool, environmentId: string, fingerprint: string, name: string, path: string, tagManagerUrl: string, type: string, url: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($path):reauthorize" $qp)
  let body = {accountId: $accountId, authorizationCode: $authorizationCode, authorizationTimestamp: $authorizationTimestamp, containerId: $containerId, containerVersionId: $containerVersionId, description: $description, enableDebug: $enableDebug, environmentId: $environmentId, fingerprint: $fingerprint, name: $name, path: $body_path, tagManagerUrl: $tagManagerUrl, type: $type, url: $body_url, workspaceId: $workspaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resolves a merge conflict for a workspace entity by updating it to the resolved entity passed in the request.
#
# POST /tagmanager/v2/{path}:resolve_conflict
# operationId: tagmanager.accounts.containers.workspaces.resolve_conflict
# --client shape: {accountId?: string, clientId?: string, containerId?: string, fingerprint?: string, name?: string, notes?: string, parameter?: list, parentFolderId?: string, path?: string, priority?: int, tagManagerUrl?: string, type?: string, workspaceId?: string}
# --folder shape: {accountId?: string, containerId?: string, fingerprint?: string, folderId?: string, name?: string, notes?: string, path?: string, tagManagerUrl?: string, workspaceId?: string}
# --tag shape: {accountId?: string, blockingRuleId?: list, blockingTriggerId?: list, consentSettings?: record, containerId?: string, fingerprint?: string, firingRuleId?: list, firingTriggerId?: list, liveOnly?: bool, monitoringMetadata?: record, monitoringMetadataTagNameKey?: string, name?: string, notes?: string, parameter?: list, parentFolderId?: string, path?: string, paused?: bool, priority?: record, scheduleEndMs?: string, scheduleStartMs?: string, setupTag?: list, tagFiringOption?: "tagFiringOptionUnspecified"|"unlimited"|"oncePerEvent"|"oncePerLoad", tagId?: string, tagManagerUrl?: string, teardownTag?: list, type?: string, workspaceId?: string}
# --trigger shape: {accountId?: string, autoEventFilter?: list, checkValidation?: record, containerId?: string, continuousTimeMinMilliseconds?: record, customEventFilter?: list, eventName?: record, filter?: list, fingerprint?: string, horizontalScrollPercentageList?: record, interval?: record, intervalSeconds?: record, limit?: record, maxTimerLengthSeconds?: record, name?: string, notes?: string, parameter?: list, parentFolderId?: string, path?: string, selector?: record, tagManagerUrl?: string, totalTimeMinMilliseconds?: record, triggerId?: string, type?: "eventTypeUnspecified"|"pageview"|"domReady"|"windowLoaded"|"customEvent"|"triggerGroup"|"init"|"consentInit"|"serverPageview"|"always"|"firebaseAppException"|"firebaseAppUpdate"|"firebaseCampaign"|"firebaseFirstOpen"|"firebaseInAppPurchase"|"firebaseNotificationDismiss"|"firebaseNotificationForeground"|"firebaseNotificationOpen"|"firebaseNotificationReceive"|"firebaseOsUpdate"|"firebaseSessionStart"|"firebaseUserEngagement"|"formSubmission"|"click"|"linkClick"|"jsError"|"historyChange"|"timer"|"ampClick"|"ampTimer"|"ampScroll"|"ampVisibility"|"youTubeVideo"|"scrollDepth"|"elementVisibility", uniqueTriggerId?: record, verticalScrollPercentageList?: record, visibilitySelector?: record, visiblePercentageMax?: record, visiblePercentageMin?: record, waitForTags?: record, waitForTagsTimeout?: record, workspaceId?: string}
# --variable shape: {accountId?: string, containerId?: string, disablingTriggerId?: list, enablingTriggerId?: list, fingerprint?: string, formatValue?: record, name?: string, notes?: string, parameter?: list, parentFolderId?: string, path?: string, scheduleEndMs?: string, scheduleStartMs?: string, tagManagerUrl?: string, type?: string, variableId?: string, workspaceId?: string}
export def "tagmanager conflict" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --fingerprint: string # When provided, this fingerprint must match the fingerprint of the entity_in_workspace in the merge conflict.
  --changeStatus: string@changeStatus-completer # Represents how the entity has been changed in the workspace.
  --client: record # shape: {accountId?: string, clientId?: string, containerId?: string, fingerprint?: string, name?: string, notes?: string, parameter?: list, parentFolderId?: string, path?: string, priority?: int, tagManagerUrl?: string, type?: string, workspaceId?: string}
  --folder: record # Represents a Google Tag Manager Folder. — shape: {accountId?: string, containerId?: string, fingerprint?: string, folderId?: string, name?: string, notes?: string, path?: string, tagManagerUrl?: string, workspaceId?: string}
  --tag: record # Represents a Google Tag Manager Tag. — shape: {accountId?: string, blockingRuleId?: list, blockingTriggerId?: list, consentSettings?: record, containerId?: string, fingerprint?: string, firingRuleId?: list, firingTriggerId?: list, liveOnly?: bool, monitoringMetadata?: record, monitoringMetadataTagNameKey?: string, name?: string, notes?: string, parameter?: list, parentFolderId?: string, path?: string, paused?: bool, priority?: record, scheduleEndMs?: string, scheduleStartMs?: string, setupTag?: list, tagFiringOption?: "tagFiringOptionUnspecified"|"unlimited"|"oncePerEvent"|"oncePerLoad", tagId?: string, tagManagerUrl?: string, teardownTag?: list, type?: string, workspaceId?: string}
  --trigger: record # Represents a Google Tag Manager Trigger — shape: {accountId?: string, autoEventFilter?: list, checkValidation?: record, containerId?: string, continuousTimeMinMilliseconds?: record, customEventFilter?: list, eventName?: record, filter?: list, fingerprint?: string, horizontalScrollPercentageList?: record, interval?: record, intervalSeconds?: record, limit?: record, maxTimerLengthSeconds?: record, name?: string, notes?: string, parameter?: list, parentFolderId?: string, path?: string, selector?: record, tagManagerUrl?: string, totalTimeMinMilliseconds?: record, triggerId?: string, type?: "eventTypeUnspecified"|"pageview"|"domReady"|"windowLoaded"|"customEvent"|"triggerGroup"|"init"|"consentInit"|"serverPageview"|"always"|"firebaseAppException"|"firebaseAppUpdate"|"firebaseCampaign"|"firebaseFirstOpen"|"firebaseInAppPurchase"|"firebaseNotificationDismiss"|"firebaseNotificationForeground"|"firebaseNotificationOpen"|"firebaseNotificationReceive"|"firebaseOsUpdate"|"firebaseSessionStart"|"firebaseUserEngagement"|"formSubmission"|"click"|"linkClick"|"jsError"|"historyChange"|"timer"|"ampClick"|"ampTimer"|"ampScroll"|"ampVisibility"|"youTubeVideo"|"scrollDepth"|"elementVisibility", uniqueTriggerId?: record, verticalScrollPercentageList?: record, visibilitySelector?: record, visiblePercentageMax?: record, visiblePercentageMin?: record, waitForTags?: record, waitForTagsTimeout?: record, workspaceId?: string}
  --variable: record # Represents a Google Tag Manager Variable. — shape: {accountId?: string, containerId?: string, disablingTriggerId?: list, enablingTriggerId?: list, fingerprint?: string, formatValue?: record, name?: string, notes?: string, parameter?: list, parentFolderId?: string, path?: string, scheduleEndMs?: string, scheduleStartMs?: string, tagManagerUrl?: string, type?: string, variableId?: string, workspaceId?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "fingerprint" $fingerprint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($path):resolve_conflict" $qp)
  let body = {changeStatus: $changeStatus, client: $client, folder: $folder, tag: $tag, trigger: $trigger, variable: $variable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reverts changes to a GTM Zone in a GTM Workspace.
#
# POST /tagmanager/v2/{path}:revert
# operationId: tagmanager.accounts.containers.workspaces.zones.revert
export def "tagmanager tagmanageraccountscontainersworkspaceszonesrevert" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --fingerprint: string # When provided, this fingerprint must match the fingerprint of the zone in storage.
]: nothing -> record<zone: record<accountId: string, boundary: record<condition: list, customEvaluationTriggerId: list>, childContainer: list<record>, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record<enable: bool, whitelistedTypeId: list>, workspaceId: string, zoneId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "fingerprint" $fingerprint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($path):revert" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets the latest version used for synchronization of workspaces when detecting conflicts and errors.
#
# POST /tagmanager/v2/{path}:set_latest
# operationId: tagmanager.accounts.containers.versions.set_latest
export def "tagmanager latest" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<accountId: string, builtInVariable: table<accountId: string, containerId: string, name: string, path: string, type: string, workspaceId: string>, client: table<accountId: string, clientId: string, containerId: string, fingerprint: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, priority: int, tagManagerUrl: string, type: string, workspaceId: string>, container: record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>>, containerId: string, containerVersionId: string, customTemplate: table<accountId: string, containerId: string, fingerprint: string, galleryReference: record, name: string, path: string, tagManagerUrl: string, templateData: string, templateId: string, workspaceId: string>, deleted: bool, description: string, fingerprint: string, folder: table<accountId: string, containerId: string, fingerprint: string, folderId: string, name: string, notes: string, path: string, tagManagerUrl: string, workspaceId: string>, gtagConfig: table<accountId: string, containerId: string, fingerprint: string, gtagConfigId: string, parameter: list, path: string, tagManagerUrl: string, type: string, workspaceId: string>, name: string, path: string, tag: table<accountId: string, blockingRuleId: list, blockingTriggerId: list, consentSettings: record, containerId: string, fingerprint: string, firingRuleId: list, firingTriggerId: list, liveOnly: bool, monitoringMetadata: record, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, paused: bool, priority: record, scheduleEndMs: string, scheduleStartMs: string, setupTag: list, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: list, type: string, workspaceId: string>, tagManagerUrl: string, trigger: table<accountId: string, autoEventFilter: list, checkValidation: record, containerId: string, continuousTimeMinMilliseconds: record, customEventFilter: list, eventName: record, filter: list, fingerprint: string, horizontalScrollPercentageList: record, interval: record, intervalSeconds: record, limit: record, maxTimerLengthSeconds: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, selector: record, tagManagerUrl: string, totalTimeMinMilliseconds: record, triggerId: string, type: string, uniqueTriggerId: record, verticalScrollPercentageList: record, visibilitySelector: record, visiblePercentageMax: record, visiblePercentageMin: record, waitForTags: record, waitForTagsTimeout: record, workspaceId: string>, variable: table<accountId: string, containerId: string, disablingTriggerId: list, enablingTriggerId: list, fingerprint: string, formatValue: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string>, zone: table<accountId: string, boundary: record, childContainer: list, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record, workspaceId: string, zoneId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($path):set_latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the tagging snippet for a Container.
#
# GET /tagmanager/v2/{path}:snippet
# operationId: tagmanager.accounts.containers.snippet
export def "tagmanager tagmanageraccountscontainerssnippet" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<snippet: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($path):snippet" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Syncs a workspace to the latest container version by updating all unmodified workspace entities and displaying conflicts for modified entities.
#
# POST /tagmanager/v2/{path}:sync
# operationId: tagmanager.accounts.containers.workspaces.sync
export def "tagmanager tagmanageraccountscontainersworkspacessync" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<mergeConflict: table<entityInBaseVersion: record, entityInWorkspace: record>, syncStatus: record<mergeConflict: bool, syncError: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($path):sync" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Undeletes a Container Version.
#
# POST /tagmanager/v2/{path}:undelete
# operationId: tagmanager.accounts.containers.versions.undelete
export def "tagmanager tagmanageraccountscontainersversionsundelete" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<accountId: string, builtInVariable: table<accountId: string, containerId: string, name: string, path: string, type: string, workspaceId: string>, client: table<accountId: string, clientId: string, containerId: string, fingerprint: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, priority: int, tagManagerUrl: string, type: string, workspaceId: string>, container: record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>>, containerId: string, containerVersionId: string, customTemplate: table<accountId: string, containerId: string, fingerprint: string, galleryReference: record, name: string, path: string, tagManagerUrl: string, templateData: string, templateId: string, workspaceId: string>, deleted: bool, description: string, fingerprint: string, folder: table<accountId: string, containerId: string, fingerprint: string, folderId: string, name: string, notes: string, path: string, tagManagerUrl: string, workspaceId: string>, gtagConfig: table<accountId: string, containerId: string, fingerprint: string, gtagConfigId: string, parameter: list, path: string, tagManagerUrl: string, type: string, workspaceId: string>, name: string, path: string, tag: table<accountId: string, blockingRuleId: list, blockingTriggerId: list, consentSettings: record, containerId: string, fingerprint: string, firingRuleId: list, firingTriggerId: list, liveOnly: bool, monitoringMetadata: record, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, paused: bool, priority: record, scheduleEndMs: string, scheduleStartMs: string, setupTag: list, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: list, type: string, workspaceId: string>, tagManagerUrl: string, trigger: table<accountId: string, autoEventFilter: list, checkValidation: record, containerId: string, continuousTimeMinMilliseconds: record, customEventFilter: list, eventName: record, filter: list, fingerprint: string, horizontalScrollPercentageList: record, interval: record, intervalSeconds: record, limit: record, maxTimerLengthSeconds: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, selector: record, tagManagerUrl: string, totalTimeMinMilliseconds: record, triggerId: string, type: string, uniqueTriggerId: record, verticalScrollPercentageList: record, visibilitySelector: record, visiblePercentageMax: record, visiblePercentageMin: record, waitForTags: record, waitForTagsTimeout: record, workspaceId: string>, variable: table<accountId: string, containerId: string, disablingTriggerId: list, enablingTriggerId: list, fingerprint: string, formatValue: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string>, zone: table<accountId: string, boundary: record, childContainer: list, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record, workspaceId: string, zoneId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tagmanager/v2/($path):undelete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
