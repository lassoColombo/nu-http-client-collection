# Auto-generated client for Engagement.ManagementClient v2014-12-01
# Source: https://api.apis.guru/v2/specs/azure.com/mobileengagement-mobile-engagement/2014-12-01/swagger.json
# Auth: --token flag or $env.ENGAGEMENT_MANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ENGAGEMENT_MANAGEMENTCLIENT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def delivery-time-completer [] { ["any" "background" "session"] }
def notification-type-completer [] { ["popup" "system"] }
def push-mode-completer [] { ["manual" "one-shot" "real-time"] }
def type-completer [] { ["only_notif" "text/base64" "text/html" "text/plain"] }
def export-format-completer [] { ["CsvBlob" "JsonBlob"] }
def campaign-type-completer [] { ["Announcement" "DataPush" "NativePush" "Poll"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-providers-microsoft-mobile-engagement-app-collections list" } } | get name | first)
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

# Lists app collections in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.MobileEngagement/appCollections
# operationId: AppCollections_List
export def "subscriptions-providers-microsoft-mobile-engagement-app-collections list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.MobileEngagement/appCollections") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Checks availability of an app collection name in the Engagement domain.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.MobileEngagement/checkAppCollectionNameAvailability
# operationId: AppCollections_CheckNameAvailability
export def "subscriptions-providers-microsoft-mobile-engagement-check-app-collection-name-availability check" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --available: oneof<nothing, bool> # Available.
  --name: string # Name.
  --unavailability-reason: string # UnavailabilityReason.
]: any -> record<available: bool, name: string, unavailabilityReason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.MobileEngagement/checkAppCollectionNameAvailability") $qp)
  let req_body = {"available": $available, "name": $name, "unavailabilityReason": $unavailability_reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists supported platforms for Engagement applications.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.MobileEngagement/supportedPlatforms
# operationId: SupportedPlatforms_List
export def "subscriptions-providers-microsoft-mobile-engagement-supported-platforms list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<platforms: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.MobileEngagement/supportedPlatforms") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Lists apps in an appCollection.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps
# operationId: Apps_List
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps list" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Get the list of campaigns.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}
# operationId: Campaigns_List
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-campaigns list" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --skip: int # Control paging of campaigns, start results at the given offset, defaults to 0 (1st page of data).
  --top: int # Control paging of campaigns, number of campaigns to return with each call. It returns all campaigns by default. When specifying $top parameter, the response contains a `nextLink` property describing the path to get the next page if there are more results.
  --filter: string # Filter can be used to restrict the results to campaigns matching a specific state. The syntax is `$filter=state eq 'draft'`. Valid state values are: draft, scheduled, in-progress, and finished. Only the eq operator and the state property are supported.
  --orderby: string # Sort results by an expression which looks like `$orderby=id asc` (this example is actually the default behavior). The syntax is orderby={property} {direction} or just orderby={property}. The available sorting properties are id, name, state, activatedDate, and finishedDate. The available directions are asc (for ascending order) and desc (for descending order). When not specified the asc direction is used. Only one property at a time can be used for sorting.
  --search: string # Restrict results to campaigns matching the optional `search` expression. This currently performs the search based on the name on the campaign only, case insensitive. If the campaign contains the value of the `search` parameter anywhere in the name, it matches.
]: nothing -> record<nextLink: string, value: table<activatedDate: string, endTime: string, finishedDate: string, name: string, startTime: string, timezone: string, id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name), kind: (encode-path-segment $kind)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/campaigns/{kind}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$skip": $skip, "$top": $top, "$filter": $filter, "$orderby": $orderby, "$search": $search} | compact), body: null}
}

