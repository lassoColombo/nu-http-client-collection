# Auto-generated client for Sumo Logic API v1.0.0
# Source: https://api.sumologic.com/docs/sumologic-api.yaml
# Auth: --token flag or $env.SUMOLOGIC_TOKEN

const BASE_URL = "https://api.sumologic.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SUMOLOGIC_TOKEN | default "" }
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
def base-url-completer [] { ["https://api.sumologic.com" "https://api.au.sumologic.com/api" "https://api.ca.sumologic.com/api" "https://api.ch.sumologic.com/api" "https://api.de.sumologic.com/api" "https://api.eu.sumologic.com/api" "https://api.fed.sumologic.com/api" "https://api.jp.sumologic.com/api" "https://api.kr.sumologic.com/api" "https://api.in.sumologic.com/api" "https://api.sumologic.com/api" "https://api.us2.sumologic.com/api"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def type-completer [] { ["ServiceNowDefinition" "WebhookDefinition"] }
def accept-completer [] { ["application/json" "application/xml"] }
def accept-completer-1 [] { ["application/json" "application/pdf" "image/png"] }
def type-completer-1 [] { ["AuthorizationCodeClient" "ClientCredentialsClient"] }
def sortOrder-completer [] { ["ascending" "descending"] }
def accept-completer-2 [] { ["application/json" "application/scim+json"] }
def status-completer [] { ["disable" "enable"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "apps listApps" } } | get name | first)
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

# List available apps.
#
# GET /v1/apps
# operationId: listApps
export def "apps listApps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<apps: table<appDefinition: record, appManifest: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/apps")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an app by UUID.
#
# GET /v1/apps/{uuid}
# operationId: getApp
export def "apps get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<appDefinition: record<contentId: string, uuid: string, name: string, appVersion: string, preview: bool, manifestVersion: string>, appManifest: record<family: string, description: string, categories: list<string>, hoverText: string, iconURL: string, screenshotURLs: list<string>, helpURL: string, helpDocIdMap: record, communityURL: string, requirements: list<string>, accountTypes: list<string>, requiresInstallationInstructions: bool, installationInstructions: string, parameters: list<record>, author: string, authorWebsite: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/apps/($uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Install an app by UUID.
#
# POST /v1/apps/{uuid}/install
# operationId: installApp
export def "apps-install installApp" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Preferred name of the app to be installed. This will be the name of the app in the selected installation folder. (e.g. Sumo Logic Configuration App)
  description: string # Preferred description of the app to be installed. This will be displayed as the app description in the selected installation folder. (e.g. Sumo Logic Configuration App to configure collectors and data sources)
  destinationFolderId: string # Identifier of the folder in which the app will be installed in hexadecimal format. (e.g. 00000000000001C8)
  --dataSourceValues: record # Dictionary of properties specifying log-source name and value. (e.g. {logsrc: _sourceCategory = api})
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/apps/($uuid)/install")
  let body = {name: $name, description: $description, destinationFolderId: $destinationFolderId, dataSourceValues: $dataSourceValues} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# App install job status.
