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

def base-url-completer [] { ["https://tagmanager.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def type-completer [] { ["latest" "live" "user" "workspace"] }
def tag-firing-option-completer [] { ["oncePerEvent" "oncePerLoad" "tagFiringOptionUnspecified" "unlimited"] }
def type-completer-1 [] { ["always" "ampClick" "ampScroll" "ampTimer" "ampVisibility" "click" "consentInit" "customEvent" "domReady" "elementVisibility" "eventTypeUnspecified" "firebaseAppException" "firebaseAppUpdate" "firebaseCampaign" "firebaseFirstOpen" "firebaseInAppPurchase" "firebaseNotificationDismiss" "firebaseNotificationForeground" "firebaseNotificationOpen" "firebaseNotificationReceive" "firebaseOsUpdate" "firebaseSessionStart" "firebaseUserEngagement" "formSubmission" "historyChange" "init" "jsError" "linkClick" "pageview" "scrollDepth" "serverPageview" "timer" "triggerGroup" "windowLoaded" "youTubeVideo"] }
def type-completer-2 [] { ["advertiserId" "advertisingTrackingEnabled" "ampBrowserLanguage" "ampCanonicalHost" "ampCanonicalPath" "ampCanonicalUrl" "ampClientId" "ampClientMaxScrollX" "ampClientMaxScrollY" "ampClientScreenHeight" "ampClientScreenWidth" "ampClientScrollX" "ampClientScrollY" "ampClientTimestamp" "ampClientTimezone" "ampGtmEvent" "ampPageDownloadTime" "ampPageLoadTime" "ampPageViewId" "ampReferrer" "ampTitle" "ampTotalEngagedTime" "appId" "appName" "appVersionCode" "appVersionName" "builtInVariableTypeUnspecified" "clickClasses" "clickElement" "clickId" "clickTarget" "clickText" "clickUrl" "clientName" "containerId" "containerVersion" "debugMode" "deviceName" "elementVisibilityFirstTime" "elementVisibilityRatio" "elementVisibilityRecentTime" "elementVisibilityTime" "environmentName" "errorLine" "errorMessage" "errorUrl" "event" "eventName" "firebaseEventParameterCampaign" "firebaseEventParameterCampaignAclid" "firebaseEventParameterCampaignAnid" "firebaseEventParameterCampaignClickTimestamp" "firebaseEventParameterCampaignContent" "firebaseEventParameterCampaignCp1" "firebaseEventParameterCampaignGclid" "firebaseEventParameterCampaignSource" "firebaseEventParameterCampaignTerm" "firebaseEventParameterCurrency" "firebaseEventParameterDynamicLinkAcceptTime" "firebaseEventParameterDynamicLinkLinkid" "firebaseEventParameterNotificationMessageDeviceTime" "firebaseEventParameterNotificationMessageId" "firebaseEventParameterNotificationMessageName" "firebaseEventParameterNotificationMessageTime" "firebaseEventParameterNotificationTopic" "firebaseEventParameterPreviousAppVersion" "firebaseEventParameterPreviousOsVersion" "firebaseEventParameterPrice" "firebaseEventParameterProductId" "firebaseEventParameterQuantity" "firebaseEventParameterValue" "firstPartyServingUrl" "formClasses" "formElement" "formId" "formTarget" "formText" "formUrl" "historySource" "htmlId" "language" "newHistoryFragment" "newHistoryState" "newHistoryUrl" "oldHistoryFragment" "oldHistoryState" "oldHistoryUrl" "osVersion" "pageHostname" "pagePath" "pageUrl" "platform" "queryString" "randomNumber" "referrer" "requestMethod" "requestPath" "resolution" "scrollDepthDirection" "scrollDepthThreshold" "scrollDepthUnits" "sdkVersion" "serverPageLocationHostname" "serverPageLocationPath" "serverPageLocationUrl" "videoCurrentTime" "videoDuration" "videoPercent" "videoProvider" "videoStatus" "videoTitle" "videoUrl" "videoVisible" "visitorRegion"] }
def setting-source-completer [] { ["current" "other" "settingSourceUnspecified"] }
def change-status-completer [] { ["added" "changeStatusUnspecified" "deleted" "none" "updated"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "tagmanager-accounts list" } } | get name | first)
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
export def "tagmanager-accounts list" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --include-google-tags: oneof<nothing, bool> # Also retrieve accounts associated with Google Tag when true.
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> record<account: table<accountId: string, features: record, fingerprint: string, name: string, path: string, shareData: bool, tagManagerUrl: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "includeGoogleTags" $include_google_tags "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tagmanager/v2/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Looks up a Container by destination ID.
#
# GET /tagmanager/v2/accounts/containers:lookup
# operationId: tagmanager.accounts.containers.lookup
export def "tagmanager-accounts-containers-lookup get" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --destination-id: string # Destination ID linked to a GTM Container, e.g. AW-123456789. Example: accounts/containers:lookup?destination_id={destination_id}.
]: nothing -> record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "destinationId" $destination_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tagmanager/v2/accounts/containers:lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the enabled Built-In Variables of a GTM Container.
#
# GET /tagmanager/v2/{parent}/built_in_variables
# operationId: tagmanager.accounts.containers.workspaces.built_in_variables.list
export def "tagmanager-built-in-variables list" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> record<builtInVariable: table<accountId: string, containerId: string, name: string, path: string, type: string, workspaceId: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/built_in_variables") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates one or more GTM Built-In Variables.
#
# POST /tagmanager/v2/{parent}/built_in_variables
# operationId: tagmanager.accounts.containers.workspaces.built_in_variables.create
export def "tagmanager-built-in-variables create" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --type: list<string> # The types of built-in variables to enable.
]: nothing -> record<builtInVariable: table<accountId: string, containerId: string, name: string, path: string, type: string, workspaceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "type" $type "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/built_in_variables") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all GTM Clients of a GTM container workspace.
#
# GET /tagmanager/v2/{parent}/clients
# operationId: tagmanager.accounts.containers.workspaces.clients.list
export def "tagmanager-clients list" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> record<client: table<accountId: string, clientId: string, containerId: string, fingerprint: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, priority: int, tagManagerUrl: string, type: string, workspaceId: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/clients") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a GTM Client.
#
# POST /tagmanager/v2/{parent}/clients
# operationId: tagmanager.accounts.containers.workspaces.clients.create
# --parameter item shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
export def "tagmanager-clients create" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --account-id: string # GTM Account ID.
  --client-id: string # The Client ID uniquely identifies the GTM client.
  --container-id: string # GTM Container ID.
  --fingerprint: string # The fingerprint of the GTM Client as computed at storage time. This value is recomputed whenever the client is modified.
  --name: string # Client display name. @mutable tagmanager.accounts.containers.workspaces.clients.create @mutable tagmanager.accounts.containers.workspaces.clients.update
  --notes: string # User notes on how to apply this tag in the container. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --parameter: list # The client's parameters. @mutable tagmanager.accounts.containers.workspaces.clients.create @mutable tagmanager.accounts.containers.workspaces.clients.update — item shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --parent-folder-id: string # Parent folder id.
  --path: string # GTM client's API relative path.
  --priority: int # Priority determines relative firing order. @mutable tagmanager.accounts.containers.workspaces.clients.create @mutable tagmanager.accounts.containers.workspaces.clients.update (format: int32)
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --type: string # Client type. @mutable tagmanager.accounts.containers.workspaces.clients.create @mutable tagmanager.accounts.containers.workspaces.clients.update
  --workspace-id: string # GTM Workspace ID.
]: any -> record<accountId: string, clientId: string, containerId: string, fingerprint: string, name: string, notes: string, parameter: table<key: string, list: list, map: list, type: string, value: string>, parentFolderId: string, path: string, priority: int, tagManagerUrl: string, type: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/clients") $qp)
  let req_body = {"accountId": $account_id, "clientId": $client_id, "containerId": $container_id, "fingerprint": $fingerprint, "name": $name, "notes": $notes, "parameter": $parameter, "parentFolderId": $parent_folder_id, "path": $path, "priority": $priority, "tagManagerUrl": $tag_manager_url, "type": $type, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all Containers that belongs to a GTM Account.
#
# GET /tagmanager/v2/{parent}/containers
# operationId: tagmanager.accounts.containers.list
export def "tagmanager-containers list" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> record<container: table<accountId: string, containerId: string, domainName: list, features: record, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list, tagManagerUrl: string, taggingServerUrls: list, usageContext: list>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/containers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Container.
#
# POST /tagmanager/v2/{parent}/containers
# operationId: tagmanager.accounts.containers.create
# --features shape: {supportBuiltInVariables?: bool, supportClients?: bool, supportEnvironments?: bool, supportFolders?: bool, supportGtagConfigs?: bool, supportTags?: bool, supportTemplates?: bool, supportTriggers?: bool, supportUserPermissions?: bool, supportVariables?: bool, supportVersions?: bool, supportWorkspaces?: bool, supportZones?: bool}
export def "tagmanager-containers create" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --account-id: string # GTM Account ID.
  --container-id: string # The Container ID uniquely identifies the GTM Container.
  --domain-name: list<string> # List of domain names associated with the Container. @mutable tagmanager.accounts.containers.create @mutable tagmanager.accounts.containers.update
  --features: record # shape: {supportBuiltInVariables?: bool, supportClients?: bool, supportEnvironments?: bool, supportFolders?: bool, supportGtagConfigs?: bool, supportTags?: bool, supportTemplates?: bool, supportTriggers?: bool, supportUserPermissions?: bool, supportVariables?: bool, supportVersions?: bool, supportWorkspaces?: bool, supportZones?: bool}
  --fingerprint: string # The fingerprint of the GTM Container as computed at storage time. This value is recomputed whenever the account is modified.
  --name: string # Container display name. @mutable tagmanager.accounts.containers.create @mutable tagmanager.accounts.containers.update
  --notes: string # Container Notes. @mutable tagmanager.accounts.containers.create @mutable tagmanager.accounts.containers.update
  --path: string # GTM Container's API relative path.
  --public-id: string # Container Public ID.
  --tag-ids: list<string> # All Tag IDs that refer to this Container.
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --tagging-server-urls: list<string> # List of server-side container URLs for the Container. If multiple URLs are provided, all URL paths must match. @mutable tagmanager.accounts.containers.create @mutable tagmanager.accounts.containers.update
  --usage-context: list<string> # List of Usage Contexts for the Container. Valid values include: web, android, or ios. @mutable tagmanager.accounts.containers.create @mutable tagmanager.accounts.containers.update
]: any -> record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/containers") $qp)
  let req_body = {"accountId": $account_id, "containerId": $container_id, "domainName": $domain_name, "features": $features, "fingerprint": $fingerprint, "name": $name, "notes": $notes, "path": $path, "publicId": $public_id, "tagIds": $tag_ids, "tagManagerUrl": $tag_manager_url, "taggingServerUrls": $tagging_server_urls, "usageContext": $usage_context} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all Destinations linked to a GTM Container.