# Create a push campaign (announcement, poll, data push or native push).
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}
# operationId: Campaigns_Create
# --audience shape: {criteria?: record, expression?: string, filters?: list}
# --questions item shape: {choices?: list, id?: int, localization?: record, title?: string}
# --notificationOptions shape: {actionText?: string, bigPicture?: string, bigText?: string, sound?: string}
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-campaigns create" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --audience: record # Specify which users will be targeted by this campaign. By default, all users will be targeted. If you set `pushMode` property to `manual`, the only thing you can specify in the audience is the push quota filter. An audience is a boolean expression made of criteria (variables) operators (`not`, `and` or `or`) and parenthesis. Additionally, a set of filters can be added to an audience. 65535 bytes max as per JSON encoding. — shape: {criteria?: record, expression?: string, filters?: list}
  --category: string # Category of the campaign. Categories can be used on the application side to customize campaigns.
  --delivery-activities: list<string> # Announcements/polls only. Array containing the list of activities in which the campaign can be delivered. deliveryTime must be set to session. If the platform is iOS, this option can also be set if deliveryTime is set to any. In that case, if the campaign is received when the application is launched, it will be delivered only in the specified list of activities.
  --delivery-time: string@delivery-time-completer # Announcements/polls only. Defines when the campaign should be delivered. Valid values are: * `any`: Campaign will be delivered as soon as possible. * `background`: iOS only. Campaign will be only delivered when the application is in background (out of app). * `session`: Campaign will be delivered when the application is running.
  --end-time: string # The date at which the campaign should be finished. The date shall conform to the following format: `yyyy-MM-ddTHH:mm:ssZ`. Example: `2011-11-21 15:23Z`
  --localization: record # Push campaigns can be localized using an optional JSON object. The JSON key is a two-character language code as specified by the ISO 639-1 standard. The corresponding value is an object containing the localizable properties.
  --name: string # Unique name of the campaign.
  --notification-badge: oneof<nothing, bool> # A flag indicating whether or not you want the native Apple Push notification to update the badge icon to the number of unread messages. The `deliveryTime` property must be set to `any` or `background`. (default: false)
  --notification-closeable: oneof<nothing, bool> # A flag indicating whether or not you want the notification to be closeable. (default: true)
  --notification-icon: oneof<nothing, bool> # A flag indicating whether or not you want to display the resource icon in notification content. (default: true)
  --notification-sound: oneof<nothing, bool> # * `Android`: A flag indicating whether or not you want the system notification to make a sound. The `notificationType` property must be set to `system`. * `iOS`: A flag indicating whether or not you want the native Apple Push notification to make a sound. The `deliveryTime` property must be set to `any` or `background`. This will play the 'default' sound. If you want to play a custom sound, see the `notificationOptions` property. * `Windows`: A flag indicating whether or not you want the native Windows Notification Service to make a sound. The `deliveryTime` property must be set to `any`. (default: false)
  --notification-type: string@notification-type-completer # Android only. Defines how the notification should be displayed. Valid values are: * `system`: Display the notification using a standard system notification. * `popup`: Display the notification using a in-app banner notification. (default: popup)
  --notification-vibrate: oneof<nothing, bool> # Android only. A flag indicating whether or not you want the system notification to make a vibration. The notificationType property must be set to system. (default: false)
  --push-mode: string@push-mode-completer # Announcements/polls only. Defines how the campaign is pushed. Valid values are: * `real-time`: Never ending campaign, the campaign will be delivered to your existing users and also to your new users. * `one-shot`: In this mode, the campaign will be delivered only to your existing users (campaign will stop after that). * `manual`: In this mode, the campaign will not be pushed automatically to devices. You will have to use the Push campaign command to push the campaign to your end-users. Campaigns can be pushed multiple times to the same device. (default: real-time)
  --questions: list # Poll questions. — item shape: {choices?: list, id?: int, localization?: record, title?: string}
  --start-time: string # The date at which the campaign should be started. The date shall conform to the following format: `yyyy-MM-ddTHH:mm:ssZ`. * If you set pushMode property to manual, this attribute will be ignored. * If you set pushMode property to one-shot, then the timezone attribute must be specified. Example: `2011-11-21 15:23Z`
  --timezone: string # The id of the time zone to use for the startTime and endTime dates. If not provided, the two date attributes will be expressed using the device timezone. Example: America/Los_Angeles
  --type: string@type-completer # Applicable only to announcements and data pushes. Type of announcement. Valid values are: * `text/plain`: Text-only announcement: `body` property should only contain plain text. * `text/html`: HTML announcement: `body` attribute can contain HTML code. * `only_notif`: Notification-only announcement. With this kind of announcements, the `body`, `title`, `actionButtonText` and `exitButtonText` are ignored. Type of data push. Valid values are: * `text/plain`: Text only data push: `body` property must be plain text. * `text/base64`: Base 64 data push: `body` property must be encoded in base 64.
  --action-button-text: string # Text of the action button for text/web announcements and polls (answer button).
  --action-url: string # URL to launch when the announcement is actioned.
  --body: string # Body of the text/web announcement, poll or data push. This field supports appInfo markers.
  --exit-button-text: string # Text of the exit button for text/web announcements and polls.
  --notification-image: string # Optional image encoded in base 64. Usually included in the right part of in app notifications (or as a banner if there is neither text nor content icon). For Android system notifications, the image is used as the large icon (displayed only on Android 3+). (format: byte)
  --notification-message: string # Message of the notification. This field supports appInfo markers.
  --notification-options: any # shape: {actionText?: string, bigPicture?: string, bigText?: string, sound?: string}
  --notification-title: string # Title of the notification. This field supports appInfo markers.
  --payload: record # Native push payload.
  --title: string # Title of the announcement or poll. This field supports appInfo markers.
]: any -> record<id: int, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name), kind: (encode-path-segment $kind)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/campaigns/{kind}") $qp)
  let req_body = {"audience": $audience, "category": $category, "deliveryActivities": $delivery_activities, "deliveryTime": $delivery_time, "endTime": $end_time, "localization": $localization, "name": $name, "notificationBadge": $notification_badge, "notificationCloseable": $notification_closeable, "notificationIcon": $notification_icon, "notificationSound": $notification_sound, "notificationType": $notification_type, "notificationVibrate": $notification_vibrate, "pushMode": $push_mode, "questions": $questions, "startTime": $start_time, "timezone": $timezone, "type": $type, "actionButtonText": $action_button_text, "actionUrl": $action_url, "body": $body, "exitButtonText": $exit_button_text, "notificationImage": $notification_image, "notificationMessage": $notification_message, "notificationOptions": $notification_options, "notificationTitle": $notification_title, "payload": $payload, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Test a new campaign on a set of devices.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/test
# operationId: Campaigns_TestNew
# --data shape: {audience?: record, category?: string, deliveryActivities?: list<string>, deliveryTime?: "any"|"background"|"session", endTime?: string, localization?: record, name?: string, notificationBadge?: bool, notificationCloseable?: bool, notificationIcon?: bool, notificationSound?: bool, notificationType?: "system"|"popup", notificationVibrate?: bool, pushMode?: "real-time"|"one-shot"|"manual", questions?: list, startTime?: string, timezone?: string, ... (11 more fields)}
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-campaigns-test test-new" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  data: any # shape: {audience?: record, category?: string, deliveryActivities?: list<string>, deliveryTime?: "any"|"background"|"session", endTime?: string, localization?: record, name?: string, notificationBadge?: bool, notificationCloseable?: bool, notificationIcon?: bool, notificationSound?: bool, notificationType?: "system"|"popup", notificationVibrate?: bool, pushMode?: "real-time"|"one-shot"|"manual", questions?: list, startTime?: string, timezone?: string, ... (11 more fields)}
  device_id: string # Device identifier (as returned by the SDK).
  --lang: string # The language to test expressed using ISO 639-1 code. The default language of the campaign will be used if the parameter is not provided.
]: any -> record<state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name), kind: (encode-path-segment $kind)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/campaigns/{kind}/test") $qp)
  let req_body = {"data": $data, "deviceId": $device_id, "lang": $lang} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Delete a campaign previously created by a call to Create campaign.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}