#
# GET /v1/apps/install/{jobId}/status
# operationId: getAsyncInstallStatus
export def "apps-install-status get-by-jobId" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, statusMessage: string, error: record<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/apps/install/($jobId)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start app install job
#
# POST /v2/apps/{uuid}/install
# operationId: asyncInstallApp
export def "apps-install asyncInstallApp" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # Version of the app to install. You can either specify a specific version of the app or use `latest` to install the latest version of the app. _If version is not specified, the latest version of the app will be installed_.  (default: latest, e.g. 1.0.1)
  --parameters: record # Map of additional parameters for the app installation. (e.g. {db_system: redis})
]: any -> record<jobId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/apps/($uuid)/install")
  let body = {version: $version, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# App install job status
#
# GET /v2/apps/install/{jobId}/status
# operationId: getAsyncInstallAppStatus
export def "apps-install-status get-by-jobId-1" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, instanceId: string, path: string, folderId: string, error: record<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/apps/install/($jobId)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start app uninstall job
#
# POST /v2/apps/{uuid}/uninstall
# operationId: asyncUninstallApp
export def "apps-uninstall asyncUninstallApp" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<jobId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/apps/($uuid)/uninstall")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# App uninstall job status
#
# GET /v2/apps/uninstall/{jobId}/status
# operationId: getAsyncUninstallAppStatus
export def "apps-uninstall-status get" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/apps/uninstall/($jobId)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start app upgrade job
#
# POST /v2/apps/{uuid}/upgrade
# operationId: asyncUpgradeApp
export def "apps-upgrade asyncUpgradeApp" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # Version of the app to upgrade. You can either specify a specific version of the app or use `latest` to install the latest version of the app. _If version is not specified, the latest version of the app will be installed_.  (default: latest, e.g. 1.0.1)
  --parameters: record # Map of additional parameters for the app installation. (e.g. {db_system: redis})
]: any -> record<jobId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/apps/($uuid)/upgrade")
  let body = {version: $version, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# App upgrade job status
#
# GET /v2/apps/upgrade/{jobId}/status
# operationId: getAsyncUpgradeAppStatus
export def "apps-upgrade-status get" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, instanceId: string, path: string, folderId: string, error: record<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/apps/upgrade/($jobId)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List apps
#
# GET /v2/apps
# operationId: listAppsV2
export def "apps listAppsV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the app. (e.g. AWS%20CloudTrail)
  --author: string # Author of the app. (e.g. Sumo%20Logic)
]: nothing -> record<apps: table<uuid: string, name: string, description: string, latestVersion: string, icon: string, author: string, accountTypes: list, beta: bool, installs: int, attributes: record, installable: bool, showOnMarketplace: bool, modifiedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "author" $author "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/apps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details of an app version.
#
# GET /v2/apps/{uuid}/details
# operationId: getAppDetails
export def "apps-details get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # Version of the app. The latest version is used if this is omitted or specified as "latest". (e.g. 1.0.0)
]: nothing -> record<uuid: string, version: string, baseUrl: string, manifest: string, config: string, readme: string, files: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/apps/($uuid)/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get subscription status for the user
#
# GET /v2/apps/{uuid}/subscription
# operationId: getAppNotificationSubscriptionStatus
export def "apps-subscription get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/apps/($uuid)/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscribe to an app upgrade notification
#
# POST /v2/apps/{uuid}/subscription
# operationId: subscribeToAppNotification
export def "apps-subscription subscribeToAppNotification" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/apps/($uuid)/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unsubscribe from an app upgrade notification
#
# DELETE /v2/apps/{uuid}/subscription
# operationId: unsubscribeFromAppNotification
export def "apps-subscription unsubscribeFromAppNotification" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/apps/($uuid)/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of connections.
#
# GET /v1/connections
# operationId: listConnections
export def "connections listConnections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of connections returned in the response. The number of connections returned may be less than the `limit`. (format: int32, default: 100)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left.
]: nothing -> record<data: table<type: string, id: string, name: string, description: string, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new connection.
#
# POST /v1/connections
# Discriminator (request): type = ServiceNowDefinition, WebhookDefinition
# operationId: createConnection
export def "connections createConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer # Type of connection. Valid values are `WebhookDefinition`, `ServiceNowDefinition`.
  name: string # Name of the connection.
  --description: string # Description of the connection. (default: )
]: any -> record<type: string, id: string, name: string, description: string, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections")
  let body = {type: $type, name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Test a new connection url.
#
# POST /v1/connections/test
# Discriminator (request): type = ServiceNowDefinition, WebhookDefinition
# operationId: testConnection
export def "connections-test testConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --functionalities: list # A comma-separated functionalities of webhook payload to test. Acceptable values: `alert`, `resolution`. (default: [alert], e.g. alert,resolution)
  --connectionId: string # Unique identifier of an existing connection to test. It should be provided when the request body of an existing connection contains masked authorization headers. If not provided, the authorization headers will not be correctly unmasked, and the test may fail due to unauthorized access. (e.g. 0000000000123ABC)
  type: string@type-completer # Type of connection. Valid values are `WebhookDefinition`, `ServiceNowDefinition`.
  name: string # Name of the connection.
  --description: string # Description of the connection. (default: )
]: any -> record<statusCode: int, responseContent: string, alertStatusCode: int, alertResponseContent: string, resolutionStatusCode: int, resolutionResponseContent: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "functionalities" $functionalities "csv") (serialize-qp "connectionId" $connectionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/connections/test" $qp)
  let body = {type: $type, name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get incident templates for CloudSOAR connections.
#
# POST /v1/connections/incidentTemplates
# operationId: getIncidentTemplates
export def "connections-incident-templates post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # Optional CloudSOAR domain URL to use for the API call to get incident templates. (e.g. https://staging.soar.sumologic.com/)
  --authHeader: string # Optional CloudSOAR authorization header to use for the API call to get incident templates. (e.g. SOMEAUTHHEADERSTRING)
  --connectionId: string # Optional connectionId to get incident templates for an existing CloudSOAR connection. If provided, the authHeader and url will be taken from the existing connection object. (e.g. 0000000000123ABC)
]: any -> record<templates: table<id: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connections/incidentTemplates")
  let body = {url: $body_url, authHeader: $authHeader, connectionId: $connectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a connection.
#
# GET /v1/connections/{id}
# Discriminator (response): type
# operationId: getConnection
export def "connections get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string # Type of connection to return. Valid values are `WebhookConnection`, `ServiceNowConnection`. (default: WebhookConnection)
]: nothing -> record<type: string, id: string, name: string, description: string, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/connections/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a connection.
#
# PUT /v1/connections/{id}
# Discriminator (request): type = ServiceNowDefinition, WebhookDefinition
# operationId: updateConnection
export def "connections updateConnection" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer # Type of connection. Valid values are `WebhookDefinition`, `ServiceNowDefinition`.
  name: string # Name of the connection.
  --description: string # Description of the connection. (default: )
]: any -> record<type: string, id: string, name: string, description: string, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connections/($id)")
  let body = {type: $type, name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a connection.
#
# DELETE /v1/connections/{id}
# operationId: deleteConnection
export def "connections delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string # Type of connection to delete. Valid values are `WebhookConnection`, `ServiceNowConnection`.
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/connections/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of scheduled views.
#
# GET /v1/scheduledViews
# operationId: listScheduledViews
export def "scheduled-views listScheduledViews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of scheduled views returned in the response. The number of scheduled views returned may be less than the `limit`. (format: int32, default: 100)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left.
]: nothing -> record<data: list<record>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/scheduledViews" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new scheduled view.
#
# POST /v1/scheduledViews
# operationId: createScheduledView
export def "scheduled-views createScheduledView" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: string # The query that defines the data to be included in the scheduled view. (e.g. _sourceCategory=*/Apache)
  indexName: string # Name of the index for the scheduled view. (e.g. TestScheduledView)
  startTime: string # Start timestamp in UTC in [RFC3339](https://tools.ietf.org/html/rfc3339) format. (format: date-time)
  --retentionPeriod: int # The number of days to retain data in the scheduled view, or -1 to use the default value for your account. Only relevant if your account has multi-retention enabled. (format: int32, default: -1, e.g. 60)
  --dataForwardingId: string # An optional ID of a data forwarding configuration to be used by the scheduled view.
  --parsingMode: string # Define the parsing mode to scan the JSON format log messages. Possible values are:   1. `AutoParse`   2. `Manual` In AutoParse mode, the system automatically figures out fields to parse based on the search query. While in the Manual mode, no fields are parsed out automatically. For more information see [Dynamic Parsing](https://help.sumologic.com/?cid=0011). (default: Manual, e.g. AutoParse)
  --timeZone: string # Time zone for ingesting data in scheduled view. Follow the format in the [IANA Time Zone Database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List). (default: UTC, e.g. America/Los_Angeles)
  --description: string # Description of the scheduled view. (default: )
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scheduledViews")
  let body = {query: $body_query, indexName: $indexName, startTime: $startTime, retentionPeriod: $retentionPeriod, dataForwardingId: $dataForwardingId, parsingMode: $parsingMode, timeZone: $timeZone, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a scheduled view.
#
# GET /v1/scheduledViews/{id}
# operationId: getScheduledView
export def "scheduled-views get" [
  id: string
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
  let full_url = (build-url $base $"/v1/scheduledViews/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a scheduled view.
#
# PUT /v1/scheduledViews/{id}
# operationId: updateScheduledView
export def "scheduled-views updateScheduledView" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataForwardingId: string # An optional ID of a data forwarding configuration to be used by the scheduled view.
  --retentionPeriod: int # The number of days to retain data in the scheduled view, or -1 to use the default value for your account.  Only relevant if your account has multi-retention. enabled. (format: int32, default: -1, e.g. 365)
  --reduceRetentionPeriodImmediately: string@bool-completer # This is required if the newly specified `retentionPeriod` is less than the existing retention period.  In such a situation, a value of `true` says that data between the existing retention period and the new retention period should be deleted immediately; if `false`, such data will be deleted after seven days. This property is optional and ignored if the specified `retentionPeriod` is greater than or equal to the current retention period. (default: false)
  --timeZone: string # Updates the time zone for ingesting data in scheduled view to the specified timezone ( does nothing if not specified ). Follow the format in the [IANA Time Zone Database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List). (e.g. America/Los_Angeles)
  --description: string # Description of the scheduled view.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/scheduledViews/($id)")
  let body = {dataForwardingId: $dataForwardingId, retentionPeriod: $retentionPeriod, reduceRetentionPeriodImmediately: $reduceRetentionPeriodImmediately, timeZone: $timeZone, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disable a scheduled view.
#
# DELETE /v1/scheduledViews/{id}/disable
# operationId: disableScheduledView
export def "scheduled-views-disable disableScheduledView" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/scheduledViews/($id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause a scheduled view.
#
# POST /v1/scheduledViews/{id}/pause
# operationId: pauseScheduledView
export def "scheduled-views-pause pauseScheduledView" [
  id: string
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
  let full_url = (build-url $base $"/v1/scheduledViews/($id)/pause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start a scheduled view.
#
# POST /v1/scheduledViews/{id}/start
# operationId: startScheduledView
export def "scheduled-views-start startScheduledView" [
  id: string
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
  let full_url = (build-url $base $"/v1/scheduledViews/($id)/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Provides information about scheduled views quota.
#
# GET /v1/scheduledViews/quota
# operationId: getScheduledViewsQuota
export def "scheduled-views-quota get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<quota: int, remaining: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scheduledViews/quota")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a lookup table.
#
# POST /v1/lookupTables
# operationId: createTable
# --fields item shape: {fieldName: string, fieldType: string}
export def "lookup-tables createTable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string # The description of the lookup table. (e.g. This is a sample lookup table description.)
  --body-fields: list # The list of fields in the lookup table. — item shape: {fieldName: string, fieldType: string}
  primaryKeys: list # The names of the fields that make up the primary key for the lookup table. These will be a subset of the fields that the table will contain. (e.g. [FieldName1])
  --ttl: int # A time to live for each entry in the lookup table (in minutes). 365 days is the maximum time to live for each entry that you can specify. Setting it to 0 means that the records will not expire automatically. (format: int32, default: 0, e.g. 100)
  --sizeLimitAction: string # The action that needs to be taken when the size limit is reached for the table. The possible values can be `StopIncomingMessages` or `DeleteOldData`. DeleteOldData will start deleting old data once size limit is reached whereas StopIncomingMessages will discard all the updates made to the lookup table once size limit is reached. (default: StopIncomingMessages, e.g. DeleteOldData)
  name: string # The name of the lookup table. (e.g. SampleLookupTable)
  parentFolderId: string # The parent-folder-path identifier of the lookup table in the Library. (e.g. 0000000001C41EE4)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/lookupTables")
  let body = {description: $description, fields: $body_fields, primaryKeys: $primaryKeys, ttl: $ttl, sizeLimitAction: $sizeLimitAction, name: $name, parentFolderId: $parentFolderId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a lookup table.
#
# GET /v1/lookupTables/{id}
# operationId: lookupTableById
export def "lookup-tables lookupTableById" [
  id: string
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
  let full_url = (build-url $base $"/v1/lookupTables/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a lookup table.
#
# PUT /v1/lookupTables/{id}
# operationId: updateTable
export def "lookup-tables updateTable" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ttl: int # A time to live for each entry in the lookup table (in minutes). 0 is a special value. A TTL of 0 implies entry will never be deleted from the table. (format: int32, default: 0, e.g. 100)
  description: string # The description of the lookup table. The description cannot be blank. (e.g. This is a sample lookup table description.)
  --sizeLimitAction: string # The action that needs to be taken when the size limit is reached for the table. The possible values can be `StopIncomingMessages` or `DeleteOldData`. DeleteOldData will starting deleting old data once size limit is reached whereas StopIncomingMessages will discard all the updates made to the lookup table once size limit is reached. (default: StopIncomingMessages, e.g. DeleteOldData)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/lookupTables/($id)")
  let body = {ttl: $ttl, description: $description, sizeLimitAction: $sizeLimitAction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a lookup table.
#
# DELETE /v1/lookupTables/{id}
# operationId: deleteTable
export def "lookup-tables delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/lookupTables/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a CSV file.
#
# POST /v1/lookupTables/{id}/upload
# operationId: uploadFile
export def "lookup-tables-upload uploadFile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --merge: string@bool-completer # This indicates whether the file contents will be merged with existing data in the lookup table or not. If this is true then data with the same primary keys will be updated while the rest of the rows will be appended. By default, merge is false. The response includes a request identifier that you need to use in the [Request Status API](#operation/requestStatus) to track the status of the upload request. (default: false, e.g. true)
  --fileEncoding: string # File encoding of file being uploaded. (default: UTF-8, e.g. UTF-16)
  file: string # The CSV file to upload.   - The size limit for the CSV file is 100MB.   - Use Unix format, with newlines ("\n") separating rows.   - The first row should contain headers that match the lookup table schema. Matching is     case-insensitive. (format: binary)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "merge" $merge "scalar") (serialize-qp "fileEncoding" $fileEncoding "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/lookupTables/($id)/upload" $qp)
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get the status of an async job.
#
# GET /v1/lookupTables/jobs/{jobId}/status
# operationId: requestJobStatus
export def "lookup-tables-jobs-status requestJobStatus" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<jobId: string, status: string, statusMessages: list<string>, errors: table<code: string, message: string, detail: string, meta: record>, warnings: table<message: string, cause: string>, lookupContentId: string, lookupName: string, lookupContentPath: string, requestType: string, userId: string, createdAt: string, modifiedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/lookupTables/jobs/($jobId)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Empty a lookup table.
#
# POST /v1/lookupTables/{id}/truncate
# operationId: truncateTable
export def "lookup-tables-truncate truncateTable" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/lookupTables/($id)/truncate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Insert or Update a lookup table row.
#
# PUT /v1/lookupTables/{id}/row
# operationId: updateTableRow
# --row item shape: {columnName: string, columnValue: string}
export def "lookup-tables-row updateTableRow" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  row: list # A list of all the field identifiers and their corresponding values. — item shape: {columnName: string, columnValue: string}
]: any -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/lookupTables/($id)/row")
  let body = {row: $row} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a lookup table row.
#
# PUT /v1/lookupTables/{id}/deleteTableRow
# operationId: deleteTableRow
# --primaryKey item shape: {columnName: string, columnValue: string}
export def "lookup-tables-delete-table-row put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  primaryKey: list # A list of all the primary key field identifiers and their corresponding values which defines the row to delete. — item shape: {columnName: string, columnValue: string}
]: any -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/lookupTables/($id)/deleteTableRow")
  let body = {primaryKey: $primaryKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of partitions.
#
# GET /v1/partitions
# operationId: listPartitions
export def "partitions listPartitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of partitions returned in the response. The number of partitions returned may be less than the `limit`. (format: int32, default: 100)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left.
  --viewTypes: list # The type of partitions to retrieve. Valid values are:   1. `DefaultView`: To get General Index partition.   2. `Partition`: To get user defined views/partitions.   3. `AuditIndex`: To get the internal audit indexes. Eg. sumologic_audit_events.  More than one type of partitions can be retrieved in same request. (e.g. [AuditIndex, Partition])
]: nothing -> record<data: list<record>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "viewTypes" $viewTypes "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/partitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new partition.
#
# POST /v1/partitions
# operationId: createPartition
export def "partitions createPartition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the partition. (e.g. apache)
  routingExpression: string # The query that defines the data to be included in the partition. (e.g. _sourcecategory=*/Apache)
  --analyticsTier: string # The Data Tier where the data in the partition will reside. Possible values are:               1. `continuous`               2. `frequent`               3. `infrequent` Note: The "infrequent" and "frequent" tiers are only available to Cloud Flex Credits Enterprise Suite accounts. (e.g. continuous)
  --retentionPeriod: int # The number of days to retain data in the partition, or -1 to use the default value for your account.  Only relevant if your account has variable retention enabled. (default: -1, e.g. 365)
  --isCompliant: string@bool-completer # Whether the partition is compliant or not. Mark a partition as compliant if it contains data used for compliance or audit purpose. Retention for a compliant partition can only be increased and cannot be reduced after the partition is marked compliant. A partition once marked compliant, cannot be marked non-compliant later. (default: false, e.g. false)
  --isIncludedInDefaultSearch: string@bool-completer # Indicates whether the partition is included in the default search scope. When executing a  query such as "error | count," certain partitions are automatically part of the search scope.  However, for specific partitions, the user must explicitly mention the partition using the _index  term, as in "_index=webApp error | count". This property governs the default inclusion of the  partition in the search scope. Configuring this property is exclusively permitted for flex partitions. (e.g. true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/partitions")
  let body = {name: $name, routingExpression: $routingExpression, analyticsTier: $analyticsTier, retentionPeriod: $retentionPeriod, isCompliant: $isCompliant, isIncludedInDefaultSearch: $isIncludedInDefaultSearch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a partition.
#
# GET /v1/partitions/{id}
# operationId: getPartition
export def "partitions get" [
  id: string
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
  let full_url = (build-url $base $"/v1/partitions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a partition.
#
# PUT /v1/partitions/{id}
# operationId: updatePartition
export def "partitions updatePartition" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --retentionPeriod: int # The number of days to retain data in the partition, or -1 to use the default value for your account. Only relevant if your account has variable retention enabled. (e.g. 365)
  --reduceRetentionPeriodImmediately: string@bool-completer # This is required if the newly specified `retentionPeriod` is less than the existing retention period.  In such a situation, a value of `true` says that data between the existing retention period and the new  retention period should be deleted immediately; if `false`, such data will be deleted after seven days.  This property is optional and ignored if the specified `retentionPeriod` is greater than or equal to the  current retention period. (default: false)
  --isCompliant: string@bool-completer # Whether to mark a partition as compliant. Mark a partition as compliant if it contains data used for compliance or audit purpose. Retention for a compliant partition can only be increased and cannot be reduced after the partition marked as compliant. A partition once marked compliant, cannot be marked non-compliant later. (default: false, e.g. false)
  --isIncludedInDefaultSearch: string@bool-completer # Indicates whether the partition is included in the default search scope. When executing a  query such as "error | count," certain partitions are automatically part of the search scope.  However, for specific partitions, the user must explicitly mention the partition using the _index  term, as in "_index=webApp error | count". This property governs the default inclusion of the  partition in the search scope. Configuring this property is exclusively permitted for flex partitions.
  --routingExpression: string # The query that defines the data to be included in the partition. (e.g. _sourcecategory=*/Apache)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/partitions/($id)")
  let body = {retentionPeriod: $retentionPeriod, reduceRetentionPeriodImmediately: $reduceRetentionPeriodImmediately, isCompliant: $isCompliant, isIncludedInDefaultSearch: $isIncludedInDefaultSearch, routingExpression: $routingExpression} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Decommission a partition.
#
# POST /v1/partitions/{id}/decommission
# operationId: decommissionPartition
export def "partitions-decommission decommissionPartition" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/partitions/($id)/decommission")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a retention update for a partition
#
# POST /v1/partitions/{id}/cancelRetentionUpdate
# operationId: cancelRetentionUpdate
export def "partitions-cancel-retention-update cancelRetentionUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/partitions/($id)/cancelRetentionUpdate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Provides information about partitions quota.
#
# GET /v1/partitions/quota
# operationId: getPartitionsQuota
export def "partitions-quota get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<quota: int, remaining: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/partitions/quota")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Amazon S3 data forwarding destinations.
#
# GET /v1/logsDataForwarding/destinations
# operationId: getDataForwardingBuckets
export def "logs-data-forwarding-destinations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of data forwarding destinations returned in the response. The number of data forwarding destinations returned may be less than the `limit`. (format: int32, default: 10)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left.
]: nothing -> record<nextToken: string, data: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/logsDataForwarding/destinations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an S3 data forwarding destination.
#
# POST /v1/logsDataForwarding/destinations
# operationId: createDataForwardingBucket
export def "logs-data-forwarding-destinations createDataForwardingBucket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destinationName: string # Name of the S3 data forwarding destination. (e.g. df-destination)
  --description: string # Description of the S3 data forwarding destination.
  authenticationMode: string # AWS IAM authentication method used for access. Possible values are: 1. `AccessKey` 2. `RoleBased` (e.g. RoleBased)
  --accessKeyId: string # The AWS Access ID to access the S3 bucket. (e.g. accessKeyId)
  --secretAccessKey: string # The AWS Secret Key to access the S3 bucket. (e.g. secretAccessKey)
  --roleArn: string # The AWS Role ARN to access the S3 bucket. (e.g. roleArn)
  --region: string # The region where the S3 bucket is located. (e.g. us-east-1)
  --encrypted: string@bool-completer # Enable S3 server-side encryption.
  --enabled: string@bool-completer # True if the destination is Active. (e.g. true)
  bucketName: string # The name of the Amazon S3 bucket. (e.g. df-bucket)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/logsDataForwarding/destinations")
  let body = {destinationName: $destinationName, description: $description, authenticationMode: $authenticationMode, accessKeyId: $accessKeyId, secretAccessKey: $secretAccessKey, roleArn: $roleArn, region: $region, encrypted: $encrypted, enabled: $enabled, bucketName: $bucketName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an S3 data forwarding destination.
#
# GET /v1/logsDataForwarding/destinations/{id}
# operationId: getDataForwardingDestination
export def "logs-data-forwarding-destinations get" [
  id: string
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
  let full_url = (build-url $base $"/v1/logsDataForwarding/destinations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an S3 data forwarding destination.
#
# PUT /v1/logsDataForwarding/destinations/{id}
# operationId: UpdateDataForwardingBucket
export def "logs-data-forwarding-destinations UpdateDataForwardingBucket" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --destinationName: string # Name of the S3 data forwarding destination. (e.g. df-destination)
  --description: string # Description of the S3 data forwarding destination.
  authenticationMode: string # AWS IAM authentication method used for access. Possible values are: 1. `AccessKey` 2. `RoleBased` (e.g. RoleBased)
  --accessKeyId: string # The AWS Access ID to access the S3 bucket. (e.g. accessKeyId)
  --secretAccessKey: string # The AWS Secret Key to access the S3 bucket. (e.g. secretAccessKey)
  --roleArn: string # The AWS Role ARN to access the S3 bucket. (e.g. roleArn)
  --region: string # The region where the S3 bucket is located. (e.g. us-east-1)
  --encrypted: string@bool-completer # Enable S3 server-side encryption.
  --enabled: string@bool-completer # True if the destination is Active. (e.g. true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/logsDataForwarding/destinations/($id)")
  let body = {destinationName: $destinationName, description: $description, authenticationMode: $authenticationMode, accessKeyId: $accessKeyId, secretAccessKey: $secretAccessKey, roleArn: $roleArn, region: $region, encrypted: $encrypted, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an S3 data forwarding destination.
#
# DELETE /v1/logsDataForwarding/destinations/{id}
# operationId: deleteDataForwardingBucket
export def "logs-data-forwarding-destinations delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/logsDataForwarding/destinations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all S3 data forwarding rules.
#
# GET /v1/logsDataForwarding/rules
# operationId: getRulesAndBuckets
export def "logs-data-forwarding-rules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of data forwarding rules returned in the response. The number of data forwarding rules returned may be less than the `limit`. (format: int32, default: 10)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left.
]: nothing -> record<data: table<bucket: record>, nextToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/logsDataForwarding/rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an S3 data forwarding rule.
#
# POST /v1/logsDataForwarding/rules
# operationId: createDataForwardingRule
export def "logs-data-forwarding-rules createDataForwardingRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  indexId: string # The `id` of the Partition or Scheduled View the rule applies to. (e.g. 1)
  destinationId: string # The data forwarding destination id. (e.g. 1)
  --enabled: string@bool-completer # True when the data forwarding rule is enabled. (e.g. true)
  --fileFormat: string # Specify the path prefix to a directory in the S3 bucket and how to format the file name. (e.g. {index}_{day}_{hour}_{minute}_{second})
  --payloadSchema: string # Schema for the payload. Default value of the payload schema is "allFields" for scheduled view, and "builtInFields" for partition. "raw" payloadSchema should be used in conjunction with "text" format and vice-versa. (e.g. builtInFields)
  --format: string # Format of the payload. Default format will be "csv". "text" format should be used in conjunction with "raw" payloadSchema and vice-versa. (e.g. csv)
]: any -> record<indexId: string, destinationId: string, enabled: bool, fileFormat: string, payloadSchema: string, format: string, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/logsDataForwarding/rules")
  let body = {indexId: $indexId, destinationId: $destinationId, enabled: $enabled, fileFormat: $fileFormat, payloadSchema: $payloadSchema, format: $format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an S3 data forwarding rule by its index.
#
# GET /v1/logsDataForwarding/rules/{indexId}
# operationId: getDataForwardingRule
export def "logs-data-forwarding-rules get" [
  indexId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<bucket: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/logsDataForwarding/rules/($indexId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an S3 data forwarding rule by its index.
#
# PUT /v1/logsDataForwarding/rules/{indexId}
# operationId: updateDataForwardingRule
export def "logs-data-forwarding-rules updateDataForwardingRule" [
  indexId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --destinationId: string # Data forwarding destination id. (e.g. 1)
  --enabled: string@bool-completer # True when the data forwarding rule is enabled. (e.g. true)
  --fileFormat: string # Specify the path prefix to a directory in the S3 bucket and how to format the file name. (e.g. {index}_{day}_{hour}_{minute}_{second})
  --payloadSchema: string # Schema for the payload. Default value of the payload schema is "allFields" for scheduled view, and "builtInFields" for partition. "raw" payloadSchema should be used in conjunction with "text" format and vice-versa. (e.g. builtInFields)
  --format: string # Format of the payload. Default format will be "csv". "text" format should be used in conjunction with "raw" payloadSchema and vice-versa. (e.g. csv)
]: any -> record<indexId: string, destinationId: string, enabled: bool, fileFormat: string, payloadSchema: string, format: string, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/logsDataForwarding/rules/($indexId)")
  let body = {destinationId: $destinationId, enabled: $enabled, fileFormat: $fileFormat, payloadSchema: $payloadSchema, format: $format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an S3 data forwarding rule by its index.
#
# DELETE /v1/logsDataForwarding/rules/{indexId}
# operationId: deleteDataForwardingRule
export def "logs-data-forwarding-rules delete" [
  indexId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/logsDataForwarding/rules/($indexId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all saved log searches.
#
# GET /v1/logSearches
# operationId: listLogSearches
export def "log-searches listLogSearches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of log searches returned in the response. The number of log searches returned may be less than the `limit`. (format: int32, default: 50, e.g. 50)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left. (e.g. GDCiRv4vebF3UWFJQ1kySXBOR3Bzh69GR0RyWm9vCtc)
]: nothing -> record<logSearches: table<createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, id: string, parentId: string>, warnings: list<string>, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/logSearches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Save a log search.
#
# POST /v1/logSearches
# operationId: createLogSearch
export def "log-searches createLogSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  parentId: string # Identifier of a folder where to save the log search. (e.g. 000000000000001A)
]: any -> record<createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, id: string, parentId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/logSearches")
  let body = {parentId: $parentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the saved log search.
#
# GET /v1/logSearches/{id}
# operationId: getLogSearch
export def "log-searches get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, id: string, parentId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/logSearches/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the saved log Search.
#
# PUT /v1/logSearches/{id}
# operationId: updateLogSearch
# --schedule shape: {cronExpression?: string, displayableTimeRange?: string, parseableTimeRange: record, timeZone: string, threshold?: record, notification: record, scheduleType: string, muteErrorEmails?: bool, parameters?: list}
export def "log-searches updateLogSearch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the item in the content library. (e.g. Short title)
  --description: string # Item description in the content library. (e.g. Long and detailed description)
  --schedule: record # shape: {cronExpression?: string, displayableTimeRange?: string, parseableTimeRange: record, timeZone: string, threshold?: record, notification: record, scheduleType: string, muteErrorEmails?: bool, parameters?: list}
  --properties: string # Aggregate Results Settings and View configurations, Legends settings, and different visualisation settings overrides. Leave this field empty to use the defaults. This property contains JSON object encoded as a string.  (e.g. { "key": "value" })
]: any -> record<createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, id: string, parentId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/logSearches/($id)")
  let body = {name: $name, description: $description, schedule: $schedule, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the saved log search.
#
# DELETE /v1/logSearches/{id}
# operationId: deleteLogSearch
export def "log-searches delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/logSearches/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of Data Deletion Rules
#
# GET /v1/dataDeletionRules
# operationId: listDeletionRules
export def "data-deletion-rules listDeletionRules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of deletion Rules returned in the response (format: int32, default: 50, e.g. 100)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left.
]: nothing -> record<deletionRulesList: table<ruleName: string, ruleReason: string, query: string, startMillis: int, endMillis: int, byReceiptTime: bool, timezone: string, parsingMode: string, id: string, createdAt: string, modifiedAt: string, error: string, status: string, createdBy: string, modifiedBy: string, deletedRanges: list>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/dataDeletionRules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Data Deletion Rule
#
# POST /v1/dataDeletionRules
# operationId: createDataDeletionRule
export def "data-deletion-rules createDataDeletionRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ruleName: string # Name of the deletion rule.
  ruleReason: string # Reason mentioning what data is being deleted and why.
  --body-query: string # query to filter out the logs that need to be deleted.
  startMillis: int # Start time of the search as a number of milliseconds. (format: int64, e.g. 1704976268773)
  endMillis: int # End time of the search as a number of milliseconds. (format: int64, e.g. 1704977168773)
  --byReceiptTime: string@bool-completer # Flag to order the search results in the order collector received it. This has the value `true` if the search is to be run by receipt time and `false` if it is to be run by message time. (default: false)
  --timezone: string # Timezone for the resolving timerange from startMillis,endMillis (default: UTC)
  --parsingMode: string # Define the parsing mode to scan the JSON format log messages. Possible values are:   1. `AutoParse`   2. `Manual` In AutoParse mode, the system automatically figures out fields to parse based on the search query. While in the Manual mode, no fields are parsed out automatically. For more information see [Dynamic Parsing](https://help.sumologic.com/?cid=0011). (default: Manual, e.g. AutoParse)
]: any -> record<ruleName: string, ruleReason: string, query: string, startMillis: int, endMillis: int, byReceiptTime: bool, timezone: string, parsingMode: string, id: string, createdAt: string, modifiedAt: string, error: string, status: string, createdBy: string, modifiedBy: string, deletedRanges: table<startTime: string, endTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dataDeletionRules")
  let body = {ruleName: $ruleName, ruleReason: $ruleReason, query: $body_query, startMillis: $startMillis, endMillis: $endMillis, byReceiptTime: $byReceiptTime, timezone: $timezone, parsingMode: $parsingMode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Data Deletion Rule information for the given Id.
#
# GET /v1/dataDeletionRules/{id}
# operationId: getDataDeletionRule
export def "data-deletion-rules get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ruleName: string, ruleReason: string, query: string, startMillis: int, endMillis: int, byReceiptTime: bool, timezone: string, parsingMode: string, id: string, createdAt: string, modifiedAt: string, error: string, status: string, createdBy: string, modifiedBy: string, deletedRanges: table<startTime: string, endTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dataDeletionRules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel the data Deletion Rule with the given Id.
#
# POST /v1/dataDeletionRules/{id}/cancel
# operationId: cancelDataDeletionRule
export def "data-deletion-rules-cancel cancelDataDeletionRule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ruleName: string, ruleReason: string, query: string, startMillis: int, endMillis: int, byReceiptTime: bool, timezone: string, parsingMode: string, id: string, createdAt: string, modifiedAt: string, error: string, status: string, createdBy: string, modifiedBy: string, deletedRanges: table<startTime: string, endTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dataDeletionRules/($id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the data Deletion Rule with the given Id.
#
# DELETE /v1/dataDeletionRules/{id}/delete
# operationId: deleteDataDeletionRule
export def "data-deletion-rules-delete delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dataDeletionRules/($id)/delete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of data masking rules.
#
# GET /v1/dataMaskingRules
# operationId: listDataMaskingRules
export def "data-masking-rules listDataMaskingRules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of data masking rules returned in the response. The number of rules returned may be less than the `limit`. (format: int32, default: 100)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results.
]: nothing -> record<data: list<record>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/dataMaskingRules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new data masking rule.
#
# POST /v1/dataMaskingRules
# operationId: createDataMaskingRule
export def "data-masking-rules createDataMaskingRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Optional description of the data masking rule. Provide context about what PII this rule masks and why it's needed. (e.g. Masks email addresses in application logs)
  regexPattern: string # Regular expression pattern to match PII data that should be masked. The pattern must be valid according to Java regex syntax. All matches in search results will be replaced with the mask string. Required when creating a rule. When updating, if omitted the existing pattern is retained. (e.g. \b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b)
  --maskString: string # The string to replace matched PII with. Defaults to '##redactedPII##' if not specified. Use descriptive mask strings like 'EMAIL_REDACTED' or 'PHONE_REDACTED' for clarity. (default: ##redactedPII##, e.g. EMAIL_REDACTED)
  --enabled: string@bool-completer # Whether the data masking rule is active. Only enabled rules are applied to search results. Set to false to temporarily disable a rule without deleting it. (default: true)
  name: string # Name of the data masking rule. Use a name that makes it easy to identify the rule. Must be unique within the organization. This field is immutable and cannot be changed after creation. (e.g. Email Masking)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dataMaskingRules")
  let body = {description: $description, regexPattern: $regexPattern, maskString: $maskString, enabled: $enabled, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a data masking rule.
#
# GET /v1/dataMaskingRules/{id}
# operationId: getDataMaskingRule
export def "data-masking-rules get" [
  id: string
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
  let full_url = (build-url $base $"/v1/dataMaskingRules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a data masking rule.
#
# PUT /v1/dataMaskingRules/{id}
# operationId: updateDataMaskingRule
export def "data-masking-rules updateDataMaskingRule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Optional description of the data masking rule. Provide context about what PII this rule masks and why it's needed. (e.g. Masks email addresses in application logs)
  --regexPattern: string # Regular expression pattern to match PII data that should be masked. The pattern must be valid according to Java regex syntax. All matches in search results will be replaced with the mask string. Required when creating a rule. When updating, if omitted the existing pattern is retained. (e.g. \b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b)
  --maskString: string # The string to replace matched PII with. Defaults to '##redactedPII##' if not specified. Use descriptive mask strings like 'EMAIL_REDACTED' or 'PHONE_REDACTED' for clarity. (default: ##redactedPII##, e.g. EMAIL_REDACTED)
  --enabled: string@bool-completer # Whether the data masking rule is active. Only enabled rules are applied to search results. Set to false to temporarily disable a rule without deleting it. (default: true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dataMaskingRules/($id)")
  let body = {description: $description, regexPattern: $regexPattern, maskString: $maskString, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a data masking rule.
#
# DELETE /v1/dataMaskingRules/{id}
# operationId: deleteDataMaskingRule
export def "data-masking-rules delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dataMaskingRules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test and preview a regex pattern by evaluating it against sample input text. Optionally provide a maskString to use as the replacement for text that matches the regex.
#
# POST /v1/dataMaskingRules/evaluate
# operationId: evaluateDataMaskingPattern
export def "data-masking-rules-evaluate evaluateDataMaskingPattern" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  regexPattern: string # Regex pattern used to identify substrings to mask. (e.g. \\b\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\b)
  --maskString: string # Optional mask string. If null or empty, the service may apply a default mask string. (nullable, default: ##redactedPII##, e.g. EMAIL_REDACTED)
  text: string # Sample message used for masking evaluation. (e.g. 2026-04-21 INFO User 192.168.1.1 logged in at 10.0.0.1)
]: any -> record<maskedText: string, matchCount: int, matchPositions: table<start: int, end: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dataMaskingRules/evaluate")
  let body = {regexPattern: $regexPattern, maskString: $maskString, text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of field extraction rules.
#
# GET /v1/extractionRules
# operationId: listExtractionRules
export def "extraction-rules listExtractionRules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of field extraction rules returned in the response. The number of field extraction rules returned may be less than the `limit`. (format: int32, default: 100)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results.
]: nothing -> record<data: list<record>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/extractionRules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new field extraction rule.
#
# POST /v1/extractionRules
# operationId: createExtractionRule
export def "extraction-rules createExtractionRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the field extraction rule. Use a name that makes it easy to identify the rule. (e.g. ExtractionRule123)
  scope: string # Scope of the field extraction rule. This could be a sourceCategory, sourceHost, or any other metadata that describes the data you want to extract from. Think of the Scope as the first portion of an ad hoc search, before the first pipe ( | ). You'll use the Scope to run a search against the rule. (e.g. _sourceHost=127.0.0.1)
  parseExpression: string # Describes the fields to be parsed. (e.g. csv _raw extract 1 as f1)
  --enabled: string@bool-completer # Is the field extraction rule enabled. (default: true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/extractionRules")
  let body = {name: $name, scope: $scope, parseExpression: $parseExpression, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a field extraction rule.
#
# GET /v1/extractionRules/{id}
# operationId: getExtractionRule
export def "extraction-rules get" [
  id: string
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
  let full_url = (build-url $base $"/v1/extractionRules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a field extraction rule.
#
# PUT /v1/extractionRules/{id}
# operationId: updateExtractionRule
export def "extraction-rules updateExtractionRule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the field extraction rule. Use a name that makes it easy to identify the rule. (e.g. ExtractionRule123)
  scope: string # Scope of the field extraction rule. This could be a sourceCategory, sourceHost, or any other metadata that describes the data you want to extract from. Think of the Scope as the first portion of an ad hoc search, before the first pipe ( | ). You'll use the Scope to run a search against the rule. (e.g. _sourceHost=127.0.0.1)
  parseExpression: string # Describes the fields to be parsed. (e.g. csv _raw extract 1 as f1)
  --enabled: string@bool-completer # Is the field extraction rule enabled.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/extractionRules/($id)")
  let body = {name: $name, scope: $scope, parseExpression: $parseExpression, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a field extraction rule.
#
# DELETE /v1/extractionRules/{id}
# operationId: deleteExtractionRule
export def "extraction-rules delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/extractionRules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of dynamic parsing rules.
#
# GET /v1/dynamicParsingRules
# operationId: listDynamicParsingRules
export def "dynamic-parsing-rules listDynamicParsingRules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of dynamic parsing rules returned in the response. The number of dynamic parsing rules returned may be less than the `limit`. (format: int32, default: 100, e.g. 10)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. (e.g. 0000000001C51FF7)
]: nothing -> record<data: list<record>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/dynamicParsingRules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new dynamic parsing rule.
#
# POST /v1/dynamicParsingRules
# operationId: createDynamicParsingRule
export def "dynamic-parsing-rules createDynamicParsingRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the dynamic parsing rule. Use a name that makes it easy to identify the rule. (e.g. DynamicParsingRule123)
  scope: string # Scope of the dynamic parsing rule. This could be a sourceCategory, sourceHost, or any other metadata that describes the data you want to extract from. Think of the Scope as the first portion of an ad hoc search, before the first pipe ( | ). You'll use the Scope to run a search against the rule. (e.g. _sourceHost=127.0.0.1)
  --enabled: string@bool-completer # Is the dynamic parsing rule enabled. (default: true, e.g. false)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dynamicParsingRules")
  let body = {name: $name, scope: $scope, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a dynamic parsing rule.
#
# GET /v1/dynamicParsingRules/{id}
# operationId: getDynamicParsingRule
export def "dynamic-parsing-rules get" [
  id: string
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
  let full_url = (build-url $base $"/v1/dynamicParsingRules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a dynamic parsing rule.
#
# PUT /v1/dynamicParsingRules/{id}
# operationId: updateDynamicParsingRule
export def "dynamic-parsing-rules updateDynamicParsingRule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the dynamic parsing rule. Use a name that makes it easy to identify the rule. (e.g. DynamicParsingRule123)
  scope: string # Scope of the dynamic parsing rule. This could be a sourceCategory, sourceHost, or any other metadata that describes the data you want to extract from. Think of the Scope as the first portion of an ad hoc search, before the first pipe ( | ). You'll use the Scope to run a search against the rule. (e.g. _sourceHost=127.0.0.1)
  --enabled: string@bool-completer # Is the dynamic parsing rule enabled. (default: true, e.g. false)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dynamicParsingRules/($id)")
  let body = {name: $name, scope: $scope, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a dynamic parsing rule.
#
# DELETE /v1/dynamicParsingRules/{id}
# operationId: deleteDynamicParsingRule
export def "dynamic-parsing-rules delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dynamicParsingRules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all custom fields.
#
# GET /v1/fields
# operationId: listCustomFields
export def "fields listCustomFields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<fieldName: string, fieldId: string, dataType: string, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/fields")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new field.
#
# POST /v1/fields
# operationId: createField
export def "fields createField" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  fieldName: string # Field name. (e.g. hostIP)
]: any -> record<fieldName: string, fieldId: string, dataType: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/fields")
  let body = {fieldName: $fieldName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a custom field.
#
# GET /v1/fields/{id}
# operationId: getCustomField
export def "fields get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fieldName: string, fieldId: string, dataType: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fields/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a custom field.
#
# DELETE /v1/fields/{id}
# operationId: deleteField
export def "fields delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fields/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable custom field with a specified identifier.
#
# PUT /v1/fields/{id}/enable
# operationId: enableField
export def "fields-enable enableField" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fields/($id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable a custom field.
#
# DELETE /v1/fields/{id}/disable
# operationId: disableField
export def "fields-disable disableField" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fields/($id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of dropped fields.
#
# GET /v1/fields/dropped
# operationId: listDroppedFields
export def "fields-dropped listDroppedFields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<fieldName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/fields/dropped")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of built-in fields.
#
# GET /v1/fields/builtin
# operationId: listBuiltInFields
export def "fields-builtin listBuiltInFields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<fieldName: string, fieldId: string, dataType: string, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/fields/builtin")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a built-in field.
#
# GET /v1/fields/builtin/{id}
# operationId: getBuiltInField
export def "fields-builtin get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fieldName: string, fieldId: string, dataType: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fields/builtin/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get capacity information.
#
# GET /v1/fields/quota
# operationId: getFieldQuota
export def "fields-quota get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<quota: int, remaining: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/fields/quota")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of ingest budgets.
#
# GET /v2/ingestBudgets
# operationId: listIngestBudgetsV2
export def "ingest-budgets listIngestBudgetsV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of budgets returned in the response. The number of budgets returned may be less than the `limit`. (format: int32, default: 100)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results.
]: nothing -> record<data: list<record>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/ingestBudgets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new ingest budget.
#
# POST /v2/ingestBudgets
# operationId: createIngestBudgetV2
export def "ingest-budgets createIngestBudgetV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Display name of the ingest budget. (e.g. Developer Budget)
  scope: string # A scope is a constraint that will be used to identify the messages on which budget needs to be applied. A scope is consists of key and value separated by =. The field must be enabled in the fields table. Value supports wildcard. e.g. _sourceCategory=*prod*payment*, cluster=kafka. If the scope is defined _sourceCategory=*nginx* in this budget will be applied on messages having fields _sourceCategory=prod/nginx, _sourceCategory=dev/nginx, or _sourceCategory=dev/nginx/error (e.g. _sourceCategory=*prod*nginx*)
  capacityBytes: int # Capacity of the ingest budget, in bytes. It takes a few minutes for Collectors to stop collecting when capacity is reached. We recommend setting a soft limit that is lower than your needed hard limit. The capacity bytes unit varies based on the budgetType field. For `dailyVolume` budgetType the capacity specified is in bytes/day whereas for `minuteVolume` budgetType its bytes/min. (format: int64, e.g. 1000)
  --timezone: string # Time zone of the reset time for the ingest budget. Follow the format in the [IANA Time Zone Database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List). (default: Etc/UTC, e.g. America/Los_Angeles)
  --resetTime: string # Reset time of the ingest budget in HH:MM format. (default: 00:00, e.g. 23:30)
  --description: string # Description of the ingest budget.
  action: string # Action to take when ingest budget's capacity is reached. All actions are audited. Supported values are:   * `stopCollecting`   * `keepCollecting` (e.g. stopCollecting)
  --auditThreshold: int # The threshold as a percentage of when an ingest budget's capacity usage is logged in the Audit Index. (format: int32, e.g. 85)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/ingestBudgets")
  let body = {name: $name, scope: $scope, capacityBytes: $capacityBytes, timezone: $timezone, resetTime: $resetTime, description: $description, action: $action, auditThreshold: $auditThreshold} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an ingest budget.
#
# GET /v2/ingestBudgets/{id}
# operationId: getIngestBudgetV2
export def "ingest-budgets get" [
  id: string
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
  let full_url = (build-url $base $"/v2/ingestBudgets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an ingest budget.
#
# PUT /v2/ingestBudgets/{id}
# operationId: updateIngestBudgetV2
export def "ingest-budgets updateIngestBudgetV2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Display name of the ingest budget. (e.g. Developer Budget)
  scope: string # A scope is a constraint that will be used to identify the messages on which budget needs to be applied. A scope is consists of key and value separated by =. The field must be enabled in the fields table. Value supports wildcard. e.g. _sourceCategory=*prod*payment*, cluster=kafka. If the scope is defined _sourceCategory=*nginx* in this budget will be applied on messages having fields _sourceCategory=prod/nginx, _sourceCategory=dev/nginx, or _sourceCategory=dev/nginx/error (e.g. _sourceCategory=*prod*nginx*)
  capacityBytes: int # Capacity of the ingest budget, in bytes. It takes a few minutes for Collectors to stop collecting when capacity is reached. We recommend setting a soft limit that is lower than your needed hard limit. The capacity bytes unit varies based on the budgetType field. For `dailyVolume` budgetType the capacity specified is in bytes/day whereas for `minuteVolume` budgetType its bytes/min. (format: int64, e.g. 1000)
  --timezone: string # Time zone of the reset time for the ingest budget. Follow the format in the [IANA Time Zone Database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List). (default: Etc/UTC, e.g. America/Los_Angeles)
  --resetTime: string # Reset time of the ingest budget in HH:MM format. (default: 00:00, e.g. 23:30)
  --description: string # Description of the ingest budget.
  action: string # Action to take when ingest budget's capacity is reached. All actions are audited. Supported values are:   * `stopCollecting`   * `keepCollecting` (e.g. stopCollecting)
  --auditThreshold: int # The threshold as a percentage of when an ingest budget's capacity usage is logged in the Audit Index. (format: int32, e.g. 85)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/ingestBudgets/($id)")
  let body = {name: $name, scope: $scope, capacityBytes: $capacityBytes, timezone: $timezone, resetTime: $resetTime, description: $description, action: $action, auditThreshold: $auditThreshold} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an ingest budget.
#
# DELETE /v2/ingestBudgets/{id}
# operationId: deleteIngestBudgetV2
export def "ingest-budgets delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/ingestBudgets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset usage.
#
# POST /v2/ingestBudgets/{id}/usage/reset
# operationId: resetUsageV2
export def "ingest-budgets-usage-reset resetUsageV2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/ingestBudgets/($id)/usage/reset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of users.
#
# GET /v1/users
# operationId: listUsers
export def "users listUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of users returned in the response. The number of users returned may be less than the `limit`. (format: int32, default: 100)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left.
  --sortBy: string # Sort the list of users by the `firstName`, `lastName`, or `email` field.
  --email: string # Find user with the given email address.
  --includeServiceAccounts: string@bool-completer # Include service accounts while listing users within the organization.
]: nothing -> record<data: list<record>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "includeServiceAccounts" $includeServiceAccounts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new user.
#
# POST /v1/users
# operationId: createUser
export def "users createUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  firstName: string # First name of the user. (e.g. John)
  lastName: string # Last name of the user. (e.g. Doe)
  email: string # Email address of the user. (format: email, e.g. johndoe@acme.com)
  roleIds: list # List of roleIds associated with the user. (e.g. [00000000000001DF, 00000000000002D2])
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users")
  let body = {firstName: $firstName, lastName: $lastName, email: $email, roleIds: $roleIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a user.
#
# GET /v1/users/{id}
# operationId: getUser
export def "users get" [
  id: string
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
  let full_url = (build-url $base $"/v1/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user.
#
# PUT /v1/users/{id}
# operationId: updateUser
export def "users updateUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  firstName: string # First name of the user. If the caller has `manageUsersAndRoles` capability, this field can be updated for any user. If the caller does NOT have `manageUsersAndRoles` capability, then only the calling user's firstName can be updated. (e.g. John)
  lastName: string # Last name of the user. If the caller has `manageUsersAndRoles` capability, this field can be updated for any user. If the caller does NOT have `manageUsersAndRoles` capability, then only the calling user's lastName can be updated. (e.g. Doe)
  --isActive: string@bool-completer # This has the value `true` if the user is active and `false` if they have been deactivated. To modify this field you must have the `manageUserAndRoles` capability. (e.g. true)
  --roleIds: list # List of role identifiers associated with the user. To modify this field you must have the `manageUserAndRoles` capability. (e.g. [00000000000001DF, 00000000000002D2])
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($id)")
  let body = {firstName: $firstName, lastName: $lastName, isActive: $isActive, roleIds: $roleIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a user.
#
# DELETE /v1/users/{id}
# operationId: deleteUser
export def "users delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transferTo: string # Identifier of the user to receive the transfer of content from the deleted user. <br> **Note:** If `deleteContent` is not set to `true`, and no user identifier is specified in `transferTo`, content from the deleted user is transferred to the executing user.
  --deleteContent: string@bool-completer # Whether to delete content from the deleted user or not. <br> **Warning:** If `deleteContent` is set to `true`, all of the content for the user being deleted is permanently deleted and cannot be recovered.
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "transferTo" $transferTo "scalar") (serialize-qp "deleteContent" $deleteContent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/users/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change email address.
#
# POST /v1/users/{id}/email/requestChange
# operationId: requestChangeEmail
export def "users-email-request-change requestChangeEmail" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # New email address of the user. (format: email, e.g. johndoe@acme.com)
]: any -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($id)/email/requestChange")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset password.
#
# POST /v1/users/{id}/password/reset
# operationId: resetPassword
export def "users-password-reset resetPassword" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($id)/password/reset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unlock a user.
#
# POST /v1/users/{id}/unlock
# operationId: unlockUser
export def "users-unlock unlockUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($id)/unlock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable MFA for user.
#
# PUT /v1/users/{id}/mfa/disable
# operationId: disableMfa
export def "users-mfa-disable disableMfa" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # Email of user whose mfa is being disabled. (format: email, e.g. johndoe@cme.com)
  password: string # Password of user whose mfa is being disabled.
]: any -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($id)/mfa/disable")
  let body = {email: $email, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resend verification email.
#
# POST /v1/users/{id}/resendWelcomeEmail
# operationId: resendWelcomeEmail
export def "users-resend-welcome-email resendWelcomeEmail" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($id)/resendWelcomeEmail")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of roles.
#
# GET /v1/roles
# operationId: listRoles
export def "roles listRoles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of roles returned in the response. The number of roles returned may be less than the `limit`. (format: int32, default: 100)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left.
  --sortBy: string # Sort the list of roles by the `name` field.
  --name: string # Only return roles matching the given name.
]: nothing -> record<data: list<record>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new role.
#
# POST /v1/roles
# operationId: createRole
export def "roles createRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the role. (e.g. DataAdmin)
  --description: string # Description of the role. (e.g. Manage data of the org.)
  --filterPredicate: string # A search filter to restrict access to specific logs. The filter is silently added to the beginning of each query a user runs. For example, using '!_sourceCategory=billing' as a filter predicate will prevent users assigned to the role from viewing logs from the source category named 'billing'. (e.g. !_sourceCategory=billing)
  --users: list # List of user identifiers to assign the role to. (e.g. [0000000006743FE0, 0000000005FCE0EE])
  --capabilities: list # List of [capabilities](https://help.sumologic.com/docs/manage/users-roles/roles/role-capabilities/) associated with this role. Valid values are ### Data Management   - viewCollectors   - manageCollectors   - manageBudgets   - manageDataVolumeFeed   - viewFieldExtraction   - manageFieldExtractionRules   - manageS3DataForwarding   - manageContent   - manageApps   - dataVolumeIndex   - manageConnections   - viewScheduledViews   - manageScheduledViews   - viewPartitions   - managePartitions   - viewFields   - manageFields   - viewAccountOverview   - manageTokens   - downloadSearchResults   - manageIndexes   - manageDataStreams   - viewParsers   - viewDataStreams  ### Entity management   - manageEntityTypeConfig  ### Metrics   - metricsTransformation   - metricsExtraction   - metricsRules  ### Security   - managePasswordPolicy   - ipAllowlisting   - ipWhitelisting   - createAccessKeys   - manageAccessKeys   - manageSupportAccountAccess   - manageAuditDataFeed   - manageSaml   - shareDashboardOutsideOrg   - manageOrgSettings   - changeDataAccessLevel  ### Dashboards   - shareDashboardWorld   - shareDashboardAllowlist   - shareDashboardWhitelist  ### UserManagement   - manageUsersAndRoles  ### Observability   - searchAuditIndex   - auditEventIndex  ### Cloud SIEM Enterprise   - viewCse   - cseViewAutomations   - cseManageContextActions   - cseViewNetworkBlocks   - cseManageInsightTags   - cseViewRules   - cseViewThreatIntelligence   - cseCommentOnInsights   - cseViewEntityGroups   - cseManageEntityConfiguration   - cseManageNetworkBlocks   - cseManageMatchLists   - cseViewCustomInsights   - cseManageActions   - cseManageAutomations   - cseManageMappings   - cseManageThreatIntelligence   - cseViewActions   - cseCreateInsights   - cseManageTagSchemas   - cseInvokeInsights   - cseManageCustomEntityType   - cseViewTagSchemas   - cseDeleteInsights   - cseManageCustomInsights   - cseViewFileAnalysis   - cseManageFileAnalysis   - cseManageEntityCriticality   - cseViewEntityCriticality   - cseViewEntity   - cseManageCustomInsightStatuses   - cseViewContextActions   - cseViewMappings   - cseViewCustomEntityType   - cseManageEntityGroups   - cseViewCustomInsightStatuses   - cseViewEnrichments   - cseManageInsightSignals   - cseManageRules   - cseManageArtifacts   - cseViewMatchLists   - cseManageInsightPolicy   - cseManageEnrichments   - cseViewEntityConfiguration   - cseManageEntity   - cseExecuteAutomations   - cseManageSuppressedEntities   - cseManageInsightStatus     - cseManageInsightAssignee   - cseManageFavoriteFields   - cseViewSuppressedEntities  ### Alerting   - viewMonitorsV2   - manageMonitorsV2   - viewAlerts   - viewMutingSchedules   - manageMutingSchedules   - adminMonitorsV2  ### SLO   - viewSlos   - manageSlos  ### CloudSoar   - cloudSoarPlaybooksAccess   - cloudSoarNotificationConfigure   - cloudSoarReportAll   - cloudSoarIncidentTriageAccess   - cloudSoarIncidentTaskView   - cloudSoarIncidentChangeOwnership   - cloudSoarIncidentNotesEdit   - cloudSoarAPIEmailEdit   - cloudSoarIncidentTemplatesAccess   - cloudSoarIncidentPlaybooksManage   - cloudSoarGeneralConfigure   - cloudSoarEntitiesAccess   - cloudSoarEntitiesBulkPhysicalDelete   - cloudSoarIncidentAttachmentsAccess   - cloudSoarAppCentralAccess   - cloudSoarBridgeMonitoringAccess   - viewCloudSoar   - cloudSoarIncidentView   - cloudSoarObservabilityAccess   - cloudSoarAPIEmailRead   - cloudSoarAppCentralExport   - cloudSoarWidgetsAll   - cloudSoarIncidentTaskReassign   - cloudSoarIntegrationsAccess   - cloudSoarCustomizationIncidentLabels   - cloudSoarAutomationRulesConfigure   - cloudSoarIncidentTaskAccessAll   - cloudSoarAuditAndInformationConfigureAuditTrail   - cloudSoarIncidentTriageEdit   - cloudSoarIncidentEdit   - cloudSoarNotificationTriage   - cloudSoarIncidentTriageBulkPhysicalDelete   - cloudSoarIncidentNotesAccess   - cloudSoarAPIUse   - cloudSoarIncidentPlaybooksEdit   - cloudSoarDashboardAll   - cloudSoarEntitiesManage   - cloudSoarIncidentTemplatesConfigure   - cloudSoarIncidentTriageAccessAll   - cloudSoarPlaybooksConfigure   - cloudSoarIncidentAccessAll   - cloudSoarCustomizationLogo   - cloudSoarIncidentTaskAccess   - cloudSoarIncidentTriageView   - cloudSoarIntegrationsConfigure   - cloudSoarIncidentManageInvestigators   - cloudSoarIncidentAccess   - cloudSoarAuditAndInformationLicenseInformation   - cloudSoarIncidentBulkOperations   - cloudSoarCustomizationFields   - cloudSoarIncidentTaskEdit   - cloudSoarDashboardAccess   - cloudSoarIncidentAttachmentsEdit   - cloudSoarIncidentFoldersEdit   - cloudSoarUserManagementGroups   - cloudSoarIncidentPlaybooksAccess   - cloudSoarIncidentWarRoomUse   - cloudSoarReportAccess   - cloudSoarAuditAndInformationAuditTrail   - cloudSoarAutomationRulesAccess   - cloudSoarIncidentTriageChangeOwnership   - cloudSoarObservabilityManagement (e.g. [manageContent, manageDataVolumeFeed, manageFieldExtractionRules, manageS3DataForwarding])
  --autofillDependencies: string@bool-completer # Set this to true if you want to automatically append all missing capability requirements. If set to false an error will be thrown if any capabilities are missing their dependencies. (default: true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/roles")
  let body = {name: $name, description: $description, filterPredicate: $filterPredicate, users: $users, capabilities: $capabilities, autofillDependencies: $autofillDependencies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a role.
#
# GET /v1/roles/{id}
# operationId: getRole
export def "roles get-by-id" [
  id: string
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
  let full_url = (build-url $base $"/v1/roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a role.
#
# PUT /v1/roles/{id}
# operationId: updateRole
export def "roles updateRole" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the role. (e.g. DataAdmin)
  description: string # Description of the role. (e.g. Manage data of the org.)
  filterPredicate: string # A search filter to restrict access to specific logs. The filter is silently added to the beginning of each query a user runs. For example, using '!_sourceCategory=billing' as a filter predicate will prevent users assigned to the role from viewing logs from the source category named 'billing'. (e.g. !_sourceCategory=billing)
  users: list # List of user identifiers to assign the role to. (e.g. [0000000006743FE0, 0000000005FCE0EE])
  capabilities: list # List of [capabilities](https://help.sumologic.com/Manage/Users-and-Roles/Manage-Roles/Role-Capabilities) associated with this role. Valid values are ### Data Management   - viewCollectors   - manageCollectors   - manageBudgets   - manageDataVolumeFeed   - viewFieldExtraction   - manageFieldExtractionRules   - manageS3DataForwarding   - manageContent   - manageApps   - dataVolumeIndex   - manageConnections   - viewScheduledViews   - manageScheduledViews   - viewPartitions   - managePartitions   - viewFields   - manageFields   - viewAccountOverview   - manageTokens   - downloadSearchResults  ### Entity management   - manageEntityTypeConfig  ### Metrics   - metricsTransformation   - metricsExtraction   - metricsRules  ### Security   - managePasswordPolicy   - ipAllowlisting   - createAccessKeys   - manageAccessKeys   - manageSupportAccountAccess   - manageAuditDataFeed   - manageSaml   - shareDashboardOutsideOrg   - manageOrgSettings   - changeDataAccessLevel  ### Dashboards   - shareDashboardWorld   - shareDashboardAllowlist  ### UserManagement   - manageUsersAndRoles  ### Observability   - searchAuditIndex   - auditEventIndex  ### Cloud SIEM Enterprise   - viewCse  ### Alerting   - viewMonitorsV2   - manageMonitorsV2   - viewAlerts (e.g. [manageContent, manageDataVolumeFeed, manageFieldExtractionRules, manageS3DataForwarding])
  --autofillDependencies: string@bool-completer # Set this to true if you want to automatically append all missing capability requirements. If set to false an error will be thrown if any capabilities are missing their dependencies. (default: true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/roles/($id)")
  let body = {name: $name, description: $description, filterPredicate: $filterPredicate, users: $users, capabilities: $capabilities, autofillDependencies: $autofillDependencies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a role.
#
# DELETE /v1/roles/{id}
# operationId: deleteRole
export def "roles delete-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign a role to a user.
#
# PUT /v1/roles/{roleId}/users/{userId}
# operationId: assignRoleToUser
export def "roles-users assignRoleToUser" [
  roleId: string
  userId: string
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
  let full_url = (build-url $base $"/v1/roles/($roleId)/users/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove role from a user.
#
# DELETE /v1/roles/{roleId}/users/{userId}
# operationId: removeRoleFromUser
export def "roles-users removeRoleFromUser" [
  roleId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/roles/($roleId)/users/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of roles.
#
# GET /v2/roles
# operationId: listRolesV2
export def "roles listRolesV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of roles returned in the response. The number of roles returned may be less than the `limit`. (format: int32, default: 100)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left.
  --sortBy: string # Sort the list of roles by the `name` field.
  --name: string # Only return roles matching the given name.
]: nothing -> record<data: list<record>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new role.
#
# POST /v2/roles
# operationId: createRoleV2
# --selectedViews item shape: {viewName: string}
export def "roles createRoleV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the role. (e.g. DataAdmin)
  --description: string # Description of the role. (e.g. Manage data of the org.)
  --logAnalyticsFilter: string # A search filter which would be applied on partitions which belong to Log Analytics product area. (e.g. !_sourceCategory=collector)
  --auditDataFilter: string # A search filter which would be applied on partitions which belong to Audit Data product area. Help Doc : (https://help.sumologic.com/docs/manage/security/audit-index/). (e.g. info)
  --securityDataFilter: string # A search filter which would be applied on partitions which belong to Security Data product area. (e.g. error)
  --selectionType: string # Describes the Permission Construct for the list of views in "selectedViews" parameter.  ### Valid Values are :    - `All` selectionType would allow access to all views in the org.   - `Allow` selectionType would allow access to specific views mentioned in "selectedViews" parameter.   - `Deny` selectionType would deny access to specific views mentioned in "selectedViews" parameter. (e.g. All)
  --selectedViews: list # List of views which with specific view level filters in accordance to the selectionType chosen. — item shape: {viewName: string}
  --users: list # List of user identifiers to assign the role to. (e.g. [0000000006743FE0, 0000000005FCE0EE])
  --capabilities: list # List of [capabilities](https://help.sumologic.com/docs/manage/users-roles/roles/role-capabilities/) associated with this role. Valid values are ### Data Management   - viewCollectors   - manageCollectors   - manageBudgets   - manageDataVolumeFeed   - viewFieldExtraction   - manageFieldExtractionRules   - manageS3DataForwarding   - manageContent   - manageApps   - dataVolumeIndex   - manageConnections   - viewScheduledViews   - manageScheduledViews   - viewPartitions   - managePartitions   - viewFields   - manageFields   - viewAccountOverview   - manageTokens   - downloadSearchResults   - manageIndexes   - manageDataStreams   - viewParsers   - viewDataStreams  ### Entity management   - manageEntityTypeConfig  ### Metrics   - metricsTransformation   - metricsExtraction   - metricsRules  ### Security   - managePasswordPolicy   - ipAllowlisting   - ipWhitelisting   - createAccessKeys   - manageAccessKeys   - manageSupportAccountAccess   - manageAuditDataFeed   - manageSaml   - shareDashboardOutsideOrg   - manageOrgSettings   - changeDataAccessLevel  ### Dashboards   - shareDashboardWorld   - shareDashboardAllowlist   - shareDashboardWhitelist  ### UserManagement   - manageUsersAndRoles  ### Observability   - searchAuditIndex   - auditEventIndex  ### Cloud SIEM Enterprise   - viewCse   - cseViewAutomations   - cseManageContextActions   - cseViewNetworkBlocks   - cseManageInsightTags   - cseViewRules   - cseViewThreatIntelligence   - cseCommentOnInsights   - cseViewEntityGroups   - cseManageEntityConfiguration   - cseManageNetworkBlocks   - cseManageMatchLists   - cseViewCustomInsights   - cseManageActions   - cseManageAutomations   - cseManageMappings   - cseManageThreatIntelligence   - cseViewActions   - cseCreateInsights   - cseManageTagSchemas   - cseInvokeInsights   - cseManageCustomEntityType   - cseViewTagSchemas   - cseDeleteInsights   - cseManageCustomInsights   - cseViewFileAnalysis   - cseManageFileAnalysis   - cseManageEntityCriticality   - cseViewEntityCriticality   - cseViewEntity   - cseManageCustomInsightStatuses   - cseViewContextActions   - cseViewMappings   - cseViewCustomEntityType   - cseManageEntityGroups   - cseViewCustomInsightStatuses   - cseViewEnrichments   - cseManageInsightSignals   - cseManageRules   - cseManageArtifacts   - cseViewMatchLists   - cseManageInsightPolicy   - cseManageEnrichments   - cseViewEntityConfiguration   - cseManageEntity   - cseExecuteAutomations   - cseManageSuppressedEntities   - cseManageInsightStatus     - cseManageInsightAssignee   - cseManageFavoriteFields   - cseViewSuppressedEntities  ### Alerting   - viewMonitorsV2   - manageMonitorsV2   - viewAlerts   - viewMutingSchedules   - manageMutingSchedules   - adminMonitorsV2  ### SLO   - viewSlos   - manageSlos  ### CloudSoar   - cloudSoarPlaybooksAccess   - cloudSoarNotificationConfigure   - cloudSoarReportAll   - cloudSoarIncidentTriageAccess   - cloudSoarIncidentTaskView   - cloudSoarIncidentChangeOwnership   - cloudSoarIncidentNotesEdit   - cloudSoarAPIEmailEdit   - cloudSoarIncidentTemplatesAccess   - cloudSoarIncidentPlaybooksManage   - cloudSoarGeneralConfigure   - cloudSoarEntitiesAccess   - cloudSoarEntitiesBulkPhysicalDelete   - cloudSoarIncidentAttachmentsAccess   - cloudSoarAppCentralAccess   - cloudSoarBridgeMonitoringAccess   - viewCloudSoar   - cloudSoarIncidentView   - cloudSoarObservabilityAccess   - cloudSoarAPIEmailRead   - cloudSoarAppCentralExport   - cloudSoarWidgetsAll   - cloudSoarIncidentTaskReassign   - cloudSoarIntegrationsAccess   - cloudSoarCustomizationIncidentLabels   - cloudSoarAutomationRulesConfigure   - cloudSoarIncidentTaskAccessAll   - cloudSoarAuditAndInformationConfigureAuditTrail   - cloudSoarIncidentTriageEdit   - cloudSoarIncidentEdit   - cloudSoarNotificationTriage   - cloudSoarIncidentTriageBulkPhysicalDelete   - cloudSoarIncidentNotesAccess   - cloudSoarAPIUse   - cloudSoarIncidentPlaybooksEdit   - cloudSoarDashboardAll   - cloudSoarEntitiesManage   - cloudSoarIncidentTemplatesConfigure   - cloudSoarIncidentTriageAccessAll   - cloudSoarPlaybooksConfigure   - cloudSoarIncidentAccessAll   - cloudSoarCustomizationLogo   - cloudSoarIncidentTaskAccess   - cloudSoarIncidentTriageView   - cloudSoarIntegrationsConfigure   - cloudSoarIncidentManageInvestigators   - cloudSoarIncidentAccess   - cloudSoarAuditAndInformationLicenseInformation   - cloudSoarIncidentBulkOperations   - cloudSoarCustomizationFields   - cloudSoarIncidentTaskEdit   - cloudSoarDashboardAccess   - cloudSoarIncidentAttachmentsEdit   - cloudSoarIncidentFoldersEdit   - cloudSoarUserManagementGroups   - cloudSoarIncidentPlaybooksAccess   - cloudSoarIncidentWarRoomUse   - cloudSoarReportAccess   - cloudSoarAuditAndInformationAuditTrail   - cloudSoarAutomationRulesAccess   - cloudSoarIncidentTriageChangeOwnership   - cloudSoarObservabilityManagement (e.g. [manageContent, manageDataVolumeFeed, manageFieldExtractionRules, manageS3DataForwarding])
  --autofillDependencies: string@bool-completer # Set this to true if you want to automatically append all missing capability requirements. If set to false an error will be thrown if any capabilities are missing their dependencies. (default: true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/roles")
  let body = {name: $name, description: $description, logAnalyticsFilter: $logAnalyticsFilter, auditDataFilter: $auditDataFilter, securityDataFilter: $securityDataFilter, selectionType: $selectionType, selectedViews: $selectedViews, users: $users, capabilities: $capabilities, autofillDependencies: $autofillDependencies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a role.
#
# GET /v2/roles/{id}
# operationId: getRoleV2
export def "roles get-by-id-1" [
  id: string
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
  let full_url = (build-url $base $"/v2/roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a role.
#
# PUT /v2/roles/{id}
# operationId: updateRoleV2
# --selectedViews item shape: {viewName: string}
export def "roles updateRoleV2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the role. (e.g. DataAdmin)
  description: string # Description of the role. (e.g. Manage data of the org.)
  logAnalyticsFilter: string # A search filter which would be applied on partitions which belong to Log Analytics product area. (e.g. !_sourceCategory=collector)
  auditDataFilter: string # A search filter which would be applied on partitions which belong to Audit Data product area. Help Doc : (https://help.sumologic.com/docs/manage/security/audit-index/). (e.g. info)
  securityDataFilter: string # A search filter which would be applied on partitions which belong to Security Data product area. (e.g. error)
  selectionType: string # Describes the Permission Construct for the list of views in "selectedViews" parameter.  ### Valid Values are :    - `All` selectionType would allow access to all views in the org.   - `Allow` selectionType would allow access to specific views mentioned in "selectedViews" parameter.   - `Deny` selectionType would deny access to specific views mentioned in "selectedViews" parameter. (e.g. All)
  selectedViews: list # List of views which with specific view level filters in accordance to the selectionType chosen. — item shape: {viewName: string}
  users: list # List of user identifiers to assign the role to. (e.g. [0000000006743FE0, 0000000005FCE0EE])
  capabilities: list # List of [capabilities](https://help.sumologic.com/Manage/Users-and-Roles/Manage-Roles/Role-Capabilities) associated with this role. Valid values are ### Data Management   - viewCollectors   - manageCollectors   - manageBudgets   - manageDataVolumeFeed   - viewFieldExtraction   - manageFieldExtractionRules   - manageS3DataForwarding   - manageContent   - manageApps   - dataVolumeIndex   - manageConnections   - viewScheduledViews   - manageScheduledViews   - viewPartitions   - managePartitions   - viewFields   - manageFields   - viewAccountOverview   - manageTokens   - downloadSearchResults  ### Entity management   - manageEntityTypeConfig  ### Metrics   - metricsTransformation   - metricsExtraction   - metricsRules  ### Security   - managePasswordPolicy   - ipAllowlisting   - createAccessKeys   - manageAccessKeys   - manageSupportAccountAccess   - manageAuditDataFeed   - manageSaml   - shareDashboardOutsideOrg   - manageOrgSettings   - changeDataAccessLevel  ### Dashboards   - shareDashboardWorld   - shareDashboardAllowlist  ### UserManagement   - manageUsersAndRoles  ### Observability   - searchAuditIndex   - auditEventIndex  ### Cloud SIEM Enterprise   - viewCse  ### Alerting   - viewMonitorsV2   - manageMonitorsV2   - viewAlerts (e.g. [manageContent, manageDataVolumeFeed, manageFieldExtractionRules, manageS3DataForwarding])
  --autofillDependencies: string@bool-completer # Set this to true if you want to automatically append all missing capability requirements. If set to false an error will be thrown if any capabilities are missing their dependencies. (default: true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/roles/($id)")
  let body = {name: $name, description: $description, logAnalyticsFilter: $logAnalyticsFilter, auditDataFilter: $auditDataFilter, securityDataFilter: $securityDataFilter, selectionType: $selectionType, selectedViews: $selectedViews, users: $users, capabilities: $capabilities, autofillDependencies: $autofillDependencies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a role.
#
# DELETE /v2/roles/{id}
# operationId: deleteRoleV2
export def "roles delete-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign a role to a user.
#
# PUT /v2/roles/{roleId}/users/{userId}
# operationId: assignRoleToUserV2
export def "roles-users assignRoleToUserV2" [
  roleId: string
  userId: string
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
  let full_url = (build-url $base $"/v2/roles/($roleId)/users/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove role from a user.
#
# DELETE /v2/roles/{roleId}/users/{userId}
# operationId: removeRoleFromUserV2
export def "roles-users removeRoleFromUserV2" [
  roleId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/roles/($roleId)/users/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new folder.
#
# POST /v2/content/folders
# operationId: createFolder
export def "content-folders createFolder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isAdminMode: string # Set this to "true" if you want to perform the request as a Content Administrator.
  name: string # The name of the folder. (e.g. SampleFolder)
  --description: string # The description of the folder. (e.g. This is a sample folder.)
  parentId: string # The identifier of the parent folder.
]: any -> record<description: string, children: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/content/folders")
  let body = {name: $name, description: $description, parentId: $parentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"isAdminMode": $isAdminMode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a folder.
#
# GET /v2/content/folders/{id}
# operationId: getFolder
export def "content-folders get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isAdminMode: string # Set this to "true" if you want to perform the request as a Content Administrator.
]: nothing -> record<description: string, children: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/content/folders/($id)")
  let extra_headers = {"isAdminMode": $isAdminMode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a folder.
#
# PUT /v2/content/folders/{id}
# operationId: updateFolder
export def "content-folders updateFolder" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isAdminMode: string # Set this to "true" if you want to perform the request as a Content Administrator.
  name: string # The name of the folder. (e.g. SampleFolder)
  --description: string # The description of the folder. (e.g. This is a sample folder.)
]: any -> record<description: string, children: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/content/folders/($id)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"isAdminMode": $isAdminMode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get personal folder.
#
# GET /v2/content/folders/personal
# operationId: getPersonalFolder
export def "content-folders-personal get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description: string, children: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/content/folders/personal")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Schedule Global View job
#
# GET /v2/content/folders/global
# operationId: getGlobalFolderAsync
export def "content-folders-global get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isAdminMode: string # Set this to "true" if you want to perform the request as a Content Administrator.
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/content/folders/global")
  let extra_headers = {"isAdminMode": $isAdminMode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Global View job status
#
# GET /v2/content/folders/global/{jobId}/status
# operationId: getGlobalFolderAsyncStatus
export def "content-folders-global-status get" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, statusMessage: string, error: record<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/content/folders/global/($jobId)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Global View job result
#
# GET /v2/content/folders/global/{jobId}/result
# operationId: getGlobalFolderAsyncResult
export def "content-folders-global-result get" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/content/folders/global/($jobId)/result")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Schedule Admin Recommended folder job
#
# GET /v2/content/folders/adminRecommended
# operationId: getAdminRecommendedFolderAsync
export def "content-folders-admin-recommended get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isAdminMode: string # Set this to "true" if you want to perform the request as a Content Administrator.
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/content/folders/adminRecommended")
  let extra_headers = {"isAdminMode": $isAdminMode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Admin Recommended folder job status
#
# GET /v2/content/folders/adminRecommended/{jobId}/status
# operationId: getAdminRecommendedFolderAsyncStatus
export def "content-folders-admin-recommended-status get" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, statusMessage: string, error: record<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/content/folders/adminRecommended/($jobId)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Admin Recommended folder job result
#
# GET /v2/content/folders/adminRecommended/{jobId}/result
# operationId: getAdminRecommendedFolderAsyncResult
export def "content-folders-admin-recommended-result get" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description: string, children: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/content/folders/adminRecommended/($jobId)/result")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Schedule Installed Apps folder job
#
# GET /v2/content/folders/installedApps
# operationId: getInstalledAppsFolderAsync
export def "content-folders-installed-apps get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isAdminMode: string # Set this to "true" if you want to perform the request as a Content Administrator.
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/content/folders/installedApps")
  let extra_headers = {"isAdminMode": $isAdminMode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Installed Apps folder job status
#
# GET /v2/content/folders/installedApps/{jobId}/status
# operationId: getInstalledAppsFolderAsyncStatus
export def "content-folders-installed-apps-status get" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, statusMessage: string, error: record<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/content/folders/installedApps/($jobId)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Installed Apps folder job result
#
# GET /v2/content/folders/installedApps/{jobId}/result
# operationId: getInstalledAppsFolderAsyncResult
export def "content-folders-installed-apps-result get" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description: string, children: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/content/folders/installedApps/($jobId)/result")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get permissions of a content item
#
# GET /v2/content/{id}/permissions
# operationId: getContentPermissions
export def "content-permissions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --explicitOnly: string@bool-completer # There are two permission types: explicit and implicit. Permissions specifically assigned to the content item are explicit. Permissions derived from a parent content item, like a folder are implicit. To return only explicit permissions set this to true. (default: false)
  --isAdminMode: string # Set this to "true" if you want to perform the request as a Content Administrator.
]: nothing -> record<explicitPermissions: table<permissionName: string, sourceType: string, sourceId: string, contentId: string>, implicitPermissions: table<permissionName: string, sourceType: string, sourceId: string, contentId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "explicitOnly" $explicitOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/content/($id)/permissions" $qp)
  let extra_headers = {"isAdminMode": $isAdminMode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add permissions to a content item.
#
# PUT /v2/content/{id}/permissions/add
# operationId: addContentPermissions
# --contentPermissionAssignments item shape: {permissionName: string, sourceType: string, sourceId: string, contentId: string}
export def "content-permissions-add addContentPermissions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isAdminMode: string # Set this to "true" if you want to perform the request as a Content Administrator.
  contentPermissionAssignments: list # Content permissions to be updated. — item shape: {permissionName: string, sourceType: string, sourceId: string, contentId: string}
  --notifyRecipients: string@bool-completer # Set this to "true" to notify the users who had a permission update.
  notificationMessage: string # The notification message sent to the users who had a permission update.
]: any -> record<explicitPermissions: table<permissionName: string, sourceType: string, sourceId: string, contentId: string>, implicitPermissions: table<permissionName: string, sourceType: string, sourceId: string, contentId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/content/($id)/permissions/add")
  let body = {contentPermissionAssignments: $contentPermissionAssignments, notifyRecipients: $notifyRecipients, notificationMessage: $notificationMessage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"isAdminMode": $isAdminMode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove permissions from a content item.
#
# PUT /v2/content/{id}/permissions/remove
# operationId: removeContentPermissions
# --contentPermissionAssignments item shape: {permissionName: string, sourceType: string, sourceId: string, contentId: string}
export def "content-permissions-remove removeContentPermissions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isAdminMode: string # Set this to "true" if you want to perform the request as a Content Administrator.
  contentPermissionAssignments: list # Content permissions to be updated. — item shape: {permissionName: string, sourceType: string, sourceId: string, contentId: string}
  --notifyRecipients: string@bool-completer # Set this to "true" to notify the users who had a permission update.
  notificationMessage: string # The notification message sent to the users who had a permission update.
]: any -> record<explicitPermissions: table<permissionName: string, sourceType: string, sourceId: string, contentId: string>, implicitPermissions: table<permissionName: string, sourceType: string, sourceId: string, contentId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/content/($id)/permissions/remove")
  let body = {contentPermissionAssignments: $contentPermissionAssignments, notifyRecipients: $notifyRecipients, notificationMessage: $notificationMessage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"isAdminMode": $isAdminMode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get content item by path.
#
# GET /v2/content/path
# operationId: getItemByPath
export def "content-path list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --path: string # Path of the content item to retrieve. (e.g. /Library/Users/user@sumo.com/SampleFolder)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/content/path" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get path of an item.
#
# GET /v2/content/{contentId}/path
# operationId: getPathById
export def "content-path get" [
  contentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<path: string, pathItems: table<id: string, name: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/content/($contentId)/path")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start a content export job.
#
# POST /v2/content/{id}/export
# operationId: beginAsyncExport
export def "content-export beginAsyncExport" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isAdminMode: string # Set this to "true" if you want to perform the request as a Content Administrator.
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/content/($id)/export")
  let extra_headers = {"isAdminMode": $isAdminMode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Content export job status.
#
# GET /v2/content/{contentId}/export/{jobId}/status
# operationId: getAsyncExportStatus
export def "content-export-status get" [
  contentId: string
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isAdminMode: string # Set this to "true" if you want to perform the request as a Content Administrator.
]: nothing -> record<status: string, statusMessage: string, error: record<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/content/($contentId)/export/($jobId)/status")
  let extra_headers = {"isAdminMode": $isAdminMode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Content export job result.
#
# GET /v2/content/{contentId}/export/{jobId}/result
# Discriminator (response): type
# operationId: getAsyncExportResult
export def "content-export-result get" [
  contentId: string
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isAdminMode: string # Set this to "true" if you want to perform the request as a Content Administrator.
]: nothing -> record<type: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/content/($contentId)/export/($jobId)/result")
  let extra_headers = {"isAdminMode": $isAdminMode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start a content import job.
#
# POST /v2/content/folders/{folderId}/import
# Discriminator (request): type
# operationId: beginAsyncImport
export def "content-folders-import beginAsyncImport" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --overwrite: string@bool-completer # Set this to "true" to overwrite a content item if the name already exists. (default: false)
  --isAdminMode: string # Set this to "true" if you want to perform the request as a Content Administrator.
  type: string # The content item type. **Note:**  - `MewboardSyncDefinition` _is depreciated, and will soon be removed. Please use_ `DashboardV2SyncDefinition`    _instead_.  - Dashboard links are not supported for dashboards.
  name: string # The name of the item.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "overwrite" $overwrite "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/content/folders/($folderId)/import" $qp)
  let body = {type: $type, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"isAdminMode": $isAdminMode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Content import job status.
#
# GET /v2/content/folders/{folderId}/import/{jobId}/status
# operationId: getAsyncImportStatus
export def "content-folders-import-status get" [
  folderId: string
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isAdminMode: string # Set this to "true" if you want to perform the request as a Content Administrator.
]: nothing -> record<status: string, statusMessage: string, error: record<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/content/folders/($folderId)/import/($jobId)/status")
  let extra_headers = {"isAdminMode": $isAdminMode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Content import job result.
#
# GET /v2/content/folders/{folderId}/import/{jobId}/result
# operationId: getAsyncImportResult
export def "content-folders-import-result get" [
  folderId: string
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isAdminMode: string # Set this to "true" if you want to perform the request as a Content Administrator.
]: nothing -> record<status: string, summary: record<totalItems: int, successCount: int, failureCount: int>, failures: table<path: string, type: string, error: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/content/folders/($folderId)/import/($jobId)/result")
  let extra_headers = {"isAdminMode": $isAdminMode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start a content deletion job.
#
# DELETE /v2/content/{id}/delete
# operationId: beginAsyncDelete
export def "content-delete beginAsyncDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isAdminMode: string # Set this to "true" if you want to perform the request as a Content Administrator.
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/content/($id)/delete")
  let extra_headers = {"isAdminMode": $isAdminMode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Content deletion job status.
#
# GET /v2/content/{id}/delete/{jobId}/status
# operationId: getAsyncDeleteStatus
export def "content-delete-status get" [
  id: string
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isAdminMode: string # Set this to "true" if you want to perform the request as a Content Administrator.
]: nothing -> record<status: string, statusMessage: string, error: record<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/content/($id)/delete/($jobId)/status")
  let extra_headers = {"isAdminMode": $isAdminMode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start a content copy job.
#
# POST /v2/content/{id}/copy
# operationId: beginAsyncCopy
export def "content-copy beginAsyncCopy" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --destinationFolder: string # The identifier of the destination folder.
  --isAdminMode: string # Set this to "true" if you want to perform the request as a Content Administrator.
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "destinationFolder" $destinationFolder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/content/($id)/copy" $qp)
  let extra_headers = {"isAdminMode": $isAdminMode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Content copy job status.
#
# GET /v2/content/{id}/copy/{jobId}/status
# operationId: asyncCopyStatus
export def "content-copy-status asyncCopyStatus" [
  id: string
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isAdminMode: string # Set this to "true" if you want to perform the request as a Content Administrator.
]: nothing -> record<status: string, statusMessage: string, error: record<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/content/($id)/copy/($jobId)/status")
  let extra_headers = {"isAdminMode": $isAdminMode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Move an item.
#
# POST /v2/content/{id}/move
# operationId: moveItem
export def "content-move moveItem" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --destinationFolderId: string # Identifier of the destination folder.
  --isAdminMode: string # Set this to "true" if you want to perform the request as a Content Administrator.
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "destinationFolderId" $destinationFolderId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/content/($id)/move" $qp)
  let extra_headers = {"isAdminMode": $isAdminMode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of transformation rules.
#
# GET /v1/transformationRules
# operationId: getTransformationRules
export def "transformation-rules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of transformation rules returned in the response. (format: int32, default: 100, e.g. 10)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left.
]: nothing -> record<data: list<record>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/transformationRules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new transformation rule.
#
# POST /v1/transformationRules
# operationId: createRule
# --ruleDefinition shape: {name: string, selector: string, dimensionTransformations?: list, transformedMetricsRetention?: int, retention: int}
export def "transformation-rules createRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ruleDefinition: record # The properties that define a transformation rule. — shape: {name: string, selector: string, dimensionTransformations?: list, transformedMetricsRetention?: int, retention: int}
  --enabled: string@bool-completer # True if the rule is enabled. (e.g. true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/transformationRules")
  let body = {ruleDefinition: $ruleDefinition, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a transformation rule.
#
# GET /v1/transformationRules/{id}
# operationId: getTransformationRule
export def "transformation-rules get" [
  id: string
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
  let full_url = (build-url $base $"/v1/transformationRules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a transformation rule.
#
# PUT /v1/transformationRules/{id}
# operationId: updateTransformationRule
# --ruleDefinition shape: {name: string, selector: string, dimensionTransformations?: list, transformedMetricsRetention?: int, retention: int}
export def "transformation-rules updateTransformationRule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ruleDefinition: record # The properties that define a transformation rule. — shape: {name: string, selector: string, dimensionTransformations?: list, transformedMetricsRetention?: int, retention: int}
  --enabled: string@bool-completer # True if the rule is enabled. (e.g. true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/transformationRules/($id)")
  let body = {ruleDefinition: $ruleDefinition, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a transformation rule.
#
# DELETE /v1/transformationRules/{id}
# operationId: deleteRule
export def "transformation-rules delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/transformationRules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the owner of an account.
#
# GET /v1/account/accountOwner
# operationId: getAccountOwner
export def "account-account-owner get" [
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
  let full_url = (build-url $base "/v1/account/accountOwner")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get overview of the account status.
#
# GET /v1/account/status
# operationId: getStatus
export def "account-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pricingModel: string, canUpdatePlan: bool, planType: string, planExpirationDays: int, applicationUse: string, accountActivated: bool, totalCredits: int, logModel: string, isSubscriptionV2: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the configured subdomain.
#
# GET /v1/account/subdomain
# operationId: getSubdomain
export def "account-subdomain get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, subdomain: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/subdomain")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update account subdomain.
#
# PUT /v1/account/subdomain
# operationId: updateSubdomain
export def "account-subdomain updateSubdomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  subdomain: string # The new subdomain. (e.g. my-company)
]: any -> record<createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, subdomain: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/subdomain")
  let body = {subdomain: $subdomain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create account subdomain.
#
# POST /v1/account/subdomain
# operationId: createSubdomain
export def "account-subdomain createSubdomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  subdomain: string # The new subdomain. (e.g. my-company)
]: any -> record<createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, subdomain: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/subdomain")
  let body = {subdomain: $subdomain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the configured subdomain.
#
# DELETE /v1/account/subdomain
# operationId: deleteSubdomain
export def "account-subdomain delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/subdomain")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Recover subdomains for a user.
#
# POST /v1/account/subdomain/recover
# operationId: recoverSubdomains
export def "account-subdomain-recover recoverSubdomains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Email address of the user to get subdomain information.
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/account/subdomain/recover" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export credits usage details as CSV.
#
# POST /v1/account/usage/report
# operationId: exportUsageReport
export def "account-usage-report exportUsageReport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startDate: string # Start date, without the time, of the usage data to fetch. If no value is provided startDate is used as the start of the subscription. The start date cannot be before the start of the subscription. (e.g. 2019-07-20)
  --endDate: string # End date, without the time, of usage data to fetch. If no value is provided endDate is used as the end of the subscription. The end date cannot be after the end of the subscription. (e.g. 2019-08-20)
  --groupBy: string # Perform a groupBy operation on the usage details. If no value is provided data is grouped by `Day` - `day`: Aggregate the data by day - `week`: Aggregate the data by week. Week starts at Monday and ends at sunday night. - `month`: Aggregate the data by calendar month. (default: day, e.g. day)
  --reportType: string # Specifies the type of report to be exported. Available types are `standard` and `detailed`. An additional `childDetailed` type is available for Sumo Orgs parents. Detailed report will have raw consumption along with the credits breakdown. If no value is provided Standard reports will be exported. (default: standard, e.g. standard)
  --includeDeploymentCharge: string@bool-completer # Deployment charges will be applied to the returned usages csv if this is set to true and the organization  is a part of Sumo Organizations as a child organization. (default: false, e.g. false)
]: any -> record<jobId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account/usage/report")
  let body = {startDate: $startDate, endDate: $endDate, groupBy: $groupBy, reportType: $reportType, includeDeploymentCharge: $includeDeploymentCharge} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get report generation status.
#
# GET /v1/account/usage/report/{jobId}/status
# operationId: getStatusForReport
export def "account-usage-report-status get" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, message: string, detail: string, meta: record, status: string, statusMessage: string, reportDownloadURL: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/account/usage/report/($jobId)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get usage forecast with respect to last number of days specified.
#
# GET /v1/account/usageForecast
# operationId: getUsageForecast
export def "account-usage-forecast get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --numberOfDays: float # Number of days to use for calculating average usage and forecast.
]: nothing -> record<averageUsage: float, usagePercentage: float, forecastedUsage: float, forecastedUsagePercentage: float, remainingDays: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "numberOfDays" $numberOfDays "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/account/usageForecast" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the pending plan update request, if any.
#
# GET /v1/plan/pendingUpdateRequest
# operationId: getPendingUpdateRequest
export def "plan-pending-update-request get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<createdOn: string, plan: record<productId: string, planCost: float, billingFrequency: string, consumables: list<record>, planType: string, planName: string, discountAmount: int, contractPeriod: record<startDate: string, endDate: string>, currentBillingPeriod: record<startDate: string, endDate: string>, credits: int, baselines: record<continuousIngest: int, continuousStorage: int, frequentIngest: int, frequentStorage: int, infrequentIngest: int, infrequentStorage: int, infrequentScan: int, metrics: int, cseIngest: int, cseStorage: int, tracingIngest: int, flexIngest: int, flexStorage: int, flexScanRatio: int, aiInvestigation: int>, pendingUpdateRequest: bool, prorationDetails: record<remainingDays: int, proratedCredits: int, proratedCost: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/plan/pendingUpdateRequest")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the pending plan update request, if any.
#
# DELETE /v1/plan/pendingUpdateRequest
# operationId: deletePendingUpdateRequest
export def "plan-pending-update-request delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/plan/pendingUpdateRequest")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get usages for child orgs.
#
# POST /v1/organizations/usages
# operationId: getChildUsages
export def "organizations-usages post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startDate: string # Start date, without the time, of the usage data to fetch. (e.g. 2019-07-20)
  --endDate: string # End date, without the time, of usage data to fetch. (e.g. 2019-10-20)
]: any -> record<data: table<status: string, orgName: string, orgId: string, allocatedCredits: float, usages: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/organizations/usages")
  let body = {startDate: $startDate, endDate: $endDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Save a metrics search.
#
# POST /v1/metricsSearches
# operationId: createMetricsSearch
# --timeRange shape: {type: string}
# --metricsQueries item shape: {rowId: string, query: string}
export def "metrics-searches createMetricsSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string # Item title in the content library. (e.g. Short title)
  description: string # Item description in the content library. (e.g. Long and detailed description)
  timeRange: record # e.g. {type: BeginBoundedTimeRange, from: {type: RelativeTimeRangeBoundary, relativeTime: -15m}} — shape: {type: string}
  --logQuery: string # Log query used to add an overlay to the chart. (e.g. my_metric | timeslice 1m | count by _timeslice)
  metricsQueries: list # Metrics queries, up to the maximum of six. — item shape: {rowId: string, query: string}
  --desiredQuantizationInSecs: int # Desired quantization in seconds. (format: int32, default: 0, e.g. 60)
  --properties: string # Chart properties, like line width, color palette, and the fill missing data method. Leave this field empty to use the defaults. This property contains JSON object encoded as a string.  (e.g. { \"key\": \"value\" })
  parentId: string # Identifier of a folder to which the metrics search should be added. (e.g. 000000000000001A)
]: any -> record<title: string, description: string, timeRange: record<type: string>, logQuery: string, metricsQueries: table<rowId: string, query: string>, desiredQuantizationInSecs: int, properties: string, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, id: string, parentId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/metricsSearches")
  let body = {title: $title, description: $description, timeRange: $timeRange, logQuery: $logQuery, metricsQueries: $metricsQueries, desiredQuantizationInSecs: $desiredQuantizationInSecs, properties: $properties, parentId: $parentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a metrics search.
#
# GET /v1/metricsSearches/{id}
# operationId: getMetricsSearch
export def "metrics-searches get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<title: string, description: string, timeRange: record<type: string>, logQuery: string, metricsQueries: table<rowId: string, query: string>, desiredQuantizationInSecs: int, properties: string, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, id: string, parentId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/metricsSearches/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a metrics search.
#
# PUT /v1/metricsSearches/{id}
# operationId: updateMetricsSearch
# --timeRange shape: {type: string}
# --metricsQueries item shape: {rowId: string, query: string}
export def "metrics-searches updateMetricsSearch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string # Item title in the content library. (e.g. Short title)
  description: string # Item description in the content library. (e.g. Long and detailed description)
  timeRange: record # e.g. {type: BeginBoundedTimeRange, from: {type: RelativeTimeRangeBoundary, relativeTime: -15m}} — shape: {type: string}
  --logQuery: string # Log query used to add an overlay to the chart. (e.g. my_metric | timeslice 1m | count by _timeslice)
  metricsQueries: list # Metrics queries, up to the maximum of six. — item shape: {rowId: string, query: string}
  --desiredQuantizationInSecs: int # Desired quantization in seconds. (format: int32, default: 0, e.g. 60)
  --properties: string # Chart properties, like line width, color palette, and the fill missing data method. Leave this field empty to use the defaults. This property contains JSON object encoded as a string.  (e.g. { \"key\": \"value\" })
]: any -> record<title: string, description: string, timeRange: record<type: string>, logQuery: string, metricsQueries: table<rowId: string, query: string>, desiredQuantizationInSecs: int, properties: string, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, id: string, parentId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/metricsSearches/($id)")
  let body = {title: $title, description: $description, timeRange: $timeRange, logQuery: $logQuery, metricsQueries: $metricsQueries, desiredQuantizationInSecs: $desiredQuantizationInSecs, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a metrics search.
#
# DELETE /v1/metricsSearches/{id}
# operationId: deleteMetricsSearch
export def "metrics-searches delete-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/metricsSearches/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of tokens.
#
# GET /v1/tokens
# operationId: listTokens
export def "tokens listTokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: string, name: string, description: string, status: string, type: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a token.
#
# POST /v1/tokens
# Discriminator (response): type
# operationId: createToken
export def "tokens createToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the token. (e.g. token-name)
  --description: string # Description of the token. (e.g. token description: for test.)
  status: string # Status of the token. Can be `Active`, or `Inactive`. (e.g. Active)
  type: string # Type of the token. Valid values: 1) CollectorRegistration (e.g. CollectorRegistration)
]: any -> record<id: string, name: string, description: string, status: string, type: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tokens")
  let body = {name: $name, description: $description, status: $status, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a token.
#
# GET /v1/tokens/{id}
# Discriminator (response): type
# operationId: getToken
export def "tokens get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, status: string, type: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tokens/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a token.
#
# PUT /v1/tokens/{id}
# Discriminator (response): type
# operationId: updateToken
export def "tokens updateToken" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the token. (e.g. token-name)
  --description: string # Description of the token. (e.g. token description: for test.)
  status: string # Status of the token. Can be `Active`, or `Inactive`. (e.g. Active)
  type: string # Type of the token. Valid values: 1) CollectorRegistration (e.g. CollectorRegistration)
  version: int # Version of the token. (format: int64)
]: any -> record<id: string, name: string, description: string, status: string, type: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tokens/($id)")
  let body = {name: $name, description: $description, status: $status, type: $type, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a token.
#
# DELETE /v1/tokens/{id}
# operationId: deleteToken
export def "tokens delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tokens/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all access keys.
#
# GET /v1/accessKeys
# operationId: listAccessKeys
export def "access-keys listAccessKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of access keys returned in the response. The number of access keys returned may be less than the `limit`. (format: int32, default: 100)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left.
]: nothing -> record<data: table<id: string, label: string, corsHeaders: list, disabled: bool, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, serviceAccountId: string, lastUsed: string, scopes: list, effectiveScopes: list>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/accessKeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an access key.
#
# POST /v1/accessKeys
# operationId: createAccessKey
export def "access-keys createAccessKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  label: string # A name for the access key to be created. (e.g. automation access key)
  --corsHeaders: list # An array of domains for which the access key is valid. Whether Sumo Logic accepts or rejects an API request depends on whether it contains an ORIGIN header and the entries in the allowlist. Sumo Logic will reject:   1. Requests with an ORIGIN header but the allowlist is empty.   2. Requests with an ORIGIN header that don't match any entry in the allowlist. (e.g. [https://my-app.com, https://mail.my-app.com])
  --scopes: list # Scopes assigned to the key. ### Alerting   - adminMonitorsV2   - viewMonitorsV2   - manageMonitorsV2  ### Data Management   - manageApps   - viewCollectors   - manageCollectors   - viewConnections   - manageConnections   - contentAdmin   - viewFieldExtractionRules   - manageFieldExtractionRules               - viewFields   - manageFields   - manageBudgets   - viewLibrary   - manageLibrary   - viewPartitions   - managePartitions   - manageS3DataForwarding   - viewScheduledViews   - manageScheduledViews   - manageTokens  ### Logs   - runLogSearch  ### Metrics   - runMetricsQuery   ### Reliability Management   - viewSlos   - manageSlos  ### Security   - manageAccessKeys   - viewPersonalAccessKeys   - managePersonalAccessKeys  ### UserManagement   - viewUsersAndRoles   - manageUsersAndRoles (e.g. [manageUsersAndRoles, viewCollectors])
]: any -> record<id: string, label: string, corsHeaders: list<string>, disabled: bool, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, serviceAccountId: string, lastUsed: string, scopes: list<string>, effectiveScopes: list<string>, key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/accessKeys")
  let body = {label: $label, corsHeaders: $corsHeaders, scopes: $scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List personal keys.
#
# GET /v1/accessKeys/personal
# operationId: listPersonalAccessKeys
export def "access-keys-personal listPersonalAccessKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: string, label: string, corsHeaders: list, disabled: bool, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, serviceAccountId: string, lastUsed: string, scopes: list, effectiveScopes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/accessKeys/personal")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all scopes.
#
# GET /v1/accessKeys/scopes
# operationId: listScopes
export def "access-keys-scopes listScopes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: string, label: string, type: string, dependsOn: list, group: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/accessKeys/scopes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an access key.
#
# PUT /v1/accessKeys/{id}
# operationId: updateAccessKey
export def "access-keys updateAccessKey" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --disabled: string@bool-completer # Indicates whether the access key is disabled or not. (e.g. true)
  --corsHeaders: list # An array of domains for which the access key is valid. Whether Sumo Logic accepts or rejects an API request depends on whether it contains an ORIGIN header and the entries in the allowlist. Sumo Logic will reject:   1. Requests with an ORIGIN header but the allowlist is empty.   2. Requests with an ORIGIN header that don't match any entry in the allowlist. (e.g. [https://my-app.com, https://mail.my-app.com])
  --scopes: list # Scopes assigned to the key. <br><br> Note: Updates to scopes will take up to 5m to reflect due to caching in the system. ### Alerting   - adminMonitorsV2   - viewMonitorsV2   - manageMonitorsV2  ### Data Management   - manageApps   - viewCollectors   - manageCollectors   - viewConnections   - manageConnections   - contentAdmin   - viewFieldExtractionRules   - manageFieldExtractionRules               - viewFields   - manageFields   - manageBudgets   - viewLibrary   - manageLibrary   - viewPartitions   - managePartitions   - manageS3DataForwarding   - viewScheduledViews   - manageScheduledViews   - manageTokens  ### Logs   - runLogSearch  ### Metrics   - runMetricsQuery   ### Reliability Management   - viewSlos   - manageSlos  ### Security   - manageAccessKeys   - viewPersonalAccessKeys   - managePersonalAccessKeys  ### UserManagement   - viewUsersAndRoles   - manageUsersAndRoles (e.g. [manageUsersAndRoles, viewCollectors])
]: any -> record<id: string, label: string, corsHeaders: list<string>, disabled: bool, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, serviceAccountId: string, lastUsed: string, scopes: list<string>, effectiveScopes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accessKeys/($id)")
  let body = {disabled: $disabled, corsHeaders: $corsHeaders, scopes: $scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an access key.
#
# DELETE /v1/accessKeys/{id}
# operationId: deleteAccessKey
export def "access-keys delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accessKeys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rotate the access key secret
#
# PUT /v1/accessKeys/{id}/rotate
# operationId: rotateAccessKeySecret
export def "access-keys-rotate rotateAccessKeySecret" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, label: string, corsHeaders: list<string>, disabled: bool, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, serviceAccountId: string, lastUsed: string, scopes: list<string>, effectiveScopes: list<string>, key: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accessKeys/($id)/rotate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of SAML configurations.
#
# GET /v1/saml/identityProviders
# operationId: getIdentityProviders
export def "saml-identity-providers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/saml/identityProviders")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new SAML configuration.
#
# POST /v1/saml/identityProviders
# operationId: createIdentityProvider
# --onDemandProvisioningEnabled shape: {firstNameAttribute?: string, lastNameAttribute?: string, onDemandProvisioningRoles: list}
@deprecated --flag spInitiatedLoginPath
export def "saml-identity-providers createIdentityProvider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --spInitiatedLoginPath: string # This property has been deprecated and is no longer used. (DEPRECATED, default: , e.g. http://www.okta.com/abxcseyuiwelflkdjh)
  configurationName: string # Name of the SSO policy or another name used to describe the policy internally. (e.g. SumoLogic)
  issuer: string # The unique URL assigned to the organization by the SAML Identity Provider. (e.g. http://www.okta.com/abxcseyuiwelflkdjh)
  --spInitiatedLoginEnabled: string@bool-completer # True if Sumo Logic redirects users to your identity provider with a SAML AuthnRequest when signing in. (default: false)
  --authnRequestUrl: string # The URL that the identity provider has assigned for Sumo Logic to submit SAML authentication requests to the identity provider. (default: , e.g. https://www.okta.com/app/sumologic/abxcseyuiwelflkdjh/sso/saml)
  x509cert1: string # The certificate is used to verify the signature in SAML assertions.
  --x509cert2: string # The backup certificate used to verify the signature in SAML assertions when x509cert1 expires. (default: )
  --x509cert3: string # The backup certificate used to verify the signature in SAML assertions when x509cert1 expires and x509cert2 is empty. (default: )
  --onDemandProvisioningEnabled: record # shape: {firstNameAttribute?: string, lastNameAttribute?: string, onDemandProvisioningRoles: list}
  --rolesAttribute: string # The role that Sumo Logic will assign to users when they sign in. (default: , e.g. Sumo_Role)
  --logoutEnabled: string@bool-completer # True if users are redirected to a URL after signing out of Sumo Logic. (default: false)
  --logoutUrl: string # The URL that users will be redirected to after signing out of Sumo Logic. (default: , e.g. https://www.sumologic.com)
  --emailAttribute: string # The email address of the new user account. (default: , e.g. attribute/subject)
  --debugMode: string@bool-completer # True if additional details are included when a user fails to sign in. (default: false)
  --signAuthnRequest: string@bool-completer # True if Sumo Logic will send signed Authn requests to the identity provider. (default: false)
  --disableRequestedAuthnContext: string@bool-completer # True if Sumo Logic will include the RequestedAuthnContext element of the SAML AuthnRequests it sends to the identity provider. (default: false)
  --isRedirectBinding: string@bool-completer # True if the SAML binding is of HTTP Redirect type. (default: false)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/saml/identityProviders")
  let body = {spInitiatedLoginPath: $spInitiatedLoginPath, configurationName: $configurationName, issuer: $issuer, spInitiatedLoginEnabled: $spInitiatedLoginEnabled, authnRequestUrl: $authnRequestUrl, x509cert1: $x509cert1, x509cert2: $x509cert2, x509cert3: $x509cert3, onDemandProvisioningEnabled: $onDemandProvisioningEnabled, rolesAttribute: $rolesAttribute, logoutEnabled: $logoutEnabled, logoutUrl: $logoutUrl, emailAttribute: $emailAttribute, debugMode: $debugMode, signAuthnRequest: $signAuthnRequest, disableRequestedAuthnContext: $disableRequestedAuthnContext, isRedirectBinding: $isRedirectBinding} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a SAML configuration.
#
# PUT /v1/saml/identityProviders/{id}
# operationId: updateIdentityProvider
# --onDemandProvisioningEnabled shape: {firstNameAttribute?: string, lastNameAttribute?: string, onDemandProvisioningRoles: list}
@deprecated --flag spInitiatedLoginPath
export def "saml-identity-providers updateIdentityProvider" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --spInitiatedLoginPath: string # This property has been deprecated and is no longer used. (DEPRECATED, default: , e.g. http://www.okta.com/abxcseyuiwelflkdjh)
  configurationName: string # Name of the SSO policy or another name used to describe the policy internally. (e.g. SumoLogic)
  issuer: string # The unique URL assigned to the organization by the SAML Identity Provider. (e.g. http://www.okta.com/abxcseyuiwelflkdjh)
  --spInitiatedLoginEnabled: string@bool-completer # True if Sumo Logic redirects users to your identity provider with a SAML AuthnRequest when signing in. (default: false)
  --authnRequestUrl: string # The URL that the identity provider has assigned for Sumo Logic to submit SAML authentication requests to the identity provider. (default: , e.g. https://www.okta.com/app/sumologic/abxcseyuiwelflkdjh/sso/saml)
  x509cert1: string # The certificate is used to verify the signature in SAML assertions.
  --x509cert2: string # The backup certificate used to verify the signature in SAML assertions when x509cert1 expires. (default: )
  --x509cert3: string # The backup certificate used to verify the signature in SAML assertions when x509cert1 expires and x509cert2 is empty. (default: )
  --onDemandProvisioningEnabled: record # shape: {firstNameAttribute?: string, lastNameAttribute?: string, onDemandProvisioningRoles: list}
  --rolesAttribute: string # The role that Sumo Logic will assign to users when they sign in. (default: , e.g. Sumo_Role)
  --logoutEnabled: string@bool-completer # True if users are redirected to a URL after signing out of Sumo Logic. (default: false)
  --logoutUrl: string # The URL that users will be redirected to after signing out of Sumo Logic. (default: , e.g. https://www.sumologic.com)
  --emailAttribute: string # The email address of the new user account. (default: , e.g. attribute/subject)
  --debugMode: string@bool-completer # True if additional details are included when a user fails to sign in. (default: false)
  --signAuthnRequest: string@bool-completer # True if Sumo Logic will send signed Authn requests to the identity provider. (default: false)
  --disableRequestedAuthnContext: string@bool-completer # True if Sumo Logic will include the RequestedAuthnContext element of the SAML AuthnRequests it sends to the identity provider. (default: false)
  --isRedirectBinding: string@bool-completer # True if the SAML binding is of HTTP Redirect type. (default: false)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saml/identityProviders/($id)")
  let body = {spInitiatedLoginPath: $spInitiatedLoginPath, configurationName: $configurationName, issuer: $issuer, spInitiatedLoginEnabled: $spInitiatedLoginEnabled, authnRequestUrl: $authnRequestUrl, x509cert1: $x509cert1, x509cert2: $x509cert2, x509cert3: $x509cert3, onDemandProvisioningEnabled: $onDemandProvisioningEnabled, rolesAttribute: $rolesAttribute, logoutEnabled: $logoutEnabled, logoutUrl: $logoutUrl, emailAttribute: $emailAttribute, debugMode: $debugMode, signAuthnRequest: $signAuthnRequest, disableRequestedAuthnContext: $disableRequestedAuthnContext, isRedirectBinding: $isRedirectBinding} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a SAML configuration.
#
# DELETE /v1/saml/identityProviders/{id}
# operationId: deleteIdentityProvider
export def "saml-identity-providers delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saml/identityProviders/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get list of allowlisted users.
#
# GET /v1/saml/allowlistedUsers
# operationId: getAllowlistedUsers
export def "saml-allowlisted-users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<userId: string, firstName: string, lastName: string, email: string, canManageSaml: bool, isActive: bool, lastLogin: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/saml/allowlistedUsers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Allowlist a user.
#
# POST /v1/saml/allowlistedUsers/{userId}
# operationId: createAllowlistedUser
export def "saml-allowlisted-users createAllowlistedUser" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<userId: string, firstName: string, lastName: string, email: string, canManageSaml: bool, isActive: bool, lastLogin: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saml/allowlistedUsers/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove an allowlisted user.
#
# DELETE /v1/saml/allowlistedUsers/{userId}
# operationId: deleteAllowlistedUser
export def "saml-allowlisted-users delete" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saml/allowlistedUsers/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Require SAML for sign-in.
#
# POST /v1/saml/lockdown/enable
# operationId: enableSamlLockdown
export def "saml-lockdown-enable enableSamlLockdown" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/saml/lockdown/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable SAML lockdown.
#
# POST /v1/saml/lockdown/disable
# operationId: disableSamlLockdown
export def "saml-lockdown-disable disableSamlLockdown" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/saml/lockdown/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get SAML configuration metadata XML.
#
# GET /v1/saml/identityProviders/{id}/metadata
# operationId: getSamlMetadata
export def "saml-identity-providers-metadata get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saml/identityProviders/($id)/metadata")
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all allowlisted CIDRs/IP addresses.
#
# GET /v1/serviceAllowlist/addresses
# operationId: listAllowlistedCidrs
export def "service-allowlist-addresses listAllowlistedCidrs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<cidr: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/serviceAllowlist/addresses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Allowlist CIDRs/IP addresses.
#
# POST /v1/serviceAllowlist/addresses/add
# operationId: addAllowlistedCidrs
# --data item shape: {cidr: string, description?: string}
export def "service-allowlist-addresses-add addAllowlistedCidrs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: list # An array of CIDR notations and/or IP addresses. — item shape: {cidr: string, description?: string}
]: any -> record<data: table<cidr: string, description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/serviceAllowlist/addresses/add")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove allowlisted CIDRs/IP addresses.
#
# POST /v1/serviceAllowlist/addresses/remove
# operationId: deleteAllowlistedCidrs
# --data item shape: {cidr: string, description?: string}
export def "service-allowlist-addresses-remove post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: list # An array of CIDR notations and/or IP addresses. — item shape: {cidr: string, description?: string}
]: any -> record<data: table<cidr: string, description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/serviceAllowlist/addresses/remove")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enable service allowlisting.
#
# POST /v1/serviceAllowlist/enable
# operationId: enableAllowlisting
export def "service-allowlist-enable enableAllowlisting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowlistType: string # The type of allowlisting to be enabled. It can be one of: `Login`, `Content`, or `Both`. (e.g. Login)
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allowlistType" $allowlistType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/serviceAllowlist/enable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable service allowlisting.
#
# POST /v1/serviceAllowlist/disable
# operationId: disableAllowlisting
export def "service-allowlist-disable disableAllowlisting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowlistType: string # The type of allowlisting to be disabled. It can be one of: `Login`, `Content`, or `Both`. (e.g. Login)
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allowlistType" $allowlistType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/serviceAllowlist/disable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the allowlisting status.
#
# GET /v1/serviceAllowlist/status
# operationId: getAllowlistingStatus
export def "service-allowlist-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<contentEnabled: bool, loginEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/serviceAllowlist/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Audit policy.
#
# GET /v1/policies/audit
# operationId: getAuditPolicy
export def "policies-audit get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/policies/audit")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Audit policy.
#
# PUT /v1/policies/audit
# operationId: setAuditPolicy
export def "policies-audit setAuditPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # Whether the Audit policy is enabled. (e.g. true)
]: any -> record<enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/policies/audit")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Search Audit policy.
#
# GET /v1/policies/searchAudit
# operationId: getSearchAuditPolicy
export def "policies-search-audit get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/policies/searchAudit")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Search Audit policy.
#
# PUT /v1/policies/searchAudit
# operationId: setSearchAuditPolicy
export def "policies-search-audit setSearchAuditPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # Whether the Search Audit policy is enabled. (e.g. true)
]: any -> record<enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/policies/searchAudit")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Share Dashboards Outside Organization policy.
#
# GET /v1/policies/shareDashboardsOutsideOrganization
# operationId: getShareDashboardsOutsideOrganizationPolicy
export def "policies-share-dashboards-outside-organization get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/policies/shareDashboardsOutsideOrganization")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Share Dashboards Outside Organization policy.
#
# PUT /v1/policies/shareDashboardsOutsideOrganization
# operationId: setShareDashboardsOutsideOrganizationPolicy
export def "policies-share-dashboards-outside-organization setShareDashboardsOutsideOrganizationPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # Whether the Share Dashboards Outside Organization policy is enabled. (e.g. true)
]: any -> record<enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/policies/shareDashboardsOutsideOrganization")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Data Access Level policy.
#
# GET /v1/policies/dataAccessLevel
# operationId: getDataAccessLevelPolicy
export def "policies-data-access-level get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/policies/dataAccessLevel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Data Access Level policy.
#
# PUT /v1/policies/dataAccessLevel
# operationId: setDataAccessLevelPolicy
export def "policies-data-access-level setDataAccessLevelPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # Whether the Data Access Level policy is enabled. (e.g. true)
]: any -> record<enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/policies/dataAccessLevel")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get User Concurrent Sessions Limit policy.
#
# GET /v1/policies/userConcurrentSessionsLimit
# operationId: getUserConcurrentSessionsLimitPolicy
export def "policies-user-concurrent-sessions-limit get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool, maxConcurrentSessions: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/policies/userConcurrentSessionsLimit")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set User Concurrent Sessions Limit policy.
#
# PUT /v1/policies/userConcurrentSessionsLimit
# operationId: setUserConcurrentSessionsLimitPolicy
export def "policies-user-concurrent-sessions-limit setUserConcurrentSessionsLimitPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # Whether the User Concurrent Sessions Limit policy is enabled. (e.g. true)
  --maxConcurrentSessions: int # Maximum number of concurrent sessions a user may have. (format: int32, default: 100, e.g. 50)
]: any -> record<enabled: bool, maxConcurrentSessions: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/policies/userConcurrentSessionsLimit")
  let body = {enabled: $enabled, maxConcurrentSessions: $maxConcurrentSessions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Max User Session Timeout policy.
#
# GET /v1/policies/maxUserSessionTimeout
# operationId: getMaxUserSessionTimeoutPolicy
export def "policies-max-user-session-timeout get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<maxUserSessionTimeout: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/policies/maxUserSessionTimeout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Max User Session Timeout policy.
#
# PUT /v1/policies/maxUserSessionTimeout
# operationId: setMaxUserSessionTimeoutPolicy
export def "policies-max-user-session-timeout setMaxUserSessionTimeoutPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  maxUserSessionTimeout: string # Maximum web session timeout users are able to configure within their user preferences. Valid values are: `5m`, `15m`, `30m`, `1h`, `2h`, `6h`, `12h`, `1d`, `2d`, `3d`, `5d`, or `7d` (e.g. 1d)
]: any -> record<maxUserSessionTimeout: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/policies/maxUserSessionTimeout")
  let body = {maxUserSessionTimeout: $maxUserSessionTimeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get access key lifetime policy.
#
# GET /v1/policies/accessKeysLifetime
# operationId: getAccessKeysLifetimePolicy
export def "policies-access-keys-lifetime get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<accessKeysLifetimeInDays: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/policies/accessKeysLifetime")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set access keys lifetime policy.
#
# PUT /v1/policies/accessKeysLifetime
# operationId: setAccessKeysLifetimePolicy
export def "policies-access-keys-lifetime setAccessKeysLifetimePolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  accessKeysLifetimeInDays: string # The number of days it will take for an access key to expire without being rotated/copied. Setting it to 0 (never) means that access keys will never expire. Valid values are: `0`, `30`, `45`, `60`, `90`, `180`, or `365` (e.g. 60)
]: any -> record<accessKeysLifetimeInDays: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/policies/accessKeysLifetime")
  let body = {accessKeysLifetimeInDays: $accessKeysLifetimeInDays} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Data Deletion policy.
#
# GET /v1/policies/dataDeletion
# operationId: getDataDeletionPolicy
export def "policies-data-deletion get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/policies/dataDeletion")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Data Deletion policy.
#
# PUT /v1/policies/dataDeletion
# operationId: setDataDeletionPolicy
export def "policies-data-deletion setDataDeletionPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # Whether the Data Deletion policy is enabled. (e.g. true)
]: any -> record<enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/policies/dataDeletion")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of health events.
#
# GET /v1/healthEvents
# operationId: listAllHealthEvents
export def "health-events listAllHealthEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of health events returned in the response. The number of health events returned may be less than the `limit`. (format: int32, default: 100)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left.
]: nothing -> record<data: table<eventId: string, eventName: string, details: record, resourceIdentity: record, eventTime: string, subsystem: string, severityLevel: string>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/healthEvents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Health events for specific resources.
#
# POST /v1/healthEvents/resources
# operationId: listAllHealthEventsForResources
# --data item shape: {id: string, name?: string, type: "Collector"|"Source"|"IngestBudget"|"Organisation"|"LogsToMetricsRule"|"ScheduledView"}
export def "health-events-resources listAllHealthEventsForResources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of health events returned in the response. The number of health events returned may be less than the `limit`. (format: int32, default: 100)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left.
  data: list # A list of the resources. — item shape: {id: string, name?: string, type: "Collector"|"Source"|"IngestBudget"|"Organisation"|"LogsToMetricsRule"|"ScheduledView"}
]: any -> record<data: table<eventId: string, eventName: string, details: record, resourceIdentity: record, eventTime: string, subsystem: string, severityLevel: string>, next: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/healthEvents/resources" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get ingestion jobs for an Archive Source.
#
# GET /v1/archive/{sourceId}/jobs
# operationId: listArchiveJobsBySourceId
export def "archive-jobs listArchiveJobsBySourceId" [
  sourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of jobs returned in the response. The number of jobs returned may be less than the `limit`. (format: int32, default: 10)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left.
]: nothing -> record<data: list<record>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/archive/($sourceId)/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an ingestion job.
#
# POST /v1/archive/{sourceId}/jobs
# operationId: createArchiveJob
export def "archive-jobs createArchiveJob" [
  sourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the ingestion job.
  startTime: string # The starting timestamp of the ingestion job. (format: date-time, e.g. 2018-10-16T09:10:00Z)
  endTime: string # The ending timestamp of the ingestion job. (format: date-time, e.g. 2018-10-16T10:10:00Z)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/archive/($sourceId)/jobs")
  let body = {name: $name, startTime: $startTime, endTime: $endTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an ingestion job.
#
# DELETE /v1/archive/{sourceId}/jobs/{id}
# operationId: deleteArchiveJob
export def "archive-jobs delete" [
  sourceId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/archive/($sourceId)/jobs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List ingestion jobs for all Archive Sources.
#
# GET /v1/archive/jobs/count
# operationId: listArchiveJobsCountPerSource
export def "archive-jobs-count listArchiveJobsCountPerSource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<sourceId: string, pending: int, scanning: int, ingesting: int, failed: int, succeeded: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/archive/jobs/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets estimated usage details.
#
# POST /v1/logSearches/estimatedUsage
# operationId: getLogSearchEstimatedUsage
export def "log-searches-estimated-usage post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  timezone: string # Time zone to get the estimated usage details. Follow the format in the [IANA Time Zone Database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List).  (e.g. America/Los_Angeles)
]: any -> record<estimatedUsageDetails: record<dataScannedInBytes: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/logSearches/estimatedUsage")
  let body = {timezone: $timezone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets Tier Wise estimated usage details.
#
# POST /v1/logSearches/estimatedUsageByTier
# operationId: getLogSearchEstimatedUsageByTier
# --timeRange shape: {type: string}
# --queryParameters item shape: {autoComplete?: record, name: string, description?: string, dataType: string, value: string}
export def "log-searches-estimated-usage-by-tier post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  queryString: string # Query to perform. (e.g. error {{sourceCategory}}| count by _sourceCategory)
  timeRange: record # e.g. {type: BeginBoundedTimeRange, from: {type: RelativeTimeRangeBoundary, relativeTime: -15m}} — shape: {type: string}
  --runByReceiptTime: string@bool-completer # This has the value `true` if the search is to be run by receipt time and `false` if it is to be run by message time. (default: false, e.g. false)
  --queryParameters: list # Values for search template used in the search query. Learn more about the search templates here : https://help.sumologic.com/docs/search/get-started-with-search/build-search/search-templates/ — item shape: {autoComplete?: record, name: string, description?: string, dataType: string, value: string}
  --intervalTimeType: string # This parameter defines whether you want to run the search by messageTime, receiptTime, or searchableTime.  By default, the search will run by messageTime. If both runByReceiptTime and intervalTimeType parameters are present then  the preference will be given to the intervalTimeType. (default: messageTime, e.g. messageTime)
  timezone: string # Time zone to get the estimated usage details. Follow the format in the [IANA Time Zone Database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List).  (e.g. America/Los_Angeles)
]: any -> record<estimatedUsageDetails: table<tier: string, dataScannedInBytes: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/logSearches/estimatedUsageByTier")
  let body = {queryString: $queryString, timeRange: $timeRange, runByReceiptTime: $runByReceiptTime, queryParameters: $queryParameters, intervalTimeType: $intervalTimeType, timezone: $timezone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets estimated usage details per metering type.
#
# POST /v1/logSearches/estimatedUsageByMeteringType
# operationId: getLogSearchEstimatedUsageByMeteringType
# --emulateSearchContext shape: {roleIds?: list, userId?: string}
export def "log-searches-estimated-usage-by-metering-type post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  timezone: string # Time zone to get the estimated usage details. Follow the format in the [IANA Time Zone Database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List).  (e.g. America/Los_Angeles)
  --emulateSearchContext: record # Contains keys like "roleIds" with a list of role IDs or "userId" as a string. — shape: {roleIds?: list, userId?: string}
]: any -> record<estimatedUsageDetails: table<meteringType: string, dataScannedInBytes: int, tier: string, scanCreditAccounted: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/logSearches/estimatedUsageByMeteringType")
  let body = {timezone: $timezone, emulateSearchContext: $emulateSearchContext} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets estimated usage details per view.
#
# POST /v1/logSearches/estimatedUsageByView
# operationId: logSearchesEstimatedUsageByView
# --emulateSearchContext shape: {roleIds?: list, userId?: string}
export def "log-searches-estimated-usage-by-view logSearchesEstimatedUsageByView" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  timezone: string # Time zone to get the estimated usage details. Follow the format in the [IANA Time Zone Database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List).  (e.g. America/Los_Angeles)
  --emulateSearchContext: record # Contains keys like "roleIds" with a list of role IDs or "userId" as a string. — shape: {roleIds?: list, userId?: string}
]: any -> record<estimatedUsageDetails: table<viewName: string, usageDetails: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/logSearches/estimatedUsageByView")
  let body = {timezone: $timezone, emulateSearchContext: $emulateSearchContext} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all dashboards.
#
# GET /v2/dashboards
# operationId: listDashboards
export def "dashboards listDashboards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of dashboard returned in the response. The number of dashboards returned may be less than the `limit`. (format: int32, default: 50, e.g. 50)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left. (e.g. GDCiRv4vebF3UWFJQ1kySXBOR3Bzh69GR0RyWm9vCtc)
  --mode: string # whether to list all viewable dashboards under the folders (e.g. createdByUser)
]: nothing -> record<dashboards: table<title: string, description: string, folderId: string, topologyLabelMap: record, domain: string, hierarchies: list, refreshInterval: int, timeRange: record, panels: list, layout: record, variables: list, theme: string, isPublic: bool, highlightViolations: bool, organizations: record, id: string, contentId: string, scheduleId: string, scheduleCount: int>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "mode" $mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/dashboards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new dashboard.
#
# POST /v2/dashboards
# operationId: createDashboard
# --topologyLabelMap shape: {data: record}
# --timeRange shape: {type: string}
# --panels item shape: {id?: string, key: string, title?: string, visualSettings?: string, keepVisualSettingsConsistentWithParent?: bool, panelType: string}
# --layout shape: {layoutType: string, layoutStructures: list}
# --variables item shape: {id?: string, name: string, displayName?: string, defaultValue?: string, sourceDefinition: record, allowMultiSelect?: bool, includeAllOption?: bool, hideFromUI?: bool, valueType?: string}
# --organizations shape: {defaultOrgIds?: list}
export def "dashboards createDashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string # Title of the dashboard. (e.g. Kubernetes Dashboard)
  --description: string # Description of the dashboard. (e.g. A view of pods, namespaces and nodes of your cluster.)
  --folderId: string # The identifier of the folder to save the dashboard in. By default it is saved in your personal folder.  (e.g. 000000000C1C17C6)
  --topologyLabelMap: record # Map of the topology labels. Each label has a key and a list of values. If a value is `*`, it means the label will match content for all values of its key.  (e.g. {data: {service: [kube-scheduler, kube-dns]}}) — shape: {data: record}
  --domain: string # If set denotes that the dashboard concerns a given domain (e.g. `aws`, `k8s`, `app`). (default: , e.g. aws)
  --hierarchies: list # If set to non-empty array denotes that the dashboard concerns given hierarchies. (default: [], e.g. [Kubernetes Node View])
  --refreshInterval: int # Interval of time (in seconds) to automatically refresh the dashboard. A value of 0 means we never automatically refresh the dashboard. Allowed values are `0`, `30`, `60`, `120`, `300`, `900`, `1800`, `3600`, `7200`, `86400`.  (format: int32, e.g. 30)
  timeRange: record # e.g. {type: BeginBoundedTimeRange, from: {type: RelativeTimeRangeBoundary, relativeTime: -15m}} — shape: {type: string}
  --panels: list # Panels in the dashboard. — item shape: {id?: string, key: string, title?: string, visualSettings?: string, keepVisualSettingsConsistentWithParent?: bool, panelType: string}
  --layout: record # shape: {layoutType: string, layoutStructures: list}
  --body-variables: list # Variables to apply to the panels. — item shape: {id?: string, name: string, displayName?: string, defaultValue?: string, sourceDefinition: record, allowMultiSelect?: bool, includeAllOption?: bool, hideFromUI?: bool, valueType?: string}
  --theme: string # Theme for the dashboard. Either `Light` or `Dark`. (default: Light, e.g. light)
  --isPublic: string@bool-completer # Is the dashboard public (default: false)
  --highlightViolations: string@bool-completer # Whether to highlight threshold violations. (default: false)
  --organizations: record # The organization details to run the dashboard by — shape: {defaultOrgIds?: list}
]: any -> record<title: string, description: string, folderId: string, topologyLabelMap: record<data: record>, domain: string, hierarchies: list<string>, refreshInterval: int, timeRange: record<type: string>, panels: table<id: string, key: string, title: string, visualSettings: string, keepVisualSettingsConsistentWithParent: bool, panelType: string>, layout: record<layoutType: string, layoutStructures: list<record>>, variables: table<id: string, name: string, displayName: string, defaultValue: string, sourceDefinition: record, allowMultiSelect: bool, includeAllOption: bool, hideFromUI: bool, valueType: string>, theme: string, isPublic: bool, highlightViolations: bool, organizations: record<defaultOrgIds: list<string>>, id: string, contentId: string, scheduleId: string, scheduleCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/dashboards")
  let body = {title: $title, description: $description, folderId: $folderId, topologyLabelMap: $topologyLabelMap, domain: $domain, hierarchies: $hierarchies, refreshInterval: $refreshInterval, timeRange: $timeRange, panels: $panels, layout: $layout, variables: $body_variables, theme: $theme, isPublic: $isPublic, highlightViolations: $highlightViolations, organizations: $organizations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a dashboard.
#
# GET /v2/dashboards/{id}
# operationId: getDashboard
export def "dashboards get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<title: string, description: string, folderId: string, topologyLabelMap: record<data: record>, domain: string, hierarchies: list<string>, refreshInterval: int, timeRange: record<type: string>, panels: table<id: string, key: string, title: string, visualSettings: string, keepVisualSettingsConsistentWithParent: bool, panelType: string>, layout: record<layoutType: string, layoutStructures: list<record>>, variables: table<id: string, name: string, displayName: string, defaultValue: string, sourceDefinition: record, allowMultiSelect: bool, includeAllOption: bool, hideFromUI: bool, valueType: string>, theme: string, isPublic: bool, highlightViolations: bool, organizations: record<defaultOrgIds: list<string>>, id: string, contentId: string, scheduleId: string, scheduleCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/dashboards/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a dashboard.
#
# PUT /v2/dashboards/{id}
# operationId: updateDashboard
# --topologyLabelMap shape: {data: record}
# --timeRange shape: {type: string}
# --panels item shape: {id?: string, key: string, title?: string, visualSettings?: string, keepVisualSettingsConsistentWithParent?: bool, panelType: string}
# --layout shape: {layoutType: string, layoutStructures: list}
# --variables item shape: {id?: string, name: string, displayName?: string, defaultValue?: string, sourceDefinition: record, allowMultiSelect?: bool, includeAllOption?: bool, hideFromUI?: bool, valueType?: string}
# --organizations shape: {defaultOrgIds?: list}
export def "dashboards updateDashboard" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string # Title of the dashboard. (e.g. Kubernetes Dashboard)
  --description: string # Description of the dashboard. (e.g. A view of pods, namespaces and nodes of your cluster.)
  --folderId: string # The identifier of the folder to save the dashboard in. By default it is saved in your personal folder.  (e.g. 000000000C1C17C6)
  --topologyLabelMap: record # Map of the topology labels. Each label has a key and a list of values. If a value is `*`, it means the label will match content for all values of its key.  (e.g. {data: {service: [kube-scheduler, kube-dns]}}) — shape: {data: record}
  --domain: string # If set denotes that the dashboard concerns a given domain (e.g. `aws`, `k8s`, `app`). (default: , e.g. aws)
  --hierarchies: list # If set to non-empty array denotes that the dashboard concerns given hierarchies. (default: [], e.g. [Kubernetes Node View])
  --refreshInterval: int # Interval of time (in seconds) to automatically refresh the dashboard. A value of 0 means we never automatically refresh the dashboard. Allowed values are `0`, `30`, `60`, `120`, `300`, `900`, `1800`, `3600`, `7200`, `86400`.  (format: int32, e.g. 30)
  timeRange: record # e.g. {type: BeginBoundedTimeRange, from: {type: RelativeTimeRangeBoundary, relativeTime: -15m}} — shape: {type: string}
  --panels: list # Panels in the dashboard. — item shape: {id?: string, key: string, title?: string, visualSettings?: string, keepVisualSettingsConsistentWithParent?: bool, panelType: string}
  --layout: record # shape: {layoutType: string, layoutStructures: list}
  --body-variables: list # Variables to apply to the panels. — item shape: {id?: string, name: string, displayName?: string, defaultValue?: string, sourceDefinition: record, allowMultiSelect?: bool, includeAllOption?: bool, hideFromUI?: bool, valueType?: string}
  --theme: string # Theme for the dashboard. Either `Light` or `Dark`. (default: Light, e.g. light)
  --isPublic: string@bool-completer # Is the dashboard public (default: false)
  --highlightViolations: string@bool-completer # Whether to highlight threshold violations. (default: false)
  --organizations: record # The organization details to run the dashboard by — shape: {defaultOrgIds?: list}
]: any -> record<title: string, description: string, folderId: string, topologyLabelMap: record<data: record>, domain: string, hierarchies: list<string>, refreshInterval: int, timeRange: record<type: string>, panels: table<id: string, key: string, title: string, visualSettings: string, keepVisualSettingsConsistentWithParent: bool, panelType: string>, layout: record<layoutType: string, layoutStructures: list<record>>, variables: table<id: string, name: string, displayName: string, defaultValue: string, sourceDefinition: record, allowMultiSelect: bool, includeAllOption: bool, hideFromUI: bool, valueType: string>, theme: string, isPublic: bool, highlightViolations: bool, organizations: record<defaultOrgIds: list<string>>, id: string, contentId: string, scheduleId: string, scheduleCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/dashboards/($id)")
  let body = {title: $title, description: $description, folderId: $folderId, topologyLabelMap: $topologyLabelMap, domain: $domain, hierarchies: $hierarchies, refreshInterval: $refreshInterval, timeRange: $timeRange, panels: $panels, layout: $layout, variables: $body_variables, theme: $theme, isPublic: $isPublic, highlightViolations: $highlightViolations, organizations: $organizations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a dashboard.
#
# DELETE /v2/dashboards/{id}
# operationId: deleteDashboard
export def "dashboards delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/dashboards/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start a report job
#
# POST /v2/dashboards/reportJobs
# operationId: generateDashboardReport
# --action shape: {actionType: string}
# --template shape: {templateType: string}
export def "dashboards-report-jobs generateDashboardReport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  action: record # The base class of all report action types. `DirectDownloadReportAction` downloads dashboard from browser. New action types may be supported in the future. — shape: {actionType: string}
  exportFormat: string # File format of the report. Can be `Pdf` or `Png`. `Pdf` is portable document format. `Png` is portable graphics image format. (e.g. Pdf)
  timezone: string # Time zone for the query time ranges. Follow the format in the [IANA Time Zone Database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List). (e.g. America/Los_Angeles)
  template: record # shape: {templateType: string}
  --theme: string # Theme for the report rendering. If absent, the default theme of the dashboard is used. (e.g. Light)
  --exportWidth: int # Pixel width of the exported PDF or PNG. If absent, the default width is used. (e.g. 1500)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/dashboards/reportJobs")
  let body = {action: $action, exportFormat: $exportFormat, timezone: $timezone, template: $template, theme: $theme, exportWidth: $exportWidth} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get report generation job status
#
# GET /v2/dashboards/reportJobs/{jobId}/status
# operationId: getAsyncReportGenerationStatus
export def "dashboards-report-jobs-status get" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, statusMessage: string, error: record<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/dashboards/reportJobs/($jobId)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get report generation job result
#
# GET /v2/dashboards/reportJobs/{jobId}/result
# operationId: getAsyncReportGenerationResult
export def "dashboards-report-jobs-result get" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/dashboards/reportJobs/($jobId)/result")
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Migrate Legacy Dashboards to Dashboards(New)
#
# POST /v2/dashboards/migrate
# operationId: migrateReportToDashboard
export def "dashboards-migrate migrateReportToDashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  contentIds: list # Content identifiers of the Legacy dashboards.
]: any -> record<jobId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/dashboards/migrate")
  let body = {contentIds: $contentIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Preview of Migrating Legacy Dashboards to Dashboards(New)
#
# POST /v2/dashboards/migrate/preview
# operationId: previewMigrateReportToDashboard
export def "dashboards-migrate-preview previewMigrateReportToDashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  contentIds: list # Content identifiers of the Legacy dashboards.
]: any -> record<count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/dashboards/migrate/preview")
  let body = {contentIds: $contentIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get dashboard migration status.
#
# GET /v2/dashboards/migrate/{jobId}/status
# operationId: getDashboardMigrationStatus
export def "dashboards-migrate-status get" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, statusMessage: string, error: record<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/dashboards/migrate/($jobId)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get dashboard migration result.
#
# GET /v2/dashboards/migrate/{jobId}/result
# operationId: getDashboardMigrationResult
export def "dashboards-migrate-result get" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record, richData: record, status: record<successCount: int, failedCount: int, totalCount: int>, errors: record, warnings: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/dashboards/migrate/($jobId)/result")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all dashboard report schedules.
#
# GET /v1/dashboards/reportSchedules
# operationId: listReportSchedules
export def "dashboards-report-schedules listReportSchedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dashboardId: string # UUID of the dashboard that the report shedules are associated with.
  --limit: int # Limit the number of dashboard report schedules returned in the response. The number of dashboard report schedules returned may be less than the `limit`. (format: int32, default: 50, e.g. 50)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left. (e.g. GDCiRv4vebF3UWFJQ1kySXBOR3Bzh69GR0RyWm9vCtc)
]: nothing -> record<reportSchedules: table<dashboardId: string, timeRange: record, variableValues: record, reportFormat: string, scheduleType: string, cronExpression: string, timeZone: string, emailNotification: record, isActive: bool, theme: string, exportWidth: int, scheduleId: string>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dashboardId" $dashboardId "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/dashboards/reportSchedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Schedule dashboard report
#
# POST /v1/dashboards/reportSchedules
# operationId: createScheduleReport
# --timeRange shape: {type: string}
# --variableValues shape: {data: record, richData?: record}
export def "dashboards-report-schedules createScheduleReport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  dashboardId: string # Identifier of dashboard the schedule will generate report for. (e.g. B23OjNs5ZCyn5VdMwOBoLo3PjgRnJSAlNTKEDAcpuDG2CIgRe9KFXMofm2H2)
  --timeRange: record # e.g. {type: BeginBoundedTimeRange, from: {type: RelativeTimeRangeBoundary, relativeTime: -15m}} — shape: {type: string}
  --variableValues: record # shape: {data: record, richData?: record}
  reportFormat: string # File format of the report. Can be `Pdf` or `Png`. `Pdf` is portable document format. `Png` is portable graphics image format. (e.g. Pdf)
  scheduleType: string # Run schedule of the scheduled report. Set to "Custom" to specify the schedule with a CRON expression. Possible schedule types are:   - `RealTime`   - `15Minutes`   - `1Hour`   - `2Hours`   - `4Hours`   - `6Hours`   - `8Hours`   - `12Hours`   - `1Day`   - `1Week`   - `Custom` (e.g. 1Day)
  --cronExpression: string # Cron-like expression specifying the report's schedule. Field scheduleType must be set to "Custom", otherwise, scheduleType takes precedence over cronExpression. (e.g. 0 0/15 * * * ? *)
  timeZone: string # Time zone identifier for time specification. Either an abbreviation such as "PST", a full name such as "America/Los_Angeles", or a custom ID such as "GMT-8:00". Note that the support of abbreviations is for JDK 1.1.x compatibility only and full names should be used. (e.g. America/Los_Angeles)
  emailNotification: any
  --isActive: string@bool-completer # Is the dashboard report schedule active (default: true)
  --theme: string # Theme for the report rendering. Must be `Light` or `Dark`. If absent, the dashboard's own theme is used. (e.g. Light)
  --exportWidth: int # Pixel width of the exported PDF or PNG. If absent, the default width is used. (e.g. 1500)
]: any -> record<dashboardId: string, timeRange: record<type: string>, variableValues: record<data: record, richData: record>, reportFormat: string, scheduleType: string, cronExpression: string, timeZone: string, emailNotification: record<connectionType: string, recipients: list<string>, subject: string, messageBody: string, timeZone: string>, isActive: bool, theme: string, exportWidth: int, scheduleId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dashboards/reportSchedules")
  let body = {dashboardId: $dashboardId, timeRange: $timeRange, variableValues: $variableValues, reportFormat: $reportFormat, scheduleType: $scheduleType, cronExpression: $cronExpression, timeZone: $timeZone, emailNotification: $emailNotification, isActive: $isActive, theme: $theme, exportWidth: $exportWidth} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get dashboard report schedule.
#
# GET /v1/dashboards/reportSchedules/{scheduleId}
# operationId: getReportSchedule
export def "dashboards-report-schedules get" [
  scheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dashboardId: string, timeRange: record<type: string>, variableValues: record<data: record, richData: record>, reportFormat: string, scheduleType: string, cronExpression: string, timeZone: string, emailNotification: record<connectionType: string, recipients: list<string>, subject: string, messageBody: string, timeZone: string>, isActive: bool, theme: string, exportWidth: int, scheduleId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dashboards/reportSchedules/($scheduleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update dashboard report schedule.
#
# PUT /v1/dashboards/reportSchedules/{scheduleId}
# operationId: updateReportSchedule
# --timeRange shape: {type: string}
# --variableValues shape: {data: record, richData?: record}
export def "dashboards-report-schedules updateReportSchedule" [
  scheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  dashboardId: string # Identifier of dashboard the schedule will generate report for. (e.g. B23OjNs5ZCyn5VdMwOBoLo3PjgRnJSAlNTKEDAcpuDG2CIgRe9KFXMofm2H2)
  --timeRange: record # e.g. {type: BeginBoundedTimeRange, from: {type: RelativeTimeRangeBoundary, relativeTime: -15m}} — shape: {type: string}
  --variableValues: record # shape: {data: record, richData?: record}
  reportFormat: string # File format of the report. Can be `Pdf` or `Png`. `Pdf` is portable document format. `Png` is portable graphics image format. (e.g. Pdf)
  scheduleType: string # Run schedule of the scheduled report. Set to "Custom" to specify the schedule with a CRON expression. Possible schedule types are:   - `RealTime`   - `15Minutes`   - `1Hour`   - `2Hours`   - `4Hours`   - `6Hours`   - `8Hours`   - `12Hours`   - `1Day`   - `1Week`   - `Custom` (e.g. 1Day)
  --cronExpression: string # Cron-like expression specifying the report's schedule. Field scheduleType must be set to "Custom", otherwise, scheduleType takes precedence over cronExpression. (e.g. 0 0/15 * * * ? *)
  timeZone: string # Time zone identifier for time specification. Either an abbreviation such as "PST", a full name such as "America/Los_Angeles", or a custom ID such as "GMT-8:00". Note that the support of abbreviations is for JDK 1.1.x compatibility only and full names should be used. (e.g. America/Los_Angeles)
  emailNotification: any
  --isActive: string@bool-completer # Is the dashboard report schedule active (default: true)
  --theme: string # Theme for the report rendering. Must be `Light` or `Dark`. If absent, the dashboard's own theme is used. (e.g. Light)
  --exportWidth: int # Pixel width of the exported PDF or PNG. If absent, the default width is used. (e.g. 1500)
]: any -> record<dashboardId: string, timeRange: record<type: string>, variableValues: record<data: record, richData: record>, reportFormat: string, scheduleType: string, cronExpression: string, timeZone: string, emailNotification: record<connectionType: string, recipients: list<string>, subject: string, messageBody: string, timeZone: string>, isActive: bool, theme: string, exportWidth: int, scheduleId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dashboards/reportSchedules/($scheduleId)")
  let body = {dashboardId: $dashboardId, timeRange: $timeRange, variableValues: $variableValues, reportFormat: $reportFormat, scheduleType: $scheduleType, cronExpression: $cronExpression, timeZone: $timeZone, emailNotification: $emailNotification, isActive: $isActive, theme: $theme, exportWidth: $exportWidth} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete dashboard report schedule.
#
# DELETE /v1/dashboards/reportSchedules/{scheduleId}
# operationId: deleteReportSchedule
export def "dashboards-report-schedules delete" [
  scheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dashboards/reportSchedules/($scheduleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all metrics search pages.
#
# GET /v2/metricsSearches
# operationId: ListMetricsSearches
export def "metrics-searches ListMetricsSearches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of metric searches returned in the response. The number of metric searches returned may be less than the `limit`. (format: int32, default: 50, e.g. 50)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left. (e.g. GDCiRv4vebF3UWFJQ1kySXBOR3Bzh69GR0RyWm9vCtc)
  --mode: string # whether to list all viewable metric searches under the folders (e.g. createdByUser)
]: nothing -> record<metricsSearches: table<id: string>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "mode" $mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/metricsSearches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new metrics search page.
#
# POST /v2/metricsSearches
# operationId: createMetricsSearches
# --timeRange shape: {type: string}
# --queries item shape: {queryString: string, queryType: string, queryKey: string, metricsQueryMode?: string, metricsQueryData?: record, tracesQueryData?: record, spansQueryData?: record, parseMode?: string, timeSource?: string, transient?: bool, outputCardinalityLimit?: int}
export def "metrics-searches createMetricsSearches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string # Title of the metrics search page.
  timeRange: record # e.g. {type: BeginBoundedTimeRange, from: {type: RelativeTimeRangeBoundary, relativeTime: -15m}} — shape: {type: string}
  --description: string # Description of the metrics search page.
  queries: list # Queries of the metrics search page. — item shape: {queryString: string, queryType: string, queryKey: string, metricsQueryMode?: string, metricsQueryData?: record, tracesQueryData?: record, spansQueryData?: record, parseMode?: string, timeSource?: string, transient?: bool, outputCardinalityLimit?: int}
  --visualSettings: string # Visual settings of the metrics search page.
  --folderId: string # The identifier of the folder to save the metrics search in. By default it is saved in your personal folder.  (e.g. 000000000C1C17C6)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/metricsSearches")
  let body = {title: $title, timeRange: $timeRange, description: $description, queries: $queries, visualSettings: $visualSettings, folderId: $folderId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a metrics search page.
#
# GET /v2/metricsSearches/{id}
# operationId: getMetricsSearches
export def "metrics-searches get-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/metricsSearches/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a metrics search page.
#
# PUT /v2/metricsSearches/{id}
# operationId: updateMetricsSearches
# --timeRange shape: {type: string}
# --queries item shape: {queryString: string, queryType: string, queryKey: string, metricsQueryMode?: string, metricsQueryData?: record, tracesQueryData?: record, spansQueryData?: record, parseMode?: string, timeSource?: string, transient?: bool, outputCardinalityLimit?: int}
export def "metrics-searches updateMetricsSearches" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string # Title of the metrics search page.
  timeRange: record # e.g. {type: BeginBoundedTimeRange, from: {type: RelativeTimeRangeBoundary, relativeTime: -15m}} — shape: {type: string}
  --description: string # Description of the metrics search page.
  queries: list # Queries of the metrics search page. — item shape: {queryString: string, queryType: string, queryKey: string, metricsQueryMode?: string, metricsQueryData?: record, tracesQueryData?: record, spansQueryData?: record, parseMode?: string, timeSource?: string, transient?: bool, outputCardinalityLimit?: int}
  --visualSettings: string # Visual settings of the metrics search page.
  --folderId: string # The identifier of the folder to save the metrics search in. By default it is saved in your personal folder.  (e.g. 000000000C1C17C6)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/metricsSearches/($id)")
  let body = {title: $title, timeRange: $timeRange, description: $description, queries: $queries, visualSettings: $visualSettings, folderId: $folderId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a metrics search page.
#
# DELETE /v2/metricsSearches/{id}
# operationId: deleteMetricsSearches
export def "metrics-searches delete-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/metricsSearches/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Usage info of monitors.
#
# GET /v1/monitors/usageInfo
# operationId: getMonitorUsageInfo
export def "monitors-usage-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<monitorType: string, usage: int, limit: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/monitors/usageInfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable monitors.
#
# PUT /v1/monitors/disable
# operationId: disableMonitorByIds
export def "monitors-disable disableMonitorByIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # A comma-separated list of identifiers. (e.g. 0000000000000001,0000000000000002,0000000000000003)
]: nothing -> record<monitors: record, warnings: table<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/monitors/disable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all playbooks.
#
# GET /v1/monitors/playbooks
# operationId: getMonitorPlaybooks
export def "monitors-playbooks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --playbookType: string # A string value for playbook type. (e.g. CSE)
]: nothing -> table<description: string, playbookId: string, name: string, versionId: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "playbookType" $playbookType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/monitors/playbooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get playbook details.
#
# GET /v1/monitors/playbooksDetails
# operationId: getPlaybooksDetails
export def "monitors-playbooks-details get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # A comma-separated list of playbook identifiers. (e.g. 649074b5b3d402d6e80b0d1d,649074b7b3d402d6e80b0da1,649074b6b3d402d6e80b0d75)
]: nothing -> table<description: string, playbookId: string, name: string, versionId: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/monitors/playbooksDetails" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk fetch SLI values, error budget remaining and SLI computation status for the current compliance period.
#
# GET /v1/slos/sli
# operationId: sli
export def "slos-sli sli" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # The identifiers of the SLOs. (e.g. 000000000000000A,000000000000000B)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/slos/sli" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Usage info of SLOs.
#
# GET /v1/slos/usageInfo
# operationId: getSloUsageInfo
export def "slos-usage-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<sliType: string, usage: int, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/slos/usageInfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the current password policy.
#
# GET /v1/passwordPolicy
# operationId: getPasswordPolicy
export def "password-policy get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<minLength: int, maxLength: int, mustContainLowercase: bool, mustContainUppercase: bool, mustContainDigits: bool, mustContainSpecialChars: bool, maxPasswordAgeInDays: int, minUniquePasswords: int, accountLockoutThreshold: int, failedLoginResetDurationInMins: int, accountLockoutDurationInMins: int, requireMfa: bool, rememberMfa: bool, disallowWeakPasswords: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/passwordPolicy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update password policy.
#
# PUT /v1/passwordPolicy
# operationId: setPasswordPolicy
export def "password-policy setPasswordPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --minLength: int # The minimum length of the password. (format: int32, default: 8, e.g. 8)
  --maxLength: int # The maximum length of the password. (Setting this to any value other than 128 is no longer supported; this field may be deprecated in the future.) (format: int32, default: 128, e.g. 128)
  --mustContainLowercase: string@bool-completer # If the password must contain lower case characters. (default: true, e.g. true)
  --mustContainUppercase: string@bool-completer # If the password must contain upper case characters. (default: true, e.g. true)
  --mustContainDigits: string@bool-completer # If the password must contain digits. (default: true, e.g. true)
  --mustContainSpecialChars: string@bool-completer # If the password must contain special characters. (default: true, e.g. true)
  --maxPasswordAgeInDays: int # Maximum number of days that a password can be used before user is required to change it. Put -1 if the user should not have to change their password. (format: int32, default: 365, e.g. 365)
  --minUniquePasswords: int # The minimum number of unique new passwords that a user must use before an old password can be reused. (format: int32, default: 10, e.g. 10)
  --accountLockoutThreshold: int # Number of failed login attempts allowed before account is locked-out. (format: int32, default: 6, e.g. 6)
  --failedLoginResetDurationInMins: int # The duration of time in minutes that must elapse from the first failed login attempt after which failed login count is reset to 0. (format: int32, default: 10, e.g. 10)
  --accountLockoutDurationInMins: int # The duration of time in minutes that a locked-out account remained locked before getting unlocked automatically. (format: int32, default: 30, e.g. 30)
  --requireMfa: string@bool-completer # If MFA should be required to log in. By default, this field is set to `false`. (default: false, e.g. false)
  --rememberMfa: string@bool-completer # If MFA should be remembered on the browser. (default: true, e.g. true)
  --disallowWeakPasswords: string@bool-completer # If weak passwords should be disallowed. By default, this field is set to `false`. (default: false, e.g. false)
]: any -> record<minLength: int, maxLength: int, mustContainLowercase: bool, mustContainUppercase: bool, mustContainDigits: bool, mustContainSpecialChars: bool, maxPasswordAgeInDays: int, minUniquePasswords: int, accountLockoutThreshold: int, failedLoginResetDurationInMins: int, accountLockoutDurationInMins: int, requireMfa: bool, rememberMfa: bool, disallowWeakPasswords: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/passwordPolicy")
  let body = {minLength: $minLength, maxLength: $maxLength, mustContainLowercase: $mustContainLowercase, mustContainUppercase: $mustContainUppercase, mustContainDigits: $mustContainDigits, mustContainSpecialChars: $mustContainSpecialChars, maxPasswordAgeInDays: $maxPasswordAgeInDays, minUniquePasswords: $minUniquePasswords, accountLockoutThreshold: $accountLockoutThreshold, failedLoginResetDurationInMins: $failedLoginResetDurationInMins, accountLockoutDurationInMins: $accountLockoutDurationInMins, requireMfa: $requireMfa, rememberMfa: $rememberMfa, disallowWeakPasswords: $disallowWeakPasswords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the root folder in the library.
#
# GET /v1/parsers/root
# operationId: getParsersLibraryRoot
export def "parsers-root get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isLocked: bool, isSystem: bool, isMutable: bool, children: table<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isLocked: bool, isSystem: bool, isMutable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/parsers/root")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk read folders and parsers.
#
# GET /v1/parsers
# operationId: parsersReadByIds
export def "parsers parsersReadByIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # A comma-separated list of identifiers. (e.g. 0000000000000001,0000000000000002,0000000000000003)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/parsers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a folder or parser.
#
# POST /v1/parsers
# Discriminator (request): type
# operationId: parsersCreate
export def "parsers parsersCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parentId: string # Identifier of the parent folder in which to create the folder or parser.
  name: string # Name of the folder or parser.
  description: string # Description of the folder or parser.
  type: string # Type of the object model.
  --isLocked: string@bool-completer # Locking/Unlocking requires the `LockParsers` capability. Locked objects can only be `Localized`. Updating or moving requires unlocking the object. Locking/Unlocking recursively locks all of the objects children. All children of a locked object must be locked. (default: false)
]: any -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isLocked: bool, isSystem: bool, isMutable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parentId" $parentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/parsers" $qp)
  let body = {name: $name, description: $description, type: $type, isLocked: $isLocked} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk delete folders and parsers.
#
# DELETE /v1/parsers
# operationId: parsersDeleteByIds
export def "parsers parsersDeleteByIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # A comma-separated list of identifiers. (e.g. 0000000000000001,0000000000000002,0000000000000003)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/parsers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read a folder or parser.
#
# GET /v1/parsers/{id}
# Discriminator (response): type
# operationId: parsersReadById
export def "parsers parsersReadById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isLocked: bool, isSystem: bool, isMutable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/parsers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a folder or parser.
#
# PUT /v1/parsers/{id}
# Discriminator (request): type
# operationId: parsersUpdateById
export def "parsers parsersUpdateById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the folder or parser.
  description: string # Description of the folder or parser.
  version: int # Version of the folder or parser. (format: int64)
  type: string # Type of the object model.
]: any -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isLocked: bool, isSystem: bool, isMutable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/parsers/($id)")
  let body = {name: $name, description: $description, version: $version, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a folder or parser.
#
# DELETE /v1/parsers/{id}
# operationId: parsersDeleteById
export def "parsers parsersDeleteById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/parsers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get full path of folder or parser.
#
# GET /v1/parsers/{id}/path
# operationId: getParsersFullPath
export def "parsers-path get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pathItems: table<id: string, name: string, description: string>, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/parsers/($id)/path")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lock a folder or a parser.
#
# POST /v1/parsers/{id}/lock
# Discriminator (response): type
# operationId: parsersLockById
export def "parsers-lock parsersLockById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isLocked: bool, isSystem: bool, isMutable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/parsers/($id)/lock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unlock a folder or a parser.
#
# POST /v1/parsers/{id}/unlock
# Discriminator (response): type
# operationId: parsersUnlockById
export def "parsers-unlock parsersUnlockById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isLocked: bool, isSystem: bool, isMutable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/parsers/($id)/unlock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Move a folder or parser.
#
# POST /v1/parsers/{id}/move
# Discriminator (response): type
# operationId: parsersMove
export def "parsers-move parsersMove" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parentId: string # Identifier of the parent folder to move the folder or parser to.
]: nothing -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isLocked: bool, isSystem: bool, isMutable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parentId" $parentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/parsers/($id)/move" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copy a folder or parser.
#
# POST /v1/parsers/{id}/copy
# Discriminator (response): type
# operationId: parsersCopy
export def "parsers-copy parsersCopy" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  parentId: string # Identifier of the parent folder to copy to.
  --name: string # Optionally provide a new name.
  --description: string # Optionally provide a new description.
]: any -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isLocked: bool, isSystem: bool, isMutable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/parsers/($id)/copy")
  let body = {parentId: $parentId, name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export a folder or parser.
#
# GET /v1/parsers/{id}/export
# Discriminator (response): type
# operationId: parsersExportItem
export def "parsers-export parsersExportItem" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --preserveLock: string@bool-completer # Set this to true if you want to export an object and preserve the locked status.  (default: false)
]: nothing -> record<name: string, description: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "preserveLock" $preserveLock "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/parsers/($id)/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import a folder or parser
#
# POST /v1/parsers/{parentId}/import
# Discriminator (request): type
# operationId: parsersImportItem
export def "parsers-import parsersImportItem" [
  parentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the folder or parser.
  description: string # Description of the folder or parser.
  type: string # Type of the object model.
]: any -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isLocked: bool, isSystem: bool, isMutable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/parsers/($parentId)/import")
  let body = {name: $name, description: $description, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read a folder or parser by its path.
#
# GET /v1/parsers/path
# Discriminator (response): type
# operationId: parsersGetByPath
export def "parsers-path parsersGetByPath" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --path: string # The path of the folder or parser.
]: nothing -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isLocked: bool, isSystem: bool, isMutable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/parsers/path" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for folders or parsers.
#
# GET /v1/parsers/search
# operationId: parsersSearch
export def "parsers-search parsersSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The search query to find folder or parsers. Below is the list of different filters with examples:   - **createdBy** : Filter by the user's identifier who created the content. Example: `createdBy:000000000000968B`.   - **createdBefore** : Filter by the content objects created before the given timestamp(in milliseconds). Example: `createdBefore:1457997222`.   - **createdAfter** : Filter by the content objects created after the given timestamp(in milliseconds). Example: `createdAfter:1457997111`.   - **modifiedBefore** : Filter by the content objects modified before the given timestamp(in milliseconds). Example: `modifiedBefore:1457997222`.   - **modifiedAfter** : Filter by the content objects modified after the given timestamp(in milliseconds). Example: `modifiedAfter:1457997111`.   - **type** : Filter by the type of the content object. Example: `type:folder`. You can also use multiple filters in one query. For example to search for all content objects created by user with identifier 000000000000968B with creation timestamp after 1457997222 containing the text Test, the query would look like:   `createdBy:000000000000968B createdAfter:1457997222 Test` (e.g. createdBy:000000000000968B Test)
  --limit: int # Maximum number of items you want in the response. (format: int32, default: 100, e.g. 10)
  --offset: int # The position or row from where to start the search operation. (format: int32, default: 0, e.g. 5)
]: nothing -> table<item: record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isLocked: bool, isSystem: bool, isMutable: bool>, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/parsers/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lock a folder or a parser.
#
# POST /v1/system/parsers/{id}/lock
# Discriminator (response): type
# operationId: systemParsersLockById
export def "system-parsers-lock systemParsersLockById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isLocked: bool, isSystem: bool, isMutable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/system/parsers/($id)/lock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unlock a folder or a parser.
#
# POST /v1/system/parsers/{id}/unlock
# Discriminator (response): type
# operationId: systemParsersUnlockById
export def "system-parsers-unlock systemParsersUnlockById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isLocked: bool, isSystem: bool, isMutable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/system/parsers/($id)/unlock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of service accounts.
#
# GET /v1/serviceAccounts
# operationId: listServiceAccounts
export def "service-accounts listServiceAccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/serviceAccounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new service account.
#
# POST /v1/serviceAccounts
# operationId: createServiceAccount
export def "service-accounts createServiceAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the service account. (e.g. Service Account)
  email: string # Email address of the service account. (format: email, e.g. johndoe@acme.com)
  roleIds: list # List of roleIds associated with the service account. (e.g. [00000000000001DF, 00000000000002D2])
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/serviceAccounts")
  let body = {name: $name, email: $email, roleIds: $roleIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a service account.
#
# GET /v1/serviceAccounts/{id}
# operationId: getServiceAccount
export def "service-accounts get" [
  id: string
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
  let full_url = (build-url $base $"/v1/serviceAccounts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a service account.
#
# PUT /v1/serviceAccounts/{id}
# operationId: updateServiceAccount
export def "service-accounts updateServiceAccount" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the service account. (e.g. Service Account)
  --isActive: string@bool-completer # This has the value `true` if the service account is active and `false` if it has been deactivated. (e.g. true)
  --roleIds: list # List of role identifiers associated with the service account. (e.g. [00000000000001DF, 00000000000002D2])
  --email: string # New email address of the service account. (format: email, e.g. johndoe@acme.com)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/serviceAccounts/($id)")
  let body = {name: $name, isActive: $isActive, roleIds: $roleIds, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a service account.
#
# DELETE /v1/serviceAccounts/{id}
# operationId: deleteServiceAccount
export def "service-accounts delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transferTo: string # Identifier of a user/service account to receive the transfer of content from the deleted service account. <br> **Note:** If `deleteContent` is not set to `true`, and no user identifier is specified in `transferTo`, content from the deleted service account is transferred to the executing user.
  --deleteContent: string@bool-completer # Whether to delete content from the deleted service account or not. <br> **Warning:** If `deleteContent` is set to `true`, all of the content for the service account being  deleted is permanently deleted and cannot be recovered.
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "transferTo" $transferTo "scalar") (serialize-qp "deleteContent" $deleteContent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/serviceAccounts/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List access keys for a service account.
#
# GET /v1/serviceAccounts/{serviceAccountId}/accessKeys
# operationId: listAccessKeysForServiceAccount
export def "service-accounts-access-keys listAccessKeysForServiceAccount" [
  serviceAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: string, label: string, corsHeaders: list, disabled: bool, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, serviceAccountId: string, lastUsed: string, scopes: list, effectiveScopes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/serviceAccounts/($serviceAccountId)/accessKeys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new access key for a service account.
#
# POST /v1/serviceAccounts/{serviceAccountId}/accessKeys
# operationId: createAccessKeyForServiceAccount
export def "service-accounts-access-keys createAccessKeyForServiceAccount" [
  serviceAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  label: string # A name for the access key to be created. (e.g. automation access key)
  --corsHeaders: list # An array of domains for which the access key is valid. Whether Sumo Logic accepts or rejects an API request depends on whether it contains an ORIGIN header and the entries in the allowlist. Sumo Logic will reject:   1. Requests with an ORIGIN header but the allowlist is empty.   2. Requests with an ORIGIN header that don't match any entry in the allowlist. (e.g. [https://my-app.com, https://mail.my-app.com])
  --scopes: list # Scopes assigned to the key. ### Alerting   - adminMonitorsV2   - viewMonitorsV2   - manageMonitorsV2  ### Data Management   - manageApps   - viewCollectors   - manageCollectors   - viewConnections   - manageConnections   - contentAdmin   - viewFieldExtractionRules   - manageFieldExtractionRules               - viewFields   - manageFields   - manageBudgets   - viewLibrary   - manageLibrary   - viewPartitions   - managePartitions   - manageS3DataForwarding   - viewScheduledViews   - manageScheduledViews   - manageTokens  ### Logs   - runLogSearch  ### Metrics   - runMetricsQuery   ### Reliability Management   - viewSlos   - manageSlos  ### Security   - manageAccessKeys   - viewPersonalAccessKeys   - managePersonalAccessKeys  ### UserManagement   - viewUsersAndRoles   - manageUsersAndRoles (e.g. [manageUsersAndRoles, viewCollectors])
]: any -> record<id: string, label: string, corsHeaders: list<string>, disabled: bool, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, serviceAccountId: string, lastUsed: string, scopes: list<string>, effectiveScopes: list<string>, key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/serviceAccounts/($serviceAccountId)/accessKeys")
  let body = {label: $label, corsHeaders: $corsHeaders, scopes: $scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an access key of a service account.
#
# GET /v1/serviceAccounts/{serviceAccountId}/accessKeys/{accessId}
# operationId: getAccessKeyByIdOfAServiceAccount
export def "service-accounts-access-keys get" [
  serviceAccountId: string
  accessId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, label: string, corsHeaders: list<string>, disabled: bool, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, serviceAccountId: string, lastUsed: string, scopes: list<string>, effectiveScopes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/serviceAccounts/($serviceAccountId)/accessKeys/($accessId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an access key of a service account.
#
# PUT /v1/serviceAccounts/{serviceAccountId}/accessKeys/{accessId}
# operationId: updateAccessKeyOfAServiceAccount
export def "service-accounts-access-keys updateAccessKeyOfAServiceAccount" [
  serviceAccountId: string
  accessId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --disabled: string@bool-completer # Indicates whether the access key is disabled or not. (e.g. true)
  --corsHeaders: list # An array of domains for which the access key is valid. Whether Sumo Logic accepts or rejects an API request depends on whether it contains an ORIGIN header and the entries in the allowlist. Sumo Logic will reject:   1. Requests with an ORIGIN header but the allowlist is empty.   2. Requests with an ORIGIN header that don't match any entry in the allowlist. (e.g. [https://my-app.com, https://mail.my-app.com])
  --scopes: list # Scopes assigned to the key. <br><br> Note: Updates to scopes will take up to 5m to reflect due to caching in the system. ### Alerting   - adminMonitorsV2   - viewMonitorsV2   - manageMonitorsV2  ### Data Management   - manageApps   - viewCollectors   - manageCollectors   - viewConnections   - manageConnections   - contentAdmin   - viewFieldExtractionRules   - manageFieldExtractionRules               - viewFields   - manageFields   - manageBudgets   - viewLibrary   - manageLibrary   - viewPartitions   - managePartitions   - manageS3DataForwarding   - viewScheduledViews   - manageScheduledViews   - manageTokens  ### Logs   - runLogSearch  ### Metrics   - runMetricsQuery   ### Reliability Management   - viewSlos   - manageSlos  ### Security   - manageAccessKeys   - viewPersonalAccessKeys   - managePersonalAccessKeys  ### UserManagement   - viewUsersAndRoles   - manageUsersAndRoles (e.g. [manageUsersAndRoles, viewCollectors])
]: any -> record<id: string, label: string, corsHeaders: list<string>, disabled: bool, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, serviceAccountId: string, lastUsed: string, scopes: list<string>, effectiveScopes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/serviceAccounts/($serviceAccountId)/accessKeys/($accessId)")
  let body = {disabled: $disabled, corsHeaders: $corsHeaders, scopes: $scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an access key of a service account.
#
# DELETE /v1/serviceAccounts/{serviceAccountId}/accessKeys/{accessId}
# operationId: deleteAccessKeyOfAServiceAccount
export def "service-accounts-access-keys delete" [
  serviceAccountId: string
  accessId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/serviceAccounts/($serviceAccountId)/accessKeys/($accessId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all scopes.
#
# GET /v1/oauth/scopes
# operationId: listOAuthScopes
export def "oauth-scopes listOAuthScopes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: string, label: string, type: string, dependsOn: list, group: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/oauth/scopes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the OAuth clients.
#
# GET /v1/oauth/clients
# operationId: listOAuthClients
export def "oauth-clients listOAuthClients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of OAuth clients returned in the response. The number of OAuth clients returned may be  less than the `limit`. (format: int32, default: 100)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is  returned in the response body. Subsequent GET requests should specify the continuation token to get the  next page of results. `token` is set to null when no more pages are left.
  --runAsId: string # Identifier of the service account that the OAuth Client runs as.
  --clientId: string # Filter clients by exact client ID. When specified, returns only the client matching this ID. Supports URL-based client identifiers (URL-encode the value).
]: nothing -> record<data: table<type: string, clientId: string, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, name: string, description: string, disabled: bool, scopes: list>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "runAsId" $runAsId "scalar") (serialize-qp "clientId" $clientId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/oauth/clients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new OAuth client.
#
# POST /v1/oauth/clients
# Discriminator (request): type = ClientCredentialsClient, AuthorizationCodeClient
# operationId: createOAuthClient
export def "oauth-clients createOAuthClient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-1 # Type of the object model.
  name: string # Name of the OAuth client. (e.g. My OAuth Client)
  --description: string # Description of the OAuth client. (default: , e.g. OAuth client for data ingestion)
  --scopes: list # Scopes assigned to the client. ### Alerting   - adminMonitorsV2   - viewMonitorsV2   - manageMonitorsV2  ### Data Management   - manageApps   - viewCollectors   - manageCollectors   - viewConnections   - manageConnections   - contentAdmin   - viewFieldExtractionRules   - manageFieldExtractionRules               - viewFields   - manageFields   - manageBudgets   - viewLibrary   - manageLibrary   - viewPartitions   - managePartitions    - manageS3DataForwarding   - viewScheduledViews   - manageScheduledViews   - manageTokens  ### Logs   - runLogSearch  ### Metrics   - runMetricsQuery   ### Reliability Management   - viewSlos   - manageSlos  ### Security   - manageAccessKeys   - viewPersonalAccessKeys   - managePersonalAccessKeys  ### UserManagement   - viewUsersAndRoles   - manageUsersAndRoles (default: [], e.g. [manageUsersAndRoles, viewCollectors])
]: any -> record<type: string, clientId: string, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, name: string, description: string, disabled: bool, scopes: list<string>, clientSecret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/oauth/clients")
  let body = {type: $type, name: $name, description: $description, scopes: $scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an OAuth client.
#
# GET /v1/oauth/clients/{clientId}
# Discriminator (response): type = ClientCredentialsClient, AuthorizationCodeClient
# operationId: getOAuthClientById
export def "oauth-clients get" [
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, clientId: string, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, name: string, description: string, disabled: bool, scopes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/oauth/clients/($clientId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an OAuth client.
#
# PUT /v1/oauth/clients/{clientId}
# Discriminator (request): type = ClientCredentialsClient, AuthorizationCodeClient
# operationId: updateOAuthClient
export def "oauth-clients updateOAuthClient" [
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-1 # Type of the object model.
  name: string # Name of the OAuth client. (e.g. My OAuth Client)
  description: string # Description of the OAuth client. (e.g. OAuth client for data ingestion)
  --disabled: string@bool-completer # Whether the OAuth client is disabled. Disabled OAuth clients cannot be used to authenticate users.
  scopes: list # Scopes assigned to the client. ### Alerting   - adminMonitorsV2   - viewMonitorsV2   - manageMonitorsV2  ### Data Management   - manageApps   - viewCollectors   - manageCollectors   - viewConnections   - manageConnections   - contentAdmin   - viewFieldExtractionRules   - manageFieldExtractionRules               - viewFields   - manageFields   - manageBudgets   - viewLibrary   - manageLibrary   - viewPartitions   - managePartitions    - manageS3DataForwarding   - viewScheduledViews   - manageScheduledViews   - manageTokens  ### Logs   - runLogSearch  ### Metrics   - runMetricsQuery   ### Reliability Management   - viewSlos   - manageSlos  ### Security   - manageAccessKeys   - viewPersonalAccessKeys   - managePersonalAccessKeys  ### UserManagement   - viewUsersAndRoles   - manageUsersAndRoles (e.g. [manageUsersAndRoles, viewCollectors])
]: any -> record<type: string, clientId: string, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, name: string, description: string, disabled: bool, scopes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/oauth/clients/($clientId)")
  let body = {type: $type, name: $name, description: $description, disabled: $disabled, scopes: $scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an OAuth client.
#
# DELETE /v1/oauth/clients/{clientId}
# operationId: deleteOAuthClient
export def "oauth-clients delete" [
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/oauth/clients/($clientId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rotate the oauth client secret
#
# PUT /v1/oauth/clients/{clientId}/rotate
# Discriminator (response): type = ClientCredentialsClient, AuthorizationCodeClient
# operationId: rotateOauthSecret
export def "oauth-clients-rotate rotateOauthSecret" [
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, clientId: string, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, name: string, description: string, disabled: bool, scopes: list<string>, clientSecret: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/oauth/clients/($clientId)/rotate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List OAuth consents.
#
# GET /v1/oauth/consents
# operationId: listOAuthConsents
export def "oauth-consents listOAuthConsents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of consents returned in the response. (format: int32, default: 100)
  --qp-token: string # Continuation token to get the next page of results.
  --authorizedUser: string # Filter consents by the identifier of the user who authorized the consent.
  --clientId: string # Filter consents by the clientId of a registered OAuth client.
]: nothing -> record<data: table<id: string, clientId: string, clientName: string, authorizedAt: string, authorizedUser: string, lastUsedAt: string, scopes: list>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "authorizedUser" $authorizedUser "scalar") (serialize-qp "clientId" $clientId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/oauth/consents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an OAuth consent.
#
# DELETE /v1/oauth/consents/{consentId}
# operationId: deleteOAuthConsent
export def "oauth-consents delete" [
  consentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/oauth/consents/($consentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List SCIM Users
#
# GET /v1/scim/Users
# operationId: listSCIMUsers
export def "scim-users listSCIMUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
  --startIndex: int # The index of the first result to return. Defaults to 1 if not specified, a value less than 1 SHALL be interpreted as 1 (format: int32, default: 1)
  --count: int # The maximum number of results to return. Defaults to 100 (default: 100)
  --filter: string # Find user with the given email address (e.g. emails.value eq "john@doe.com")
  --sortOrder: string@sortOrder-completer # The sort order. Use "ascending" or "descending" (e.g. descending)
  --sortBy: string # Sort the list of users by the `givenName`, `familyName`, or `emails` field (e.g. givenName)
]: nothing -> record<totalResults: int, startIndex: int, itemsPerPage: int, Resources: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startIndex" $startIndex "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "sortBy" $sortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/scim/Users" $qp)
  let accept_val = ($accept | default "application/scim+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create SCIM User
#
# POST /v1/scim/Users
# operationId: createSCIMUser
# --Resources item shape: {schemas: list, userName: string, name: record, emails: list, roles: list, id: string, active?: bool, meta?: record}
export def "scim-users createSCIMUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
  --totalResults: int # Total number of users that match the filter criteria (e.g. 100)
  --startIndex: int # The index of the first returned result (format: int32, default: 0, e.g. 0)
  --itemsPerPage: int # The number of results returned in this page (e.g. 10)
  --Resources: list # List of SCIM user resources — item shape: {schemas: list, userName: string, name: record, emails: list, roles: list, id: string, active?: bool, meta?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scim/Users")
  let body = {totalResults: $totalResults, startIndex: $startIndex, itemsPerPage: $itemsPerPage, Resources: $Resources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/scim+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a SCIM User
#
# GET /v1/scim/Users/{id}
# operationId: getSCIMUserById
export def "scim-users get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/scim/Users/($id)")
  let accept_val = ($accept | default "application/scim+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update SCIM User
#
# PUT /v1/scim/Users/{id}
# operationId: updateSCIMUser
# --Resources item shape: {schemas: list, userName: string, name: record, emails: list, roles: list, id: string, active?: bool, meta?: record}
export def "scim-users updateSCIMUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
  --totalResults: int # Total number of users that match the filter criteria (e.g. 100)
  --startIndex: int # The index of the first returned result (format: int32, default: 0, e.g. 0)
  --itemsPerPage: int # The number of results returned in this page (e.g. 10)
  --Resources: list # List of SCIM user resources — item shape: {schemas: list, userName: string, name: record, emails: list, roles: list, id: string, active?: bool, meta?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/scim/Users/($id)")
  let body = {totalResults: $totalResults, startIndex: $startIndex, itemsPerPage: $itemsPerPage, Resources: $Resources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/scim+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete SCIM User
#
# DELETE /v1/scim/Users/{id}
# operationId: deleteSCIMUserById
export def "scim-users delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
]: nothing -> record<status: int, schemas: list<string>, scimType: string, detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/scim/Users/($id)")
  let accept_val = ($accept | default "application/scim+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update SCIM User Attributes
#
# PATCH /v1/scim/Users/{id}
# operationId: patchSCIMUser
# --Resources item shape: {schemas: list, userName: string, name: record, emails: list, roles: list, id: string, active?: bool, meta?: record}
export def "scim-users patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
  --totalResults: int # Total number of users that match the filter criteria (e.g. 100)
  --startIndex: int # The index of the first returned result (format: int32, default: 0, e.g. 0)
  --itemsPerPage: int # The number of results returned in this page (e.g. 10)
  --Resources: list # List of SCIM user resources — item shape: {schemas: list, userName: string, name: record, emails: list, roles: list, id: string, active?: bool, meta?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/scim/Users/($id)")
  let body = {totalResults: $totalResults, startIndex: $startIndex, itemsPerPage: $itemsPerPage, Resources: $Resources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/scim+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Run metrics queries
#
# POST /v1/metricsQueries
# operationId: runMetricsQueries
# --queries item shape: {rowId: string, query: string, quantization?: int, rollup?: string, timeshift?: int}
# --timeRange shape: {type: string}
export def "metrics-queries runMetricsQueries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  queries: list # A list of metrics queries. — item shape: {rowId: string, query: string, quantization?: int, rollup?: string, timeshift?: int}
  timeRange: record # e.g. {type: BeginBoundedTimeRange, from: {type: RelativeTimeRangeBoundary, relativeTime: -15m}} — shape: {type: string}
]: any -> record<queryResult: table<rowId: string, timeSeriesList: record>, errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/metricsQueries")
  let body = {queries: $queries, timeRange: $timeRange} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Run a trace search query asynchronously.
#
# POST /v1/tracing/tracequery
# operationId: createTraceQuery
# --queryRows item shape: {query: record, rowId: string, orderBy?: record}
# --timeRange shape: {type: string}
export def "tracing-tracequery createTraceQuery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  queryRows: list # A list of trace queries. — item shape: {query: record, rowId: string, orderBy?: record}
  timeRange: record # e.g. {type: BeginBoundedTimeRange, from: {type: RelativeTimeRangeBoundary, relativeTime: -15m}} — shape: {type: string}
]: any -> record<queryId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tracing/tracequery")
  let body = {queryRows: $queryRows, timeRange: $timeRange} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel a trace search query.
#
# DELETE /v1/tracing/tracequery/{queryId}
# operationId: cancelTraceQuery
export def "tracing-tracequery cancelTraceQuery" [
  queryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tracing/tracequery/($queryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a trace search query status.
#
# GET /v1/tracing/tracequery/{queryId}/status
# operationId: getTraceQueryStatus
export def "tracing-tracequery-status get" [
  queryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<queryRows: table<rowId: string, status: string, statusMessage: string, count: int>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tracing/tracequery/($queryId)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get results of a trace search query.
#
# GET /v1/tracing/tracequery/{queryId}/rows/{rowId}/traces
# operationId: getTraceQueryResult
export def "tracing-tracequery-rows-traces get" [
  queryId: string
  rowId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit of the number of traces returned in the response. (format: int32, default: 100, e.g. 100)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left. (e.g. dlFXd0lhSkxzRjAwYnpVZkMrRmlhYnF4cGtNMWdnVEI)
]: nothing -> record<results: table<id: string, rootService: string, rootResource: string, rootStatus: record, rootOperationName: string, metrics: record, startedAt: string, criticalPathServiceBreakdownSummary: record>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/tracing/tracequery/($queryId)/rows/($rowId)/traces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get trace search query metrics.
#
# GET /v1/tracing/metrics
# operationId: getMetrics
export def "tracing-metrics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<metrics: table<metric: string, description: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tracing/metrics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get filter fields for trace search queries.
#
# GET /v1/tracing/tracequery/fields
# operationId: getTraceQueryFields
export def "tracing-tracequery-fields get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fields: table<field: string, fieldType: string, valueListing: bool, description: string, type: string, noValuesReason: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tracing/tracequery/fields")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get trace search query filter field values.
#
# GET /v1/tracing/tracequery/fields/{field}/values
# operationId: getTraceQueryFieldValues
export def "tracing-tracequery-fields-values get" [
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Search filter to apply on the values to be returned. Only values containing the search query term will be returned.
  --limit: int # The maximum number of results to fetch. (format: int32, default: 10)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left.
  --fieldType: string # Indicates the kind of a field. Possible values: `SpanAttribute`, `SpanEventAttribute`. (e.g. SpanEventAttribute)
]: nothing -> record<fieldValues: list<string>, totalCount: int, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "fieldType" $fieldType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/tracing/tracequery/fields/($field)/values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get trace details.
#
# GET /v1/tracing/traces/{traceId}
# operationId: getTrace
export def "tracing-traces get" [
  traceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, rootService: string, rootResource: string, rootStatus: record<code: string, message: string>, rootOperationName: string, metrics: record, startedAt: string, criticalPathServiceBreakdownSummary: record<elements: list<record>, otherServicesDuration: int, idleTime: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tracing/traces/($traceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if the trace exists.
#
# GET /v1/tracing/traces/{traceId}/exists
# operationId: traceExists
export def "tracing-traces-exists traceExists" [
  traceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<exists: bool, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tracing/traces/($traceId)/exists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of trace spans.
#
# GET /v1/tracing/traces/{traceId}/spans
# operationId: getSpans
export def "tracing-traces-spans list" [
  traceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of results to fetch. (format: int32, default: 100)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left.
]: nothing -> record<spanPage: table<id: string, parentId: string, operationName: string, resource: string, service: string, serviceColor: string, serviceType: string, duration: int, startedAt: string, status: record, kind: string, remoteService: string, remoteServiceColor: string, remoteServiceType: string, info: record, numberOfLinks: int>, totalCount: int, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/tracing/traces/($traceId)/spans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of events (without their attributes) per span for a trace.
#
# GET /v1/tracing/traces/{traceId}/traceEvents
# operationId: getTraceLightEvents
export def "tracing-traces-trace-events get" [
  traceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of spans with events returned by a single query. (format: int32, default: 100)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left. (e.g. dlFXd0lhSkxzRjAwYnpVZkMrRmlhYnF4cGtNMWdnVEI)
]: nothing -> record<spanEvents: record, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/tracing/traces/($traceId)/traceEvents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a critical path of a trace.
#
# GET /v1/tracing/traces/{traceId}/criticalPath
# operationId: getCriticalPath
export def "tracing-traces-critical-path get" [
  traceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of results to fetch. (format: int32, default: 100)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left.
]: nothing -> record<segments: table<spanId: string, service: string, serviceColor: string, startOffset: int, duration: int, fraction: float>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/tracing/traces/($traceId)/criticalPath" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a critical path service breakdown of a trace.
#
# GET /v1/tracing/traces/{traceId}/criticalPath/breakdown/service
# operationId: getCriticalPathServiceBreakdown
export def "tracing-traces-critical-path-breakdown-service get" [
  traceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<elements: table<service: string, serviceColor: string, duration: int, numSpans: int, longestSegmentDuration: int>, idleTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tracing/traces/($traceId)/criticalPath/breakdown/service")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get span details.
#
# GET /v1/tracing/traces/{traceId}/spans/{spanId}
# operationId: getSpan
export def "tracing-traces-spans get" [
  traceId: string
  spanId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, parentId: string, operationName: string, resource: string, service: string, serviceColor: string, serviceType: string, duration: int, startedAt: string, status: record<code: string, message: string>, kind: string, remoteService: string, remoteServiceColor: string, remoteServiceType: string, info: record<type: string>, numberOfLinks: int, errorMessage: string, fields: record, criticalPathContribution: record<duration: int, fraction: float>, logs: list<string>, events: table<timestamp: string, name: string, attributes: list>, links: table<traceId: string, spanId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tracing/traces/($traceId)/spans/($spanId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get span billing details.
#
# GET /v1/tracing/traces/{traceId}/spans/{spanId}/billingInfo
# operationId: getSpanBillingInfo
export def "tracing-traces-spans-billing-info get" [
  traceId: string
  spanId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<billedBytes: int, billedFormat: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tracing/traces/($traceId)/spans/($spanId)/billingInfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Run a span analytics query asynchronously.
#
# POST /v1/tracing/spanquery
# operationId: createSpanQuery
# --queryRows item shape: {queryString: string, rowId: string}
# --timeRange shape: {type: string}
export def "tracing-spanquery createSpanQuery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  queryRows: list # A list of span analytics queries. — item shape: {queryString: string, rowId: string}
  timeRange: record # e.g. {type: BeginBoundedTimeRange, from: {type: RelativeTimeRangeBoundary, relativeTime: -15m}} — shape: {type: string}
  --timeZone: string # Time zone for the query time ranges. Follow the format in the [IANA Time Zone Database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List). (default: UTC, e.g. America/Los_Angeles)
]: any -> record<queryId: string, queryRows: table<rowId: string, errors: list, isAggregation: bool, executedQuery: string>, hasErrors: bool, timeRange: record<type: string, from: record<type: string>, to: record<type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tracing/spanquery")
  let body = {queryRows: $queryRows, timeRange: $timeRange, timeZone: $timeZone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel a span analytics query.
#
# DELETE /v1/tracing/spanquery/{queryId}
# operationId: cancelSpanQuery
export def "tracing-spanquery cancelSpanQuery" [
  queryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tracing/spanquery/($queryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a span analytics query status.
#
# GET /v1/tracing/spanquery/{queryId}/status
# operationId: getSpanQueryStatus
export def "tracing-spanquery-status get" [
  queryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<queryRows: table<rowId: string, status: string, statusMessage: string, count: int, approximatedFieldCounts: bool, facetsCompleted: bool>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tracing/spanquery/($queryId)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause a span analytics query.
#
# PUT /v1/tracing/spanquery/{queryId}/pause
# operationId: pauseSpanQuery
export def "tracing-spanquery-pause pauseSpanQuery" [
  queryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tracing/spanquery/($queryId)/pause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resume a span analytics query.
#
# PUT /v1/tracing/spanquery/{queryId}/resume
# operationId: resumeSpanQuery
export def "tracing-spanquery-resume resumeSpanQuery" [
  queryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tracing/spanquery/($queryId)/resume")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get results of a span analytics query.
#
# GET /v1/tracing/spanquery/{queryId}/rows/{rowId}/spans
# operationId: getSpanQueryResult
export def "tracing-spanquery-rows-spans get" [
  queryId: string
  rowId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit of the number of spans returned in the response. (format: int32, default: 100, e.g. 100)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left. (e.g. dlFXd0lhSkxzRjAwYnpVZkMrRmlhYnF4cGtNMWdnVEI)
]: nothing -> record<spanPage: table<spanId: string, traceId: string, parentSpanId: string, operationName: string, service: string, remoteService: string, duration: int, startedAt: string, status: record, kind: string, tagsJSON: string, metadata: record>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/tracing/spanquery/($queryId)/rows/($rowId)/spans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of facets of a span analytics query.
#
# GET /v1/tracing/spanquery/{queryId}/rows/{rowId}/facets
# operationId: getSpanQueryFacets
export def "tracing-spanquery-rows-facets get" [
  queryId: string
  rowId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<facets: table<name: string, cardinality: int, dataType: string, inSchema: bool, valueFrequency: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tracing/spanquery/($queryId)/rows/($rowId)/facets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get span analytics query aggregated results.
#
# GET /v1/tracing/spanquery/{queryId}/aggregates
# operationId: getSpanQueryAggregates
export def "tracing-spanquery-aggregates get" [
  queryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: record<status: string, statusMessage: string, series: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tracing/spanquery/($queryId)/aggregates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get filter fields for span analytics queries.
#
# GET /v1/tracing/spanquery/fields
# operationId: getSpanQueryFields
export def "tracing-spanquery-fields get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fields: table<field: string, fieldType: string, valueListing: bool, description: string, type: string, noValuesReason: record, inSchema: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tracing/spanquery/fields")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get span analytics query filter field values.
#
# GET /v1/tracing/spanquery/fields/{field}/values
# operationId: getSpanQueryFieldValues
export def "tracing-spanquery-fields-values get" [
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Search filter to apply on the values to be returned. Only values containing the search query term will be returned.
  --limit: int # The maximum number of results to fetch. (format: int32, default: 10)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left.
]: nothing -> record<fieldValues: list<string>, totalCount: int, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/tracing/spanquery/fields/($field)/values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a service map.
#
# GET /v1/tracing/serviceMap
# operationId: getServiceMap
export def "tracing-service-map get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<nodes: table<serviceName: string, serviceColor: string, lastSeenAt: string, isRemote: bool, serviceType: string>, edges: table<source: string, target: string, lastSeenAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tracing/serviceMap")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get threat intel indicators DB information
#
# GET /v1/threatIntel/datastore/db
# operationId: datastoreGet
export def "threat-intel-datastore-db datastoreGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<diskSize: int, indicatorCount: int, indicatorLimit: int, sourceStatus: table<source: string, description: string, diskSize: int, indicatorCount: int, sumoProvided: bool, supportsCat: bool, enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/threatIntel/datastore/db")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove the threat intel indicators DB
#
# DELETE /v1/threatIntel/datastore/db
# operationId: removeDatastore
export def "threat-intel-datastore-db removeDatastore" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/threatIntel/datastore/db")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get threat intel indicators store retention period in terms of days.
#
# GET /v1/threatIntel/datastore/retentionPeriod
# operationId: retentionPeriod
export def "threat-intel-datastore-retention-period retentionPeriod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<retentionPeriod: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/threatIntel/datastore/retentionPeriod")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the threat intel indicators store retention period in terms of days.
#
# POST /v1/threatIntel/datastore/retentionPeriod
# operationId: setRetentionPeriod
export def "threat-intel-datastore-retention-period setRetentionPeriod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  retentionPeriod: int # Retention period in days. (format: int64, e.g. 120)
]: any -> record<retentionPeriod: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/threatIntel/datastore/retentionPeriod")
  let body = {retentionPeriod: $retentionPeriod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Uploads indicators in a Sumo normalized format.
#
# POST /v1/threatIntel/datastore/indicators/normalized
# operationId: uploadNormalizedIndicators
# --indicators item shape: {id: string, indicator: string, type: string, source: string, updated?: string, validFrom: string, validUntil?: string, confidence: int, threatType: string, actors?: string, killChain?: string, fields?: record}
export def "threat-intel-datastore-indicators-normalized uploadNormalizedIndicators" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  indicators: list # The list of normalized threat intel indicators to upload. — item shape: {id: string, indicator: string, type: string, source: string, updated?: string, validFrom: string, validUntil?: string, confidence: int, threatType: string, actors?: string, killChain?: string, fields?: record}
]: any -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/threatIntel/datastore/indicators/normalized")
  let body = {indicators: $indicators} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Uploads indicators in a STIX 2.x json format.
#
# POST /v1/threatIntel/datastore/indicators/stix
# operationId: uploadStixIndicators
# --indicators item shape: {type: string, spec_version: string, id: string, created: string, modified: string, created_by_ref?: string, revoked?: bool, labels?: list, confidence?: int, lang?: string, external_references?: list, object_marking_refs?: list, granular_markings?: list, extensions?: record, name?: string, description?: string, indicator_types?: list, pattern: string, pattern_type: string, pattern_version?: string, valid_from: string, valid_until?: string, kill_chain_phases?: list}
export def "threat-intel-datastore-indicators-stix uploadStixIndicators" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-source: string # User-provided text to identify the source of the indicator (e.g. FreeTAXII)
  indicators: list # The list of stix threat intel indicators to upload. — item shape: {type: string, spec_version: string, id: string, created: string, modified: string, created_by_ref?: string, revoked?: bool, labels?: list, confidence?: int, lang?: string, external_references?: list, object_marking_refs?: list, granular_markings?: list, extensions?: record, name?: string, description?: string, indicator_types?: list, pattern: string, pattern_type: string, pattern_version?: string, valid_from: string, valid_until?: string, kill_chain_phases?: list}
]: any -> record<invalidIndicators: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/threatIntel/datastore/indicators/stix")
  let body = {source: $body_source, indicators: $indicators} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Removes indicators by their IDS
#
# DELETE /v1/threatIntel/datastore/indicators
# operationId: removeIndicators
export def "threat-intel-datastore-indicators removeIndicators" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-source: string # The source of the indicator ID to match against (e.g. Crowdstrike)
  indicatorIds: list # The list of indicator IDs to match against (e.g. [indicator--abcd, indicator--ef012])
]: any -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/threatIntel/datastore/indicators")
  let body = {source: $body_source, indicatorIds: $indicatorIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates source properties
#
# PUT /v1/threatIntel/datastore/dataSource/{dataSourceName}
# operationId: dataSourcePropertiesUpdate
export def "threat-intel-datastore-data-source dataSourcePropertiesUpdate" [
  dataSourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # True if enabled. (e.g. true)
  --description: string # The data source description. (e.g. This is a stix1.2 data source.)
]: any -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/threatIntel/datastore/dataSource/($dataSourceName)")
  let body = {enabled: $enabled, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get paginated list of OT Collectors
#
# POST /v1/otCollectors
# operationId: getPaginatedOTCollectors
# --filters shape: {tags?: list, os?: string, collectorVersionRange?: record, alive?: bool, isRemotelyManaged?: bool, isUpgradeAvailable?: bool, hasNoSourceTemplateLinked?: bool, healthStatus?: "Healthy"|"Error"|"Warning"}
export def "ot-collectors post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # search by collector id or free text search on collector properties. (e.g. testAgent)
  --filters: record # parameter which is used for filtering. — shape: {tags?: list, os?: string, collectorVersionRange?: record, alive?: bool, isRemotelyManaged?: bool, isUpgradeAvailable?: bool, hasNoSourceTemplateLinked?: bool, healthStatus?: "Healthy"|"Error"|"Warning"}
  --sortBy: string # parameter which is used for sorting. (e.g. name)
  --next: string # parameter which is used for fetching next set of results. (e.g. token)
  --limit: int # parameter which is used for limiting number of otCollectors on a page. (format: int32, e.g. 30)
  --includeCount: string@bool-completer # count of filtered otCollectors. (nullable, e.g. false)
]: any -> record<data: table<id: string, name: string, version: record, category: string, description: string, tags: record, healthIncidentsTracker: record, ephemeral: bool, alive: bool, isRemotelyManaged: bool, effectiveConfig: record, systemInfo: record, timeZone: string, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, sourceTemplateLinkedCount: int>, next: string, count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/otCollectors")
  let body = {search: $search, filters: $filters, sortBy: $sortBy, next: $next, limit: $limit, includeCount: $includeCount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get OT Collector by ID.
#
# GET /v1/otCollectors/{id}
# operationId: getOTCollector
export def "ot-collectors get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, version: record<currentVersion: string, latestAvailableVersion: string>, category: string, description: string, tags: record, healthIncidentsTracker: record<errorsCount: int, warningsCount: int>, ephemeral: bool, alive: bool, isRemotelyManaged: bool, effectiveConfig: record, systemInfo: record<hostName: string, hostOsName: string, hostOsVersion: string, hostIpAddress: string, hostEnv: string>, timeZone: string, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, sourceTemplateLinkedCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/otCollectors/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an OT Collector.
#
# DELETE /v1/otCollectors/{id}
# operationId: deleteOTCollector
export def "ot-collectors delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/otCollectors/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a count of OT Collectors.
#
# GET /v1/otCollectors/totalCount
# operationId: getOTCollectorsCount
export def "ot-collectors-total-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/otCollectors/totalCount")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get OT Collectors by name.
#
# GET /v1/otCollectors/otCollectorsByName
# operationId: getOTCollectorsByNames
export def "ot-collectors-ot-collectors-by-name get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --names: list # A required parameter that accepts a list of names for which we need to collect all metadata.
]: nothing -> record<data: table<id: string, name: string, version: record, category: string, description: string, tags: record, healthIncidentsTracker: record, ephemeral: bool, alive: bool, isRemotelyManaged: bool, effectiveConfig: record, systemInfo: record, timeZone: string, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, sourceTemplateLinkedCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "names" $names "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/otCollectors/otCollectorsByName" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all Offline OT Collectors
#
# DELETE /v1/otCollectors/offline
# operationId: deleteOfflineOTCollectors
export def "ot-collectors-offline delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/otCollectors/offline")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all source templates.
#
# GET /v1/sourceTemplates
# operationId: getSourceTemplatesV2
export def "source-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --showDisabled: string@bool-completer # A boolean parameter to get all, including disabled source templates. (default: false)
  --name: string # Only return source template matching the given name (exact match). (nullable)
]: nothing -> record<data: table<schemaRef: record, id: string, inputJson: record, config: string, selector: record, totalCollectorLinked: int, createdAt: string, modifiedAt: string, createdBy: string, modifiedBy: string, status: string, isEnabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "showDisabled" $showDisabled "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/sourceTemplates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create source template.
#
# POST /v1/sourceTemplates
# operationId: createSourceTemplateV2
# --schemaRef shape: {type: string}
# --inputJson shape: {name: string, receivers: record, description?: string, processors?: record}
# --selector shape: {tags?: list, names?: list}
export def "source-templates createSourceTemplateV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  schemaRef: record # schema reference for source template. — shape: {type: string}
  inputJson: record # inputJson of source template — shape: {name: string, receivers: record, description?: string, processors?: record}
  --selector: record # Agent selector conditions — shape: {tags?: list, names?: list}
  --isEnabled: string@bool-completer # Indicates whether the source template is enabled - **Create operation:** Defaults to `true` (the template is enabled when created). - **Update operation:** If omitted, the existing status is preserved. (e.g. true)
]: any -> record<schemaRef: record<type: string>, id: string, inputJson: record, config: string, selector: record<tags: list<list>, names: list<string>>, totalCollectorLinked: int, createdAt: string, modifiedAt: string, createdBy: string, modifiedBy: string, status: string, isEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sourceTemplates")
  let body = {schemaRef: $schemaRef, inputJson: $inputJson, selector: $selector, isEnabled: $isEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a source template by Id.
#
# GET /v1/sourceTemplates/{id}
# operationId: getSourceTemplateV2
export def "source-templates get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<schemaRef: record<type: string>, id: string, inputJson: record, config: string, selector: record<tags: list<list>, names: list<string>>, totalCollectorLinked: int, createdAt: string, modifiedAt: string, createdBy: string, modifiedBy: string, status: string, isEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sourceTemplates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update source template.
#
# POST /v1/sourceTemplates/{id}
# operationId: updateSourceTemplateV2
# --schemaRef shape: {type: string}
# --inputJson shape: {name: string, receivers: record, description?: string, processors?: record}
# --selector shape: {tags?: list, names?: list}
export def "source-templates updateSourceTemplateV2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  schemaRef: record # schema reference for source template. — shape: {type: string}
  inputJson: record # InputJson of source template — shape: {name: string, receivers: record, description?: string, processors?: record}
  --selector: record # Agent selector conditions — shape: {tags?: list, names?: list}
  --isEnabled: string@bool-completer # Indicates whether the source template is enabled. If omitted, the existing status is preserved. (e.g. true)
]: any -> record<schemaRef: record<type: string>, id: string, inputJson: record, config: string, selector: record<tags: list<list>, names: list<string>>, totalCollectorLinked: int, createdAt: string, modifiedAt: string, createdBy: string, modifiedBy: string, status: string, isEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sourceTemplates/($id)")
  let body = {schemaRef: $schemaRef, inputJson: $inputJson, selector: $selector, isEnabled: $isEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a source template.
#
# DELETE /v1/sourceTemplates/{id}
# operationId: deleteSourceTemplateV2
export def "source-templates delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sourceTemplates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update status of source template
#
# PUT /v1/sourceTemplates/{id}/status
# operationId: updateSourceTemplateStatusV2
export def "source-templates-status updateSourceTemplateStatusV2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  status: string@status-completer # status to set for the source template (enable or disable).
]: any -> record<schemaRef: record<type: string>, id: string, inputJson: record, config: string, selector: record<tags: list<list>, names: list<string>>, totalCollectorLinked: int, createdAt: string, modifiedAt: string, createdBy: string, modifiedBy: string, status: string, isEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sourceTemplates/($id)/status")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upgrade source template.
#
# POST /v1/sourceTemplates/{id}/upgrade
# operationId: upgradeSourceTemplateV2
# --schemaRef shape: {type: string, version: string}
# --inputJson shape: {name: string, receivers: record, description?: string, processors?: record}
export def "source-templates-upgrade upgradeSourceTemplateV2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  schemaRef: record # schema reference for upgrade source template request. — shape: {type: string, version: string}
  inputJson: record # inputJson of source template — shape: {name: string, receivers: record, description?: string, processors?: record}
]: any -> record<schemaRef: record<type: string>, id: string, inputJson: record, config: string, selector: record<tags: list<list>, names: list<string>>, totalCollectorLinked: int, createdAt: string, modifiedAt: string, createdBy: string, modifiedBy: string, status: string, isEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sourceTemplates/($id)/upgrade")
  let body = {schemaRef: $schemaRef, inputJson: $inputJson} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Preview source template linking changes.
#
# POST /v1/sourceTemplates/getLinkedSourceTemplatesImpact
# operationId: getLinkedSourceTemplatesImpact
export def "source-templates-get-linked-source-templates-impact post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  collectorId: string # otCollector id for which tags are edited. (e.g. 00005AF3107BF0D6)
  --tags: record # JSON map of key-value metadata to apply to the otCollector. (default: {}, e.g. {environment: production, location: us-west-2})
  --updatedName: string # Updated Name of the otCollector. (e.g. demo_macOS)
]: any -> record<collectorId: string, addedSourceTemplates: table<sourceTemplateDefinition: record, reasonTags: list>, removedSourceTemplates: table<sourceTemplateDefinition: record, reasonTags: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sourceTemplates/getLinkedSourceTemplatesImpact")
  let body = {collectorId: $collectorId, tags: $tags, updatedName: $updatedName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return all source templates of a customer (deprecated).
#
# GET /v1/sourceTemplate
# DEPRECATED
# operationId: getSourceTemplates
@deprecated
export def "source-template list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --showDisabled: string@bool-completer # A boolean parameter to get all, including disabled source templates. (default: false)
  --name: string # Only return source template matching the given name (exact match). (nullable)
]: nothing -> record<data: table<schemaRef: record, id: string, inputJson: record, config: string, selector: record, totalCollectorLinked: int, createdAt: string, modifiedAt: string, createdBy: string, modifiedBy: string, status: string, isEnabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "showDisabled" $showDisabled "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/sourceTemplate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create source template (deprecated).
#
# POST /v1/sourceTemplate
# DEPRECATED
# operationId: createSourceTemplate
# --schemaRef shape: {type: string}
# --inputJson shape: {name: string, receivers: record, description?: string, processors?: record}
# --selector shape: {tags?: list, names?: list}
@deprecated
export def "source-template createSourceTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  schemaRef: record # schema reference for source template. — shape: {type: string}
  inputJson: record # inputJson of source template — shape: {name: string, receivers: record, description?: string, processors?: record}
  --selector: record # Agent selector conditions — shape: {tags?: list, names?: list}
  --isEnabled: string@bool-completer # Indicates whether the source template is enabled - **Create operation:** Defaults to `true` (the template is enabled when created). - **Update operation:** If omitted, the existing status is preserved. (e.g. true)
]: any -> record<schemaRef: record<type: string>, id: string, inputJson: record, config: string, selector: record<tags: list<list>, names: list<string>>, totalCollectorLinked: int, createdAt: string, modifiedAt: string, createdBy: string, modifiedBy: string, status: string, isEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sourceTemplate")
  let body = {schemaRef: $schemaRef, inputJson: $inputJson, selector: $selector, isEnabled: $isEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a source template by Id (deprecated).
#
# GET /v1/sourceTemplate/{id}
# DEPRECATED
# operationId: getSourceTemplate
@deprecated
export def "source-template get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<schemaRef: record<type: string>, id: string, inputJson: record, config: string, selector: record<tags: list<list>, names: list<string>>, totalCollectorLinked: int, createdAt: string, modifiedAt: string, createdBy: string, modifiedBy: string, status: string, isEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sourceTemplate/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update source template (deprecated).
#
# POST /v1/sourceTemplate/{id}
# DEPRECATED
# operationId: updateSourceTemplate
# --schemaRef shape: {type: string}
# --inputJson shape: {name: string, receivers: record, description?: string, processors?: record}
# --selector shape: {tags?: list, names?: list}
@deprecated
export def "source-template updateSourceTemplate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  schemaRef: record # schema reference for source template. — shape: {type: string}
  inputJson: record # inputJson of source template — shape: {name: string, receivers: record, description?: string, processors?: record}
  --selector: record # Agent selector conditions — shape: {tags?: list, names?: list}
  --isEnabled: string@bool-completer # Indicates whether the source template is enabled - **Create operation:** Defaults to `true` (the template is enabled when created). - **Update operation:** If omitted, the existing status is preserved. (e.g. true)
]: any -> record<schemaRef: record<type: string>, id: string, inputJson: record, config: string, selector: record<tags: list<list>, names: list<string>>, totalCollectorLinked: int, createdAt: string, modifiedAt: string, createdBy: string, modifiedBy: string, status: string, isEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sourceTemplate/($id)")
  let body = {schemaRef: $schemaRef, inputJson: $inputJson, selector: $selector, isEnabled: $isEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a source template (deprecated).
#
# DELETE /v1/sourceTemplate/{id}
# DEPRECATED
# operationId: deleteSourceTemplate
@deprecated
export def "source-template delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sourceTemplate/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upgrade source template (deprecated).
#
# POST /v1/upgrade/sourceTemplate/{id}
# DEPRECATED
# operationId: upgradeSourceTemplate
# --schemaRef shape: {type: string, version: string}
# --inputJson shape: {name: string, receivers: record, description?: string, processors?: record}
@deprecated
export def "upgrade-source-template upgradeSourceTemplate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  schemaRef: record # schema reference for upgrade source template request. — shape: {type: string, version: string}
  inputJson: record # inputJson of source template — shape: {name: string, receivers: record, description?: string, processors?: record}
]: any -> record<schemaRef: record<type: string>, id: string, inputJson: record, config: string, selector: record<tags: list<list>, names: list<string>>, totalCollectorLinked: int, createdAt: string, modifiedAt: string, createdBy: string, modifiedBy: string, status: string, isEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/upgrade/sourceTemplate/($id)")
  let body = {schemaRef: $schemaRef, inputJson: $inputJson} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get linked source templates update based on the ot-collector tags user is wants to update.
#
# POST /v1/sourceTemplate/getLinkedSourceTemplatesImpact
# operationId: getLinkedSourceTemplatesUpdate
export def "source-template-get-linked-source-templates-impact post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  collectorId: string # otCollector id for which tags are edited. (e.g. 00005AF3107BF0D6)
  --tags: record # JSON map of key-value metadata to apply to the otCollector. (default: {}, e.g. {environment: production, location: us-west-2})
  --updatedName: string # Updated Name of the otCollector. (e.g. demo_macOS)
]: any -> record<collectorId: string, addedSourceTemplates: table<sourceTemplateDefinition: record, reasonTags: list>, removedSourceTemplates: table<sourceTemplateDefinition: record, reasonTags: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sourceTemplate/getLinkedSourceTemplatesImpact")
  let body = {collectorId: $collectorId, tags: $tags, updatedName: $updatedName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update status of source template (deprecated)
#
# PUT /v1/sourceTemplate/{id}/status
# DEPRECATED
# operationId: updateSourceTemplateStatus
@deprecated
export def "source-template-status updateSourceTemplateStatus" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  status: string@status-completer # status to set for the source template (enable or disable).
]: any -> record<schemaRef: record<type: string>, id: string, inputJson: record, config: string, selector: record<tags: list<list>, names: list<string>>, totalCollectorLinked: int, createdAt: string, modifiedAt: string, createdBy: string, modifiedBy: string, status: string, isEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sourceTemplate/($id)/status")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get schema base identities grouped by type and sorted by version.
#
# GET /v1/schemaIdentitiesGrouped
# operationId: getSchemaIdentitiesGrouped
export def "schema-identities-grouped get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<type: string, versions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/schemaIdentitiesGrouped")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all event extraction rules.
#
# GET /v1/eventExtractionRules
# operationId: getEventExtractionRules
export def "event-extraction-rules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/eventExtractionRules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create event extraction rule.
#
# POST /v1/eventExtractionRules
# operationId: createEventExtractionRule
# --correlationExpression shape: {queryFieldName: string, eventFieldName: string, stringMatchingAlgorithm: string}
export def "event-extraction-rules createEventExtractionRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of event extraction rule. (e.g. foo)
  --description: string # Description of event extraction rule. (e.g. foo)
  --body-query: string # Query string for the Event Extraction Rule. Logs matching this query are periodically ingested into the `sumologic_userdata_events` index (**Events**).  Guidelines for creating the query:   - Optimize the query to limit the number of returned log messages (intended for special logs only).   - The query runs in `Manual` mode, explicitly parse and extract only the necessary fields for event correlation and visualization.   - Use the `fields` operator to restrict the output to required fields.  (e.g. _sourceCategory=eventSource)
  --correlationExpression: record # Correlation Expression specifies how to determine related events for a log search query.  The value of `eventFieldName` from Events is compared with the values of `queryFieldName` from the log search query output using the defined stringMatchingAlgorithm. Events that match according to this algorithm are considered correlated. — shape: {queryFieldName: string, eventFieldName: string, stringMatchingAlgorithm: string}
  configuration: record # Configuration for the Event Extraction Rule.  This object defines how event fields are mapped to their corresponding values. Each field specifies a `valueSource`, which provides the actual value, and an optional `mappingType`, indicating the value is hardcoded.  The following fields are **required**:   - `eventType`: Type of the event. Accepted values are `Deployment`, `Feature Flag Change`, `Configuration Change` or `Infrastructure Change`.   - `eventPriority`: Indicates the priority of the event. Accepted values are `High`, `Medium`, or `Low`.   - `eventSource`: Source system or component where the event originated (e.g., "Jenkins").   - `eventName`: Descriptive name of the event (e.g., "monitor-manager deployed.").  The following fields are **optional**:   - `eventDescription`: Additional context or details about the event.  Custom fields can also be added as needed to capture domain-specific event data.  (e.g. {eventType: {valueSource: Deploy, mappingType: HardCoded}, eventPriority: {valueSource: High, mappingType: HardCoded}, eventSource: {valueSource: Jenkins, mappingType: HardCoded}, eventName: {valueSource: monitor-manager deployed., mappingType: HardCoded}, eventDescription: {valueSource: 2 containers in monitor-manager were upgraded., mappingType: HardCoded}})
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/eventExtractionRules")
  let body = {name: $name, description: $description, query: $body_query, correlationExpression: $correlationExpression, configuration: $configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get event extraction rules quota.
#
# GET /v1/eventExtractionRules/quota
# operationId: getEventExtractionRulesQuota
export def "event-extraction-rules-quota get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<quota: int, remaining: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/eventExtractionRules/quota")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an event extraction rule.
#
# GET /v1/eventExtractionRules/{id}
# operationId: getEventExtractionRule
export def "event-extraction-rules get" [
  id: string
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
  let full_url = (build-url $base $"/v1/eventExtractionRules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an event extraction rule.
#
# PUT /v1/eventExtractionRules/{id}
# operationId: updateEventExtractionRule
# --correlationExpression shape: {queryFieldName: string, eventFieldName: string, stringMatchingAlgorithm: string}
export def "event-extraction-rules updateEventExtractionRule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of event extraction rule. (e.g. foo)
  --description: string # Description of event extraction rule. (e.g. foo)
  --body-query: string # Query string for the Event Extraction Rule. Logs matching this query are periodically ingested into the `sumologic_userdata_events` index (**Events**).  Guidelines for creating the query:   - Optimize the query to limit the number of returned log messages (intended for special logs only).   - The query runs in `Manual` mode, explicitly parse and extract only the necessary fields for event correlation and visualization.   - Use the `fields` operator to restrict the output to required fields.  (e.g. _sourceCategory=eventSource)
  --correlationExpression: record # Correlation Expression specifies how to determine related events for a log search query.  The value of `eventFieldName` from Events is compared with the values of `queryFieldName` from the log search query output using the defined stringMatchingAlgorithm. Events that match according to this algorithm are considered correlated. — shape: {queryFieldName: string, eventFieldName: string, stringMatchingAlgorithm: string}
  configuration: record # Configuration for the Event Extraction Rule.  This object defines how event fields are mapped to their corresponding values. Each field specifies a `valueSource`, which provides the actual value, and an optional `mappingType`, indicating the value is hardcoded.  The following fields are **required**:   - `eventType`: Type of the event. Accepted values are `Deployment`, `Feature Flag Change`, `Configuration Change` or `Infrastructure Change`.   - `eventPriority`: Indicates the priority of the event. Accepted values are `High`, `Medium`, or `Low`.   - `eventSource`: Source system or component where the event originated (e.g., "Jenkins").   - `eventName`: Descriptive name of the event (e.g., "monitor-manager deployed.").  The following fields are **optional**:   - `eventDescription`: Additional context or details about the event.  Custom fields can also be added as needed to capture domain-specific event data.  (e.g. {eventType: {valueSource: Deploy, mappingType: HardCoded}, eventPriority: {valueSource: High, mappingType: HardCoded}, eventSource: {valueSource: Jenkins, mappingType: HardCoded}, eventName: {valueSource: monitor-manager deployed., mappingType: HardCoded}, eventDescription: {valueSource: 2 containers in monitor-manager were upgraded., mappingType: HardCoded}})
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/eventExtractionRules/($id)")
  let body = {name: $name, description: $description, query: $body_query, correlationExpression: $correlationExpression, configuration: $configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an event extraction rule.
#
# DELETE /v1/eventExtractionRules/{id}
# operationId: deleteEventExtractionRule
export def "event-extraction-rules delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/eventExtractionRules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get budgets
#
# GET /v1/budgets
# operationId: getBudgets
export def "budgets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of budgets returned in the response. The number of budgets returned may be less than the `limit`. (format: int32, default: 100)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results.
]: nothing -> record<data: table<name: string, capacity: int, unit: string, budgetType: string, scope: record, window: string, applicableOn: string, groupBy: string, action: string, status: string, id: string, orgId: string, resetTime: string, resetTimeZone: string, resetDayOfWeek: string, resetDateOfMonth: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/budgets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a budget definition
#
# POST /v1/budgets
# operationId: createBudget
# --scope shape: {includedUsers: list, excludedUsers: list, includedRoles: list, excludedRoles: list}
export def "budgets createBudget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the budget.
  capacity: int # Capacity of the budget. (format: int64)
  unit: string # Unit of the budget. (e.g. GB)
  budgetType: string # Type of the budget. (e.g. ScanBudget)
  scope: record # shape: {includedUsers: list, excludedUsers: list, includedRoles: list, excludedRoles: list}
  window: string # Window of the budget. Use Daily/Weekly/Monthly for creating a time based budget (beta) (e.g. Query)
  applicableOn: string # Grouping of the budget. (e.g. PerEntity)
  groupBy: string # Grouping Entity of the budget. (e.g. User)
  action: string # Action to be taken if the budget is breached (e.g. Warn)
  --status: string # Signifies the state of the budget. (Active/Inactive) (e.g. active)
]: any -> record<name: string, capacity: int, unit: string, budgetType: string, scope: record<includedUsers: list<string>, excludedUsers: list<string>, includedRoles: list<string>, excludedRoles: list<string>>, window: string, applicableOn: string, groupBy: string, action: string, status: string, id: string, orgId: string, resetTime: string, resetTimeZone: string, resetDayOfWeek: string, resetDateOfMonth: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/budgets")
  let body = {name: $name, capacity: $capacity, unit: $unit, budgetType: $budgetType, scope: $scope, window: $window, applicableOn: $applicableOn, groupBy: $groupBy, action: $action, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get budget
#
# GET /v1/budgets/{budgetId}
# operationId: getBudget
export def "budgets get" [
  budgetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, capacity: int, unit: string, budgetType: string, scope: record<includedUsers: list<string>, excludedUsers: list<string>, includedRoles: list<string>, excludedRoles: list<string>>, window: string, applicableOn: string, groupBy: string, action: string, status: string, id: string, orgId: string, resetTime: string, resetTimeZone: string, resetDayOfWeek: string, resetDateOfMonth: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/budgets/($budgetId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update budget
#
# PUT /v1/budgets/{budgetId}
# operationId: updateBudget
# --scope shape: {includedUsers: list, excludedUsers: list, includedRoles: list, excludedRoles: list}
export def "budgets updateBudget" [
  budgetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the budget.
  capacity: int # Capacity of the budget. (format: int64)
  unit: string # Unit of the budget. (e.g. GB)
  budgetType: string # Type of the budget. (e.g. ScanBudget)
  scope: record # shape: {includedUsers: list, excludedUsers: list, includedRoles: list, excludedRoles: list}
  window: string # Window of the budget. Use Daily/Weekly/Monthly for creating a time based budget (beta) (e.g. Query)
  applicableOn: string # Grouping of the budget. (e.g. PerEntity)
  groupBy: string # Grouping Entity of the budget. (e.g. User)
  action: string # Action to be taken if the budget is breached (e.g. Warn)
  --status: string # Signifies the state of the budget. (Active/Inactive) (e.g. active)
]: any -> record<name: string, capacity: int, unit: string, budgetType: string, scope: record<includedUsers: list<string>, excludedUsers: list<string>, includedRoles: list<string>, excludedRoles: list<string>>, window: string, applicableOn: string, groupBy: string, action: string, status: string, id: string, orgId: string, resetTime: string, resetTimeZone: string, resetDayOfWeek: string, resetDateOfMonth: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/budgets/($budgetId)")
  let body = {name: $name, capacity: $capacity, unit: $unit, budgetType: $budgetType, scope: $scope, window: $window, applicableOn: $applicableOn, groupBy: $groupBy, action: $action, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete budget
#
# DELETE /v1/budgets/{budgetId}
# operationId: deleteBudget
export def "budgets delete" [
  budgetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/budgets/($budgetId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get budget usages
#
# GET /v1/budgets/usage
# operationId: getBudgetUsages
export def "budgets-usage list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of budget usages returned in the response. The number of budget usages returned may be less than the `limit`. (format: int32, default: 100)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results.
]: nothing -> record<data: table<budgetId: string, usage: int, usagePercentage: int>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/budgets/usage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get budget usage
#
# GET /v1/budgets/{budgetId}/usage
# operationId: getBudgetUsage
export def "budgets-usage get" [
  budgetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<budgetId: string, usage: int, usagePercentage: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/budgets/($budgetId)/usage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all macros.
#
# GET /v2/macros
# operationId: listMacros
export def "macros listMacros" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of macro returned in the response. The number of macros returned may be less than the `limit`. Default 50. (format: int32, default: 50, e.g. 50)
  --qp-token: string # Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. `token` is set to null when no more pages are left. (e.g. GDCiRv4vebF3UWFJQ1kySXBOR3Bzh69GR0RyWm9vCtc)
]: nothing -> record<data: table<id: string, createdAt: string, createdBy: string>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/macros" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new macro.
#
# POST /v2/macros
# operationId: createMacro
# --arguments item shape: {name: string, type?: string}
# --argumentValidations item shape: {evalExpression: string, errorMessage: string}
export def "macros createMacro" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description of the macro. (e.g. Macro for geo lookup.)
  definition: string # The definition of the macro. Use a valid Sumo Log Search expression. (e.g. lookup latitude, longitude from geo://location on ip = {{ip_field}} | count by latitude, longitude | sort _count" )
  --enabled: string@bool-completer # If the macro is enabled or not (default True) (default: true)
  --arguments: list # Arguments used in the macro. — item shape: {name: string, type?: string}
  --argumentValidations: list # Validation expressions for the arguments. — item shape: {evalExpression: string, errorMessage: string}
  name: string # Name of the macro. (e.g. MacroGeoLookup)
  --macroCreationSuggestionId: string # Identifier if the suggestion comes from an macro creation suggestion. This id is used to track macro creation suggestions, and to delete the suggestion once the macro is created. (e.g. ABC12)
]: any -> record<id: string, createdAt: string, createdBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/macros")
  let body = {description: $description, definition: $definition, enabled: $enabled, arguments: $arguments, argumentValidations: $argumentValidations, name: $name, macroCreationSuggestionId: $macroCreationSuggestionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a macro.
#
# GET /v2/macros/{id}
# operationId: getMacro
export def "macros get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, createdAt: string, createdBy: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/macros/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a macro.
#
# PUT /v2/macros/{id}
# operationId: editMacro
# --arguments item shape: {name: string, type?: string}
# --argumentValidations item shape: {evalExpression: string, errorMessage: string}
export def "macros editMacro" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description of the macro. (e.g. Macro for geo lookup.)
  definition: string # The definition of the macro. Use a valid Sumo Log Search expression. (e.g. lookup latitude, longitude from geo://location on ip = {{ip_field}} | count by latitude, longitude | sort _count" )
  --enabled: string@bool-completer # If the macro is enabled or not (default True) (default: true)
  --arguments: list # Arguments used in the macro. — item shape: {name: string, type?: string}
  --argumentValidations: list # Validation expressions for the arguments. — item shape: {evalExpression: string, errorMessage: string}
]: any -> record<id: string, createdAt: string, createdBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/macros/($id)")
  let body = {description: $description, definition: $definition, enabled: $enabled, arguments: $arguments, argumentValidations: $argumentValidations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a macro.
#
# DELETE /v2/macros/{id}
# operationId: deleteMacro
export def "macros delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/macros/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk read a mutingschedule or folder.
#
# GET /v1/mutingSchedules
# operationId: mutingSchedulesReadByIds
export def "muting-schedules mutingSchedulesReadByIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # A comma-separated list of identifiers. (e.g. 0000000000000001,0000000000000002,0000000000000003)
  --skipChildren: string@bool-completer # a boolean parameter to control skipping fetching children of requested folder(s)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "skipChildren" $skipChildren "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/mutingSchedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a mutingschedule or folder.
#
# POST /v1/mutingSchedules
# Discriminator (request): type
# operationId: mutingSchedulesCreate
export def "muting-schedules mutingSchedulesCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parentId: string # Identifier of the parent folder in which to create the mutingschedule or folder.
  name: string # Name of the mutingschedule or folder.
  --description: string # Description of the mutingschedule or folder. (default: )
  type: string # Type of the object model. Valid values:   1) MutingSchedulesLibraryMutingschedule   2) MutingSchedulesLibraryFolder
]: any -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parentId" $parentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/mutingSchedules" $qp)
  let body = {name: $name, description: $description, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk delete a mutingschedule or folder.
#
# DELETE /v1/mutingSchedules
# operationId: mutingSchedulesDeleteByIds
export def "muting-schedules mutingSchedulesDeleteByIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # A comma-separated list of identifiers. (e.g. 0000000000000001,0000000000000002,0000000000000003)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/mutingSchedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the root mutingSchedules folder.
#
# GET /v1/mutingSchedules/root
# operationId: getMutingSchedulesLibraryRoot
export def "muting-schedules-root get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list<string>, children: table<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/mutingSchedules/root")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for a mutingschedule or folder.
#
# GET /v1/mutingSchedules/search
# operationId: mutingSchedulesSearch
export def "muting-schedules-search mutingSchedulesSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The search query to find mutingschedule or folder. Below is the list of different filters with examples:   - **createdBy** : Filter by the user's identifier who created the content. Example: `createdBy:000000000000968B`.   - **createdBefore** : Filter by the content objects created before the given timestamp(in milliseconds). Example: `createdBefore:1457997222`.   - **createdAfter** : Filter by the content objects created after the given timestamp(in milliseconds). Example: `createdAfter:1457997111`.   - **modifiedBefore** : Filter by the content objects modified before the given timestamp(in milliseconds). Example: `modifiedBefore:1457997222`.   - **modifiedAfter** : Filter by the content objects modified after the given timestamp(in milliseconds). Example: `modifiedAfter:1457997111`.   - **type** : Filter by the type of the content object. Example: `type:folder`.  You can also use multiple filters in one query. For example to search for all content objects created by user with identifier 000000000000968B with creation timestamp after 1457997222 containing the text Test, the query would look like:    `createdBy:000000000000968B createdAfter:1457997222 Test` (e.g. createdBy:000000000000968B Test)
  --limit: int # Maximum number of items you want in the response. (format: int32, default: 1000, e.g. 10)
  --offset: int # The position or row from where to start the search operation. (format: int32, default: 0, e.g. 5)
  --skipChildren: string@bool-completer # a boolean parameter to control skipping fetching children of requested folder(s)
]: nothing -> table<item: record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list>, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "skipChildren" $skipChildren "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/mutingSchedules/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a mutingschedule or folder.
#
# GET /v1/mutingSchedules/{id}
# Discriminator (response): type
# operationId: mutingSchedulesReadById
export def "muting-schedules mutingSchedulesReadById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/mutingSchedules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a mutingschedule or folder.
#
# PUT /v1/mutingSchedules/{id}
# Discriminator (request): type
# operationId: mutingSchedulesUpdateById
export def "muting-schedules mutingSchedulesUpdateById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the mutingschedule or folder.
  --description: string # The description of the mutingschedule or folder. (default: )
  version: int # The version of the mutingschedule or folder. (format: int64)
  type: string # Type of the object model.
]: any -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/mutingSchedules/($id)")
  let body = {name: $name, description: $description, version: $version, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a mutingschedule or folder.
#
# DELETE /v1/mutingSchedules/{id}
# operationId: mutingSchedulesDeleteById
export def "muting-schedules mutingSchedulesDeleteById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/mutingSchedules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the path of a mutingschedule or folder.
#
# GET /v1/mutingSchedules/{id}/path
# operationId: getMutingSchedulesFullPath
export def "muting-schedules-path get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pathItems: table<id: string, name: string, description: string>, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/mutingSchedules/($id)/path")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copy a mutingschedule or folder.
#
# POST /v1/mutingSchedules/{id}/copy
# Discriminator (response): type
# operationId: mutingSchedulesCopy
export def "muting-schedules-copy mutingSchedulesCopy" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  parentId: string # Identifier of the parent folder to copy to.
  --name: string # Optionally provide a new name.
  --description: string # Optionally provide a new description.
]: any -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/mutingSchedules/($id)/copy")
  let body = {parentId: $parentId, name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export a mutingschedule or folder.
#
# GET /v1/mutingSchedules/{id}/export
# Discriminator (response): type
# operationId: mutingSchedulesExportItem
export def "muting-schedules-export mutingSchedulesExportItem" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, description: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/mutingSchedules/($id)/export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import a mutingschedule or folder.
#
# POST /v1/mutingSchedules/{parentId}/import
# Discriminator (request): type
# operationId: mutingSchedulesImportItem
export def "muting-schedules-import mutingSchedulesImportItem" [
  parentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the mutingschedule or folder.
  --description: string # Description of the mutingschedule or folder.
  type: string # Type of the object model.
]: any -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/mutingSchedules/($parentId)/import")
  let body = {name: $name, description: $description, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk read a slo or folder.
#
# GET /v1/slos
# operationId: slosReadByIds
export def "slos slosReadByIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # A comma-separated list of identifiers. (e.g. 0000000000000001,0000000000000002,0000000000000003)
  --skipChildren: string@bool-completer # a boolean parameter to control skipping fetching children of requested folder(s)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "skipChildren" $skipChildren "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/slos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a slo or folder.
#
# POST /v1/slos
# Discriminator (request): type
# operationId: slosCreate
export def "slos slosCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parentId: string # Identifier of the parent folder in which to create the slo or folder.
  name: string # Name of the slo or folder.
  --description: string # Description of the slo or folder. (default: )
  type: string # Type of the object model. Valid values:   1) SlosLibrarySlo   2) SlosLibraryFolder
]: any -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parentId" $parentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/slos" $qp)
  let body = {name: $name, description: $description, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk delete a slo or folder.
#
# DELETE /v1/slos
# operationId: slosDeleteByIds
export def "slos slosDeleteByIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # A comma-separated list of identifiers. (e.g. 0000000000000001,0000000000000002,0000000000000003)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/slos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the root slos folder.
#
# GET /v1/slos/root
# operationId: getSlosLibraryRoot
export def "slos-root get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list<string>, children: table<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/slos/root")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read a slo or folder by its path.
#
# GET /v1/slos/path
# Discriminator (response): type
# operationId: slosGetByPath
export def "slos-path slosGetByPath" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --path: string # The path of the slo or folder.
]: nothing -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/slos/path" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for a slo or folder.
#
# GET /v1/slos/search
# operationId: slosSearch
export def "slos-search slosSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The search query to find slo or folder. Below is the list of different filters with examples:   - **createdBy** : Filter by the user's identifier who created the content. Example: `createdBy:000000000000968B`.   - **createdBefore** : Filter by the content objects created before the given timestamp(in milliseconds). Example: `createdBefore:1457997222`.   - **createdAfter** : Filter by the content objects created after the given timestamp(in milliseconds). Example: `createdAfter:1457997111`.   - **modifiedBefore** : Filter by the content objects modified before the given timestamp(in milliseconds). Example: `modifiedBefore:1457997222`.   - **modifiedAfter** : Filter by the content objects modified after the given timestamp(in milliseconds). Example: `modifiedAfter:1457997111`.   - **type** : Filter by the type of the content object. Example: `type:folder`.  You can also use multiple filters in one query. For example to search for all content objects created by user with identifier 000000000000968B with creation timestamp after 1457997222 containing the text Test, the query would look like:    `createdBy:000000000000968B createdAfter:1457997222 Test` (e.g. createdBy:000000000000968B Test)
  --limit: int # Maximum number of items you want in the response. (format: int32, default: 1000, e.g. 10)
  --offset: int # The position or row from where to start the search operation. (format: int32, default: 0, e.g. 5)
  --skipChildren: string@bool-completer # a boolean parameter to control skipping fetching children of requested folder(s)
]: nothing -> table<item: record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list>, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "skipChildren" $skipChildren "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/slos/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a slo or folder.
#
# GET /v1/slos/{id}
# Discriminator (response): type
# operationId: slosReadById
export def "slos slosReadById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/slos/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a slo or folder.
#
# PUT /v1/slos/{id}
# Discriminator (request): type
# operationId: slosUpdateById
export def "slos slosUpdateById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the slo or folder.
  --description: string # The description of the slo or folder. (default: )
  version: int # The version of the slo or folder. (format: int64)
  type: string # Type of the object model.
]: any -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/slos/($id)")
  let body = {name: $name, description: $description, version: $version, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a slo or folder.
#
# DELETE /v1/slos/{id}
# operationId: slosDeleteById
export def "slos slosDeleteById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/slos/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the path of a slo or folder.
#
# GET /v1/slos/{id}/path
# operationId: getSlosFullPath
export def "slos-path get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pathItems: table<id: string, name: string, description: string>, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/slos/($id)/path")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Move a slo or folder.
#
# POST /v1/slos/{id}/move
# Discriminator (response): type
# operationId: slosMove
export def "slos-move slosMove" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parentId: string # Identifier of the parent folder to move the slo or folder to.
]: nothing -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parentId" $parentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/slos/($id)/move" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copy a slo or folder.
#
# POST /v1/slos/{id}/copy
# Discriminator (response): type
# operationId: slosCopy
export def "slos-copy slosCopy" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  parentId: string # Identifier of the parent folder to copy to.
  --name: string # Optionally provide a new name.
  --description: string # Optionally provide a new description.
]: any -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/slos/($id)/copy")
  let body = {parentId: $parentId, name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export a slo or folder.
#
# GET /v1/slos/{id}/export
# Discriminator (response): type
# operationId: slosExportItem
export def "slos-export slosExportItem" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, description: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/slos/($id)/export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import a slo or folder.
#
# POST /v1/slos/{parentId}/import
# Discriminator (request): type
# operationId: slosImportItem
export def "slos-import slosImportItem" [
  parentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the slo or folder.
  --description: string # Description of the slo or folder.
  type: string # Type of the object model.
]: any -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/slos/($parentId)/import")
  let body = {name: $name, description: $description, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk read a monitor or folder.
#
# GET /v1/monitors
# operationId: monitorsReadByIds
export def "monitors monitorsReadByIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # A comma-separated list of identifiers. (e.g. 0000000000000001,0000000000000002,0000000000000003)
  --skipChildren: string@bool-completer # a boolean parameter to control skipping fetching children of requested folder(s)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "skipChildren" $skipChildren "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/monitors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a monitor or folder.
#
# POST /v1/monitors
# Discriminator (request): type
# operationId: monitorsCreate
export def "monitors monitorsCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parentId: string # Identifier of the parent folder in which to create the monitor or folder.
  name: string # Name of the monitor or folder.
  --description: string # Description of the monitor or folder. (default: )
  type: string # Type of the object model. Valid values:   1) MonitorsLibraryMonitor   2) MonitorsLibraryFolder
]: any -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parentId" $parentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/monitors" $qp)
  let body = {name: $name, description: $description, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk delete a monitor or folder.
#
# DELETE /v1/monitors
# operationId: monitorsDeleteByIds
export def "monitors monitorsDeleteByIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # A comma-separated list of identifiers. (e.g. 0000000000000001,0000000000000002,0000000000000003)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/monitors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the root monitors folder.
#
# GET /v1/monitors/root
# operationId: getMonitorsLibraryRoot
export def "monitors-root get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list<string>, children: table<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/monitors/root")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read a monitor or folder by its path.
#
# GET /v1/monitors/path
# Discriminator (response): type
# operationId: monitorsGetByPath
export def "monitors-path monitorsGetByPath" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --path: string # The path of the monitor or folder.
]: nothing -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/monitors/path" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for a monitor or folder.
#
# GET /v1/monitors/search
# operationId: monitorsSearch
export def "monitors-search monitorsSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The search query to find monitor or folder. Below is the list of different filters with examples:   - **createdBy** : Filter by the user's identifier who created the content. Example: `createdBy:000000000000968B`.   - **createdBefore** : Filter by the content objects created before the given timestamp(in milliseconds). Example: `createdBefore:1457997222`.   - **createdAfter** : Filter by the content objects created after the given timestamp(in milliseconds). Example: `createdAfter:1457997111`.   - **modifiedBefore** : Filter by the content objects modified before the given timestamp(in milliseconds). Example: `modifiedBefore:1457997222`.   - **modifiedAfter** : Filter by the content objects modified after the given timestamp(in milliseconds). Example: `modifiedAfter:1457997111`.   - **type** : Filter by the type of the content object. Example: `type:folder`.   - **monitorStatus** : Filter by the status of the monitor: Normal, Critical, Warning, MissingData, Disabled, AllTriggered. Example: `monitorStatus:Normal`.  You can also use multiple filters in one query. For example to search for all content objects created by user with identifier 000000000000968B with creation timestamp after 1457997222 containing the text Test, the query would look like:    `createdBy:000000000000968B createdAfter:1457997222 Test` (e.g. createdBy:000000000000968B Test)
  --limit: int # Maximum number of items you want in the response. (format: int32, default: 1000, e.g. 10)
  --offset: int # The position or row from where to start the search operation. (format: int32, default: 0, e.g. 5)
  --skipChildren: string@bool-completer # a boolean parameter to control skipping fetching children of requested folder(s)
]: nothing -> table<item: record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list>, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "skipChildren" $skipChildren "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/monitors/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a monitor or folder.
#
# GET /v1/monitors/{id}
# Discriminator (response): type
# operationId: monitorsReadById
export def "monitors monitorsReadById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/monitors/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a monitor or folder.
#
# PUT /v1/monitors/{id}
# Discriminator (request): type
# operationId: monitorsUpdateById
export def "monitors monitorsUpdateById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the monitor or folder.
  --description: string # The description of the monitor or folder. (default: )
  version: int # The version of the monitor or folder. (format: int64)
  type: string # Type of the object model.
]: any -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/monitors/($id)")
  let body = {name: $name, description: $description, version: $version, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a monitor or folder.
#
# DELETE /v1/monitors/{id}
# operationId: monitorsDeleteById
export def "monitors monitorsDeleteById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/monitors/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the path of a monitor or folder.
#
# GET /v1/monitors/{id}/path
# operationId: getMonitorsFullPath
export def "monitors-path get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pathItems: table<id: string, name: string, description: string>, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/monitors/($id)/path")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Move a monitor or folder.
#
# POST /v1/monitors/{id}/move
# Discriminator (response): type
# operationId: monitorsMove
export def "monitors-move monitorsMove" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parentId: string # Identifier of the parent folder to move the monitor or folder to.
]: nothing -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parentId" $parentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/monitors/($id)/move" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copy a monitor or folder.
#
# POST /v1/monitors/{id}/copy
# Discriminator (response): type
# operationId: monitorsCopy
export def "monitors-copy monitorsCopy" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  parentId: string # Identifier of the parent folder to copy to.
  --name: string # Optionally provide a new name.
  --description: string # Optionally provide a new description.
]: any -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/monitors/($id)/copy")
  let body = {parentId: $parentId, name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export a monitor or folder.
#
# GET /v1/monitors/{id}/export
# Discriminator (response): type
# operationId: monitorsExportItem
export def "monitors-export monitorsExportItem" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, description: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/monitors/($id)/export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import a monitor or folder.
#
# POST /v1/monitors/{parentId}/import
# Discriminator (request): type
# operationId: monitorsImportItem
export def "monitors-import monitorsImportItem" [
  parentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the monitor or folder.
  --description: string # Description of the monitor or folder.
  type: string # Type of the object model.
]: any -> record<id: string, name: string, description: string, version: int, createdAt: string, createdBy: string, modifiedAt: string, modifiedBy: string, parentId: string, contentType: string, type: string, isSystem: bool, isMutable: bool, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/monitors/($parentId)/import")
  let body = {name: $name, description: $description, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List explicit permissions on monitor or folder.
#
# GET /v1/monitors/{id}/permissions
# operationId: monitorsReadPermissionsById
export def "monitors-permissions monitorsReadPermissionsById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<permissionStatements: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/monitors/($id)/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set permissions on monitor or folder.
#
# PUT /v1/monitors/permissions/set
# operationId: monitorsSetPermissions
# --permissionStatementDefinitions item shape: {permissions: list, subjectType: string, subjectId: string, targetId: string}
export def "monitors-permissions-set monitorsSetPermissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permissionStatementDefinitions: list # List of permission statement definitions. — item shape: {permissions: list, subjectType: string, subjectId: string, targetId: string}
]: any -> record<permissionStatements: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/monitors/permissions/set")
  let body = {permissionStatementDefinitions: $permissionStatementDefinitions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke all permissions on monitor or folder.
#
# PUT /v1/monitors/permissions/revoke
# operationId: monitorsRevokePermissions
# --permissionIdentifiers item shape: {subjectType: string, subjectId: string, targetId: string}
export def "monitors-permissions-revoke monitorsRevokePermissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permissionIdentifiers: list # List of permission identifiers. — item shape: {subjectType: string, subjectId: string, targetId: string}
]: any -> record<id: string, errors: table<code: string, message: string, detail: string, meta: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/monitors/permissions/revoke")
  let body = {permissionIdentifiers: $permissionIdentifiers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List permission summaries for a monitor or folder.
#
# GET /v1/monitors/{id}/permissionSummariesBySubjects
# operationId: monitorsReadPermissionSummariesByIdGroupBySubjects
export def "monitors-permission-summaries-by-subjects monitorsReadPermissionSummariesByIdGroupBySubjects" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<permissionSummariesBySubjects: table<subjectType: string, subjectId: string, permissionSummaries: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/monitors/($id)/permissionSummariesBySubjects")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