#
# GET /tagmanager/v2/{parent}/destinations
# operationId: tagmanager.accounts.containers.destinations.list
export def "tagmanager-destinations list" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<destination: table<accountId: string, containerId: string, destinationId: string, destinationLinkId: string, fingerprint: string, name: string, path: string, tagManagerUrl: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/destinations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a Destination to this Container and removes it from the Container to which it is currently linked.
#
# POST /tagmanager/v2/{parent}/destinations:link
# operationId: tagmanager.accounts.containers.destinations.link
export def "tagmanager-destinations-link create" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --allow-user-permission-feature-update: oneof<nothing, bool> # Must be set to true to allow features.user_permissions to change from false to true. If this operation causes an update but this bit is false, the operation will fail.
  --destination-id: string # Destination ID to be linked to the current container.
]: nothing -> record<accountId: string, containerId: string, destinationId: string, destinationLinkId: string, fingerprint: string, name: string, path: string, tagManagerUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "allowUserPermissionFeatureUpdate" $allow_user_permission_feature_update "scalar") (serialize-qp "destinationId" $destination_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/destinations:link") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all GTM Environments of a GTM Container.
#
# GET /tagmanager/v2/{parent}/environments
# operationId: tagmanager.accounts.containers.environments.list
export def "tagmanager-environments list" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> record<environment: table<accountId: string, authorizationCode: string, authorizationTimestamp: string, containerId: string, containerVersionId: string, description: string, enableDebug: bool, environmentId: string, fingerprint: string, name: string, path: string, tagManagerUrl: string, type: string, url: string, workspaceId: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/environments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a GTM Environment.
#
# POST /tagmanager/v2/{parent}/environments
# operationId: tagmanager.accounts.containers.environments.create
export def "tagmanager-environments create" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --account-id: string # GTM Account ID.
  --authorization-code: string # The environment authorization code.
  --authorization-timestamp: string # The last update time-stamp for the authorization code. (format: google-datetime)
  --container-id: string # GTM Container ID.
  --container-version-id: string # Represents a link to a container version.
  --description: string # The environment description. Can be set or changed only on USER type environments. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --enable-debug: oneof<nothing, bool> # Whether or not to enable debug by default for the environment. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --environment-id: string # GTM Environment ID uniquely identifies the GTM Environment.
  --fingerprint: string # The fingerprint of the GTM environment as computed at storage time. This value is recomputed whenever the environment is modified.
  --name: string # The environment display name. Can be set or changed only on USER type environments. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --path: string # GTM Environment's API relative path.
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --type: string@type-completer # The type of this environment.
  --url: string # Default preview page url for the environment. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --workspace-id: string # Represents a link to a quick preview of a workspace.
]: any -> record<accountId: string, authorizationCode: string, authorizationTimestamp: string, containerId: string, containerVersionId: string, description: string, enableDebug: bool, environmentId: string, fingerprint: string, name: string, path: string, tagManagerUrl: string, type: string, url: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/environments") $qp)
  let req_body = {"accountId": $account_id, "authorizationCode": $authorization_code, "authorizationTimestamp": $authorization_timestamp, "containerId": $container_id, "containerVersionId": $container_version_id, "description": $description, "enableDebug": $enable_debug, "environmentId": $environment_id, "fingerprint": $fingerprint, "name": $name, "path": $path, "tagManagerUrl": $tag_manager_url, "type": $type, "url": $url, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all GTM Folders of a Container.
#
# GET /tagmanager/v2/{parent}/folders
# operationId: tagmanager.accounts.containers.workspaces.folders.list
export def "tagmanager-folders list" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> record<folder: table<accountId: string, containerId: string, fingerprint: string, folderId: string, name: string, notes: string, path: string, tagManagerUrl: string, workspaceId: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/folders") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a GTM Folder.
#
# POST /tagmanager/v2/{parent}/folders
# operationId: tagmanager.accounts.containers.workspaces.folders.create
export def "tagmanager-folders create" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --account-id: string # GTM Account ID.
  --container-id: string # GTM Container ID.
  --fingerprint: string # The fingerprint of the GTM Folder as computed at storage time. This value is recomputed whenever the folder is modified.
  --folder-id: string # The Folder ID uniquely identifies the GTM Folder.
  --name: string # Folder display name. @mutable tagmanager.accounts.containers.workspaces.folders.create @mutable tagmanager.accounts.containers.workspaces.folders.update
  --notes: string # User notes on how to apply this folder in the container. @mutable tagmanager.accounts.containers.workspaces.folders.create @mutable tagmanager.accounts.containers.workspaces.folders.update
  --path: string # GTM Folder's API relative path.
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --workspace-id: string # GTM Workspace ID.
]: any -> record<accountId: string, containerId: string, fingerprint: string, folderId: string, name: string, notes: string, path: string, tagManagerUrl: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/folders") $qp)
  let req_body = {"accountId": $account_id, "containerId": $container_id, "fingerprint": $fingerprint, "folderId": $folder_id, "name": $name, "notes": $notes, "path": $path, "tagManagerUrl": $tag_manager_url, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all Google tag configs in a Container.
#
# GET /tagmanager/v2/{parent}/gtag_config
# operationId: tagmanager.accounts.containers.workspaces.gtag_config.list
export def "tagmanager-gtag-config list" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> record<gtagConfig: table<accountId: string, containerId: string, fingerprint: string, gtagConfigId: string, parameter: list, path: string, tagManagerUrl: string, type: string, workspaceId: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/gtag_config") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Google tag config.
#
# POST /tagmanager/v2/{parent}/gtag_config
# operationId: tagmanager.accounts.containers.workspaces.gtag_config.create
# --parameter item shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
export def "tagmanager-gtag-config create" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --account-id: string # Google tag account ID.
  --container-id: string # Google tag container ID.
  --fingerprint: string # The fingerprint of the Google tag config as computed at storage time. This value is recomputed whenever the config is modified.
  --gtag-config-id: string # The ID uniquely identifies the Google tag config.
  --parameter: list # The Google tag config's parameters. @mutable tagmanager.accounts.containers.workspaces.gtag_config.create @mutable tagmanager.accounts.containers.workspaces.gtag_config.update — item shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --path: string # Google tag config's API relative path.
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --type: string # Google tag config type. @required tagmanager.accounts.containers.workspaces.gtag_config.create @required tagmanager.accounts.containers.workspaces.gtag_config.update @mutable tagmanager.accounts.containers.workspaces.gtag_config.create @mutable tagmanager.accounts.containers.workspaces.gtag_config.update
  --workspace-id: string # Google tag workspace ID. Only used by GTM containers. Set to 0 otherwise.
]: any -> record<accountId: string, containerId: string, fingerprint: string, gtagConfigId: string, parameter: table<key: string, list: list, map: list, type: string, value: string>, path: string, tagManagerUrl: string, type: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/gtag_config") $qp)
  let req_body = {"accountId": $account_id, "containerId": $container_id, "fingerprint": $fingerprint, "gtagConfigId": $gtag_config_id, "parameter": $parameter, "path": $path, "tagManagerUrl": $tag_manager_url, "type": $type, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all GTM Tags of a Container.
#
# GET /tagmanager/v2/{parent}/tags
# operationId: tagmanager.accounts.containers.workspaces.tags.list
export def "tagmanager-tags list" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> record<nextPageToken: string, tag: table<accountId: string, blockingRuleId: list, blockingTriggerId: list, consentSettings: record, containerId: string, fingerprint: string, firingRuleId: list, firingTriggerId: list, liveOnly: bool, monitoringMetadata: record, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, paused: bool, priority: record, scheduleEndMs: string, scheduleStartMs: string, setupTag: list, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: list, type: string, workspaceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/tags") $qp)
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
export def "tagmanager-tags create" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --account-id: string # GTM Account ID.
  --blocking-rule-id: list<string> # Blocking rule IDs. If any of the listed rules evaluate to true, the tag will not fire. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --blocking-trigger-id: list<string> # Blocking trigger IDs. If any of the listed triggers evaluate to true, the tag will not fire. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --consent-settings: record # shape: {consentStatus?: "notSet"|"notNeeded"|"needed", consentType?: record}
  --container-id: string # GTM Container ID.
  --fingerprint: string # The fingerprint of the GTM Tag as computed at storage time. This value is recomputed whenever the tag is modified.
  --firing-rule-id: list<string> # Firing rule IDs. A tag will fire when any of the listed rules are true and all of its blockingRuleIds (if any specified) are false. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --firing-trigger-id: list<string> # Firing trigger IDs. A tag will fire when any of the listed triggers are true and all of its blockingTriggerIds (if any specified) are false. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --live-only: oneof<nothing, bool> # If set to true, this tag will only fire in the live environment (e.g. not in preview or debug mode). @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --monitoring-metadata: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --monitoring-metadata-tag-name-key: string # If non-empty, then the tag display name will be included in the monitoring metadata map using the key specified. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --name: string # Tag display name. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --notes: string # User notes on how to apply this tag in the container. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --parameter: list # The tag's parameters. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update — item shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --parent-folder-id: string # Parent folder id.
  --path: string # GTM Tag's API relative path.
  --paused: oneof<nothing, bool> # Indicates whether the tag is paused, which prevents the tag from firing. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --priority: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --schedule-end-ms: string # The end timestamp in milliseconds to schedule a tag. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update (format: int64)
  --schedule-start-ms: string # The start timestamp in milliseconds to schedule a tag. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update (format: int64)
  --setup-tag: list # The list of setup tags. Currently we only allow one. — item shape: {stopOnSetupFailure?: bool, tagName?: string}
  --tag-firing-option: string@tag-firing-option-completer # Option to fire this tag.
  --tag-id: string # The Tag ID uniquely identifies the GTM Tag.
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --teardown-tag: list # The list of teardown tags. Currently we only allow one. — item shape: {stopTeardownOnFailure?: bool, tagName?: string}
  --type: string # GTM Tag Type. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --workspace-id: string # GTM Workspace ID.
]: any -> record<accountId: string, blockingRuleId: list<string>, blockingTriggerId: list<string>, consentSettings: record<consentStatus: string, consentType: record<key: string, list: list, map: list, type: string, value: string>>, containerId: string, fingerprint: string, firingRuleId: list<string>, firingTriggerId: list<string>, liveOnly: bool, monitoringMetadata: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: table<key: string, list: list, map: list, type: string, value: string>, parentFolderId: string, path: string, paused: bool, priority: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, scheduleEndMs: string, scheduleStartMs: string, setupTag: table<stopOnSetupFailure: bool, tagName: string>, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: table<stopTeardownOnFailure: bool, tagName: string>, type: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/tags") $qp)
  let req_body = {"accountId": $account_id, "blockingRuleId": $blocking_rule_id, "blockingTriggerId": $blocking_trigger_id, "consentSettings": $consent_settings, "containerId": $container_id, "fingerprint": $fingerprint, "firingRuleId": $firing_rule_id, "firingTriggerId": $firing_trigger_id, "liveOnly": $live_only, "monitoringMetadata": $monitoring_metadata, "monitoringMetadataTagNameKey": $monitoring_metadata_tag_name_key, "name": $name, "notes": $notes, "parameter": $parameter, "parentFolderId": $parent_folder_id, "path": $path, "paused": $paused, "priority": $priority, "scheduleEndMs": $schedule_end_ms, "scheduleStartMs": $schedule_start_ms, "setupTag": $setup_tag, "tagFiringOption": $tag_firing_option, "tagId": $tag_id, "tagManagerUrl": $tag_manager_url, "teardownTag": $teardown_tag, "type": $type, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all GTM Templates of a GTM container workspace.
#
# GET /tagmanager/v2/{parent}/templates
# operationId: tagmanager.accounts.containers.workspaces.templates.list
export def "tagmanager-templates list" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> record<nextPageToken: string, template: table<accountId: string, containerId: string, fingerprint: string, galleryReference: record, name: string, path: string, tagManagerUrl: string, templateData: string, templateId: string, workspaceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/templates") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a GTM Custom Template.
#
# POST /tagmanager/v2/{parent}/templates
# operationId: tagmanager.accounts.containers.workspaces.templates.create
# --galleryReference shape: {host?: string, isModified?: bool, owner?: string, repository?: string, signature?: string, version?: string}
export def "tagmanager-templates create" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --account-id: string # GTM Account ID.
  --container-id: string # GTM Container ID.
  --fingerprint: string # The fingerprint of the GTM Custom Template as computed at storage time. This value is recomputed whenever the template is modified.
  --gallery-reference: record # Represents the link between a custom template and an entry on the Community Template Gallery site. — shape: {host?: string, isModified?: bool, owner?: string, repository?: string, signature?: string, version?: string}
  --name: string # Custom Template display name.
  --path: string # GTM Custom Template's API relative path.
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --template-data: string # The custom template in text format.
  --template-id: string # The Custom Template ID uniquely identifies the GTM custom template.
  --workspace-id: string # GTM Workspace ID.
]: any -> record<accountId: string, containerId: string, fingerprint: string, galleryReference: record<host: string, isModified: bool, owner: string, repository: string, signature: string, version: string>, name: string, path: string, tagManagerUrl: string, templateData: string, templateId: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/templates") $qp)
  let req_body = {"accountId": $account_id, "containerId": $container_id, "fingerprint": $fingerprint, "galleryReference": $gallery_reference, "name": $name, "path": $path, "tagManagerUrl": $tag_manager_url, "templateData": $template_data, "templateId": $template_id, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all GTM Triggers of a Container.
#
# GET /tagmanager/v2/{parent}/triggers
# operationId: tagmanager.accounts.containers.workspaces.triggers.list
export def "tagmanager-triggers list" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> record<nextPageToken: string, trigger: table<accountId: string, autoEventFilter: list, checkValidation: record, containerId: string, continuousTimeMinMilliseconds: record, customEventFilter: list, eventName: record, filter: list, fingerprint: string, horizontalScrollPercentageList: record, interval: record, intervalSeconds: record, limit: record, maxTimerLengthSeconds: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, selector: record, tagManagerUrl: string, totalTimeMinMilliseconds: record, triggerId: string, type: string, uniqueTriggerId: record, verticalScrollPercentageList: record, visibilitySelector: record, visiblePercentageMax: record, visiblePercentageMin: record, waitForTags: record, waitForTagsTimeout: record, workspaceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/triggers") $qp)
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
export def "tagmanager-triggers create" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --account-id: string # GTM Account ID.
  --auto-event-filter: list # Used in the case of auto event tracking. @mutable tagmanager.accounts.containers.workspaces.triggers.create @mutable tagmanager.accounts.containers.workspaces.triggers.update — item shape: {parameter?: list, type?: "conditionTypeUnspecified"|"equals"|"contains"|"startsWith"|"endsWith"|"matchRegex"|"greater"|"greaterOrEquals"|"less"|"lessOrEquals"|"cssSelector"|"urlMatches"}
  --check-validation: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --container-id: string # GTM Container ID.
  --continuous-time-min-milliseconds: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --custom-event-filter: list # Used in the case of custom event, which is fired iff all Conditions are true. @mutable tagmanager.accounts.containers.workspaces.triggers.create @mutable tagmanager.accounts.containers.workspaces.triggers.update — item shape: {parameter?: list, type?: "conditionTypeUnspecified"|"equals"|"contains"|"startsWith"|"endsWith"|"matchRegex"|"greater"|"greaterOrEquals"|"less"|"lessOrEquals"|"cssSelector"|"urlMatches"}
  --event-name: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --filter: list # The trigger will only fire iff all Conditions are true. @mutable tagmanager.accounts.containers.workspaces.triggers.create @mutable tagmanager.accounts.containers.workspaces.triggers.update — item shape: {parameter?: list, type?: "conditionTypeUnspecified"|"equals"|"contains"|"startsWith"|"endsWith"|"matchRegex"|"greater"|"greaterOrEquals"|"less"|"lessOrEquals"|"cssSelector"|"urlMatches"}
  --fingerprint: string # The fingerprint of the GTM Trigger as computed at storage time. This value is recomputed whenever the trigger is modified.
  --horizontal-scroll-percentage-list: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --interval: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --interval-seconds: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --limit: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --max-timer-length-seconds: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --name: string # Trigger display name. @mutable tagmanager.accounts.containers.workspaces.triggers.create @mutable tagmanager.accounts.containers.workspaces.triggers.update
  --notes: string # User notes on how to apply this trigger in the container. @mutable tagmanager.accounts.containers.workspaces.triggers.create @mutable tagmanager.accounts.containers.workspaces.triggers.update
  --parameter: list # Additional parameters. @mutable tagmanager.accounts.containers.workspaces.triggers.create @mutable tagmanager.accounts.containers.workspaces.triggers.update — item shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --parent-folder-id: string # Parent folder id.
  --path: string # GTM Trigger's API relative path.
  --selector: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --total-time-min-milliseconds: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --trigger-id: string # The Trigger ID uniquely identifies the GTM Trigger.
  --type: string@type-completer-1 # Defines the data layer event that causes this trigger. @mutable tagmanager.accounts.containers.workspaces.triggers.create @mutable tagmanager.accounts.containers.workspaces.triggers.update
  --unique-trigger-id: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --vertical-scroll-percentage-list: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --visibility-selector: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --visible-percentage-max: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --visible-percentage-min: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --wait-for-tags: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --wait-for-tags-timeout: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --workspace-id: string # GTM Workspace ID.
]: any -> record<accountId: string, autoEventFilter: table<parameter: list, type: string>, checkValidation: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, containerId: string, continuousTimeMinMilliseconds: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, customEventFilter: table<parameter: list, type: string>, eventName: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, filter: table<parameter: list, type: string>, fingerprint: string, horizontalScrollPercentageList: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, interval: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, intervalSeconds: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, limit: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, maxTimerLengthSeconds: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, name: string, notes: string, parameter: table<key: string, list: list, map: list, type: string, value: string>, parentFolderId: string, path: string, selector: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, tagManagerUrl: string, totalTimeMinMilliseconds: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, triggerId: string, type: string, uniqueTriggerId: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, verticalScrollPercentageList: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, visibilitySelector: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, visiblePercentageMax: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, visiblePercentageMin: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, waitForTags: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, waitForTagsTimeout: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/triggers") $qp)
  let req_body = {"accountId": $account_id, "autoEventFilter": $auto_event_filter, "checkValidation": $check_validation, "containerId": $container_id, "continuousTimeMinMilliseconds": $continuous_time_min_milliseconds, "customEventFilter": $custom_event_filter, "eventName": $event_name, "filter": $filter, "fingerprint": $fingerprint, "horizontalScrollPercentageList": $horizontal_scroll_percentage_list, "interval": $interval, "intervalSeconds": $interval_seconds, "limit": $limit, "maxTimerLengthSeconds": $max_timer_length_seconds, "name": $name, "notes": $notes, "parameter": $parameter, "parentFolderId": $parent_folder_id, "path": $path, "selector": $selector, "tagManagerUrl": $tag_manager_url, "totalTimeMinMilliseconds": $total_time_min_milliseconds, "triggerId": $trigger_id, "type": $type, "uniqueTriggerId": $unique_trigger_id, "verticalScrollPercentageList": $vertical_scroll_percentage_list, "visibilitySelector": $visibility_selector, "visiblePercentageMax": $visible_percentage_max, "visiblePercentageMin": $visible_percentage_min, "waitForTags": $wait_for_tags, "waitForTagsTimeout": $wait_for_tags_timeout, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List all users that have access to the account along with Account and Container user access granted to each of them.
#
# GET /tagmanager/v2/{parent}/user_permissions
# operationId: tagmanager.accounts.user_permissions.list
export def "tagmanager-user-permissions list" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> record<nextPageToken: string, userPermission: table<accountAccess: record, accountId: string, containerAccess: list, emailAddress: string, path: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/user_permissions") $qp)
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
export def "tagmanager-user-permissions create" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --account-access: record # Defines the Google Tag Manager Account access permissions. — shape: {permission?: "accountPermissionUnspecified"|"noAccess"|"user"|"admin"}
  --account-id: string # The Account ID uniquely identifies the GTM Account.
  --container-access: list # GTM Container access permissions. @mutable tagmanager.accounts.permissions.create @mutable tagmanager.accounts.permissions.update — item shape: {containerId?: string, permission?: "containerPermissionUnspecified"|"noAccess"|"read"|"edit"|"approve"|"publish"}
  --email-address: string # User's email address. @mutable tagmanager.accounts.permissions.create
  --path: string # GTM UserPermission's API relative path.
]: any -> record<accountAccess: record<permission: string>, accountId: string, containerAccess: table<containerId: string, permission: string>, emailAddress: string, path: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/user_permissions") $qp)
  let req_body = {"accountAccess": $account_access, "accountId": $account_id, "containerAccess": $container_access, "emailAddress": $email_address, "path": $path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all GTM Variables of a Container.
#
# GET /tagmanager/v2/{parent}/variables
# operationId: tagmanager.accounts.containers.workspaces.variables.list
export def "tagmanager-variables list" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> record<nextPageToken: string, variable: table<accountId: string, containerId: string, disablingTriggerId: list, enablingTriggerId: list, fingerprint: string, formatValue: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/variables") $qp)
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
export def "tagmanager-variables create" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --account-id: string # GTM Account ID.
  --container-id: string # GTM Container ID.
  --disabling-trigger-id: list<string> # For mobile containers only: A list of trigger IDs for disabling conditional variables; the variable is enabled if one of the enabling trigger is true while all the disabling trigger are false. Treated as an unordered set. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update
  --enabling-trigger-id: list<string> # For mobile containers only: A list of trigger IDs for enabling conditional variables; the variable is enabled if one of the enabling triggers is true while all the disabling triggers are false. Treated as an unordered set. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update
  --fingerprint: string # The fingerprint of the GTM Variable as computed at storage time. This value is recomputed whenever the variable is modified.
  --format-value: record # shape: {caseConversionType?: "none"|"lowercase"|"uppercase", convertFalseToValue?: record, convertNullToValue?: record, convertTrueToValue?: record, convertUndefinedToValue?: record}
  --name: string # Variable display name. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update
  --notes: string # User notes on how to apply this variable in the container. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update
  --parameter: list # The variable's parameters. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update — item shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --parent-folder-id: string # Parent folder id.
  --path: string # GTM Variable's API relative path.
  --schedule-end-ms: string # The end timestamp in milliseconds to schedule a variable. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update (format: int64)
  --schedule-start-ms: string # The start timestamp in milliseconds to schedule a variable. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update (format: int64)
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --type: string # GTM Variable Type. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update
  --variable-id: string # The Variable ID uniquely identifies the GTM Variable.
  --workspace-id: string # GTM Workspace ID.
]: any -> record<accountId: string, containerId: string, disablingTriggerId: list<string>, enablingTriggerId: list<string>, fingerprint: string, formatValue: record<caseConversionType: string, convertFalseToValue: record<key: string, list: list, map: list, type: string, value: string>, convertNullToValue: record<key: string, list: list, map: list, type: string, value: string>, convertTrueToValue: record<key: string, list: list, map: list, type: string, value: string>, convertUndefinedToValue: record<key: string, list: list, map: list, type: string, value: string>>, name: string, notes: string, parameter: table<key: string, list: list, map: list, type: string, value: string>, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/variables") $qp)
  let req_body = {"accountId": $account_id, "containerId": $container_id, "disablingTriggerId": $disabling_trigger_id, "enablingTriggerId": $enabling_trigger_id, "fingerprint": $fingerprint, "formatValue": $format_value, "name": $name, "notes": $notes, "parameter": $parameter, "parentFolderId": $parent_folder_id, "path": $path, "scheduleEndMs": $schedule_end_ms, "scheduleStartMs": $schedule_start_ms, "tagManagerUrl": $tag_manager_url, "type": $type, "variableId": $variable_id, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all Container Versions of a GTM Container.
#
# GET /tagmanager/v2/{parent}/version_headers
# operationId: tagmanager.accounts.containers.version_headers.list
export def "tagmanager-version-headers list" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --include-deleted: oneof<nothing, bool> # Also retrieve deleted (archived) versions when true.
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> record<containerVersionHeader: table<accountId: string, containerId: string, containerVersionId: string, deleted: bool, name: string, numClients: string, numCustomTemplates: string, numGtagConfigs: string, numMacros: string, numRules: string, numTags: string, numTransformations: string, numTriggers: string, numVariables: string, numZones: string, path: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "includeDeleted" $include_deleted "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/version_headers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the latest container version header
#
# GET /tagmanager/v2/{parent}/version_headers:latest
# operationId: tagmanager.accounts.containers.version_headers.latest
export def "tagmanager-version-headers-latest get" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<accountId: string, containerId: string, containerVersionId: string, deleted: bool, name: string, numClients: string, numCustomTemplates: string, numGtagConfigs: string, numMacros: string, numRules: string, numTags: string, numTransformations: string, numTriggers: string, numVariables: string, numZones: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/version_headers:latest") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the live (i.e. published) container version
#
# GET /tagmanager/v2/{parent}/versions:live
# operationId: tagmanager.accounts.containers.versions.live
export def "tagmanager-versions-live get" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<accountId: string, builtInVariable: table<accountId: string, containerId: string, name: string, path: string, type: string, workspaceId: string>, client: table<accountId: string, clientId: string, containerId: string, fingerprint: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, priority: int, tagManagerUrl: string, type: string, workspaceId: string>, container: record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>>, containerId: string, containerVersionId: string, customTemplate: table<accountId: string, containerId: string, fingerprint: string, galleryReference: record, name: string, path: string, tagManagerUrl: string, templateData: string, templateId: string, workspaceId: string>, deleted: bool, description: string, fingerprint: string, folder: table<accountId: string, containerId: string, fingerprint: string, folderId: string, name: string, notes: string, path: string, tagManagerUrl: string, workspaceId: string>, gtagConfig: table<accountId: string, containerId: string, fingerprint: string, gtagConfigId: string, parameter: list, path: string, tagManagerUrl: string, type: string, workspaceId: string>, name: string, path: string, tag: table<accountId: string, blockingRuleId: list, blockingTriggerId: list, consentSettings: record, containerId: string, fingerprint: string, firingRuleId: list, firingTriggerId: list, liveOnly: bool, monitoringMetadata: record, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, paused: bool, priority: record, scheduleEndMs: string, scheduleStartMs: string, setupTag: list, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: list, type: string, workspaceId: string>, tagManagerUrl: string, trigger: table<accountId: string, autoEventFilter: list, checkValidation: record, containerId: string, continuousTimeMinMilliseconds: record, customEventFilter: list, eventName: record, filter: list, fingerprint: string, horizontalScrollPercentageList: record, interval: record, intervalSeconds: record, limit: record, maxTimerLengthSeconds: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, selector: record, tagManagerUrl: string, totalTimeMinMilliseconds: record, triggerId: string, type: string, uniqueTriggerId: record, verticalScrollPercentageList: record, visibilitySelector: record, visiblePercentageMax: record, visiblePercentageMin: record, waitForTags: record, waitForTagsTimeout: record, workspaceId: string>, variable: table<accountId: string, containerId: string, disablingTriggerId: list, enablingTriggerId: list, fingerprint: string, formatValue: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string>, zone: table<accountId: string, boundary: record, childContainer: list, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record, workspaceId: string, zoneId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/versions:live") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all Workspaces that belong to a GTM Container.
#
# GET /tagmanager/v2/{parent}/workspaces
# operationId: tagmanager.accounts.containers.workspaces.list
export def "tagmanager-workspaces list" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> record<nextPageToken: string, workspace: table<accountId: string, containerId: string, description: string, fingerprint: string, name: string, path: string, tagManagerUrl: string, workspaceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/workspaces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Workspace.
#
# POST /tagmanager/v2/{parent}/workspaces
# operationId: tagmanager.accounts.containers.workspaces.create
export def "tagmanager-workspaces create" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --account-id: string # GTM Account ID.
  --container-id: string # GTM Container ID.
  --description: string # Workspace description. @mutable tagmanager.accounts.containers.workspaces.create @mutable tagmanager.accounts.containers.workspaces.update
  --fingerprint: string # The fingerprint of the GTM Workspace as computed at storage time. This value is recomputed whenever the workspace is modified.
  --name: string # Workspace display name. @mutable tagmanager.accounts.containers.workspaces.create @mutable tagmanager.accounts.containers.workspaces.update
  --path: string # GTM Workspace's API relative path.
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --workspace-id: string # The Workspace ID uniquely identifies the GTM Workspace.
]: any -> record<accountId: string, containerId: string, description: string, fingerprint: string, name: string, path: string, tagManagerUrl: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/workspaces") $qp)
  let req_body = {"accountId": $account_id, "containerId": $container_id, "description": $description, "fingerprint": $fingerprint, "name": $name, "path": $path, "tagManagerUrl": $tag_manager_url, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all GTM Zones of a GTM container workspace.
#
# GET /tagmanager/v2/{parent}/zones
# operationId: tagmanager.accounts.containers.workspaces.zones.list
export def "tagmanager-zones list" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> record<nextPageToken: string, zone: table<accountId: string, boundary: record, childContainer: list, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record, workspaceId: string, zoneId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/zones") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a GTM Zone.
#
# POST /tagmanager/v2/{parent}/zones
# operationId: tagmanager.accounts.containers.workspaces.zones.create
# --boundary shape: {condition?: list, customEvaluationTriggerId?: list<string>}
# --childContainer item shape: {nickname?: string, publicId?: string}
# --typeRestriction shape: {enable?: bool, whitelistedTypeId?: list<string>}
export def "tagmanager-zones create" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --account-id: string # GTM Account ID.
  --boundary: record # Represents a Zone's boundaries. — shape: {condition?: list, customEvaluationTriggerId?: list<string>}
  --child-container: list # Containers that are children of this Zone. — item shape: {nickname?: string, publicId?: string}
  --container-id: string # GTM Container ID.
  --fingerprint: string # The fingerprint of the GTM Zone as computed at storage time. This value is recomputed whenever the zone is modified.
  --name: string # Zone display name.
  --notes: string # User notes on how to apply this zone in the container.
  --path: string # GTM Zone's API relative path.
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --type-restriction: record # Represents a Zone's type restrictions. — shape: {enable?: bool, whitelistedTypeId?: list<string>}
  --workspace-id: string # GTM Workspace ID.
  --zone-id: string # The Zone ID uniquely identifies the GTM Zone.
]: any -> record<accountId: string, boundary: record<condition: list<record>, customEvaluationTriggerId: list<string>>, childContainer: table<nickname: string, publicId: string>, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record<enable: bool, whitelistedTypeId: list<string>>, workspaceId: string, zoneId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/tagmanager/v2/{parent}/zones") $qp)
  let req_body = {"accountId": $account_id, "boundary": $boundary, "childContainer": $child_container, "containerId": $container_id, "fingerprint": $fingerprint, "name": $name, "notes": $notes, "path": $path, "tagManagerUrl": $tag_manager_url, "typeRestriction": $type_restriction, "workspaceId": $workspace_id, "zoneId": $zone_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes a user from the account, revoking access to it and all of its containers.
#
# DELETE /tagmanager/v2/{path}
# operationId: tagmanager.accounts.user_permissions.delete
export def "tagmanager delete" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --type: list<string> # The types of built-in variables to delete.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "type" $type "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/tagmanager/v2/{path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a user's Account & Container access.
#
# GET /tagmanager/v2/{path}
# operationId: tagmanager.accounts.user_permissions.get
export def "tagmanager get" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --container-version-id: string # The GTM ContainerVersion ID. Specify published to retrieve the currently published version.
]: nothing -> record<accountAccess: record<permission: string>, accountId: string, containerAccess: table<containerId: string, permission: string>, emailAddress: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "containerVersionId" $container_version_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/tagmanager/v2/{path}") $qp)
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
export def "tagmanager update" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --fingerprint: string # When provided, this fingerprint must match the fingerprint of the zone in storage.
  --account-access: record # Defines the Google Tag Manager Account access permissions. — shape: {permission?: "accountPermissionUnspecified"|"noAccess"|"user"|"admin"}
  --account-id: string # The Account ID uniquely identifies the GTM Account.
  --container-access: list # GTM Container access permissions. @mutable tagmanager.accounts.permissions.create @mutable tagmanager.accounts.permissions.update — item shape: {containerId?: string, permission?: "containerPermissionUnspecified"|"noAccess"|"read"|"edit"|"approve"|"publish"}
  --email-address: string # User's email address. @mutable tagmanager.accounts.permissions.create
  --body-path: string # GTM UserPermission's API relative path.
]: any -> record<accountAccess: record<permission: string>, accountId: string, containerAccess: table<containerId: string, permission: string>, emailAddress: string, path: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "fingerprint" $fingerprint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/tagmanager/v2/{path}") $qp)
  let req_body = {"accountAccess": $account_access, "accountId": $account_id, "containerAccess": $container_access, "emailAddress": $email_address, "path": $body_path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Reverts changes to a GTM Built-In Variables in a GTM Workspace.
#
# POST /tagmanager/v2/{path}/built_in_variables:revert
# operationId: tagmanager.accounts.containers.workspaces.built_in_variables.revert
export def "tagmanager-built-in-variables-revert create" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --type: string@type-completer-2 # The type of built-in variable to revert.
]: nothing -> record<enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/tagmanager/v2/{path}/built_in_variables:revert") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Finds conflicting and modified entities in the workspace.
#
# GET /tagmanager/v2/{path}/status
# operationId: tagmanager.accounts.containers.workspaces.getStatus
export def "tagmanager-status get" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<mergeConflict: table<entityInBaseVersion: record, entityInWorkspace: record>, workspaceChange: table<changeStatus: string, client: record, folder: record, tag: record, trigger: record, variable: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/tagmanager/v2/{path}/status") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Combines Containers.
#
# POST /tagmanager/v2/{path}:combine
# operationId: tagmanager.accounts.containers.combine
export def "tagmanager create-combine" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --allow-user-permission-feature-update: oneof<nothing, bool> # Must be set to true to allow features.user_permissions to change from false to true. If this operation causes an update but this bit is false, the operation will fail.
  --container-id: string # ID of container that will be merged into the current container.
  --setting-source: string@setting-source-completer # Specify the source of config setting after combine
]: nothing -> record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "allowUserPermissionFeatureUpdate" $allow_user_permission_feature_update "scalar") (serialize-qp "containerId" $container_id "scalar") (serialize-qp "settingSource" $setting_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/tagmanager/v2/{path}:combine") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Container Version from the entities present in the workspace, deletes the workspace, and sets the base container version to the newly created version.
#
# POST /tagmanager/v2/{path}:create_version
# operationId: tagmanager.accounts.containers.workspaces.create_version
export def "tagmanager create-version" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # The name of the container version to be created.
  --notes: string # The notes of the container version to be created.
]: any -> record<compilerError: bool, containerVersion: record<accountId: string, builtInVariable: list<record>, client: list<record>, container: record<accountId: string, containerId: string, domainName: list, features: record, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list, tagManagerUrl: string, taggingServerUrls: list, usageContext: list>, containerId: string, containerVersionId: string, customTemplate: list<record>, deleted: bool, description: string, fingerprint: string, folder: list<record>, gtagConfig: list<record>, name: string, path: string, tag: list<record>, tagManagerUrl: string, trigger: list<record>, variable: list<record>, zone: list<record>>, newWorkspacePath: string, syncStatus: record<mergeConflict: bool, syncError: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/tagmanager/v2/{path}:create_version") $qp)
  let req_body = {"name": $name, "notes": $notes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List all entities in a GTM Folder.
#
# POST /tagmanager/v2/{path}:entities
# operationId: tagmanager.accounts.containers.workspaces.folders.entities
export def "tagmanager create-entities" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> record<nextPageToken: string, tag: table<accountId: string, blockingRuleId: list, blockingTriggerId: list, consentSettings: record, containerId: string, fingerprint: string, firingRuleId: list, firingTriggerId: list, liveOnly: bool, monitoringMetadata: record, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, paused: bool, priority: record, scheduleEndMs: string, scheduleStartMs: string, setupTag: list, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: list, type: string, workspaceId: string>, trigger: table<accountId: string, autoEventFilter: list, checkValidation: record, containerId: string, continuousTimeMinMilliseconds: record, customEventFilter: list, eventName: record, filter: list, fingerprint: string, horizontalScrollPercentageList: record, interval: record, intervalSeconds: record, limit: record, maxTimerLengthSeconds: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, selector: record, tagManagerUrl: string, totalTimeMinMilliseconds: record, triggerId: string, type: string, uniqueTriggerId: record, verticalScrollPercentageList: record, visibilitySelector: record, visiblePercentageMax: record, visiblePercentageMin: record, waitForTags: record, waitForTagsTimeout: record, workspaceId: string>, variable: table<accountId: string, containerId: string, disablingTriggerId: list, enablingTriggerId: list, fingerprint: string, formatValue: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/tagmanager/v2/{path}:entities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Moves entities to a GTM Folder.
#
# POST /tagmanager/v2/{path}:move_entities_to_folder
# operationId: tagmanager.accounts.containers.workspaces.folders.move_entities_to_folder
export def "tagmanager move-entities-to-folder" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --tag-id: list<string> # The tags to be moved to the folder.
  --trigger-id: list<string> # The triggers to be moved to the folder.
  --variable-id: list<string> # The variables to be moved to the folder.
  --account-id: string # GTM Account ID.
  --container-id: string # GTM Container ID.
  --fingerprint: string # The fingerprint of the GTM Folder as computed at storage time. This value is recomputed whenever the folder is modified.
  --folder-id: string # The Folder ID uniquely identifies the GTM Folder.
  --name: string # Folder display name. @mutable tagmanager.accounts.containers.workspaces.folders.create @mutable tagmanager.accounts.containers.workspaces.folders.update
  --notes: string # User notes on how to apply this folder in the container. @mutable tagmanager.accounts.containers.workspaces.folders.create @mutable tagmanager.accounts.containers.workspaces.folders.update
  --body-path: string # GTM Folder's API relative path.
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --workspace-id: string # GTM Workspace ID.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "tagId" $tag_id "multi") (serialize-qp "triggerId" $trigger_id "multi") (serialize-qp "variableId" $variable_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/tagmanager/v2/{path}:move_entities_to_folder") $qp)
  let req_body = {"accountId": $account_id, "containerId": $container_id, "fingerprint": $fingerprint, "folderId": $folder_id, "name": $name, "notes": $notes, "path": $body_path, "tagManagerUrl": $tag_manager_url, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Move Tag ID out of a Container.
#
# POST /tagmanager/v2/{path}:move_tag_id
# operationId: tagmanager.accounts.containers.move_tag_id
export def "tagmanager move-tag" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --allow-user-permission-feature-update: oneof<nothing, bool> # Must be set to true to allow features.user_permissions to change from false to true. If this operation causes an update but this bit is false, the operation will fail.
  --copy-settings: oneof<nothing, bool> # Whether or not to copy tag settings from this tag to the new tag.
  --copy-terms-of-service: oneof<nothing, bool> # Must be set to true to accept all terms of service agreements copied from the current tag to the newly created tag. If this bit is false, the operation will fail.
  --copy-users: oneof<nothing, bool> # Whether or not to copy users from this tag to the new tag.
  --tag-id: string # Tag ID to be removed from the current Container.
  --tag-name: string # The name for the newly created tag.
]: nothing -> record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "allowUserPermissionFeatureUpdate" $allow_user_permission_feature_update "scalar") (serialize-qp "copySettings" $copy_settings "scalar") (serialize-qp "copyTermsOfService" $copy_terms_of_service "scalar") (serialize-qp "copyUsers" $copy_users "scalar") (serialize-qp "tagId" $tag_id "scalar") (serialize-qp "tagName" $tag_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/tagmanager/v2/{path}:move_tag_id") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Publishes a Container Version.
#
# POST /tagmanager/v2/{path}:publish
# operationId: tagmanager.accounts.containers.versions.publish
export def "tagmanager publish" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --fingerprint: string # When provided, this fingerprint must match the fingerprint of the container version in storage.
]: nothing -> record<compilerError: bool, containerVersion: record<accountId: string, builtInVariable: list<record>, client: list<record>, container: record<accountId: string, containerId: string, domainName: list, features: record, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list, tagManagerUrl: string, taggingServerUrls: list, usageContext: list>, containerId: string, containerVersionId: string, customTemplate: list<record>, deleted: bool, description: string, fingerprint: string, folder: list<record>, gtagConfig: list<record>, name: string, path: string, tag: list<record>, tagManagerUrl: string, trigger: list<record>, variable: list<record>, zone: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "fingerprint" $fingerprint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/tagmanager/v2/{path}:publish") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Quick previews a workspace by creating a fake container version from all entities in the provided workspace.
#
# POST /tagmanager/v2/{path}:quick_preview
# operationId: tagmanager.accounts.containers.workspaces.quick_preview
export def "tagmanager create-quick-preview" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<compilerError: bool, containerVersion: record<accountId: string, builtInVariable: list<record>, client: list<record>, container: record<accountId: string, containerId: string, domainName: list, features: record, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list, tagManagerUrl: string, taggingServerUrls: list, usageContext: list>, containerId: string, containerVersionId: string, customTemplate: list<record>, deleted: bool, description: string, fingerprint: string, folder: list<record>, gtagConfig: list<record>, name: string, path: string, tag: list<record>, tagManagerUrl: string, trigger: list<record>, variable: list<record>, zone: list<record>>, syncStatus: record<mergeConflict: bool, syncError: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/tagmanager/v2/{path}:quick_preview") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Re-generates the authorization code for a GTM Environment.
#
# POST /tagmanager/v2/{path}:reauthorize
# operationId: tagmanager.accounts.containers.environments.reauthorize
export def "tagmanager create-reauthorize" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --account-id: string # GTM Account ID.
  --authorization-code: string # The environment authorization code.
  --authorization-timestamp: string # The last update time-stamp for the authorization code. (format: google-datetime)
  --container-id: string # GTM Container ID.
  --container-version-id: string # Represents a link to a container version.
  --description: string # The environment description. Can be set or changed only on USER type environments. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --enable-debug: oneof<nothing, bool> # Whether or not to enable debug by default for the environment. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --environment-id: string # GTM Environment ID uniquely identifies the GTM Environment.
  --fingerprint: string # The fingerprint of the GTM environment as computed at storage time. This value is recomputed whenever the environment is modified.
  --name: string # The environment display name. Can be set or changed only on USER type environments. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --body-path: string # GTM Environment's API relative path.
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --type: string@type-completer # The type of this environment.
  --url: string # Default preview page url for the environment. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --workspace-id: string # Represents a link to a quick preview of a workspace.
]: any -> record<accountId: string, authorizationCode: string, authorizationTimestamp: string, containerId: string, containerVersionId: string, description: string, enableDebug: bool, environmentId: string, fingerprint: string, name: string, path: string, tagManagerUrl: string, type: string, url: string, workspaceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/tagmanager/v2/{path}:reauthorize") $qp)
  let req_body = {"accountId": $account_id, "authorizationCode": $authorization_code, "authorizationTimestamp": $authorization_timestamp, "containerId": $container_id, "containerVersionId": $container_version_id, "description": $description, "enableDebug": $enable_debug, "environmentId": $environment_id, "fingerprint": $fingerprint, "name": $name, "path": $body_path, "tagManagerUrl": $tag_manager_url, "type": $type, "url": $url, "workspaceId": $workspace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Resolves a merge conflict for a workspace entity by updating it to the resolved entity passed in the request.
#
# POST /tagmanager/v2/{path}:resolve_conflict
# operationId: tagmanager.accounts.containers.workspaces.resolve_conflict
# --client shape: {accountId?: string, clientId?: string, containerId?: string, fingerprint?: string, name?: string, notes?: string, parameter?: list, parentFolderId?: string, path?: string, priority?: int, tagManagerUrl?: string, type?: string, workspaceId?: string}
# --folder shape: {accountId?: string, containerId?: string, fingerprint?: string, folderId?: string, name?: string, notes?: string, path?: string, tagManagerUrl?: string, workspaceId?: string}
# --tag shape: {accountId?: string, blockingRuleId?: list<string>, blockingTriggerId?: list<string>, consentSettings?: record, containerId?: string, fingerprint?: string, firingRuleId?: list<string>, firingTriggerId?: list<string>, liveOnly?: bool, monitoringMetadata?: record, monitoringMetadataTagNameKey?: string, name?: string, notes?: string, parameter?: list, parentFolderId?: string, path?: string, paused?: bool, priority?: record, scheduleEndMs?: string, scheduleStartMs?: string, setupTag?: list, ... (6 more fields)}
# --trigger shape: {accountId?: string, autoEventFilter?: list, checkValidation?: record, containerId?: string, continuousTimeMinMilliseconds?: record, customEventFilter?: list, eventName?: record, filter?: list, fingerprint?: string, horizontalScrollPercentageList?: record, interval?: record, intervalSeconds?: record, limit?: record, maxTimerLengthSeconds?: record, name?: string, notes?: string, parameter?: list, parentFolderId?: string, path?: string, selector?: record, tagManagerUrl?: string, ... (11 more fields)}
# --variable shape: {accountId?: string, containerId?: string, disablingTriggerId?: list<string>, enablingTriggerId?: list<string>, fingerprint?: string, formatValue?: record, name?: string, notes?: string, parameter?: list, parentFolderId?: string, path?: string, scheduleEndMs?: string, scheduleStartMs?: string, tagManagerUrl?: string, type?: string, variableId?: string, workspaceId?: string}
export def "tagmanager create-resolve-conflict" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --fingerprint: string # When provided, this fingerprint must match the fingerprint of the entity_in_workspace in the merge conflict.
  --change-status: string@change-status-completer # Represents how the entity has been changed in the workspace.
  --client: record # shape: {accountId?: string, clientId?: string, containerId?: string, fingerprint?: string, name?: string, notes?: string, parameter?: list, parentFolderId?: string, path?: string, priority?: int, tagManagerUrl?: string, type?: string, workspaceId?: string}
  --folder: record # Represents a Google Tag Manager Folder. — shape: {accountId?: string, containerId?: string, fingerprint?: string, folderId?: string, name?: string, notes?: string, path?: string, tagManagerUrl?: string, workspaceId?: string}
  --tag: record # Represents a Google Tag Manager Tag. — shape: {accountId?: string, blockingRuleId?: list<string>, blockingTriggerId?: list<string>, consentSettings?: record, containerId?: string, fingerprint?: string, firingRuleId?: list<string>, firingTriggerId?: list<string>, liveOnly?: bool, monitoringMetadata?: record, monitoringMetadataTagNameKey?: string, name?: string, notes?: string, parameter?: list, parentFolderId?: string, path?: string, paused?: bool, priority?: record, scheduleEndMs?: string, scheduleStartMs?: string, setupTag?: list, ... (6 more fields)}
  --trigger: record # Represents a Google Tag Manager Trigger — shape: {accountId?: string, autoEventFilter?: list, checkValidation?: record, containerId?: string, continuousTimeMinMilliseconds?: record, customEventFilter?: list, eventName?: record, filter?: list, fingerprint?: string, horizontalScrollPercentageList?: record, interval?: record, intervalSeconds?: record, limit?: record, maxTimerLengthSeconds?: record, name?: string, notes?: string, parameter?: list, parentFolderId?: string, path?: string, selector?: record, tagManagerUrl?: string, ... (11 more fields)}
  --variable: record # Represents a Google Tag Manager Variable. — shape: {accountId?: string, containerId?: string, disablingTriggerId?: list<string>, enablingTriggerId?: list<string>, fingerprint?: string, formatValue?: record, name?: string, notes?: string, parameter?: list, parentFolderId?: string, path?: string, scheduleEndMs?: string, scheduleStartMs?: string, tagManagerUrl?: string, type?: string, variableId?: string, workspaceId?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "fingerprint" $fingerprint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/tagmanager/v2/{path}:resolve_conflict") $qp)
  let req_body = {"changeStatus": $change_status, "client": $client, "folder": $folder, "tag": $tag, "trigger": $trigger, "variable": $variable} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Reverts changes to a GTM Zone in a GTM Workspace.
#
# POST /tagmanager/v2/{path}:revert
# operationId: tagmanager.accounts.containers.workspaces.zones.revert
export def "tagmanager create-revert" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --fingerprint: string # When provided, this fingerprint must match the fingerprint of the zone in storage.
]: nothing -> record<zone: record<accountId: string, boundary: record<condition: list, customEvaluationTriggerId: list>, childContainer: list<record>, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record<enable: bool, whitelistedTypeId: list>, workspaceId: string, zoneId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "fingerprint" $fingerprint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/tagmanager/v2/{path}:revert") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets the latest version used for synchronization of workspaces when detecting conflicts and errors.
#
# POST /tagmanager/v2/{path}:set_latest
# operationId: tagmanager.accounts.containers.versions.set_latest
export def "tagmanager update-latest" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<accountId: string, builtInVariable: table<accountId: string, containerId: string, name: string, path: string, type: string, workspaceId: string>, client: table<accountId: string, clientId: string, containerId: string, fingerprint: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, priority: int, tagManagerUrl: string, type: string, workspaceId: string>, container: record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>>, containerId: string, containerVersionId: string, customTemplate: table<accountId: string, containerId: string, fingerprint: string, galleryReference: record, name: string, path: string, tagManagerUrl: string, templateData: string, templateId: string, workspaceId: string>, deleted: bool, description: string, fingerprint: string, folder: table<accountId: string, containerId: string, fingerprint: string, folderId: string, name: string, notes: string, path: string, tagManagerUrl: string, workspaceId: string>, gtagConfig: table<accountId: string, containerId: string, fingerprint: string, gtagConfigId: string, parameter: list, path: string, tagManagerUrl: string, type: string, workspaceId: string>, name: string, path: string, tag: table<accountId: string, blockingRuleId: list, blockingTriggerId: list, consentSettings: record, containerId: string, fingerprint: string, firingRuleId: list, firingTriggerId: list, liveOnly: bool, monitoringMetadata: record, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, paused: bool, priority: record, scheduleEndMs: string, scheduleStartMs: string, setupTag: list, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: list, type: string, workspaceId: string>, tagManagerUrl: string, trigger: table<accountId: string, autoEventFilter: list, checkValidation: record, containerId: string, continuousTimeMinMilliseconds: record, customEventFilter: list, eventName: record, filter: list, fingerprint: string, horizontalScrollPercentageList: record, interval: record, intervalSeconds: record, limit: record, maxTimerLengthSeconds: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, selector: record, tagManagerUrl: string, totalTimeMinMilliseconds: record, triggerId: string, type: string, uniqueTriggerId: record, verticalScrollPercentageList: record, visibilitySelector: record, visiblePercentageMax: record, visiblePercentageMin: record, waitForTags: record, waitForTagsTimeout: record, workspaceId: string>, variable: table<accountId: string, containerId: string, disablingTriggerId: list, enablingTriggerId: list, fingerprint: string, formatValue: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string>, zone: table<accountId: string, boundary: record, childContainer: list, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record, workspaceId: string, zoneId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/tagmanager/v2/{path}:set_latest") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the tagging snippet for a Container.
#
# GET /tagmanager/v2/{path}:snippet
# operationId: tagmanager.accounts.containers.snippet
export def "tagmanager get-snippet" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<snippet: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/tagmanager/v2/{path}:snippet") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Syncs a workspace to the latest container version by updating all unmodified workspace entities and displaying conflicts for modified entities.
#
# POST /tagmanager/v2/{path}:sync
# operationId: tagmanager.accounts.containers.workspaces.sync
export def "tagmanager sync" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<mergeConflict: table<entityInBaseVersion: record, entityInWorkspace: record>, syncStatus: record<mergeConflict: bool, syncError: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/tagmanager/v2/{path}:sync") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Undeletes a Container Version.
#
# POST /tagmanager/v2/{path}:undelete
# operationId: tagmanager.accounts.containers.versions.undelete
export def "tagmanager create-undelete" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<accountId: string, builtInVariable: table<accountId: string, containerId: string, name: string, path: string, type: string, workspaceId: string>, client: table<accountId: string, clientId: string, containerId: string, fingerprint: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, priority: int, tagManagerUrl: string, type: string, workspaceId: string>, container: record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>>, containerId: string, containerVersionId: string, customTemplate: table<accountId: string, containerId: string, fingerprint: string, galleryReference: record, name: string, path: string, tagManagerUrl: string, templateData: string, templateId: string, workspaceId: string>, deleted: bool, description: string, fingerprint: string, folder: table<accountId: string, containerId: string, fingerprint: string, folderId: string, name: string, notes: string, path: string, tagManagerUrl: string, workspaceId: string>, gtagConfig: table<accountId: string, containerId: string, fingerprint: string, gtagConfigId: string, parameter: list, path: string, tagManagerUrl: string, type: string, workspaceId: string>, name: string, path: string, tag: table<accountId: string, blockingRuleId: list, blockingTriggerId: list, consentSettings: record, containerId: string, fingerprint: string, firingRuleId: list, firingTriggerId: list, liveOnly: bool, monitoringMetadata: record, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, paused: bool, priority: record, scheduleEndMs: string, scheduleStartMs: string, setupTag: list, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: list, type: string, workspaceId: string>, tagManagerUrl: string, trigger: table<accountId: string, autoEventFilter: list, checkValidation: record, containerId: string, continuousTimeMinMilliseconds: record, customEventFilter: list, eventName: record, filter: list, fingerprint: string, horizontalScrollPercentageList: record, interval: record, intervalSeconds: record, limit: record, maxTimerLengthSeconds: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, selector: record, tagManagerUrl: string, totalTimeMinMilliseconds: record, triggerId: string, type: string, uniqueTriggerId: record, verticalScrollPercentageList: record, visibilitySelector: record, visiblePercentageMax: record, visiblePercentageMin: record, waitForTags: record, waitForTagsTimeout: record, workspaceId: string>, variable: table<accountId: string, containerId: string, disablingTriggerId: list, enablingTriggerId: list, fingerprint: string, formatValue: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string>, zone: table<accountId: string, boundary: record, childContainer: list, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record, workspaceId: string, zoneId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: (encode-path-segment $path)} | format pattern "/tagmanager/v2/{path}:undelete") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