# operationId: Campaigns_Delete
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-campaigns delete" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name), kind: (encode-path-segment $kind), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/campaigns/{kind}/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# The Get campaign operation retrieves information about a previously created campaign.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}
# operationId: Campaigns_Get
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-campaigns get" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<activatedDate: string, finishedDate: string, id: int, state: string, audience: record<criteria: record, expression: string, filters: list<record>>, category: string, deliveryActivities: list<string>, deliveryTime: string, endTime: string, localization: record, name: string, notificationBadge: bool, notificationCloseable: bool, notificationIcon: bool, notificationSound: bool, notificationType: string, notificationVibrate: bool, pushMode: string, questions: table<choices: list, id: int, localization: record, title: string>, startTime: string, timezone: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name), kind: (encode-path-segment $kind), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/campaigns/{kind}/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Update an existing push campaign (announcement, poll, data push or native push).
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}
# operationId: Campaigns_Update
# --audience shape: {criteria?: record, expression?: string, filters?: list}
# --questions item shape: {choices?: list, id?: int, localization?: record, title?: string}
# --notificationOptions shape: {actionText?: string, bigPicture?: string, bigText?: string, sound?: string}
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-campaigns update" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --audience: record # Specify which users will be targeted by this campaign. By default, all users will be targeted. If you set `pushMode` property to `manual`, the only thing you can specify in the audience is the push quota filter. An audience is a boolean expression made of criteria (variables) operators (`not`, `and` or `or`) and parenthesis. Additionally, a set of filters can be added to an audience. 65535 bytes max as per JSON encoding. — shape: {criteria?: record, expression?: string, filters?: list}
  --category: string # Category of the campaign. Categories can be used on the application side to customize campaigns.
  --delivery-activities: list<string> # Announcements/polls only. Array containing the list of activities in which the campaign can be delivered. deliveryTime must be set to session. If the platform is iOS, this option can also be set if deliveryTime is set to any. In that case, if the campaign is received when the application is launched, it will be delivered only in the specified list of activities.
  --delivery-time: string@delivery-time-completer # Announcements/polls only. Defines when the campaign should be delivered. Valid values are: * `any`: Campaign will be delivered as soon as possible. * `background`: iOS only. Campaign will be only delivered when the application is in background (out of app). * `session`: Campaign will be delivered when the application is running.
  --end-time: string # The date at which the campaign should be finished. The date shall conform to the following format: `yyyy-MM-ddTHH:mm:ssZ`. Example: `2011-11-21 15:23Z`
  --localization: record # Push campaigns can be localized using an optional JSON object. The JSON key is a two-character language code as specified by the ISO 639-1 standard. The corresponding value is an object containing the localizable properties.
  --name: string # Unique name of the campaign.
  --notification-badge: oneof<nothing, bool> # A flag indicating whether or not you want the native Apple Push notification to update the badge icon to the number of unread messages. The `deliveryTime` property must be set to `any` or `background`. (default: false)
  --notification-closeable: oneof<nothing, bool> # A flag indicating whether or not you want the notification to be closeable. (default: true)
  --notification-icon: oneof<nothing, bool> # A flag indicating whether or not you want to display the resource icon in notification content. (default: true)
  --notification-sound: oneof<nothing, bool> # * `Android`: A flag indicating whether or not you want the system notification to make a sound. The `notificationType` property must be set to `system`. * `iOS`: A flag indicating whether or not you want the native Apple Push notification to make a sound. The `deliveryTime` property must be set to `any` or `background`. This will play the 'default' sound. If you want to play a custom sound, see the `notificationOptions` property. * `Windows`: A flag indicating whether or not you want the native Windows Notification Service to make a sound. The `deliveryTime` property must be set to `any`. (default: false)
  --notification-type: string@notification-type-completer # Android only. Defines how the notification should be displayed. Valid values are: * `system`: Display the notification using a standard system notification. * `popup`: Display the notification using a in-app banner notification. (default: popup)
  --notification-vibrate: oneof<nothing, bool> # Android only. A flag indicating whether or not you want the system notification to make a vibration. The notificationType property must be set to system. (default: false)
  --push-mode: string@push-mode-completer # Announcements/polls only. Defines how the campaign is pushed. Valid values are: * `real-time`: Never ending campaign, the campaign will be delivered to your existing users and also to your new users. * `one-shot`: In this mode, the campaign will be delivered only to your existing users (campaign will stop after that). * `manual`: In this mode, the campaign will not be pushed automatically to devices. You will have to use the Push campaign command to push the campaign to your end-users. Campaigns can be pushed multiple times to the same device. (default: real-time)
  --questions: list # Poll questions. — item shape: {choices?: list, id?: int, localization?: record, title?: string}
  --start-time: string # The date at which the campaign should be started. The date shall conform to the following format: `yyyy-MM-ddTHH:mm:ssZ`. * If you set pushMode property to manual, this attribute will be ignored. * If you set pushMode property to one-shot, then the timezone attribute must be specified. Example: `2011-11-21 15:23Z`
  --timezone: string # The id of the time zone to use for the startTime and endTime dates. If not provided, the two date attributes will be expressed using the device timezone. Example: America/Los_Angeles
  --type: string@type-completer # Applicable only to announcements and data pushes. Type of announcement. Valid values are: * `text/plain`: Text-only announcement: `body` property should only contain plain text. * `text/html`: HTML announcement: `body` attribute can contain HTML code. * `only_notif`: Notification-only announcement. With this kind of announcements, the `body`, `title`, `actionButtonText` and `exitButtonText` are ignored. Type of data push. Valid values are: * `text/plain`: Text only data push: `body` property must be plain text. * `text/base64`: Base 64 data push: `body` property must be encoded in base 64.
  --action-button-text: string # Text of the action button for text/web announcements and polls (answer button).
  --action-url: string # URL to launch when the announcement is actioned.
  --body: string # Body of the text/web announcement, poll or data push. This field supports appInfo markers.
  --exit-button-text: string # Text of the exit button for text/web announcements and polls.
  --notification-image: string # Optional image encoded in base 64. Usually included in the right part of in app notifications (or as a banner if there is neither text nor content icon). For Android system notifications, the image is used as the large icon (displayed only on Android 3+). (format: byte)
  --notification-message: string # Message of the notification. This field supports appInfo markers.
  --notification-options: any # shape: {actionText?: string, bigPicture?: string, bigText?: string, sound?: string}
  --notification-title: string # Title of the notification. This field supports appInfo markers.
  --payload: record # Native push payload.
  --title: string # Title of the announcement or poll. This field supports appInfo markers.
]: any -> record<id: int, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name), kind: (encode-path-segment $kind), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/campaigns/{kind}/{id}") $qp)
  let req_body = {"audience": $audience, "category": $category, "deliveryActivities": $delivery_activities, "deliveryTime": $delivery_time, "endTime": $end_time, "localization": $localization, "name": $name, "notificationBadge": $notification_badge, "notificationCloseable": $notification_closeable, "notificationIcon": $notification_icon, "notificationSound": $notification_sound, "notificationType": $notification_type, "notificationVibrate": $notification_vibrate, "pushMode": $push_mode, "questions": $questions, "startTime": $start_time, "timezone": $timezone, "type": $type, "actionButtonText": $action_button_text, "actionUrl": $action_url, "body": $body, "exitButtonText": $exit_button_text, "notificationImage": $notification_image, "notificationMessage": $notification_message, "notificationOptions": $notification_options, "notificationTitle": $notification_title, "payload": $payload, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Activate a campaign previously created by a call to Create campaign.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}/activate
# operationId: Campaigns_Activate
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-campaigns-activate create" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: int, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name), kind: (encode-path-segment $kind), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/campaigns/{kind}/{id}/activate") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Finish a push campaign previously activated by a call to Activate campaign.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}/finish
# operationId: Campaigns_Finish
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-campaigns-finish create" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: int, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name), kind: (encode-path-segment $kind), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/campaigns/{kind}/{id}/finish") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Push a previously saved campaign (created with Create campaign) to a set of devices.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}/push
# operationId: Campaigns_Push
# --data shape: {audience?: record, category?: string, deliveryActivities?: list<string>, deliveryTime?: "any"|"background"|"session", endTime?: string, localization?: record, name?: string, notificationBadge?: bool, notificationCloseable?: bool, notificationIcon?: bool, notificationSound?: bool, notificationType?: "system"|"popup", notificationVibrate?: bool, pushMode?: "real-time"|"one-shot"|"manual", questions?: list, startTime?: string, timezone?: string, ... (11 more fields)}
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-campaigns-push push" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --data: any # shape: {audience?: record, category?: string, deliveryActivities?: list<string>, deliveryTime?: "any"|"background"|"session", endTime?: string, localization?: record, name?: string, notificationBadge?: bool, notificationCloseable?: bool, notificationIcon?: bool, notificationSound?: bool, notificationType?: "system"|"popup", notificationVibrate?: bool, pushMode?: "real-time"|"one-shot"|"manual", questions?: list, startTime?: string, timezone?: string, ... (11 more fields)}
  device_ids: list<string> # Device identifiers to push as a JSON array of strings. Note that if you want to push the same campaign several times to the same device, you need to make several API calls.
]: any -> record<invalidDeviceIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name), kind: (encode-path-segment $kind), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/campaigns/{kind}/{id}/push") $qp)
  let req_body = {"data": $data, "deviceIds": $device_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Get all the campaign statistics.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}/statistics
# operationId: Campaigns_GetStatistics
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-campaigns-statistics get" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<answers: record, content_actioned: int, content_displayed: int, content_exited: int, delivered: int, dropped: int, in_app_notification_actioned: int, in_app_notification_displayed: int, in_app_notification_exited: int, pushed: int, pushed_native: int, pushed_native_adm: int, pushed_native_google: int, queued: int, system_notification_actioned: int, system_notification_displayed: int, system_notification_exited: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name), kind: (encode-path-segment $kind), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/campaigns/{kind}/{id}/statistics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Suspend a push campaign previously activated by a call to Activate campaign.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}/suspend
# operationId: Campaigns_Suspend
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-campaigns-suspend create" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: int, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name), kind: (encode-path-segment $kind), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/campaigns/{kind}/{id}/suspend") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Test an existing campaign (created with Create campaign) on a set of devices.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaigns/{kind}/{id}/test
# operationId: Campaigns_TestSaved
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-campaigns-test test-saved" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  device_id: string # Device identifier (as returned by the SDK).
  --lang: string # The language to test expressed using ISO 639-1 code. The default language of the campaign will be used if the parameter is not provided.
]: any -> record<id: int, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name), kind: (encode-path-segment $kind), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/campaigns/{kind}/{id}/test") $qp)
  let req_body = {"deviceId": $device_id, "lang": $lang} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# The Get campaign operation retrieves information about a previously created campaign.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/campaignsByName/{kind}/{name}
# operationId: Campaigns_GetByName
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-campaigns-by-name get" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  kind: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<activatedDate: string, finishedDate: string, id: int, state: string, audience: record<criteria: record, expression: string, filters: list<record>>, category: string, deliveryActivities: list<string>, deliveryTime: string, endTime: string, localization: record, name: string, notificationBadge: bool, notificationCloseable: bool, notificationIcon: bool, notificationSound: bool, notificationType: string, notificationVibrate: bool, pushMode: string, questions: table<choices: list, id: int, localization: record, title: string>, startTime: string, timezone: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name), kind: (encode-path-segment $kind), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/campaignsByName/{kind}/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Query the information associated to the devices running an application.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices
# operationId: Devices_List
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-devices list" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --top: int # Number of devices to return with each call. Defaults to 100 and cannot return more. Passing a greater value is ignored. The response contains a `nextLink` property describing the URI path to get the next page of results if not all results could be returned at once.
  --select: string # By default all `meta` and `appInfo` properties are returned, this property is used to restrict the output to the desired properties. It also excludes all devices from the output that have none of the selected properties. In other terms, only devices having at least one of the selected property being set is part of the results. Examples: - `$select=appInfo` : select all devices having at least 1 appInfo, return them all and don’t return any meta property. - `$select=meta` : return only meta properties in the output. - `$select=appInfo,meta/firstSeen,meta/lastSeen` : return all `appInfo`, plus meta object containing only firstSeen and lastSeen properties. The format is thus a comma separated list of properties to select. Use `appInfo` to select all appInfo properties, `meta` to select all meta properties. Use `appInfo/{key}` and `meta/{key}` to select specific appInfo and meta properties.
  --filter: string # Filter can be used to reduce the number of results. Filter is a boolean expression that can look like the following examples: * `$filter=deviceId gt 'abcdef0123456789abcdef0123456789'` * `$filter=lastModified le 1447284263690L` * `$filter=(deviceId ge 'abcdef0123456789abcdef0123456789') and (deviceId lt 'bacdef0123456789abcdef0123456789') and (lastModified gt 1447284263690L)` The first example is used automatically for paging when returning the `nextLink` property. The filter expression is a combination of checks on some properties that can be compared to their value. The available operators are: * `gt` : greater than * `ge` : greater than or equals * `lt` : less than * `le` : less than or equals * `and` : to add multiple checks (all checks must pass), optional parentheses can be used. The properties that can be used in the expression are the following: * `deviceId {operator} '{deviceIdValue}'` : a lexicographical comparison is made on the deviceId value, use single quotes for the value. * `lastModified {operator} {number}L` : returns only meta properties or appInfo properties whose last value modification timestamp compared to the specified value is matching (value is milliseconds since January 1st, 1970 UTC). Please note the `L` character after the number of milliseconds, its required when the number of milliseconds exceeds `2^31 - 1` (which is always the case for recent timestamps). Using `lastModified` excludes all devices from the output that have no property matching the timestamp criteria, like `$select`. Please note that the internal value of `lastModified` timestamp for a given property is never part of the results.
]: nothing -> record<nextLink: string, value: table<appInfo: record, deviceId: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/devices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$top": $top, "$select": $select, "$filter": $filter} | compact), body: null}
}

# Get the list of export tasks.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks
# operationId: ExportTasks_List
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-devices-export-tasks list" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --skip: int # Control paging of export tasks, start results at the given offset, defaults to 0 (1st page of data). (default: 0)
  --top: int # Control paging of export tasks, number of export tasks to return with each call. By default, it returns all export tasks with a default paging of 20. The response contains a `nextLink` property describing the path to get the next page if there are more results. The maximum paging limit for $top is 40. (default: 20)
  --orderby: string # Sort results by an expression which looks like `$orderby=taskId asc` (default when not specified). The syntax is orderby={property} {direction} or just orderby={property}. Properties that can be specified for sorting: taskId, errorDetails, dateCreated, taskStatus, and dateCreated. The available directions are asc (for ascending order) and desc (for descending order). When not specified the asc direction is used. Only one orderby property can be specified.
]: nothing -> record<nextLink: string, value: table<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/devices/exportTasks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$skip": $skip, "$top": $top, "$orderby": $orderby} | compact), body: null}
}

# Creates a task to export activities.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/activities
# operationId: ExportTasks_CreateActivitiesTask
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-devices-export-tasks-activities create" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  container_url: string # format: uri
  --description: string # A description of the export task.
  end_date: string # A date as defined by full-date in RFC3339. (format: date)
  export_format: string@export-format-completer # The format of exported data.
  start_date: string # A date as defined by full-date in RFC3339. (format: date)
]: any -> record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/devices/exportTasks/activities") $qp)
  let req_body = {"containerUrl": $container_url, "description": $description, "endDate": $end_date, "exportFormat": $export_format, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates a task to export crashes.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/crashes
# operationId: ExportTasks_CreateCrashesTask
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-devices-export-tasks-crashes create" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  container_url: string # format: uri
  --description: string # A description of the export task.
  end_date: string # A date as defined by full-date in RFC3339. (format: date)
  export_format: string@export-format-completer # The format of exported data.
  start_date: string # A date as defined by full-date in RFC3339. (format: date)
]: any -> record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/devices/exportTasks/crashes") $qp)
  let req_body = {"containerUrl": $container_url, "description": $description, "endDate": $end_date, "exportFormat": $export_format, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates a task to export errors.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/errors
# operationId: ExportTasks_CreateErrorsTask
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-devices-export-tasks-errors create" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  container_url: string # format: uri
  --description: string # A description of the export task.
  end_date: string # A date as defined by full-date in RFC3339. (format: date)
  export_format: string@export-format-completer # The format of exported data.
  start_date: string # A date as defined by full-date in RFC3339. (format: date)
]: any -> record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/devices/exportTasks/errors") $qp)
  let req_body = {"containerUrl": $container_url, "description": $description, "endDate": $end_date, "exportFormat": $export_format, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates a task to export events.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/events
# operationId: ExportTasks_CreateEventsTask
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-devices-export-tasks-events create" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  container_url: string # format: uri
  --description: string # A description of the export task.
  end_date: string # A date as defined by full-date in RFC3339. (format: date)
  export_format: string@export-format-completer # The format of exported data.
  start_date: string # A date as defined by full-date in RFC3339. (format: date)
]: any -> record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/devices/exportTasks/events") $qp)
  let req_body = {"containerUrl": $container_url, "description": $description, "endDate": $end_date, "exportFormat": $export_format, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates a task to export push campaign data for a set of campaigns.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/feedbackByCampaign
# operationId: ExportTasks_CreateFeedbackTaskByCampaign
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-devices-export-tasks-feedback-by-campaign create" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  campaign_ids: list<int> # A list of campaign identifiers.
  campaign_type: string@campaign-type-completer # Campaign type.
  container_url: string # format: uri
  --description: string # A description of the export task.
  export_format: string@export-format-completer # The format of exported data.
]: any -> record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/devices/exportTasks/feedbackByCampaign") $qp)
  let req_body = {"campaignIds": $campaign_ids, "campaignType": $campaign_type, "containerUrl": $container_url, "description": $description, "exportFormat": $export_format} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates a task to export push campaign data for a date range.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/feedbackByDate
# operationId: ExportTasks_CreateFeedbackTaskByDateRange
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-devices-export-tasks-feedback-by-date create-range" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  campaign_type: string@campaign-type-completer # Campaign type.
  campaign_window_end: string # A date time as defined by date-time in RFC3339. (format: date-time)
  campaign_window_start: string # A date time as defined by date-time in RFC3339. (format: date-time)
  container_url: string # format: uri
  --description: string # A description of the export task.
  export_format: string@export-format-completer # The format of exported data.
]: any -> record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/devices/exportTasks/feedbackByDate") $qp)
  let req_body = {"campaignType": $campaign_type, "campaignWindowEnd": $campaign_window_end, "campaignWindowStart": $campaign_window_start, "containerUrl": $container_url, "description": $description, "exportFormat": $export_format} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates a task to export jobs.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/jobs
# operationId: ExportTasks_CreateJobsTask
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-devices-export-tasks-jobs create" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  container_url: string # format: uri
  --description: string # A description of the export task.
  end_date: string # A date as defined by full-date in RFC3339. (format: date)
  export_format: string@export-format-completer # The format of exported data.
  start_date: string # A date as defined by full-date in RFC3339. (format: date)
]: any -> record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/devices/exportTasks/jobs") $qp)
  let req_body = {"containerUrl": $container_url, "description": $description, "endDate": $end_date, "exportFormat": $export_format, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates a task to export sessions.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/sessions
# operationId: ExportTasks_CreateSessionsTask
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-devices-export-tasks-sessions create" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  container_url: string # format: uri
  --description: string # A description of the export task.
  end_date: string # A date as defined by full-date in RFC3339. (format: date)
  export_format: string@export-format-completer # The format of exported data.
  start_date: string # A date as defined by full-date in RFC3339. (format: date)
]: any -> record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/devices/exportTasks/sessions") $qp)
  let req_body = {"containerUrl": $container_url, "description": $description, "endDate": $end_date, "exportFormat": $export_format, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates a task to export tags.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/tags
# operationId: ExportTasks_CreateTagsTask
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-devices-export-tasks-tags create" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  container_url: string # format: uri
  --description: string # A description of the export task.
  export_format: string@export-format-completer # The format of exported data.
]: any -> record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/devices/exportTasks/tags") $qp)
  let req_body = {"containerUrl": $container_url, "description": $description, "exportFormat": $export_format} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates a task to export tags.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/tokens
# operationId: ExportTasks_CreateTokensTask
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-devices-export-tasks-tokens create" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  container_url: string # format: uri
  --description: string # A description of the export task.
  export_format: string@export-format-completer # The format of exported data.
]: any -> record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/devices/exportTasks/tokens") $qp)
  let req_body = {"containerUrl": $container_url, "description": $description, "exportFormat": $export_format} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Retrieves information about a previously created export task.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/exportTasks/{id}
# operationId: ExportTasks_Get
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-devices-export-tasks get" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<dateCompleted: string, dateCreated: string, description: string, errorDetails: string, exportType: string, id: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/devices/exportTasks/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Get the list of import jobs.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/importTasks
# operationId: ImportTasks_List
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-devices-import-tasks list" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --skip: int # Control paging of import jobs, start results at the given offset, defaults to 0 (1st page of data). (default: 0)
  --top: int # Control paging of import jobs, number of import jobs to return with each call. By default, it returns all import jobs with a default paging of 20. The response contains a `nextLink` property describing the path to get the next page if there are more results. The maximum paging limit for $top is 40. (default: 20)
  --orderby: string # Sort results by an expression which looks like `$orderby=jobId asc` (default when not specified). The syntax is orderby={property} {direction} or just orderby={property}. Properties that can be specified for sorting: jobId, errorDetails, dateCreated, jobStatus, and dateCreated. The available directions are asc (for ascending order) and desc (for descending order). When not specified the asc direction is used. Only one orderby property can be specified.
]: nothing -> record<nextLink: string, value: table<dateCompleted: string, dateCreated: string, errorDetails: string, id: string, state: string, storageUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/devices/importTasks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$skip": $skip, "$top": $top, "$orderby": $orderby} | compact), body: null}
}

# Creates a job to import the specified data to a storageUrl.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/importTasks
# operationId: ImportTasks_Create
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-devices-import-tasks create" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --storage-url: string # A shared Access Signature (SAS) Storage URI where the job results will be retrieved from.
]: any -> record<dateCompleted: string, dateCreated: string, errorDetails: string, id: string, state: string, storageUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/devices/importTasks") $qp)
  let req_body = {"storageUrl": $storage_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# The Get import job operation retrieves information about a previously created import job.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/importTasks/{id}
# operationId: ImportTasks_Get
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-devices-import-tasks get" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<dateCompleted: string, dateCreated: string, errorDetails: string, id: string, state: string, storageUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/devices/importTasks/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Update the tags registered for a set of devices running an application. Updates are performed asynchronously, meaning that a few seconds are needed before the modifications appear in the results of the Get device command.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/tag
# operationId: Devices_TagByDeviceId
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-devices-tag tag" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --delete-on-null: oneof<nothing, bool> # If this parameter is `true`, tags with a null value will be deleted. (default: false)
  tags: any # A JSON object describing the set of tags to record for a set of users. Each key is a device/user identifier, each value is itself a key/value set: the tags to set for the specified device/user identifier.
]: any -> record<invalidIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/devices/tag") $qp)
  let req_body = {"deleteOnNull": $delete_on_null, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Get the information associated to a device running an application.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/devices/{deviceId}
# operationId: Devices_GetByDeviceId
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-devices get" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<appInfo: record, deviceId: string, info: record<androidAPILevel: int, applicationVersionCode: int, applicationVersionName: string, carrierCountry: string, carrierName: string, firmwareName: string, firmwareVersion: string, locale: string, networkSubtype: string, networkType: string, phoneManufacturer: string, phoneModel: string, serviceVersion: string, timeZoneOffset: int>, location: record<countrycode: string, locality: string, region: string>, meta: record<firstSeen: int, lastInfo: int, lastLocation: int, lastSeen: int, nativePushEnabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name), device_id: (encode-path-segment $device_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/devices/{device_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Update the tags registered for a set of users running an application. Updates are performed asynchronously, meaning that a few seconds are needed before the modifications appear in the results of the Get device command.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/users/tag
# operationId: Devices_TagByUserId
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-users-tag tag-devices" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --delete-on-null: oneof<nothing, bool> # If this parameter is `true`, tags with a null value will be deleted. (default: false)
  tags: any # A JSON object describing the set of tags to record for a set of users. Each key is a device/user identifier, each value is itself a key/value set: the tags to set for the specified device/user identifier.
]: any -> record<invalidIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/users/tag") $qp)
  let req_body = {"deleteOnNull": $delete_on_null, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Get the information associated to a device running an application using the user identifier.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MobileEngagement/appcollections/{appCollection}/apps/{appName}/users/{userId}
# operationId: Devices_GetByUserId
export def "subscriptions-resource-groups-providers-microsoft-mobile-engagement-appcollections-apps-users get-devices" [
  subscription_id: string
  resource_group_name: string
  app_collection: string
  app_name: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<appInfo: record, deviceId: string, info: record<androidAPILevel: int, applicationVersionCode: int, applicationVersionName: string, carrierCountry: string, carrierName: string, firmwareName: string, firmwareVersion: string, locale: string, networkSubtype: string, networkType: string, phoneManufacturer: string, phoneModel: string, serviceVersion: string, timeZoneOffset: int>, location: record<countrycode: string, locality: string, region: string>, meta: record<firstSeen: int, lastInfo: int, lastLocation: int, lastSeen: int, nativePushEnabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($app_collection | is-empty) { error make --unspanned { msg: "path parameter 'appCollection' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), app_collection: (encode-path-segment $app_collection), app_name: (encode-path-segment $app_name), user_id: (encode-path-segment $user_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MobileEngagement/appcollections/{app_collection}/apps/{app_name}/users/{user_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}
